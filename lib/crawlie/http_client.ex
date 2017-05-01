defmodule Crawlie.HttpClient do
  alias Crawlie.Response

  @callback get(uri :: URI.t, opts :: Keyword.t)
    :: {:ok, Response.t} | {:error, term}
end
