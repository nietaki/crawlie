defmodule Crawlie.Options do
  @http_client :http_client

  #===========================================================================
  # API functions
  #===========================================================================

  def get(opts, option_name) do
    opts = Keyword.merge(defaults(), opts)
    Keyword.get(opts, option_name)
  end

  def put(opts, option_name, value) do
    Keyword.put(opts, option_name, value)
  end

  #===========================================================================
  # Helper functions
  #===========================================================================

  @doc false
  def with_mock_client do
    put(Keyword.new, :http_client, Crawlie.HttpClient.MockClient)
  end


  #===========================================================================
  # Internal functions
  #===========================================================================

  def defaults() do
    [follow_redirect: true, http_client: Crawlie.HttpClient.HTTPoisonClient]
  end

end
