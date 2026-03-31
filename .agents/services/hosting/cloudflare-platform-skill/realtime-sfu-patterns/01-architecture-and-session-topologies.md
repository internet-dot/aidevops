# Architecture & Session Topologies

## Architecture

```text
Client (WebRTC) <---> CF Edge <---> Backend (HTTP)
                           |
                    CF Backbone (310+ DCs)
                           |
                    Other Edges <---> Other Clients
```

Anycast: Last-mile <50ms (95%), no region select, NACK shield, distributed consensus

## Cascading Trees

Cascading trees auto-scale to millions:

```text
Publisher -> Edge A -> Edge B -> Sub1
                    \-> Edge C -> Sub2,3
```

## Use Cases

**1:1:** A creates session+publishes, B creates+subscribes to A+publishes, A subscribes to B

**N:N:** All create session+publish, backend broadcasts track IDs, all subscribe to others

**1:N:** Publisher creates+publishes, viewers each create+subscribe (no fan-out limit)

**Breakout:** Same PeerConnection! Backend closes/adds tracks, no recreation
