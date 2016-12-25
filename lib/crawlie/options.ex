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
    [
      follow_redirect: true,
      http_client: Crawlie.HttpClient.HTTPoisonClient,
      url_manager_timeout: 200,
      max_depth: 0,
      max_retries: 3,
      fetch_phase: [
        min_demand: 1,
        max_demand: 5,
        stages: core_count() * 2,
      ],
      process_phase: [
        min_demand: 5,
        max_demand: 10,
        stages: core_count(),
      ]
    ]
  end

  @spec partition_options() :: Keyword.t
  @doc """
  Keys of the options that can be used to tune a GenStage Flow partition performance
  """
  def partition_options() do
    [
      :min_demand,
      :max_demand,
      :stages,
    ]
  end


  @spec with_defaults(Keyword.t) :: Keyword.t
  @doc """
  Returns the passed-in options merged with the defaults.

  The provided options take precedence over the defaults if there are any common
  keys.
  """
  def with_defaults(options) do
    merge(defaults(), options)
  end

  @spec merge(default :: Keyword.t, overriding :: Keyword.t) :: Keyword.t
  @doc """
  Deep-merges the provided options, keeping the default values for not overridden keys

  Works for nested keyword lists
  """
  def merge(default, overriding) when is_list(default) and is_list(overriding) do
    Keyword.merge(default, overriding, fn(_k, v1, v2) -> merge(v1, v2) end)
  end
  def merge(_default, overriding), do: overriding



  @spec with_mock_client(Keyword.t) :: Keyword.t
  @doc """
  Returns the options with `Crawlie.HttpClient.MockClient` set as the HTTP client.
  """
  def with_mock_client(options) do
    Keyword.put(options, :http_client, Crawlie.HttpClient.MockClient)
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================

  def core_count(), do: System.schedulers_online

end
