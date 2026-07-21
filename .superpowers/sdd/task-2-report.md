# Task 2 Report: Add Supervised Cache and Upstream

## Status

Implemented the supervised local cache, upstream simulator, and upstream sequence counter.

## Implementation

- Added `CacheUse.Upstream.fetch/1`, returning `Cache.Response` values with request metadata, a sequence number, generated timestamp, and parsed TTL.
- Added `CacheUse.Upstream.Counter` as a named Agent exposing `next/0` and `reset/0`.
- Added `CacheUse.Upstream.Counter` and the named `CacheUse.Cache` LRU process to `CacheUse.Application` supervision with capacity `100` and `CacheUse.Upstream.fetch/1` as upstream.
- Added the focused upstream test covering visible metadata, TTL parsing, and sequence increments.
- Did not modify the sibling `../cache` repository.

## Verification

- `mix test test/cache_use/upstream_test.exs`: passed; `1 test, 0 failures`.
- `mix test`: passed; `3 tests, 0 failures`.
- `git diff --check`: passed.
- `mix format --check-formatted`: reports pre-existing formatting differences in `lib/cache_use_web/router.ex` and `config/runtime.exs`; neither file was modified by this task.

## Self-review

- The upstream test was observed failing before production implementation with `UndefinedFunctionError` for `CacheUse.Upstream.fetch/1`.
- The implementation follows the task brief exactly and uses the local cache dependency's `Cache.Request`, `Cache.Response`, and `Cache.LRU` interfaces.
- The application starts successfully during the passing test suite with the endpoint, counter, and named cache children.
- No unrelated changes were made.

## Git

The implementation and this report are committed after verification. The commit hash is recorded in the task response.

## Concern

The repository-wide format check remains red because of the two pre-existing scaffold files listed above. This task leaves that unrelated formatting drift unchanged.
