defmodule Crawlie.Stats.ServerTest do
  use ExUnit.Case

  alias Crawlie.Stats.Server
  alias Crawlie.Stats.Server.Data

  test "get_stats on a fresh server" do
    ref = Server.start_new()

    assert %Data{} = Server.get_stats(ref)
  end

end
