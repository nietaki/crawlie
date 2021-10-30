defmodule Crawlie.ParserLogic do

  alias Crawlie.Response

  @type parsed :: term
  @type result :: term

  @type parse_result :: {:ok, parsed} | {:error, term} | :skip | {:skip, reason :: atom}

  @doc """
  Parses the retrieved page to user-defined data.

  The `t:parsed/0` response gets passed on to subsequent operations along with the
  original `t:Crawlie.Response.t/0`.

  Returning `:skip` or `{:skip, reason}` skips the page from further processing without
  signalling an error. This can be used for omitting pages with unsupported / not
  interesting content types.

  If you don't need to transform the received `t:Crawlie.Response.t/0`, you can use the default
  implementation or return `{:ok, :this_can_be_whatever}`.
  """
  @callback parse(Response.t, options :: Keyword.t) :: parse_result

  @doc """
  Extracts the uri's to be crawled subsequently.
  """
  @callback extract_uris(Response.t, parsed, options :: Keyword.t) :: [URI.t | String.t]

  @doc """
  Extracts the final data from the parsed page.

  Note, this callback should return a list - you can return one, zero or many items
  that will be put in the `t:Flow.t/0` returned by `Crawlie.crawl/3` - similar
  as in `Enum.flat_map/2`.
  """
  @callback extract_data(Response.t, parsed, options :: Keyword.t) :: [result]

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Crawlie.ParserLogic

      @doc false
      def parse(%Response{body: body}, _options), do: {:ok, body}

      @doc false
      def extract_uris(_response, _parsed, _options), do: []

      @doc false
      def extract_data(_response, parsed, _options), do: [parsed]

      defoverridable [parse: 2, extract_uris: 3, extract_data: 3]
    end
  end

end
