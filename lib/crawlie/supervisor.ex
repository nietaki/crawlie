defmodule Crawlie.Supervisor do
  use Supervisor

  @name __MODULE__

  #===========================================================================
  # API
  #===========================================================================

  @spec start_stats_server() :: {:ok, pid()}

  def start_stats_server() do
    Supervisor.start_child(@name, [])
  end

  #===========================================================================
  # Plumbing
  #===========================================================================

  def start_link() do
    options = [
      name: @name
    ]
    Supervisor.start_link(__MODULE__, [], options)
  end

  def init([]) do
    children = [
      worker(Crawlie.Stats.Server, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
