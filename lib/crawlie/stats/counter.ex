defmodule Crawlie.Stats.Counter do

  @spec inc(map, term, integer | float) :: map
  @doc """
  Increases the value of a counter in the map.

  ## Example
      iex> alias Crawlie.Stats.Counter
      iex> stats = %{foo: 10, bar: 20.0}
      iex> stats
      ...>   |> Counter.inc(:foo)
      ...>   |> Counter.inc(:bar, 2.0)
      %{foo: 11, bar: 22.0}
  """
  def inc(map, key, amount \\ 1) do
    Map.update!(map, key, &(&1 + amount))
  end


  @spec dec(map, term, integer | float) :: map
  @doc """
  Increases the value of a counter in the map.

  ## Example
      iex> alias Crawlie.Stats.Counter
      iex> stats = %{foo: 10, bar: 20.0}
      iex> stats
      ...>   |> Counter.dec(:foo)
      ...>   |> Counter.dec(:bar, 2.0)
      %{foo: 9, bar: 18.0}
  """
  def dec(map, key, amount \\ 1) do
    Map.update!(map, key, &(&1 - amount))
  end
end
