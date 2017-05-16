defmodule Crawlie.Response do
  @moduledoc """
  Defines the struct representing a page retrieved by the http client.
  """

  alias __MODULE__, as: This

  @typedoc """
  The `Crawlie.Response` struct type.
  """

  @type t :: %This{
    uri: URI.t,
    status_code: integer,
    headers: [{String.t, String.t}],
    body: binary,

    content_type: String.t | nil,
    content_type_simple: String.t | nil,
  }

  defstruct [
    # "core" fields
    :uri,
    :status_code,
    :headers,
    :body,

    # "calculated" fields
    :content_type,
    :content_type_simple,
  ]

  #===========================================================================
  # API Functions
  #===========================================================================

  @spec new(String.t | URI.t, integer, [{String.t, String.t}], binary) :: This.t
  @doc """
  Constructs the `Crawlie.Response` struct.

  ## Example
      iex> alias Crawlie.Response
      iex> url = "https://foo.bar/"
      iex> headers = [{"Content-Type", "text/plain"}]
      iex> response = Response.new(url, 200, headers, "body")
      iex> response.body
      "body"
      iex> response.status_code
      200
  """
  def new(url, status_code, headers, body)
  when is_integer(status_code) and is_list(headers) and is_binary(body) do
    %This{
      uri: URI.parse(url),
      status_code: status_code,
      headers: headers,
      body: body,

      content_type: get_content_type(headers),
      content_type_simple: get_content_type_simple(headers),
    }
  end


  @spec url(This.t) :: String.t
  @doc """
  Returns the string representation of the `uri` contained in the `Crawlie.Response` struct.
  """
  def url(this) do
    URI.to_string(this.uri)
  end


  @spec content_type(This.t) :: String.t | nil
  @doc """
  Retrieves the (downcased) content type of the response.

  Deprecated, you can use `response.content_type` directly

  ## Example
      iex> alias Crawlie.Response
      iex> url = "https://foo.bar/"
      iex> headers = [{"Content-Type", "text/html; charset=UTF-8"}]
      iex> response = Response.new(url, 200, headers, "<html />")
      iex> Response.content_type(response)
      "text/html; charset=utf-8"
      iex> Response.content_type(response) == response.content_type
      true
  """
  def content_type(%This{content_type: content_type}), do: content_type


  @spec content_type_simple(This.t) :: String.t | nil
  @doc """
  Retrieves the (downcased) content type of the response, just the "type/subtype" part, with
  no additional parameters, if there are any in the Content-Type header value.

  Deprecated, you can use `response.content_type_simple` directly

  ## Example
      iex> alias Crawlie.Response
      iex> url = "https://foo.bar/"
      iex> headers = [{"Content-Type", "text/html; charset=UTF-8"}]
      iex> response = Response.new(url, 200, headers, "<html />")
      iex> Response.content_type_simple(response)
      "text/html"
      iex> Response.content_type_simple(response) == response.content_type_simple
      true
  """
  def content_type_simple(%This{content_type_simple: content_type_simple}) do
    content_type_simple
  end


  #===========================================================================
  # Internal Functions
  #===========================================================================


  @spec get_content_type([{String.t, String.t}]) :: String.t | nil

  defp get_content_type(headers) do
    headers
    |> Enum.find_value(nil, fn {k, v} ->
      if String.downcase(k) == "content-type" do
        String.downcase(v)
      else
        false
      end
    end)
  end


  @spec get_content_type_simple([{String.t, String.t}]) :: String.t | nil

  defp get_content_type_simple(headers) do
    case get_content_type(headers) do
      nil -> nil
      ct ->
        ct
        |> String.split(";", parts: 2)
        |> hd()
    end
  end

end
