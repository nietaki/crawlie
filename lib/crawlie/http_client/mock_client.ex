defmodule Crawlie.HttpClient.MockClient do

  @behaviour Crawlie.HttpClient

  @doc """
  ### Example
      iex> fun = fn(url) -> {:ok, url <> " body"} end
      iex> opts = [mock_client_fun: fun]
      iex> Crawlie.HttpClient.MockClient.get("http://a.bc/", opts)
      {:ok, "http://a.bc/ body"}
  """
  def get(url, opts) do
    client_function = Keyword.fetch!(opts, :mock_client_fun)
    client_function.(url)
  end


  @doc """
  ### Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_url
      iex> fun.("http://foo.bar/")
      {:ok, "http://foo.bar/"}
  """
  def return_url, do: &{:ok, &1}


  @doc """
  ### Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_html
      iex> fun.("http://foo.bar/")
      {:ok, "<html />"}
  """
  def return_html, do: fn(_url) -> {:ok, "<html />"} end


  @doc """
  ### Example
      iex> alias Crawlie.HttpClient.MockClient
      iex> fun = MockClient.return_error(:foo)
      iex> fun.("http://foo.bar/")
      {:error, :foo}
  """
  def return_error(error), do: fn(_url) -> {:error, error} end
end
