defmodule Crawlie.Page do
  @moduledoc """
  Defines the struct representing a url's state in the system.
  """
  alias __MODULE__, as: This

  @typedoc """
  The `Crawlie.Page` struct type.

  Fields' meaning:

  - `:uri` - page `URI`
  - `:depth` - the "depth" at which the url was found while recursively crawling the pages.
    For example `depth=0` means it was passed directly from the caller, `depth=2` means
    the crawler followed 2 links from one of the starting urls to get to the url.
  - `:retries` - url fetch retry count. If the fetching of the url never failed before, `0`.
  """
  @type t :: %This{
    depth: integer,
    uri: URI.t,
    retries: integer
  }
  defstruct [
    :uri,
    depth: 0,
    retries: 0,
  ]

  #===========================================================================
  # API Functions
  #===========================================================================

  @spec new(URI.t | String.t, integer) :: This.t
  @doc """
  Creates a new `Crawlie.Page` struct from the url
  """
  def new(uri, depth \\ 0) when is_integer(depth) do
    uri =
      uri
      |> URI.parse() # works with both binaries and %URI{}
      |> strip_fragment()
    %This{uri: uri, depth: depth}
  end


  @spec child(This.t, URI.t | String.t) :: This.t
  @doc """
  Creates a "child page" - a new `Crawlie.Page` struct with depth one greater than
  the one of the parent and no retries.
  """
  def child(%This{depth: depth}, uri) do
    This.new(uri, depth + 1)
  end


  @spec retry(This.t) :: This.t
  @doc """
  Returns the `Crawlie.Page` object with the retry count increased
  """
  def retry(%This{retries: r} = this), do: %This{this | retries: r + 1}


  @spec url(This.t) :: String.t
  @doc """
  Returns the string url of the page
  """
  def url(this), do: URI.to_string(this.uri)


  #===========================================================================
  # Internal Functions
  #===========================================================================

  defp strip_fragment(%URI{fragment: nil} = uri), do: uri
  defp strip_fragment(%URI{fragment: _} = uri), do: %URI{uri | fragment: nil}

end
