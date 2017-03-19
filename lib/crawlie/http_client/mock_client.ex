defmodule Crawlie.HttpClient.MockClient do

  alias Crawlie.Response

  @behaviour Crawlie.HttpClient

  @doc """
  Implements the `Crawlie.HttpClient` behaviour.

  ## Example
      iex> fun = fn(url) -> {:ok, url <> " body"} end
      iex> opts = [mock_client_fun: fun]
      iex> {:ok, response} = Crawlie.HttpClient.MockClient.get("http://a.bc/", opts)
      iex> response.status_code
      200
      iex> response.headers
      []
      iex> response.body
      "http://a.bc/ body"
  """
  def get(url, opts) do
    client_function = Keyword.fetch!(opts, :mock_client_fun)
    case client_function.(url) do
      {:ok, body} when is_binary(body) ->
        {:ok, Response.new(url, 200, [], body)}
      {:error, _reason} = err -> err
      els -> raise "unexpected value returned from the mock client function: #{inspect els}"
    end
  end


  @doc """
  A helper `:mock_client_fun` returning a success and the passed url.

  ## Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_url
      iex> fun.("http://foo.bar/")
      {:ok, "http://foo.bar/"}
  """
  def return_url, do: &{:ok, &1}


  @doc """
  A helper `:mock_client_fun` returning `"<html />"` for any passed url.

  ## Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_html
      iex> fun.("http://foo.bar/")
      {:ok, "<html />"}
  """
  def return_html, do: fn(_url) -> {:ok, "<html />"} end


  @doc """
  A helper `:mock_client_fun` returning a `:foo` error for any passed url.

  ## Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_error(:foo)
      iex> fun.("http://foo.bar/")
      {:error, :foo}
  """
  def return_error(error), do: fn(_url) -> {:error, error} end


end
