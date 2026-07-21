defmodule CacheUseWeb.CacheController do
  use CacheUseWeb, :controller

  def fetch(conn, params) do
    with {:ok, request} <- build_request(params) do
      response = Cache.LRU.fetch(CacheUse.Cache, request)
      json(conn, encode_response(response))
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def clear(conn, _params) do
    :ok = Cache.LRU.clear(CacheUse.Cache)
    json(conn, %{ok: true})
  end

  def invalidate(conn, params) do
    with {:ok, request} <- build_request(params) do
      :ok = Cache.LRU.invalidate(CacheUse.Cache, request)
      json(conn, %{ok: true})
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end

  def size(conn, _params) do
    json(conn, %{size: Cache.LRU.size(CacheUse.Cache)})
  end

  defp build_request(%{"path" => path} = params) when is_binary(path) and path != "" do
    {:ok, %Cache.Request{path: path, params: Map.delete(params, "path")}}
  end

  defp build_request(_params), do: {:error, "path is required"}

  defp encode_response(%Cache.Response{body: body, ttl: ttl}) do
    %{body: body, ttl: ttl}
  end
end
