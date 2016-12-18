defmodule Crawlie.ParserLogic do

  @type processed :: term
  @type result :: term

  @callback parse(url :: String.t, body :: String.t) :: processed

  @callback extract_links(url :: String.t, processed) :: [String.t]

  @callback extract_data(url :: String.t, processed) :: [result]

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Crawlie.ParserLogic

      @doc false
      def parse(_url, body), do: body

      @doc false
      def extract_links(_url, _), do: []

      @doc false
      def extract_data(_url, processed), do: [processed]

      defoverridable [parse: 2, extract_links: 2, extract_data: 2]
    end
  end

end
