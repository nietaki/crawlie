defmodule Crawlie.Stats.Distribution do

  @spec add(map, term, term, integer | float) :: map
  @doc """
  Adds a value to the bucket in the distribution under the given key.

  ## Example
      iex> alias Crawlie.Stats.Distribution
      iex> stats = %{numbers: %{}, enums: %{}}
      iex> stats
      ...>   |> Distribution.add(:numbers, 3)
      ...>   |> Distribution.add(:enums, :foo)
      %{numbers: %{3 => 1}, enums: %{foo: 1}}
  """
  def add(map, key, bucket, amount \\ 1) do
    dist = Map.fetch!(map, key)
    dist = Map.update(dist, bucket, amount, &(&1 + amount))
    Map.put(map, key, dist)
  end


  @spec remove(map, term, term, integer | float) :: map
  @doc """
  Removes a value from the bucket in the distribution under the given key.

  ## Example
      iex> alias Crawlie.Stats.Distribution
      iex> stats = %{numbers: %{0 => 10, 1 => 12}}
      iex> Distribution.remove(stats, :numbers, 1)
      %{numbers: %{0 => 10, 1 => 11}}
  """
  def remove(map, key, bucket, amount \\ 1) do
    add(map, key, bucket, -amount)
  end


  @doc """
  Adds "missing" keys to the distribution for convenience and stuff.

  ## Example
      iex> alias Crawlie.Stats.Distribution
      iex> dist = %{2 => 15, 3 => 10}
      iex> Distribution.normalize(dist, 0..4)
      %{0 => 0, 1 => 0, 2 => 15, 3 => 10, 4 => 0}
  """
  def normalize(dist, keys) do
    Enum.reduce(keys, dist, fn(key, dist) ->
      Map.update(dist, key, 0, &(&1))
    end)
  end


  @doc """
  Converts the distribution from absolute numbers to proportions or
  probability distribution if you will.

  ## Example
      iex> alias Crawlie.Stats.Distribution
      iex> dist = %{1 => 2, 2 => 0, 3 => 3}
      iex> Distribution.proportions(dist)
      %{1 => 0.4, 2 => 0.0, 3 => 0.6}
  """
  def proportions(dist) do
    total = dist |> Map.values() |> Enum.reduce(&(&1 + &2))
    dist
      |> Enum.map(fn {key, value} ->
        {key, 1.0 * value / total}
      end)
      |> Map.new()
  end


end
