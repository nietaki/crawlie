defmodule Crawlie.Utils do
  @moduledoc false

  @type utime :: integer


  @spec utimestamp(nil | :erlang.timestamp | integer) :: utime

  def utimestamp(ts \\ nil)

  def utimestamp(nil), do: utimestamp(:os.timestamp())

  def utimestamp({macro, secs, micro}) do
    macro * 1_000_000_000_000 + secs * 1_000_000 + micro
  end

  def utimestamp(unixtime) when is_integer(unixtime), do: unixtime * 1_000_000


  @spec usec_to_seconds(utime) :: float

  def usec_to_seconds(usec) when is_integer(usec) do
    usec / 1_000_000
  end

end
