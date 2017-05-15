defmodule Crawlie.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("Crawlie.Application started")
    Crawlie.Supervisor.start_link()
  end
end
