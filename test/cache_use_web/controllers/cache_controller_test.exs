defmodule CacheUseWeb.CacheControllerTest do
  use CacheUseWeb.ConnCase, async: false

  setup do
    Cache.LRU.clear(CacheUse.Cache)
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

  test "clear forces the next fetch upstream", %{conn: conn} do
    first = conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)

    assert conn |> post(~p"/api/cache/clear") |> json_response(200) == %{"ok" => true}

    second = conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)
    assert second["body"]["sequence"] == first["body"]["sequence"] + 1
  end

  test "invalidate removes only the selected request", %{conn: conn} do
    first = conn |> get(~p"/api/fetch?path=/users&id=1&ttl=60") |> json_response(200)
    other = conn |> get(~p"/api/fetch?path=/users&id=2") |> json_response(200)

    assert conn |> delete(~p"/api/cache?path=/users&id=1&ttl=60") |> json_response(200) == %{
             "ok" => true
           }

    refetched = conn |> get(~p"/api/fetch?path=/users&id=1&ttl=60") |> json_response(200)
    cached_other = conn |> get(~p"/api/fetch?path=/users&id=2") |> json_response(200)

    assert refetched["body"]["sequence"] != first["body"]["sequence"]
    assert cached_other["body"]["sequence"] == other["body"]["sequence"]
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
end
