# Patterns & Use Cases

Reference corpus for Cloudflare Realtime SFU architecture, session orchestration, media tuning, and operating envelopes.

## Chapters

- [01-architecture-and-session-topologies.md](./realtime-sfu-patterns/01-architecture-and-session-topologies.md) - Edge architecture, anycast behavior, cascading trees, 1:1/N:N/1:N/breakout flows
- [02-backend-session-orchestration.md](./realtime-sfu-patterns/02-backend-session-orchestration.md) - Express, Workers, and Durable Objects coordination examples
- [03-media-controls-and-data-channels.md](./realtime-sfu-patterns/03-media-controls-and-data-channels.md) - Bandwidth limits, simulcast, and DataChannel patterns
- [04-integrations-and-performance-envelope.md](./realtime-sfu-patterns/04-integrations-and-performance-envelope.md) - R2 and Queues integrations plus latency and scale expectations

## Scope

- Architecture and network shape
- Session and subscription topologies
- Backend API orchestration patterns
- Media sender tuning and auxiliary channels
- Integrations and expected performance ranges

## Preservation Notes

- All original diagrams, code blocks, and numeric guidance moved into the chapter files.
- This index replaces the monolithic reference so the parent file stays skimmable while preserving the full corpus.
