defmodule Crawlie.ParserLogic do

  @type processed :: term
  @type result :: term

  @callback parse(url :: String.t, body :: String.t) :: processed

  @callback extract_links(processed) :: [String.t]

  # @callback filter_link(String.t) :: boolean

  @callback extract_data(processed) :: [result]

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Crawlie.ParserLogic

      @doc false
      def parse(_url, body), do: body

      @doc false
      def extract_links(_), do: []

      @doc false
      def extract_data(processed), do: [processed]

      defoverridable [parse: 2, extract_links: 1, extract_data: 1]
    end
  end

end
