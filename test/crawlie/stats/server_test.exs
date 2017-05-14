defmodule Crawlie.Stats.ServerTest do
  use ExUnit.Case

  alias Crawlie.Stats.Server
  alias Crawlie.Stats.Server.Data

  test "get_stats on a fresh server" do
    ref = Server.start_new()

    assert %Data{} = data = Server.get_stats(ref)
    assert data.status == :ready
  end

end
