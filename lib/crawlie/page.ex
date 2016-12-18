defmodule Crawlie.Page do
  @moduledoc """
  Defines the struct representing a url's state in the system.
  """
  alias __MODULE__, as: This

  @typedoc """
  The `Crawlie.Page` struct type.

  Fields' meaning:

  - `:url` - page url
  - `:depth` - the "depth" at which the url was found while recursively crawling the pages.
    For example `depth=0` means it was passed directly from the caller, `depth=2` means
    the crawler followed 2 links from one of the starting urls to get to the url.
  - `:retries` - url fetch retry count. If the fetching of the url never failed before, `0`.
  """
  @type t :: %This{
    # the depth key should have the alphabetically lowest key in the struct so that
    # it is used in comparisons in the heap
    depth: integer,
    url: String.t,
    retries: integer
  }
  defstruct [
    :url,
    depth: 0,
    retries: 0,
  ]

  #===========================================================================
  # API Functions
  #===========================================================================

  @spec new(String.t, integer) :: This.t
  @doc """
  Creates a new `Crawlie.Page` struct from the url
  """
  def new(url, depth \\ 0) when is_binary(url) and is_integer(depth),
    do: %This{url: url, depth: depth}

end
