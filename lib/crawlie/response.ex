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
  }

  defstruct [
    # "core" fields
    :uri,
    :status_code,
    :headers,
    :body
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
  Retrieves the content type of the response.

  ## Example
      iex> alias Crawlie.Response
      iex> url = "https://foo.bar/"
      iex> headers = [{"Content-Type", "text/html; charset=UTF-8"}]
      iex> response = Response.new(url, 200, headers, "<html />")
      iex> Response.content_type(response)
      "text/html; charset=UTF-8"
  """
  def content_type(%This{headers: headers}) do
    headers
    |> Enum.find_value({nil, nil}, fn {k, v} ->
      if String.downcase(k) == "content-type" do
        v
      else
        false
      end
    end)
  end


  @spec content_type_simple(This.t) :: String.t | nil
  @doc """
  Retrieves the content type of the response, just the "type/subtype" part, with
  no additional parameters, if there are any in the Content-Type header value.

  ## Example
      iex> alias Crawlie.Response
      iex> url = "https://foo.bar/"
      iex> headers = [{"Content-Type", "text/html; charset=UTF-8"}]
      iex> response = Response.new(url, 200, headers, "<html />")
      iex> Response.content_type_simple(response)
      "text/html"
  """
  def content_type_simple(%This{} = this) do
    case content_type(this) do
      nil -> nil
      ct ->
        ct
        |> String.split(";", parts: 2)
        |> hd()
    end
  end

end
