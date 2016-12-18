defmodule CrawlieTest do
  use ExUnit.Case

  alias Crawlie.Options
  alias Crawlie.HttpClient.MockClient
  alias Crawlie.ParserLogic.Default, as: DefaultParserLogic

  doctest Crawlie

  @moduletag timeout: 1000

  test "with default parser logic and a mock client" do
    opts = Options.with_mock_client([])
    opts = Keyword.put(opts, :mock_client_fun, MockClient.return_url)
    urls = ["https://abc.d/", "https://foo.bar/"]
    ret = Crawlie.crawl(urls, DefaultParserLogic, opts)

    assert Enum.sort(ret) == Enum.sort(urls)
  end


  defmodule SimpleLogic do
    @behaviour Crawlie.ParserLogic

    def parse(_url, body, options) do
      assert Keyword.get(options, :foo) == :bar
      "parsed " <> body
    end

    def extract_links(_url, _processed, _options) do
      # TODO with links
    end

    def extract_data(_url, processed, _options) do
      [{processed, 0}, {processed, 1}]
    end

  end

  test "with a slightly more complicated logic and a mock client" do
    opts = Options.with_mock_client([foo: :bar])
    fun = fn(url) -> {:ok, (url <> " body")} end
    opts = Keyword.put(opts, :mock_client_fun, fun)

    urls = ["https://abc.d/", "https://foo.bar/"]
    ret = Crawlie.crawl(urls, SimpleLogic, opts)

    assert Enum.sort(ret) ==
      Enum.sort([
        {"parsed https://abc.d/ body", 0},
        {"parsed https://abc.d/ body", 1},
        {"parsed https://foo.bar/ body", 0},
        {"parsed https://foo.bar/ body", 1},
      ])
  end

  test "urls that always return an error are not included in the results" do
    opts = Options.with_mock_client([])
    fun = fn
      "https://abc.d/" -> {:error, :something}
      url -> {:ok, url <> " body"}
    end
    opts = Keyword.put(opts, :mock_client_fun, fun)

    urls = ["https://abc.d/", "https://foo.bar/"]
    ret = Crawlie.crawl(urls, DefaultParserLogic, opts)

    assert Enum.to_list(ret) == ["https://foo.bar/ body"]
  end

end
