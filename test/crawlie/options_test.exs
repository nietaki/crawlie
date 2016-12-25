defmodule Crawlie.OptionsTest do
  use ExUnit.Case

  alias Crawlie.Options

  test "getting the http client" do
    defaults = Options.defaults
    assert Keyword.get(defaults, :http_client) == Crawlie.HttpClient.HTTPoisonClient

    with_different_client = Keyword.put(defaults, :http_client, :foo)
    assert Keyword.get(with_different_client, :http_client) == :foo
  end

  test "getting a default option" do
    defaults = Options.defaults
    assert true == Keyword.get(defaults, :follow_redirect)
  end

  describe "merge_options" do
    test "doesn't break for empty lists" do
      assert [] == Options.merge([], [])
    end

    test "works on non-overlapping keys" do
      res = Options.merge([foo: :bar], [baz: :ban])
      assert_sorted_equals(res, [foo: :bar, baz: :ban])
    end

    test "works on overlapping keys" do
      res = Options.merge([foo: :bar], [foo: :ban])
      assert_sorted_equals(res, [foo: :ban])
    end

    test "works with overlapping keys" do
      o1 = [abc: [foo: :bar]]
      o2 = [abc: [baz: :ban]]

      res = Options.merge(o1, o2)
      assert_sorted_equals [abc: [foo: :bar, baz: :ban]], res
    end

    test "works with overlapping keys and partially overlapping values" do
      o1 = [abc: [foo: :bar, bat: :man]]
      o2 = [abc: [baz: :ban, bat: :boy]]

      res = Options.merge(o1, o2)
      assert_sorted_equals [abc: [bat: :boy, foo: :bar, baz: :ban]], res
    end
  end

  #===========================================================================
  # Helper functions
  #===========================================================================

  defp assert_sorted_equals(e1, e2) do
    assert deep_sort(e1) == deep_sort(e2)
  end

  # only sorts lists, for convenience
  defp deep_sort(ls) when is_list(ls) do
    ls
      |> Enum.map(fn{k, v} -> {k, deep_sort(v)} end)
      |> Enum.sort
  end
  defp deep_sort(whatever), do: whatever
end
