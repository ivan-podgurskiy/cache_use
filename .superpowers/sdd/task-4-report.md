# Task 4 Report: Verify and Document Manual Usage

## Status

DONE_WITH_CONCERNS

The requested README was added, the complete verification suite passed, and the
Phoenix server booted successfully for a live API smoke test. The first server
start was blocked by the default sandbox's TCP permission (`:eperm`); the same
command succeeded with the required elevated local-network permission.

## Documentation

- Replaced the generated Phoenix README with the exact local setup and curl
  commands from the Task 4 brief.
- Documented cache reuse through the upstream `sequence` value and the effects
  of TTL expiry, invalidation, and clear.

## Verification

- `mix format --check-formatted`: passed after `mix format` corrected the
  generated trailing blank line in `config/runtime.exs`.
- `mix test`: passed; 9 tests, 0 failures.
- `mix compile --warnings-as-errors`: passed.
- `git diff --check`: passed.

## Manual Smoke Test

Started with `mix phx.server`; Phoenix reported:

```text
Running CacheUseWeb.Endpoint with cowboy 2.17.0 at 127.0.0.1:4000 (http)
Access CacheUseWeb.Endpoint at http://localhost:4000
```

The documented requests returned successful JSON responses. Both identical
fetches returned `sequence: 1` and the same `generated_at_ms`; cache size
returned `{"size":1}`; invalidate and clear returned `{"ok":true}`. The server
was stopped after the smoke test and no `mix phx.server` session remains.

## Self-Review

- Only `README.md` and the generated formatting correction in
  `config/runtime.exs` are Task 4 implementation changes.
- Pre-existing `.superpowers` changes and reports were preserved and not
  staged.
- No changes were made to the sibling `../cache` dependency.

## Commit

The Task 4 implementation commit is `7b5aad3 feat: add Phoenix cache sandbox API`.

## Final Review Fix

The documented invalidation flow now uses the same request-defining parameters
as the documented fetch: both include `path=/users&id=1&ttl=60`. The controller
regression test covers fetch, invalidate, and an identical refetch, asserting
that the refetch receives a new upstream sequence. The old omission reproduced
the finding with one failure: the refetch remained at sequence 1.

## Fix Verification

- `mix test test/cache_use_web/controllers/cache_controller_test.exs`: passed;
  6 tests, 0 failures.
- `mix format --check-formatted`: passed.
- No files in the sibling `../cache` repository were modified.
