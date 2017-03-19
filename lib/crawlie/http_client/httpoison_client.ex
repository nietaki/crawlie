defmodule Crawlie.HttpClient.HTTPoisonClient do

  alias HTTPoison.Response, as: PoisonResponse
  alias Crawlie.Response

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


  @doc """
  Implements the `Crawlie.HttpClient` behaviour.
  """
  def get(url, opts) do
    headers = Keyword.get(opts, :headers, [])
    httpoison_opts = Keyword.take(opts, @valid_configuration_keys)

    with {:ok, response} <- HTTPoison.get(url, headers, httpoison_opts),
         %PoisonResponse{body: body, headers: headers, status_code: code} = response,
         response = Response.new(url, code, headers, body),
    do: {:ok, response}
  end
end
