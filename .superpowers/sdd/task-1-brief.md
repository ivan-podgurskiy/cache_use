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

