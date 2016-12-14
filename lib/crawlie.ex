defmodule Crawlie do

  alias Crawlie.Options

  @spec crawl!(Stream.t, module, Keyword.t) :: Stream.t

  def crawl!(source, parser_logic, opts \\ []) do
    client = Options.get(opts, :http_client)

    results = source
      |> Stream.map(&client.get(&1, opts))
      |> Stream.map(&elem(&1, 1))
      |> Stream.map(&parser_logic.parse("fake_url", &1))
      |> Stream.map(&parser_logic.extract_data(&1))

    results
  end

end
