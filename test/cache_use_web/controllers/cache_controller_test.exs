defmodule CacheUseWeb.CacheControllerTest do
  use CacheUseWeb.ConnCase, async: false

  setup do
    Supervisor.terminate_child(CacheUse.Supervisor, Cache.LRU)
    Supervisor.restart_child(CacheUse.Supervisor, Cache.LRU)
    CacheUse.Upstream.Counter.reset()
    :ok
  end

  test "fetch reuses cached upstream response for the same request", %{conn: conn} do
    first = conn |> get(~p"/api/fetch?path=/users&id=1&ttl=60") |> json_response(200)
    second = conn |> get(~p"/api/fetch?path=/users&id=1&ttl=60") |> json_response(200)

    assert first["body"]["sequence"] == second["body"]["sequence"]
    assert first["ttl"] == 60
  end

  test "different params produce distinct cache entries", %{conn: conn} do
    first = conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)
    second = conn |> get(~p"/api/fetch?path=/users&id=2") |> json_response(200)

    assert first["body"]["sequence"] != second["body"]["sequence"]
  end

  test "size returns cache entry count", %{conn: conn} do
    assert conn |> get(~p"/api/cache/size") |> json_response(200) == %{"size" => 0}

    conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)

    assert conn |> get(~p"/api/cache/size") |> json_response(200) == %{"size" => 1}
  end

  test "fetch requires path", %{conn: conn} do
    assert conn |> get(~p"/api/fetch?id=1") |> json_response(400) == %{
             "error" => "path is required"
           }
  end

  test "unsupported mutation endpoints are not exposed", %{conn: conn} do
    assert conn |> post("/api/cache/clear") |> response(404)
    assert conn |> delete("/api/cache?path=/users&id=1") |> response(404)
  end
end
