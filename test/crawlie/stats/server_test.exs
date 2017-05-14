defmodule Crawlie.Stats.ServerTest do
  use ExUnit.Case

  alias Crawlie.Stats.Server
  alias Crawlie.Stats.Server.Data
  alias Crawlie.Utils
  alias Crawlie.Page
  alias Crawlie.Response

  test "get_stats on a fresh server" do
    ref = Server.start_new()

    assert %Data{} = data = Server.get_stats(ref)
    assert data.status == :ready

    assert Data.finished?(data) == false
    assert Data.elapsed_usec(data) == 0

    assert %Data{
      uris_visited: 0,
      uris_extracted: 0,
      depths_dist: %{},
      retry_count_dist: %{},
      bytes_received: 0,
      status_codes_dist: %{},
      content_types_dist: %{},
      failed_fetch_uris: MapSet.new(),
      uris_skipped: 0,
      failed_parse_uris: MapSet.new(),

      status: :ready,

      utimestamp_started: nil,
      utimestamp_finished: nil,
      usec_spent_fetching: 0,
    } == data
  end

  describe "Server.Data" do
    test "finished?" do
      data = Data.new()
      assert data.status == :ready
      refute Data.finished?(data)

      data = Map.put(data, :status, :crawling)
      refute Data.finished?(data)

      data = Map.put(data, :status, :finished)
      assert Data.finished?(data)
    end

    test "elapsed_usec" do
      # fresh
      data = Data.new()
      assert Data.elapsed_usec(data) == 0

      # running
      start = Utils.utimestamp() - 1000000
      data = Map.put(data, :utimestamp_started, start)
      then = Utils.utimestamp()
      elapsed = Data.elapsed_usec(data)
      now = Utils.utimestamp()

      assert elapsed >= (then - start)
      assert elapsed <= (now - start)

      # finished
      finish = Utils.utimestamp()
      data = Map.put(data, :utimestamp_finished, finish)
      assert Data.elapsed_usec(data) == finish - start
    end
  end

  test "fetch_succeeded" do
    ref = Server.start_new()
    url = "https://foo.bar/"
    page = Page.new(url)
    response = Response.new(url, 200, [{"content-type", "foo"}], "body")
    duration = 666

    Server.fetch_succeeded(ref, page, response, duration)
    data = Server.get_stats(ref)

    assert data.bytes_received == 4
    assert data.content_types_dist == %{"foo" => 1}
    assert data.depths_dist == %{0 => 1}
    assert data.retry_count_dist == %{0 => 1}
    assert data.uris_visited == 1
    assert data.usec_spent_fetching == 666
    assert data.utimestamp_started != nil

    # page at a bigger depth
    page2 = Page.new("page2", 7)
    Server.fetch_succeeded(ref, page2, response, 100)
    data = Server.get_stats(ref)

    assert data.bytes_received == 8
    assert data.content_types_dist == %{"foo" => 2}
    assert data.depths_dist == %{0 => 1, 7 => 1}
    assert data.retry_count_dist == %{0 => 2}
    assert data.uris_visited == 2
    assert data.usec_spent_fetching == 766

    # retried page
    retried_page = page |> Map.put(:retries, 1)
    Server.fetch_succeeded(ref, retried_page, response, 200)
    data = Server.get_stats(ref)

    assert data.bytes_received == 12
    assert data.content_types_dist == %{"foo" => 3}
    assert data.depths_dist == %{0 => 2, 7 => 1}
    assert data.retry_count_dist == %{0 => 2, 1 => 1}
    assert data.uris_visited == 3
    assert data.usec_spent_fetching == 966
  end

 test "fetch_failed" do
    ref = Server.start_new()
    url = "https://foo.bar/"
    page = Page.new(url)

    Server.fetch_failed(ref, page, 100)
    data = Server.get_stats(ref)
    assert data.failed_fetch_uris == MapSet.new([page.uri])

    # no room for any more failed fetches in the set
    Server.fetch_failed(ref, page, 1)
    data2 = Server.get_stats(ref)
    assert data2.failed_fetch_uris == data.failed_fetch_uris
  end

  test "parse_failed" do
    ref = Server.start_new()
    url = "https://foo.bar/"
    page = Page.new(url)

    Server.parse_failed(ref, page, 100)
    data = Server.get_stats(ref)
    assert data.failed_parse_uris == MapSet.new([page.uri])

    # no room for any more failed parses in the set
    Server.parse_failed(ref, page, 1)
    data2 = Server.get_stats(ref)
    assert data2.failed_parse_uris == data.failed_parse_uris
  end

  test "page_skipped" do
    ref = Server.start_new()
    url = "https://foo.bar/"
    page = Page.new(url)

    Server.page_skipped(ref, page)
    data = Server.get_stats(ref)
    assert data.uris_skipped == 1
  end

  test "uris_extracted" do
    ref = Server.start_new()

    Server.uris_extracted(ref, 13)
    data = Server.get_stats(ref)
    assert data.uris_extracted == 13
  end

  test "finished" do
    ref = Server.start_new()
    data = Server.get_stats(ref)
    refute Data.finished?(data)

    Server.finished(ref)
    data = Server.get_stats(ref)

    assert Data.finished?(data)
    assert is_integer(data.utimestamp_finished)
  end

end
