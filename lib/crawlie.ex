defmodule Crawlie do

  @moduledoc """
  The simple Elixir web crawler.
  """

  require Logger

  alias Crawlie.Options
  alias Crawlie.Page
  alias Crawlie.Response
  alias Crawlie.Utils
  alias Crawlie.Stage.UrlManager
  alias Crawlie.Stats.Server, as: StatsServer


  @spec crawl(Stream.t, module, Keyword.t) :: Flow.t
  @doc """
  Crawls the urls provided in `source`, using the `Crawlie.ParserLogic` provided
  in `parser_logic`.

  The `options` are used to tweak the crawler's behaviour. You can use most of
  the options for [HttPoison](https://hexdocs.pm/httpoison/HTTPoison.html#request/5),
  as well as Crawlie specific options.

  It is perfectly ok to run multiple crawling sessions at the same time, they're independent.

  ## arguments
  - `source` - a `Stream` or an `Enum` containing the urls to crawl
  - `parser_logic`-  a `Crawlie.ParserLogic` behaviour implementation
  - `options` - a Keyword List of options

  ## Crawlie specific options

  - `:http_client` - module implementing the `Crawlie.HttpClient` behaviour to be
    used to make the requests. If not provided, will default to `Crawlie.HttpClient.HTTPoisonClient`.
  - `:mock_client_fun` - If you're using the `Crawlie.HttpClient.MockClient`, this
    would be the `url :: String.t -> {:ok, body :: String.t} | {:error, term}` function simulating
    making the requests.
    for details
  - `:max_depth` - maximum crawling "depth". `0` by default.
  - `:max_retries` - maximum amount of tries Crawlie should try to fetch any individual
    page before giving up. By default `3`.
  - `:fetch_phase` - `Flow` partition configuration for the fetching phase of the crawling `Flow`.
    It should be a Keyword List containing any subset of `:min_demand`, `:max_demand` and `:stages`
    properties. For the meaning of these options see [Flow documentation](https://hexdocs.pm/gen_stage/Flow.html)
  - `:process_phase` - same as `:fetch_phase`, but for the processing (page parsing, data and link
    extraction) part of the process
  - `:pqueue_module` - One of [pqueue](https://github.com/okeuday/pqueue) implementations:
    `:pqueue`, `:pqueue2`, `:pqueue3`, `:pqueue4`. Different implementation have different
    performance characteristics and allow for different `:max_depth` values. Consult
    [docs](https://github.com/okeuday/pqueue) for details. By default using `:pqueue3` -
    good performance and allowing arbitrary `:max_depth` values.
  """
  def crawl(source, parser_logic, options \\ []) do
    options = options
      |> Options.strip_reserved()
      |> Options.with_defaults()

    _crawl(source, parser_logic, options)
  end


  @spec crawl_and_track_stats(Stream.t, module, Keyword.t) :: {StatsServer.ref, Flow.t}
  @doc """
  Crawls the urls provided in `source`, using the `Crawlie.ParserLogic` provided and collects the crawling statistics.

  The statistics are accumulated independently, per `Crawlie.crawl_and_track_stats/3` call.

  See `Crawlie.crawl/3` for details.

  ## Additional options

  (apart from the ones from `Crawlie.crawl/3`, which all apply as well)

  - `:max_fetch_failed_uris_tracked` - `100` by default. The maximum quantity of uris that will be kept in the `Crawlie.Stats.Server`, for which the fetch operation was failed.
  - `:max_parse_failed_uris_tracked` - `100` by default. The maximum quantity of uris that will be kept in the `Crawlie.Stats.Server`, for which the parse operation was failed.
  """
  def crawl_and_track_stats(source, parser_logic, options \\ []) do
    ref = StatsServer.start_new()

    options = options
      |> Options.strip_reserved()
      |> Keyword.put(:stats_ref, ref)
      |> Options.with_defaults()

    flow = _crawl(source, parser_logic, options)

    {ref, flow}
  end


  defp _crawl(source, parser_logic, options) do
    {:ok, url_stage} = UrlManager.start_link(source, options)

    [url_stage]
      |> Flow.from_stages(options)
      |> Flow.partition(Keyword.get(options, :fetch_phase))
      |> Flow.flat_map(&fetch_operation(&1, options, url_stage))
      |> Flow.partition(Keyword.get(options, :process_phase))
      |> Flow.flat_map(&parse_operation(&1, options, parser_logic, url_stage))
      |> Flow.each(&extract_uris_operation(&1, options, parser_logic, url_stage))
      |> Flow.flat_map(&extract_data_operation(&1, options, parser_logic))
  end


  @spec fetch_operation(Page.t, Keyword.t, GenStage.stage) :: [{Page.t, String.t}]
  @doc false
  def fetch_operation(%Page{uri: uri} = page, options, url_stage) do
    client = Keyword.get(options, :http_client)
    start_time = Utils.utimestamp()
    case client.get(uri, options) do
      {:ok, response} ->
        duration_usec = Utils.utimestamp() - start_time
        Options.stats_op(options, &StatsServer.fetch_succeeded(&1, page, response, duration_usec))
        [{page, response}]
      {:error, _reason} ->
        UrlManager.page_failed(url_stage, page)
        max_failed_uris_to_track = Keyword.fetch!(options, :max_fetch_failed_uris_tracked)
        Options.stats_op(options, &StatsServer.fetch_failed(&1, page, max_failed_uris_to_track))
        []
    end
  end


  @spec parse_operation({Page.t, Response.t}, Keyword.t, module, GenStage.stage) :: [{Page.t, term}]
  @doc false
  def parse_operation({%Page{} = page, %Response{} = response}, options, parser_logic, url_stage) do

    case parser_logic.parse(response, options) do
      {:ok, parsed} ->
        [{page, response, parsed}]
      :skip ->
        UrlManager.page_skipped(url_stage, page)
        Options.stats_op(options, &StatsServer.page_skipped(&1, page))
        []
      {:skip, _reason} ->
        UrlManager.page_skipped(url_stage, page)
        Options.stats_op(options, &StatsServer.page_skipped(&1, page))
        []
      {:error, reason} ->
        UrlManager.page_failed(url_stage, page)
        max_failed_uris_to_track = Keyword.fetch!(options, :max_parse_failed_uris_tracked)
        Options.stats_op(options, &StatsServer.parse_failed(&1, page, max_failed_uris_to_track))
        Logger.warn "could not parse \"#{Page.url(page)}\", parsing failed with error #{inspect reason}"
        []
    end
  end


  @spec extract_uris_operation({Page.t, Response.t, term}, Keyword.t, module, GenStage.stage) :: any
  @doc false
  def extract_uris_operation({%Page{depth: depth} = page, response, parsed}, options, module, url_stage) do
    max_depth = Keyword.get(options, :max_depth, 0)
    if depth < max_depth do
      pages = module.extract_uris(response, parsed, options)
        |> Enum.map(&Page.child(page, &1))
      UrlManager.add_children_pages(url_stage, pages)
      Options.stats_op(options, &StatsServer.uris_extracted(&1, Enum.count(pages)))
    end

    UrlManager.page_succeeded(url_stage, page)
    :ok
  end


  @spec extract_data_operation({Page.t, term}, Keyword.t, module) :: [term]
  @doc false
  def extract_data_operation({_page, response, parsed}, options, module) do
    module.extract_data(response, parsed, options)
  end

end
