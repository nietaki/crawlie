defmodule PqueueWrapperTest do

  @pqueue_modules [:pqueue, :pqueue2, :pqueue3, :pqueue4]

  use ExUnit.Case

  alias Crawlie.Page
  alias Crawlie.PqueueWrapper, as: PW

  test "constructor" do
    Enum.each(@pqueue_modules, fn(m) ->
      empty = PW.new(m)
      assert %PW{module: ^m, data: data} = empty
      assert data != nil

      assert data == m.new
    end)
  end

  test "get_priority for :pqueue" do
    empty = PW.new(:pqueue)
    assert PW.get_priority(empty, 0) == 20
    assert PW.get_priority(empty, 40) == -20
  end

  test "get_priority for :pqueue4" do
    empty = PW.new(:pqueue4)
    assert PW.get_priority(empty, 0) == 128
    assert PW.get_priority(empty, 256) == -128
  end

  test "get_priority for :pqueue2 and :pqueue3" do
    Enum.each([:pqueue2, :pqueue3], fn(m) ->
      empty = PW.new(m)
      assert PW.get_priority(empty, 0) == 0
      assert PW.get_priority(empty, 13) == -13
      assert PW.get_priority(empty, 256) == -256
    end)
  end

  test "works in a sample scenario" do
    p0 = Page.new("foo", 0)
    p1 = Page.new("bar", 1)
    p2 = Page.new("bar", 2)
    Enum.each(@pqueue_modules, fn(m) ->
      q = PW.new(m)
      q = PW.add_page(q, p1)
      q = PW.add_page(q, p0)
      q = PW.add_page(q, p2)

      assert PW.len(q) == 3

      assert {q, ^p2} = PW.take(q)
      assert {q, ^p1} = PW.take(q)
      assert {q, ^p0} = PW.take(q)

      assert PW.empty?(q)
      assert PW.len(q) == 0
    end)
  end


end
