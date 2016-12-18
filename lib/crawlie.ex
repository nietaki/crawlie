defmodule Crawlie do

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
  - `options` - options

  ## Crawlie options

  - `:http_client` - module implementing the `Crawlie.HttpClient` behaviour to be
    used to make the requests. If not provided, will default to `Crawlie.HttpClient.HTTPoisonClient`.
  - `:mock_client_fun` - If you're using the `Crawlie.HttpClient.MockClient`, this
    would be the `url -> {:ok, body :: String.t} | {:error, term}` function simulating
    making the requests.
  """
  def crawl(source, parser_logic, options \\ []) do
    options = Options.with_defaults(options)

    {:ok, url_stage} = UrlManager.start_link(source, options)

    url_stage
      |> Flow.from_stage(options)
      |> Flow.flat_map(&fetch_operation(&1, options, url_stage))
      |> Flow.map(&parse_operation(&1, options, parser_logic))
      |> Flow.each(&extract_links_operation(&1, options, parser_logic, url_stage))
      |> Flow.flat_map(&extract_data_operation(&1, options, parser_logic))
  end


  @spec fetch_operation(Page.t, Keyword.t, GenStage.stage) :: [{Page.t, String.t}]
  @doc false
  def fetch_operation(%Page{url: url} = page, options, _url_stage) do
    client = Keyword.get(options, :http_client)
    case client.get(url, options) do
      {:ok, body} -> [{page, body}]
      {:error, _reason} ->
        #TODO retry
        []
    end
  end


  @spec parse_operation({Page.t, String.t}, Keyword.t, module) :: {Page.t, term}
  @doc false
  def parse_operation({%Page{url: url} = page, body}, options, parser_logic) when is_binary(body) do
    parsed = parser_logic.parse(url, body, options)
    {page, parsed}
  end


  @spec extract_links_operation({Page.t, term}, Keyword.t, module, GenStage.stage) :: any
  @doc false
  def extract_links_operation({%Page{url: url} = page, parsed}, options, module, url_stage) do
    pages = module.extract_links(url, parsed, options)
      |> Enum.map(&Page.child(page, &1))
    UrlManager.add_pages(url_stage, pages)
    nil
  end


  @spec extract_data_operation({Page.t, term}, Keyword.t, module) :: [term]
  @doc false
  def extract_data_operation({%Page{url: url}, parsed}, options, module) do
    module.extract_data(url, parsed, options)
  end

end
