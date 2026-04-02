# Hexagonal Architecture (Ports & Adapters)

> Sources: [Cockburn 2005](https://alistair.cockburn.us/hexagonal-architecture/) · [Cockburn & Garrido de Paz 2024](https://openlibrary.org/works/OL38388131W) · [AWS](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html)

**Goal:** Application equally driveable by users, programs, tests, or batch scripts — developed and tested in isolation from runtime devices and databases.

**Validation:** If you can run the entire application from test fixtures (FIT-style), your hexagonal boundaries are correct.

## Chapters

- [Introduction](hexagonal/01-introduction.md) — Core concepts, goal, and the high-level diagram.
- [Ports](hexagonal/02-ports.md) — Driver (inbound) and Driven (outbound) interface definitions.
- [Adapters](hexagonal/03-adapters.md) — Implementation examples for REST, Postgres, Stripe, and RabbitMQ.
- [Naming Conventions](hexagonal/04-naming-conventions.md) — Recommended patterns for naming ports and adapters.
- [Project Structure](hexagonal/05-project-structure.md) — Standard directory layout for hexagonal projects.
- [Configurability](hexagonal/06-configurability.md) — Dependency injection and environment-specific configuration.
- [Strong vs Weak Ports](hexagonal/07-strong-vs-weak-ports.md) — Avoiding domain leakage into port interfaces.
