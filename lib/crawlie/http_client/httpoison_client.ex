defmodule Crawlie.HttpClient.HTTPoisonClient do

  alias HTTPoison.Response

  @behaviour Crawlie.HttpClient

  @valid_configuration_keys [
    :timeout,
    :recv_timeout,
    :proxy,
    :proxy_auth,
    :ssl,
    :follow_redirect,
    :max_redirect,
    :params,
  ]


  def get(url, opts) do
    headers = Keyword.get(opts, :headers, [])
    httpoison_opts = Keyword.take(opts, @valid_configuration_keys)

    with  {:ok, response} <- HTTPoison.get(url, headers, httpoison_opts),
          %Response{body: body} = response,
    do: {:ok, body}
  end
end
