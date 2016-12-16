defmodule Crawlie.Options do

  #===========================================================================
  # API functions
  #===========================================================================

  @spec defaults() :: Keyword.t
  @doc """
  The default options set by Crawlie. If you set your own values in
  `Crawlie.crawl/3`, they will override the defaults.
  """
  def defaults() do
    [follow_redirect: true, http_client: Crawlie.HttpClient.HTTPoisonClient]
  end


  @spec with_defaults(Keyword.t) :: Keyword.t
  @doc """
  Returns the passed-in options merged with the defaults.

  The provided options take precedence over the defaults if there are any common
  keys.
  """
  def with_defaults(options) do
    Keyword.merge(defaults(), options)
  end


  @spec with_mock_client(Keyword.t) :: Keyword.t
  @doc """
  Returns the options with `Crawlie.HttpClient.MockClient` set as the HTTP client.
  """
  def with_mock_client(options) do
    Keyword.put(options, :http_client, Crawlie.HttpClient.MockClient)
  end




end
