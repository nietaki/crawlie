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
end
