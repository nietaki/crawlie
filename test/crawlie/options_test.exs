defmodule Crawlie.OptionsTest do
  use ExUnit.Case

  alias Crawlie.Options

  test "getting the http client" do
    empty = Keyword.new

    assert Options.get(empty, :http_client) == Crawlie.HttpClient.HTTPoisonClient
    different_client = Options.put(empty, :http_client, :foo)

    assert Options.get(different_client, :http_client) == :foo
  end

  test "getting a default option" do
    empty = Keyword.new
    assert true == Options.get(empty, :follow_redirect)
  end
end
