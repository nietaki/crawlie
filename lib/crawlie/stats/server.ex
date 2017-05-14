defmodule Crawlie.Stats.Server do
  use GenServer

  defmodule Data do
    alias __MODULE__, as: This

    defstruct [
      uris_visited: 0, # fetch
      uris_extracted: 0, # extract
      retry_count_dist: %{}, # fetch
      bytes_received: 0, # fetch
      status_codes_dist: %{}, # fetch
      content_types_dist: %{}, # fetch?
      failed_fetch_uris: MapSet.new(), # fetch
      failed_parse_uris: MapSet.new(), # parse

      status: :ready, # fetch, for simplicity, also UrlManager.shutdown_gracefully()

      utimestamp_started: nil, # see status
      utimestamp_finished: nil, # see status
      usec_spent_fetching: nil, # fetch
    ]

    def new(), do: %This{}
  end


  alias __MODULE__, as: This

  @ref_marker :stats

  @type ref :: {:stats, pid()}

  #===========================================================================
  # API Functions
  #===========================================================================

  @spec get_new_ref() :: ref
  @doc false
  def get_new_ref() do
    {:ok, pid} = Crawlie.Supervisor.start_stats_server
    pid_to_ref(pid)
  end


  @spec get_stats(ref) :: map

  def get_stats(ref) do
    pid = ref_to_pid(ref)
    GenServer.call(pid, :get_stats)
  end


  #===========================================================================
  # Business logic
  #===========================================================================

  def handle_call(:get_stats, _from, state) do
    {:reply, state, state}
  end

  #===========================================================================
  # Plumbing
  #===========================================================================

  def init() do
    state = %{}
    {:ok, state}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end


  #===========================================================================
  # Inernal Functions
  #===========================================================================

  defp pid_to_ref(pid) do
    {@ref_marker, pid}
  end


  defp ref_to_pid({@ref_marker, pid}), do: pid

end
