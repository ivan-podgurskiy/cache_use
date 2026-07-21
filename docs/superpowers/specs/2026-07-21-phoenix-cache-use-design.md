# Phoenix Cache Use Design

## Goal

Create a small Phoenix JSON API application in `cache_use` that uses the
local cache library at `/Users/ivanpodgurskiy/Projects/personal/cache`.
The dependency must be path-based so local changes in the cache package
are picked up by recompiling this app.

## Scope

The first version is an API-only Phoenix application for experiments, not
a LiveView dashboard. It should make cache behavior easy to inspect from
curl, IEx, and tests.

## Architecture

`cache_use` will be a Phoenix application with:

- `{:cache, path: "../cache"}` in `mix.exs`.
- `CacheUse.Application` supervising `Cache.LRU` as `CacheUse.Cache`.
- `CacheUse.Upstream`, a local slow/upstream simulator.
- `CacheUseWeb.CacheController`, a thin JSON layer over cache calls.

The application supervisor owns the cache process. If the cache process
crashes, Phoenix supervision restarts it empty, matching the cache
library's documented cold-start behavior.

## API

The API exposes a narrow experimental surface:

- `GET /api/fetch?path=/users&id=1&ttl=60` builds a `%Cache.Request{}`
  from query params and returns the cached or fresh `%Cache.Response{}`.
- `POST /api/cache/clear` clears all cached entries.
- `DELETE /api/cache?path=/users&id=1` invalidates one cache entry.
- `GET /api/cache/size` returns the current cache entry count.

The fetch response includes both the response body and metadata that lets
the caller see cache behavior. The upstream body includes a generated
sequence number and timestamp; repeating the same request should keep
returning the same sequence until TTL expiry, invalidation, or clear.

## Upstream

`CacheUse.Upstream.fetch/1` returns `%Cache.Response{}`. It should be
deterministic enough for tests but visible enough for manual
experiments:

- It increments a counter for each real upstream call.
- It includes the original request path and params in the response body.
- It uses request params to select TTL, defaulting to 60 seconds.

The counter can live in a supervised `Agent` so upstream calls are
observable across requests.

## Error Handling

The controller validates the required `path` query parameter and returns
JSON errors with `400` for invalid input. Cache/upstream exceptions are
not hidden in the first version; Phoenix should surface them during local
experiments, and the supervised cache process should restart as designed.

## Testing

Tests should cover:

- Repeated `GET /api/fetch` for the same request reuses the cached
  upstream sequence.
- Different request params produce distinct cache entries.
- `POST /api/cache/clear` forces the next fetch to call upstream again.
- `DELETE /api/cache` invalidates only the selected request.
- `GET /api/cache/size` reflects cache contents.

Controller tests are enough for the first version because the controller
is the user-facing experimental boundary.

## Non-Goals

- No HTML UI or LiveView dashboard in this version.
- No external upstream service.
- No production deployment configuration.
- No changes to the `cache` library itself.
