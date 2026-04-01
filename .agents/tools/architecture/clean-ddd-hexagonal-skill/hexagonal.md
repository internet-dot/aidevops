---
description: Hexagonal Architecture (Ports & Adapters) - Core principles, patterns, and project structure
mode: subagent
tools:
  read: true
  write: false
  edit: false
  bash: false
  glob: false
  grep: false
  webfetch: false
  task: false
---

# Hexagonal Architecture (Ports & Adapters)

<!-- AI-CONTEXT-START -->

## Quick Reference

**Goal:** Application equally driveable by users, programs, tests, or batch scripts — developed and tested in isolation from runtime devices and databases.

| Type | Direction | Defined by | Purpose | Asymmetry |
|------|-----------|------------|---------|-----------|
| **Driver** (Primary / Inbound) | → App | Application | How the world uses your app (use cases) | Adapter *calls* port — app defines what it **offers** |
| **Driven** (Secondary / Outbound) | App → | Application | What your app needs from external systems | Adapter *implements* port — app defines what it **needs** |

<!-- AI-CONTEXT-END -->

## Chapter Index

Full principles, code examples, and structure guidance in focused chapters:

| # | Chapter | Description |
|---|---------|-------------|
| 01 | [Introduction](hexagonal/01-introduction.md) | Core goal, validation rule, and high-level mermaid diagram |
| 02 | [Ports](hexagonal/02-ports.md) | Driver vs Driven ports with TypeScript interface examples |
| 03 | [Adapters](hexagonal/03-adapters.md) | Controller (Driver) and Repository/Gateway (Driven) implementations |
| 04 | [Naming Conventions](hexagonal/04-naming-conventions.md) | Cockburn, Interface/Impl, and Port suffix patterns |
| 05 | [Project Structure](hexagonal/05-project-structure.md) | Standard directory layout for application, domain, and infrastructure |
| 06 | [Configurability](hexagonal/06-configurability.md) | Dependency injection container setup for dev vs production |
| 07 | [Strong vs Weak Ports](hexagonal/07-strong-vs-weak-ports.md) | Avoiding concept leaks and maintaining domain purity |

## Related

- `layers.md` - Traditional N-tier layering comparison
- `ddd-tactical.md` - Domain-Driven Design patterns (Entities, Value Objects)
- `testing.md` - Testing strategy for hexagonal boundaries
