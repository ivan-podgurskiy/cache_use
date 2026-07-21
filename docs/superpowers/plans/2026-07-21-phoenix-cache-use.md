# Phoenix Cache Use Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Phoenix JSON API sandbox that uses the local `cache` library via a path dependency.

**Architecture:** `cache_use` is an API-only Phoenix application. `CacheUse.Application` supervises `Cache.LRU` as `CacheUse.Cache` and a small `CacheUse.Upstream.Counter` Agent; `CacheUseWeb.CacheController` exposes fetch, clear, invalidate, and size endpoints.

**Tech Stack:** Elixir, Mix, Phoenix API, ExUnit, local path dependency `{:cache, path: "../cache"}`.

## Global Constraints

- Use `/Users/ivanpodgurskiy/Projects/personal/cache` through `{:cache, path: "../cache"}`.
- Keep the first version API-only; do not add LiveView or HTML UI.
- Do not modify the `cache` library.
- Expose `GET /api/fetch`, `POST /api/cache/clear`, `DELETE /api/cache`, and `GET /api/cache/size`.
- The upstream response must include a generated sequence so repeated requests visibly reuse cache.

---

## File Structure

- `mix.exs`: Phoenix app definition and dependencies, including `{:cache, path: "../cache"}`.
- `config/config.exs`: Phoenix endpoint and JSON configuration.
- `config/dev.exs`: local development endpoint configuration.
- `config/test.exs`: test endpoint configuration.
- `lib/cache_use/application.ex`: application supervisor, owns endpoint, upstream counter, and cache process.
- `lib/cache_use/upstream.ex`: converts a `%Cache.Request{}` into a `%Cache.Response{}`.
- `lib/cache_use/upstream/counter.ex`: Agent-backed monotonic upstream call counter.
- `lib/cache_use_web.ex`: minimal Phoenix web macro module.
- `lib/cache_use_web/endpoint.ex`: Phoenix endpoint.
- `lib/cache_use_web/router.ex`: API routes.
- `lib/cache_use_web/controllers/cache_controller.ex`: JSON API controller.
- `test/support/conn_case.ex`: controller test helper.
- `test/cache_use_web/controllers/cache_controller_test.exs`: API behavior tests.
- `test/test_helper.exs`: starts ExUnit.

---

### Task 1: Scaffold Phoenix API Application

**Files:**
- Create: `mix.exs`
- Create: `.formatter.exs`
- Create: `.gitignore`
- Create: `config/config.exs`
- Create: `config/dev.exs`
- Create: `config/test.exs`
- Create: `lib/cache_use/application.ex`
- Create: `lib/cache_use_web.ex`
- Create: `lib/cache_use_web/endpoint.ex`
- Create: `lib/cache_use_web/router.ex`
- Create: `test/test_helper.exs`
- Create: `test/support/conn_case.ex`

**Interfaces:**
- Consumes: local sibling project at `../cache`.
- Produces: Phoenix app `:cache_use`, endpoint `CacheUseWeb.Endpoint`, router `CacheUseWeb.Router`.

- [ ] **Step 1: Generate an API-only Phoenix skeleton**

Run from `/Users/ivanpodgurskiy/Projects/personal/cache_use`:

```bash
mix phx.new . --app cache_use --module CacheUse --no-ecto --no-html --no-assets --no-dashboard --install
```

Expected: Phoenix files are created in the current directory. If Phoenix asks to install dependencies, answer yes.

- [ ] **Step 2: Set the local cache dependency**

Modify `mix.exs` so `deps/0` contains:

```elixir
defp deps do
  [
    {:phoenix, "~> 1.7.0"},
    {:phoenix_live_reload, "~> 1.2", only: :dev},
    {:plug_cowboy, "~> 2.5"},
    {:cache, path: "../cache"}
  ]
end
```

Expected: `mix.exs` uses the local path package and does not depend on Ecto, HTML, assets, or dashboard packages.

- [ ] **Step 3: Run dependency and compile checks**

Run:

```bash
mix deps.get
mix compile
```

Expected: both commands pass and compile `cache` from `../cache`.

- [ ] **Step 4: Commit if repository exists**

Run:

```bash
git rev-parse --is-inside-work-tree
```

If it returns `true`, commit:

```bash
git add .
git commit -m "chore: scaffold Phoenix cache sandbox"
```

Expected: if no git repository exists, skip the commit and continue.

---

### Task 2: Add Supervised Cache and Upstream

**Files:**
- Modify: `lib/cache_use/application.ex`
- Create: `lib/cache_use/upstream.ex`
- Create: `lib/cache_use/upstream/counter.ex`

**Interfaces:**
- Consumes: `Cache.LRU.start_link/1`, `Cache.Response`, `Cache.Request`.
- Produces: `CacheUse.Upstream.fetch/1`, `CacheUse.Upstream.Counter.next/0`, named cache process `CacheUse.Cache`.

- [ ] **Step 1: Write a focused upstream counter test in IEx-compatible terms**

Create `test/cache_use/upstream_test.exs`:

```elixir
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
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
mix test test/cache_use/upstream_test.exs
```

Expected: FAIL because `CacheUse.Upstream` does not exist.

- [ ] **Step 3: Implement upstream counter**

Create `lib/cache_use/upstream/counter.ex`:

