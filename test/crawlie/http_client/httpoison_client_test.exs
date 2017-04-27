defmodule Crawlie.HttpClient.HTTPoisonClientTest do
  use ExUnit.Case

  alias Crawlie.HttpClient.HTTPoisonClient
  alias Crawlie.Response
  alias HTTPoison.Response, as: HTTPoisonResponse

  @url "https://foo.bar/"
  @headers [{"Content-Type", "text/html"}, {"Foo", "Bar"}]
  @body "<html />"

  test "HTTPoisonClient correctly interprets the HTTPoison Response" do
    :meck.new(HTTPoison)
    :meck.expect(HTTPoison, :get, fn(url, headers, _opts) ->
      assert headers == []
      assert url == @url
      {:ok, %HTTPoisonResponse{body: @body, headers: @headers, status_code: 700}}
    end)

    assert {:ok, response} = HTTPoisonClient.get(@url, [])
    :meck.validate(HTTPoison)

    assert %Response{
      body: @body,
      headers: @headers,
      status_code: 700,
      uri: uri
    } = response

    assert URI.to_string(uri) == @url
  end

end
