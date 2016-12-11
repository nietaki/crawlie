defmodule Crawlie do

  # @type InputUrls :: Stream.t # a stream of string urls
  # @type Options :: Keyword.t


  # Parser: {url_string, body} -> {representation}

  # UriExtractor: {representation} -> Enum<url_string>

  # DataExtractor: {representation} -> Enum<data>

  # Sink: Stream -> {:ok, result}
  # or
  # Sink:

  # all individual callbacks in a Crawlie Behaviour?

  # @callback init(opts) # what would we do with the return value of the init?
    # report unrecognized options

  # @callback parse {url_string, body, depth?} -> representation
  # @callback extract_links(representation) :: Enum.t<string>
  #   @callback filter_link(opts, string) -> boolean # do we want the link? eg fro filtering by domain
  # @callback extract_data(representation) :: Enum.t<result>

  # @callback sink_accumulator() :: result_accumulator
  # @callback sink_consume(result_accumulator, [result])

end
