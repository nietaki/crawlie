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

  def new(url, status_code, headers, body)
  when is_binary(url) do
    uri = URI.parse(url)
    new(uri, status_code, headers, body)
  end

  def new(%URI{} = uri, status_code, headers, body)
  when is_integer(status_code) and is_list(headers) do
    %This{
      uri: uri,
      status_code: status_code,
      headers: headers,
      body: body,
    }
  end


  @spec url(This.t) :: String.t

  def url(this) do
    URI.to_string(this.uri)
  end


  @spec content_type(This.t) :: String.t | nil

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
