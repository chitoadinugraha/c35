# c35 docs

Canonical specifications for the c35 project. **Locked 2026-09-20.**

Start at [`spec.md`](../spec.md) for locked decisions, phase scope, and this index.

When code and docs disagree, fix the code to match these docs (or explicitly revise the doc first).

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | System overview, build order, infra |
| [structure.md](structure.md) | Repo file tree, crate layout, conventions |
| [identity.md](identity.md) | Identity model (`kind`, `type`, `alien_id`, grants) |
| [chat.md](chat.md) | Chat kinds; Home inbox = prompt only |
| [billing.md](billing.md) | Multi-wallet balances, quota, FX policy, top-up |
| [billing-plans.md](billing-plans.md) | Per-currency catalog prices + scoped plans |
| [billing-implementation.md](billing-implementation.md) | Phased rollout plan (schema → server → client) |
| [log.md](log.md) | Unified audit + billing log |
| [sync.md](sync.md) | Incremental sync, `_ts` convention, NATS subjects |
| [server.md](server.md) | Rust crate workspace layout |
| [ui.md](ui.md) | Flutter shell, pages, navigation |
| [roadmap.md](roadmap.md) | Phase 0→9 start/end goals |
| [skill.md](skill.md) | Skill scope, catalog, automation |
| [remote.md](remote.md) | Remote device: computer use (server session) + WebRTC viewer |
| [consumption.md](consumption.md) | Personal food/water tracking |
| [site.md](site.md) | Sites — block doc + data tables |
| [tx.md](tx.md) | POS / transactions (id.alienai model) |

Schemas live in [`../schemas/`](../schemas/).
