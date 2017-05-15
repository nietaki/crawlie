defmodule Crawlie.UtilsTest do
  use ExUnit.Case

  alias Crawlie.Utils

  doctest Utils

  describe "utimestamp" do
    test "is in the correct order of magnitude" do
      assert Utils.utimestamp > 567293400 * 1_000_000
    end
  end

  test "usec_to_seconds" do
    utime = 567293400978203
    sec = Utils.usec_to_seconds(utime)
    assert is_float(sec)
    assert sec > 567293400
    assert sec < 567293400 + 1
  end
end
