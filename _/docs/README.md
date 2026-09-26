# c35 docs

Canonical specifications for the c35 project. **Locked 2026-09-20.**

Start at [`spec.md`](../spec.md) for locked decisions, phase scope, and this index.

When code and docs disagree, fix the code to match these docs (or explicitly revise the doc first).

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | System overview, build order, infra |
| [snowflake.md](snowflake.md) | Snowflake bit layout, epoch, per-pod worker id |
| [structure.md](structure.md) | Repo file tree, crate layout, conventions |
| [identity.md](identity.md) | Identity model (`kind`, `type`, `alien_id`, grants) |
| [chat.md](chat.md) | Chat kinds; Home inbox = prompt only |
| [context-compaction.md](context-compaction.md) | Token packing, rolling summary, memory extraction, compaction billing |
| [billing.md](billing.md) | Multi-wallet balances, quota, FX policy, top-up |
| [billing-pricing.md](billing-pricing.md) | Alien / Frontier pool rates, model comparison, debit order |
| [billing-plans.md](billing-plans.md) | Lite–Ultra plans, bot/device SKUs, promotions |
| [billing-implementation.md](billing-implementation.md) | Phased rollout plan (schema → server → client) |
| [log.md](log.md) | Unified audit + billing log |
| [event.md](event.md) | Domain events (NATS `c35.user.*.ev.*`, triggers; not LLM trace) |
| [sync.md](sync.md) | Incremental sync, `_ts` convention, NATS subjects |
| [nats.md](nats.md) | NATS layers, JetStream streams, cron schedules, YB hydrate |
| [server.md](server.md) | Rust crate workspace layout |
| [fetcher.md](fetcher.md) | `c35-fetcher` singleton — FX rate, LLM catalog, periodic external sync |
| [platform.md](platform.md) | Platform vendor costs, wholesale COGS, root P&L |
| [ui.md](ui.md) | Flutter shell, pages, navigation |
| [roadmap.md](roadmap.md) | Phase 0→9 start/end goals |
| [skill.md](skill.md) | Skill scope, catalog, automation |
| [remote.md](remote.md) | Remote device: agent control session + WebRTC data plane (files, screen, media) |
| [inst.md](inst.md) | Instruction macros (`ai.inst`) — phrase steering + tool include/exclude |
| [image.md](image.md) | Image gen/edit tiers, `@image-high`, billing |
| [hint.md](hint.md) | Home hint chips — precompiled catalog, site shortcuts, SessionInit cache |
| [consumption.md](consumption.md) | Personal food/water tracking |
| [mcp-security.md](mcp-security.md) | **Security reminder** — MCP agent HTTP, secrets, owner lock |
| [site.md](site.md) | Sites — `site.*` schema, UITable, prompt `web.builder`, guest path URLs |
| [site-ai.md](site-ai.md) | Site mentions, multi-site context, query catalog, commerce tools |
| [tx.md](tx.md) | POS / transactions (`site.tx_*`, id.alienai model) |
| [channels.md](channels.md) | Messaging channels (Telegram, WhatsApp Cloud, WhatsApp Device) |
| [voice.md](voice.md) | STT/TTS engines (web / local / cloud), billing, cs_bots parity |
| [location.md](location.md) | Device / manual / IP city context, consent, SearXNG locale |

Schemas live in [`../schemas/`](../schemas/).

## Implementation plans

Working multitask / implementation plans live in [`plans/`](plans/). These are ephemeral execution docs — not locked specs. Update or archive when work completes.

Active: [Event bus + MCP log grep](plans/2026-09-26-event-bus-multitask.md).