```elixir
defmodule CacheUse.Upstream.Counter do
  @moduledoc false

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def next do
    Agent.get_and_update(__MODULE__, fn sequence ->
      next_sequence = sequence + 1
      {next_sequence, next_sequence}
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> 0 end)
  end
end
```

Create `lib/cache_use/upstream.ex`:

```elixir
defmodule CacheUse.Upstream do
  @moduledoc """
  Local upstream simulator used by the Phoenix cache sandbox.
  """

  alias CacheUse.Upstream.Counter

  @default_ttl 60

  def fetch(%Cache.Request{path: path, params: params}) do
    sequence = Counter.next()
    ttl = ttl_from(params)

    %Cache.Response{
      ttl: ttl,
      body: %{
        path: path,
        params: params,
        sequence: sequence,
        generated_at_ms: System.system_time(:millisecond)
      }
    }
  end

  defp ttl_from(%{"ttl" => ttl}) do
    case Integer.parse(to_string(ttl)) do
      {value, ""} when value > 0 -> value
      _ -> @default_ttl
    end
  end

  defp ttl_from(_params), do: @default_ttl
end
```

- [ ] **Step 4: Supervise counter and cache**

Modify `lib/cache_use/application.ex` children so it includes:

```elixir
children = [
  CacheUseWeb.Endpoint,
  CacheUse.Upstream.Counter,
  {Cache.LRU, cap: 100, upstream: &CacheUse.Upstream.fetch/1, name: CacheUse.Cache}
]
```

Expected: the endpoint, counter, and cache start with the app.

- [ ] **Step 5: Run upstream test**

Run:

```bash
mix test test/cache_use/upstream_test.exs
```

Expected: PASS.

---

### Task 3: Add Cache JSON Endpoints

**Files:**
- Modify: `lib/cache_use_web/router.ex`
- Create: `lib/cache_use_web/controllers/cache_controller.ex`

**Interfaces:**
- Consumes: named cache process `CacheUse.Cache`, `Cache.LRU.fetch/2`, `Cache.LRU.clear/1`, `Cache.LRU.invalidate/2`, `Cache.LRU.size/1`.
- Produces: API endpoints `GET /api/fetch`, `POST /api/cache/clear`, `DELETE /api/cache`, `GET /api/cache/size`.

- [ ] **Step 1: Write controller tests for the JSON API**

Create `test/cache_use_web/controllers/cache_controller_test.exs`:

```elixir
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
    first = conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)
    other = conn |> get(~p"/api/fetch?path=/users&id=2") |> json_response(200)

    assert conn |> delete(~p"/api/cache?path=/users&id=1") |> json_response(200) == %{"ok" => true}

    refetched = conn |> get(~p"/api/fetch?path=/users&id=1") |> json_response(200)
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
    assert conn |> get(~p"/api/fetch?id=1") |> json_response(400) == %{"error" => "path is required"}
  end
end
```

- [ ] **Step 2: Run controller tests to verify they fail**

Run:

```bash
mix test test/cache_use_web/controllers/cache_controller_test.exs
```

Expected: FAIL because routes and controller do not exist.

- [ ] **Step 3: Add routes**

Modify `lib/cache_use_web/router.ex`:

```elixir
defmodule CacheUseWeb.Router do
  use CacheUseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CacheUseWeb do
    pipe_through :api

    get "/fetch", CacheController, :fetch
    post "/cache/clear", CacheController, :clear
    delete "/cache", CacheController, :invalidate
    get "/cache/size", CacheController, :size
  end
end
```

- [ ] **Step 4: Add controller**

Create `lib/cache_use_web/controllers/cache_controller.ex`:

```elixir
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
```

- [ ] **Step 5: Run controller tests**

Run:

```bash
mix test test/cache_use_web/controllers/cache_controller_test.exs
```

Expected: PASS.

---

### Task 4: Verify and Document Manual Usage

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: final Phoenix API.
- Produces: concise local usage commands.

- [ ] **Step 1: Write README**

Create `README.md`:

```markdown
# Cache Use

Phoenix JSON API sandbox for experimenting with the local cache package at
`../cache`.

## Setup

```bash
mix deps.get
mix test
mix phx.server
```

## Try It

```bash
curl "http://localhost:4000/api/fetch?path=/users&id=1&ttl=60"
curl "http://localhost:4000/api/fetch?path=/users&id=1&ttl=60"
curl "http://localhost:4000/api/cache/size"
curl -X DELETE "http://localhost:4000/api/cache?path=/users&id=1"
curl -X POST "http://localhost:4000/api/cache/clear"
```

Repeated identical fetches should return the same upstream `sequence`
until TTL expiry, invalidation, or clear.
```

- [ ] **Step 2: Run full verification**

Run:

```bash
mix format --check-formatted
mix test
mix compile --warnings-as-errors
```

Expected: all commands pass.

- [ ] **Step 3: Start local server for manual testing**

Run:

```bash
mix phx.server
```

Expected: server starts at `http://localhost:4000`.

- [ ] **Step 4: Commit if repository exists**

Run:

```bash
git rev-parse --is-inside-work-tree
```

If it returns `true`, commit:

```bash
git add .
git commit -m "feat: add Phoenix cache sandbox API"
```

Expected: if no git repository exists, skip the commit and report that the workspace is not a git repository.
