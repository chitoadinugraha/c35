# Roadmap (LOCKED)

Status: **locked** 2026-09-20

This document defines **where we start**, **where we end**, and **what is in scope per phase**. Schemas and protos for all vertical modules are locked before server/Flutter scaffolding.

## Start (Phase 0 — done)

Foundation specs only — no Rust/Flutter code yet.

| Area | Artifacts | Status |
|------|-----------|--------|
| Identity | `identity.sql`, `identity.proto` | locked |
| Chat | `chat.sql`, `chat.proto` | locked |
| Billing | `billing.sql`, `billing.proto` | locked |
| Log | `log.sql`, `log.proto` | locked |
| Embed cache | `embed.sql` | locked |
| Wire | `wire.proto`, `sync.proto`, `session.proto` | locked |
| Skill | `skill.sql`, `skill.proto` | locked |
| Consumption | `consumption.sql`, `consumption.proto` | locked |
| Site | `site.sql`, `site.proto` | locked |
| POS / Tx | `tx.sql`, `tx.proto` | locked |

**Start goal:** one identity model, one sync model, one wire envelope — no ambiguity when coding begins.

## End (Phase 9 — vision complete)

A user can:

1. Chat with personal AI on **Home** (`kind=prompt` inbox).
2. Manage **Bots** (multi-channel, `bot_peer` conversations, stop per peer).
3. Pair and control **Devices** (remote + IoT).
4. Build **Sites** via prompt (block-composed SiteDoc → publish → custom domain).
5. Run **POS** on Sites detail (id.alienai transaksi editor UX).
6. Teach **Skills** on user/device/team scope; install from catalog.
7. Track **Consumption** (meals, nutrition, water) on personal assistant tools.
8. See billing, referral, settings — ported from cs_agent patterns.

## Phase map

```
Phase 0  Specs + schemas + protos          ← done
Phase 1  servers/ workspace + mod_identity + mod_billing + wire_ws + ResSessionInit
Phase 2  Flutter shell + Home chat (master/detail, canvas)
Phase 3  mod_referral + Referral/Settings (cs_agent port)
Phase 4  mod_chat + message renderer (tokens, cost, duration)
Phase 5  mod_log + NATS live log viewer (root)
Phase 6  mod_device + remotes pairing + Devices page
Phase 7  mod_skill + mod_consumption (personal tools on Home assistant)
Phase 8  mod_site + Sites page (UITable tabs, prompt web.builder, guest render)
Phase 9  mod_tx + POS editor (id.alienai UI; site.tx_* schema)
```

**Shipped (2026-09-26):** Skill marketplace browse/install (Alien seed catalog) + OpenSkill registry merge on search — see [`skill.md`](skill.md).

## Module boundaries

| Module | Owner scope | Site scope | Reference |
|--------|-------------|------------|-----------|
| Skill | user, device, team, global | — | cs_agent |
| Consumption | user only | — | id.alienai + cs_agent |
| Site | site_iid | `site.*` doc, product, contact, object | prompt + UITable |
| Tx / POS | site_iid | `site.tx_*` sale, debt, GL, stock | id.alienai tx.proto |

### Key decisions (locked)

- **Site registry** = `identity(kind=site)` — no duplicate site registry table.
- **Site payload** = YSQL schema **`site`** (not `ai.site_*`).
- **Guest URLs** = `alienai.id/{alien_id}` path only; custom domain via grey CNAME to `site.alienai.id` + Host header (see `site.md`).
- **Guest layout** = `site.draft.doc_json` block tree — not CSA fixed hub sections.
- **Site admin UI** = Devices-like tabs + **UITable**; layout via Home prompt (`web.builder`).
- **Staff access** = `identity_grant` on site_iid.
- **POS** follows id.alienai tx (`site_iid` replaces `aid`); tables in **`site.tx_*`**.
- **Products** in `site.product`; blocks + POS reference `product_id`.
- **Embed dedupe** = `ai.embed_cache`; entity `ehash_search` on product/contact.

## Deferred past Phase 9

| Feature | Notes |
|---------|-------|
| pgvector HNSW on product embeds | `site.product_embed` metadata ready |
| Skill marketplace payments | Catalog schema ready |
| Normalized layout tables | `site.page` / `site.block` for UITable layout editing |
| File CAS | `file.sql` — render bundles; `site.publish.render_hash` |
| HR / payroll / presence | `site.config` policy JSON only |

## Next step (Phase 1)

Scaffold `servers/` workspace:

1. `Cargo.toml` workspace under `servers/crates/`
2. `server_ai` binary — boot, apply SQL in order, HTTP/WS listen
3. `mod_identity` + `mod_billing` + `wire_ws` + `ResSessionInit`
4. `mod_llm` stub with `embed_cache` read/write

Apply order: `identity → billing → chat → log → embed → skill → consumption → site → tx`.
