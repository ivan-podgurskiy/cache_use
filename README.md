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
