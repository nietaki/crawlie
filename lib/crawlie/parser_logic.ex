defmodule Crawlie.ParserLogic do

  @type parsed :: term
  @type result :: term

  @callback parse(url :: String.t, body :: String.t, options :: Keyword.t) :: {:ok, parsed} | {:error, term}

  @callback extract_links(url :: String.t, parsed, options :: Keyword.t) :: [String.t]

  @callback extract_data(url :: String.t, parsed, options :: Keyword.t) :: [result]

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Crawlie.ParserLogic

      @doc false
      def parse(_url, body, _options), do: {:ok, body}

      @doc false
      def extract_links(_url, _, _options), do: []

      @doc false
      def extract_data(_url, parsed, _options), do: [parsed]

      defoverridable [parse: 3, extract_links: 3, extract_data: 3]
    end
  end

end
