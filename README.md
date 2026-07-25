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
```

Repeated identical fetches should return the same upstream `sequence`
until TTL expiry or LRU eviction. The current cache package exposes
`fetch/2` and `size/1`; mutation endpoints are intentionally not exposed
by this sandbox.
