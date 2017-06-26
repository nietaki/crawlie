defmodule Crawlie.Stage.UrlManagerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Crawlie.Page
  alias Crawlie.Stage.UrlManager
  alias Crawlie.PqueueWrapper, as: PW
  alias UrlManager.State

  doctest UrlManager

  @foo URI.parse("foo")
  @pfoo Page.new(@foo)

  @bar URI.parse("bar")
  @pbar Page.new(@bar)

  @baz URI.parse("baz")
  @pbaz Page.new(@baz)

  @pages [@pfoo, @pbar, @pbaz]
  @pq_module :pqueue3
  @options [foo: :bar, pqueue_module: @pq_module]

  #---------------------------------------------------------------------------
  # testing State
  #---------------------------------------------------------------------------
  test "constructor" do
    empty = State.new([], @options)
    assert State.finished_crawling?(empty) == true

    state = State.new(@pages, @options)

    assert length(@pages) == PW.len(state.discovered)
    assert Enum.sort(@pages) == Enum.sort(PW.all(state.discovered))
    assert state.options == @options
    assert Enum.count(state.visited) == 3
    assert State.finished_crawling?(state) == false
  end

  test "take_pages takes the pages from the priority queue" do
    state = State.new(@pages, @options)
    assert State.finished_crawling?(state) == false

    {new_state, pages} = State.take_pages(state, 2)
    # those could actually be any other two, but this is easier to test ;)
    assert pages == [@pbar, @pfoo]

    assert new_state.options == state.options

    assert PW.len(new_state.discovered) == 1
    assert {_, @pbaz} = PW.take(new_state.discovered)
    assert State.finished_crawling?(new_state) == false
  end

  test "take_pages handles the case where everything gets empty" do
    state = State.new(@pages, @options)

    {new_state, pages} = State.take_pages(state, 66)
    assert Enum.sort(pages) == Enum.sort(@pages)

    assert new_state.options == state.options
    refute State.finished_crawling?(new_state)

    state = new_state
    [a, b, c] = @pages

    state = State.finished_processing(state, a.uri)
    refute State.finished_crawling?(state)
    state = State.finished_processing(state, b.uri)
    refute State.finished_crawling?(state)
    state = State.finished_processing(state, c.uri)
    assert State.finished_crawling?(state)
  end

  test "add_pages/2" do
    state = State.new([], [max_depth: 5, max_retries: 3] ++ @options)
    p1 = %Page{uri: uri(@foo), depth: 5, retries: 3}
    p2 = %Page{uri: uri(@bar), depth: 6, retries: 0} # too deep
    p3 = %Page{uri: uri(@bar), depth: 1, retries: 4} # too many retries

    assert capture_log(fn ->
      new_state = State.add_pages(state, [p1, p2, p3])

      assert PW.len(new_state.discovered) == 1
      assert {_, ^p1} = PW.take(new_state.discovered)
    end) =~ "[error] Trying to add a page \"bar\" with 'depth' > max_depth:"
  end

  test "add_pages/2 doesn't add duplicate uris" do
    state = State.new([], [max_depth: 5] ++ @options)
    p1 = %Page{uri: uri(@foo), depth: 0, retries: 0}
    p2 = %Page{uri: uri(@foo), depth: 1, retries: 0}

    new_state = State.add_pages(state, [p1, p2])

    assert PW.len(new_state.discovered) == 1
    assert {_, ^p1} = PW.take(new_state.discovered)
  end

  test "adding a page that was retrieved before doesn't make it fetched again" do
    pages = [@foo, @bar] |> Enum.map(&Page.new/1)
    state = State.new(pages, [max_depth: 5, max_retries: 3] ++ @options)

    {state, _} = State.take_pages(state, 10)
    retried = %Page{uri: uri(@foo), depth: 1, retries: 0}

    state = State.add_pages(state, [retried])

    assert {_, pages} = State.take_pages(state, 10)
    assert pages == []
  end

  test "even if the input urls contain duplicates, the output ones don't" do
    pages = [@foo, @foo, @bar, @baz] |> Enum.map(&Page.new/1)
    pages2 = [@bar, "ban"] |> Enum.map(&Page.new/1)
    state = State.new(pages, [max_depth: 5, max_retries: 3] ++ @options)
    state = State.add_pages(state, pages2)

    {_state, pages} = State.take_pages(state, 10)
    assert Enum.sort(pages) == Enum.sort(Enum.map([@foo, @bar, @baz, "ban"], &Page.new/1))
  end

  test "tracks items in-flight" do
    empty = State.new([], @options)
    assert State.finished_crawling?(empty)

    state = State.started_processing(empty, @foo)
    refute State.finished_crawling?(state)

    state = State.started_processing(state, @bar)
    refute State.finished_crawling?(state)

    state = State.finished_processing(state, @bar)
    refute State.finished_crawling?(state)

    state = State.finished_processing(state, @foo)
    assert State.finished_crawling?(state)
  end

  #---------------------------------------------------------------------------
  # Testing Manager
  #---------------------------------------------------------------------------

  test "init/1" do
    args = %{pages: @pages, crawlie_options: @options}

    assert {:producer, state} = UrlManager.init(args)

    assert PW.len(state.discovered) == 3
    assert state.options == @options
  end


  #===========================================================================
  # Helper Functions
  #===========================================================================

  defp uri(url), do: URI.parse(url)

end
