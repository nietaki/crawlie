defmodule Crawlie.HttpClient do
  @type body :: String.t

  @callback get(url :: String.t, opts :: Keyword.t)
    :: {:ok, body} | {:error, term}
end
