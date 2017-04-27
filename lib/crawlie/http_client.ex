defmodule Crawlie.HttpClient do
  alias Crawlie.Response

  @callback get(url :: String.t, opts :: Keyword.t)
    :: {:ok, Response.t} | {:error, term}
end
