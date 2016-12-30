defmodule Crawlie do

  @moduledoc """
  The simple Elixir web crawler.
  """

  require Logger

  alias Experimental.GenStage
  alias Experimental.Flow

  alias Crawlie.Options
  alias Crawlie.Page
  alias Crawlie.Stage.UrlManager


  @spec crawl(Stream.t, module, Keyword.t) :: Flow.t
  @doc """
  Crawls the urls provided in `source`, using the `Crawlie.ParserLogic` provided
  in `parser_logic`.

  The `options` are used to tweak the crawler's behaviour. You can use most of
  the options for [HttPoison](https://hexdocs.pm/httpoison/HTTPoison.html#request/5),
  as well as Crawlie specific options.


  ## arguments
  - `source` - a `Stream` or an `Enum` containing the urls to crawl
  - `parser_logic`-  a `Crawlie.ParserLogic` behaviour implementation
  - `options` - a Keyword List of options

  ## Crawlie specific options

  - `:http_client` - module implementing the `Crawlie.HttpClient` behaviour to be
    used to make the requests. If not provided, will default to `Crawlie.HttpClient.HTTPoisonClient`.
  - `:mock_client_fun` - If you're using the `Crawlie.HttpClient.MockClient`, this
    would be the `url -> {:ok, body :: String.t} | {:error, term}` function simulating
    making the requests.
    for details
  - `:max_depth` - maximum crawling "depth". `0` by default.
  - `:max_retries` - maximum amount of tries Crawlie should try to fetch any individual
    page before giving up. By default `3`.
  - `:fetch_phase` - `Flow` partition configuration for the fetching phase of the crawling `Flow`.
    It should be a Keyword List containing any subset of `:min_demand`, `:max_demand` and `:stages`
    properties. For the meaning of these options see [Flow documentation](https://hexdocs.pm/gen_stage/Experimental.Flow.html)
  - `:process_phase` - same as `:fetch_phase`, but for the processing (page parsing, data and link
    extraction) part of the process
  - `:url_manager_timeout` - time in ms the `Crawlie.UrlManager` will wait for new extracted
    urls from the worker processes before wrapping up the output Flow. Will go away when
    [#7](https://github.com/nietaki/crawlie/issues/7) is implemented. Defaults to `200`.
  """
  def crawl(source, parser_logic, options \\ []) do
    options = Options.with_defaults(options)

    {:ok, url_stage} = UrlManager.start_link(source, options)

    url_stage
      |> Flow.from_stage(options)
      |> Flow.partition(Keyword.get(options, :fetch_phase))
      |> Flow.flat_map(&fetch_operation(&1, options, url_stage))
      |> Flow.partition(Keyword.get(options, :process_phase))
      |> Flow.flat_map(&parse_operation(&1, options, parser_logic))
      |> Flow.each(&extract_links_operation(&1, options, parser_logic, url_stage))
      |> Flow.flat_map(&extract_data_operation(&1, options, parser_logic))
  end


  @spec fetch_operation(Page.t, Keyword.t, GenStage.stage) :: [{Page.t, String.t}]
  @doc false
  def fetch_operation(%Page{url: url} = page, options, url_stage) do
    client = Keyword.get(options, :http_client)
    case client.get(url, options) do
      {:ok, body} -> [{page, body}]
      {:error, _reason} ->
        UrlManager.retry_page(url_stage, page)
        []
    end
  end


  @spec parse_operation({Page.t, String.t}, Keyword.t, module) :: [{Page.t, term}]
  @doc false
  def parse_operation({%Page{url: url} = page, body}, options, parser_logic) when is_binary(body) do

    case parser_logic.parse(url, body, options) do
      {:ok, parsed} -> [{page, parsed}]
      {:error, reason} ->
        Logger.warn "could not parse #{inspect page.url}, parsing failed with error #{inspect reason}"
        []
    end
  end


  @spec extract_links_operation({Page.t, term}, Keyword.t, module, GenStage.stage) :: any
  @doc false
  def extract_links_operation({%Page{url: url, depth: depth} = page, parsed}, options, module, url_stage) do
    max_depth = Keyword.get(options, :max_depth, 0)
    if depth < max_depth do
      pages = module.extract_links(url, parsed, options)
        |> Enum.map(&Page.child(page, &1))
      UrlManager.add_children_pages(url_stage, pages)
    end

    nil
  end


  @spec extract_data_operation({Page.t, term}, Keyword.t, module) :: [term]
  @doc false
  def extract_data_operation({%Page{url: url}, parsed}, options, module) do
    module.extract_data(url, parsed, options)
  end


  def is_ok_tuple({:ok, _}), do: true
  def is_ok_tuple(_), do: false

end
