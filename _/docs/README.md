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
| [billing-pricing.md](billing-pricing.md) | Alien / Frontier pool rates, model comparison, debit order |
| [billing-plans.md](billing-plans.md) | Lite–Ultra plans, bot/device SKUs, promotions |
| [billing-implementation.md](billing-implementation.md) | Phased rollout plan (schema → server → client) |
| [log.md](log.md) | Unified audit + billing log |
| [sync.md](sync.md) | Incremental sync, `_ts` convention, NATS subjects |
| [server.md](server.md) | Rust crate workspace layout |
| [ui.md](ui.md) | Flutter shell, pages, navigation |
| [roadmap.md](roadmap.md) | Phase 0→9 start/end goals |
| [skill.md](skill.md) | Skill scope, catalog, automation |
| [remote.md](remote.md) | Remote device: agent control session + WebRTC data plane (files, screen, media) |
| [inst.md](inst.md) | Instruction macros (`ai.inst`) — phrase steering + tool include/exclude |
| [hint.md](hint.md) | Home hint chips — precompiled catalog, site shortcuts, SessionInit cache |
| [consumption.md](consumption.md) | Personal food/water tracking |
| [site.md](site.md) | Sites — `site.*` schema, UITable, prompt `web.builder`, guest path URLs |
| [site-ai.md](site-ai.md) | Site mentions, multi-site context, query catalog, commerce tools |
| [tx.md](tx.md) | POS / transactions (`site.tx_*`, id.alienai model) |
| [channels.md](channels.md) | Messaging channels (Telegram, WhatsApp Cloud, WhatsApp Device) |
| [voice.md](voice.md) | STT/TTS engines (web / local / cloud), billing, cs_bots parity |

Schemas live in [`../schemas/`](../schemas/).
