defmodule Crawlie.Utils do
  @moduledoc false

  @spec utimestamp(nil | :erlang.timestamp | integer) :: Types.utimestamp

  def utimestamp(ts \\ nil)

  def utimestamp(nil), do: utimestamp(:os.timestamp())

  def utimestamp({macro, secs, micro}) do
    macro * 1_000_000_000_000 + secs * 1_000_000 + micro
  end

  def utimestamp(unixtime) when is_integer(unixtime), do: unixtime * 1_000_000


  def usec_to_seconds(usec) when is_integer(usec) do
    usec / 1_000_000
  end

end
