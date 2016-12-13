defmodule Crawlie.HttpClient.HTTPoisonClientTest do
  use ExUnit.Case

  alias Crawlie.HttpClient.HTTPoisonClient

  test "the error case" do
    assert {:error, _} = HTTPoisonClient.get("http://this.hopefully.doesnot3xist", [])
  end

end
