defmodule Crawlie.Options do
  @http_client :http_client

  #===========================================================================
  # API functions
  #===========================================================================

  @spec get(Keyword.t, atom, term) :: term
  @doc """
  Gets the option name from the options.

  If the option isn't specified in the provided options, but crawlie specifies
  a default value, the default is returned.
  """
  def get(opts, option_name, default \\ nil) do
    opts = Keyword.merge(defaults(), opts)
    Keyword.get(opts, option_name, default)
  end

  @spec put(Keyword.t, atom, term) :: Keyword.t
  @doc """
  Puts a option value in the options
  """
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

  defp defaults() do
    [follow_redirect: true, http_client: Crawlie.HttpClient.HTTPoisonClient]
  end

end
