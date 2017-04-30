defmodule Crawlie.PageTest do
  use ExUnit.Case

  alias Crawlie.Page

  doctest Page


  @url "https://foo.bar.baz/abc/def?x=y&y=z"
  @uri URI.parse(@url)

  @uri_a URI.parse("aaa")
  @uri_b URI.parse("bbb")

  test "constructor" do
    assert Page.new(@uri) == %Page{uri: @uri, depth: 0, retries: 0}
    assert Page.new(@url) == %Page{uri: @uri, depth: 0, retries: 0}

    assert Page.new(@uri, 7) == %Page{uri: @uri, depth: 7, retries: 0}
  end

  test "Page structs compare by depth" do
    assert Page.new("foo", 0) < Page.new("foo", 10)
    assert Page.new("foo", 0) < Page.new("bar", 10)
    assert %Page{uri: @uri_a, depth: 0, retries: 10} < %Page{uri: @uri_b, depth: 10, retries: 0}
  end

  test "Page.retry/1" do
    p = %Page{uri: @uri_a, depth: 17, retries: 7}
    assert Page.retry(p) == %Page{uri: @uri_a, depth: 17, retries: 8}
  end

  test "Page.child/2" do
    p = %Page{uri: @uri_a, depth: 17, retries: 7}
    assert Page.child(p, @uri_a) == %Page{uri: @uri_a, depth: 18, retries: 0}
  end

  test "Page.url/1" do
    assert @url == Page.url(Page.new(@url))
  end
end
