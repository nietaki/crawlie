defmodule Crawlie.ParserLogic do

  alias Crawlie.Response

  @type parsed :: term
  @type result :: term

  @callback parse(Response.t, options :: Keyword.t) :: {:ok, parsed} | {:error, term}

  @callback extract_links(Response.t, parsed, options :: Keyword.t) :: [String.t]

  @callback extract_data(Response.t, parsed, options :: Keyword.t) :: [result]

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Crawlie.ParserLogic

      @doc false
      def parse(%Response{body: body}, _options), do: {:ok, body}

      @doc false
      def extract_links(_response, _parsed, _options), do: []

      @doc false
      def extract_data(_response, parsed, _options), do: [parsed]

      defoverridable [parse: 2, extract_links: 3, extract_data: 3]
    end
  end

end
