defmodule Crawlie.Stats.Server do
  use GenServer

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
