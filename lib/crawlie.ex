defmodule Crawlie do

  alias Crawlie.Options


  @spec crawl(Stream.t, module, Keyword.t) :: Stream.t
  @doc """
  Crawls the urls provided in `source`, using the `Crawlie.ParserLogic` provided
  in `parser_logic`.

  The `options` are used to tweak the crawler's behaviour. You can use most of
  the options for [HttPoison](https://hexdocs.pm/httpoison/HTTPoison.html#request/5),
  as well as Crawlie specific options.

  ## Crawlie options

  - `:http_client` - module implementing the `Crawlie.HttpClient` behaviour to be
    used to make the requests.
  - `:mock_client_fun` - If you're using the `Crawlie.HttpClient.MockClient`, this
    would be the `url -> {:ok, body :: String.t} | {:error, term}` function simulating
    making the requests.
  """
  def crawl(source, parser_logic, options \\ []) do
    options = Options.with_defaults(options)
    client = Keyword.get(options, :http_client)

    results = source
      |> Stream.map(&client.get(&1, options))
      |> Stream.map(&elem(&1, 1))
      |> Stream.map(&parser_logic.parse("fake_url", &1))
      |> Stream.flat_map(&parser_logic.extract_data(&1))

    results
  end

end
