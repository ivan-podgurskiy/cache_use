defmodule CacheUse.UpstreamTest do
  use ExUnit.Case, async: false

  alias CacheUse.Upstream

  test "fetch returns visible upstream metadata and increments sequence" do
    req = %Cache.Request{path: "/users", params: %{"id" => "1", "ttl" => "30"}}

    first = Upstream.fetch(req)
    second = Upstream.fetch(req)

    assert %Cache.Response{ttl: 30} = first
    assert first.body.path == "/users"
    assert first.body.params == %{"id" => "1", "ttl" => "30"}
    assert is_integer(first.body.sequence)
    assert second.body.sequence == first.body.sequence + 1
  end
end
