defmodule Crawlie.Stage.UrlManagerTest do
  use ExUnit.Case

  alias Heap

  alias Crawlie.Page
  alias Crawlie.Stage.UrlManager
  alias UrlManager.State

  doctest UrlManager

  @urls ["foo", "bar", "baz"]
  @pages @urls |> Enum.map(&Page.new(&1))
  @options [foo: :bar]

  describe "state" do
    test "constructor" do
      state = State.new(@pages, @options)

      assert state.initial == @pages
      assert state.discovered == Heap.max()
      assert state.visited == %{}
      assert state.options == @options
    end

    test "take_pages takes the pages from the heap if available" do
      h = Heap.max

      h = Heap.push(h, Page.new("h1", 1))
      h = Heap.push(h, Page.new("h2", 2))
      h = Heap.push(h, Page.new("h3", 3))

      state = State.new(@pages)
      state = %State{state | discovered: h}

      {new_state, pages} = State.take_pages(state, 2)
      assert Enum.count(pages) == 2
      assert Enum.sort(pages) == Enum.sort([Page.new("h3", 3), Page.new("h2", 2)])

      assert new_state.initial == state.initial
      assert new_state.options == state.options

      assert Heap.size(new_state.discovered) == 1
      assert Heap.root(new_state.discovered) == Page.new("h1", 1)
      # TODO: visited
    end

    test "take_pages takes the pages from both the heap and initial" do
      h = Heap.max

      h = Heap.push(h, Page.new("h1", 1))

      state = State.new(@pages)
      state = %State{state | discovered: h}

      {new_state, pages} = State.take_pages(state, 2)
      assert Enum.count(pages) == 2
      assert Enum.sort(pages) == Enum.sort([Page.new("h1", 1), Page.new("foo")])

      assert new_state.initial == Enum.drop(state.initial, 1)
      assert new_state.options == state.options

      assert Heap.size(new_state.discovered) == 0

      # TODO: visited
    end

    test "take_pages handles the case where everything gets empty" do
      state = State.new(@pages)

      {new_state, pages} = State.take_pages(state, 66)
      assert Enum.sort(pages) == Enum.sort(@pages)

      assert new_state.initial == []
      assert new_state.options == state.options
      # TODO: visited
    end
  end

  test "init/1" do
    args = %{pages: @pages, crawlie_options: @options}

    assert {:producer, state} = UrlManager.init(args)

    assert state.initial == @pages
    assert state.discovered == Heap.max()
    assert state.visited == %{}
    assert state.options == @options
  end


end
