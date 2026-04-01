# Smart Placement Gotchas

## `INSUFFICIENT_INVOCATIONS` Status

Not enough traffic for Smart Placement to analyze.

- Ensure Worker receives consistent global traffic
- Wait up to 15 minutes (analysis time)
- Send test traffic from multiple global locations
- Check Worker has fetch event handler

## Smart Placement Making Things Slower (`UNSUPPORTED_APPLICATION`)

Worker doesn't benefit from Smart Placement when:
- No backend calls (runs faster at edge)
- Backend calls are cached (network latency to user dominates)
- Backend service has poor global distribution

Disable Smart Placement for this Worker. Review caching strategy to reduce backend calls.

## No Request Duration Metrics

Dashboard chart not showing — check:
- Smart Placement enabled in config
- 15+ minutes elapsed since deployment
- Sufficient traffic
- `placement_status` is `SUCCESS`

## `cf-placement` Header Missing

- Smart Placement not enabled
- Beta feature removed (check latest docs)
- Worker not yet analyzed

## Monolithic Full-Stack Worker

Frontend + backend in a single Worker: Smart Placement optimizes for backend latency but hurts frontend response time.

Split into two Workers:
- Frontend Worker (no Smart Placement) — runs at edge
- Backend Worker (Smart Placement) — runs near database

## Local Development

Smart Placement only activates in production — not in `wrangler dev`. Test in staging: `wrangler deploy --env staging`

## Expected Behaviors (Not Bugs)

- **1% baseline traffic**: Smart Placement routes 1% of requests without optimization for performance comparison.
- **Analysis delay**: Up to 15 min after enabling. Worker runs at default edge location during analysis. Monitor `placement_status`.

> Requirements, eligibility criteria, and "when NOT to use" guidance: [smart-placement.md](./smart-placement.md)
