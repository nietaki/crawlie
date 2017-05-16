defmodule Crawlie.ResponseTest do
  use ExUnit.Case

  alias Crawlie.Response

  doctest Response

  #===========================================================================
  # Attributes
  #===========================================================================

  @url "https://www.foo.bar/abc/de"
  @headers [
    {"Cache-Control", "private"},
    {"Content-Type", "text/html; charset=UTF-8"},
    {"Location", "https://www.foo.bar/?abc=de&fg=hj"},
    {"Content-Length", "262"}, {"Date", "Sat, 18 Mar 2017 23:20:34 GMT"},
  ]
  @status_code 200
  @body "<html><body>hello</body></html>"

  @r Response.new(@url, @status_code, @headers, @body)

  #===========================================================================
  # Tests
  #===========================================================================

  test "constructor" do
    r = Response.new(@url, @status_code, @headers, @body)

    assert URI.to_string(r.uri) == @url
    assert r.uri.path == "/abc/de"

    assert r.status_code == @status_code

    assert r.headers == @headers
    assert r.body == @body

    assert r.content_type == "text/html; charset=utf-8"
    assert r.content_type_simple == "text/html"
  end

  test "content_type/1" do
    assert Response.content_type(@r) == "text/html; charset=utf-8"
    assert @r.content_type == "text/html; charset=utf-8"
  end

  test "content_type_simple/1" do
    assert Response.content_type_simple(@r) == "text/html"

    base_case = Response.new(@url, @status_code, [{"content-type", "text/html"}], @body)
    assert Response.content_type_simple(base_case) == "text/html"
    assert base_case.content_type_simple == "text/html"
  end

  test "content_type_simple/1 with empty headers" do
    resp = Response.new(@url, @status_code, [], @body)
    assert Response.content_type_simple(resp) == nil
  end

  test "url/1" do
    assert Response.url(@r) == @url
  end

end
