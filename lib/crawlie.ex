defmodule Crawlie do

  alias Crawlie.Options

  @spec crawl(Stream.t, module, Keyword.t)
    :: {:ok, Stream.t} | {:error, term}

  def crawl(source, parser_logic, opts \\ []) do
    opts = Keyword.merge(Options.defaults, opts)

    client = Options.get(opts, :http_client)

    results = source
      |> Stream.map(&client.get(&1, opts))
      |> Stream.map(&elem(&1, 1))
      |> Stream.map(&parser_logic.parse("fake_url", &1))
      |> Stream.map(&parser_logic.extract_data(&1))

    results
  end

  def crawl!(source, parser_logic, opts) do
    {:ok, result_stream} = crawl(source, parser_logic, opts)
    result_stream
  end

end
