defmodule CrawlieTest do
  use ExUnit.Case

  alias Crawlie.Options
  alias Crawlie.HttpClient.MockClient
  alias Crawlie.ParserLogic.Default, as: DefaultParserLogic

  doctest Crawlie

  @moduletag timeout: 1000

  test "default parser logic and a mock client" do
    opts = Options.with_mock_client(Options.defaults)
    opts = Keyword.put(opts, :mock_client_fun, MockClient.return_url)
    urls = ["https://abc.d/", "https://foo.bar/"]
    ret = Crawlie.crawl(urls, DefaultParserLogic, opts)

    assert Enum.sort(ret) == Enum.sort(urls)
  end

end
