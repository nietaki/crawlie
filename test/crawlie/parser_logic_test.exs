defmodule Crawlie.ParserLogicTest do
  use ExUnit.Case

  defmodule Default do
    use Crawlie.ParserLogic
  end

  test "default implementation of the ParserLogic callbacks" do
    assert Default.parse(:some_url, "some body") == "some body"
    assert Default.extract_links(:some_processed) == []
    assert Default.extract_data(:some_processed) == :some_processed
  end
end
