# c35 — Alien AI Platform

> **Status:** Architecture locked (2026-09-20). This file is the **project spec** entry point. Canonical module specs live in [`_/specs/`](_/specs/README.md). User guides the site renders live in [`_/docs/`](_/docs/README.md).

## Goal

Rebuild Alien AI on a clean, expandable foundation — not a minimal MVP. Copy proven pieces from existing projects, then improve. Finish fast with tight structure.

## Repo layout

```
c35/
  .cache/
    server/               # server cargo target (gitignored)
    agent/                # remote agent cargo target (gitignored)
  _/                      # specs, user docs, scripts, schemas, mcps
  clients/app/            # Flutter (alienai)
  servers/                # server workspace (crates + server_ai binary)
  remotes/                # agent workspace (c_remote_*)
```

## Locked decisions (summary)

| Topic | Decision |
|-------|----------|
| Identity | Unified `ai.identity` table; every actor gets snowflake `id` (iid) — see [`_/specs/snowflake.md`](_/specs/snowflake.md) |
| Kinds | `user` · `team` · `bot` · `remote` · `iot` · `site` |
| Subtypes | `type` column (`windows`, `android`, `chat`, `switch`, `business`, …) |
| Handle | Renamed to **`alien_id`** (globally unique, `[a-z0-9_-]`) |
| Org/group | Renamed to **`team`** |
| Remote PC/Android | `kind=remote`, not a space row |
| Access / RBAC | **`identity_grant` only** — team membership, site staff, resource share |
| Sync | cs_bots-like server YB; incremental delta by `since` |
| Timestamps | All syncable rows: `created_ts`, `updated_ts`, `deleted_ts` |
| Navigation | **No space picker** — Home / Bots / Devices / Sites pages |
| Business/POS | Under **Sites** page (Devices-like tabs + UITable); prompt builds layout |
| Server | Multi-crate workspace under `servers/` (not repo root) |
| Bot | `kind=bot`, `type=chat`; one bot, many channels in `meta.channels[]` |
| Home inbox | **`prompt` AI chats only** — direct user↔user deferred |
| Build cache | `.cache/server`, `.cache/c_remote` |

Full detail: [`_/specs/architecture.md`](_/specs/architecture.md)

## Infrastructure

- **YB** — primary store (`ai` platform + `site` payload + file CAS in `ai.file_blob_*`)
- **NATS** — core pub/sub + JetStream (ephemeral); YB hydrate on recovery — [`_/specs/nats.md`](_/specs/nats.md)
- **WS / Alien Beacon** — client + device wire protocol
- **Protobuf** — all RPC / sync messages

## Phase 1 scope (build now)

1. Identity schema + wire (`ResSessionInit`, delta sync)
2. Flutter shell (title bar, avatar menu, chat master/detail, canvas)
3. Referral tree + settings (copy from `D:\cs_agent`)
4. Message renderer with billing trace (copy from `D:\cs_agent`)
5. Live log over NATS (root/admin viewer)
6. Devices page (remote + IoT)
7. Bots page (3-pane)
8. Sites page (UITable admin + prompt-built guest sites; POS later)

## Later (vision, not Phase 1)

Self-learning skills, IoT firmware + Alien Beacon, MCP tools, skill marketplace, health tracker, prompt-built websites, channels (Telegram/WhatsApp).

## UI shell (summary)

```
(Alien AI)          [server picker]  title    [canvas]  [avatar]  _ □ ×
```

Avatar menu: profile/settings · partner/root · quota rings · (bots)(devices)(sites) with counts · referral · lock · logout.

- Home = personal AI chat (binds to `user` identity, not a space). **Chat** and **Talk** are two surfaces on that same thread ([`_/specs/ui.md`](_/specs/ui.md#talk))
- Master/detail on large screens; drawer on small screens
- Canvas = end drawer on mobile; toggle hidden when no canvas content
- Chat: pin, archive, `#tag` from title, archive-below
- Friendly errors only (never red screen); technical detail in server log

Full UI spec: [`_/specs/ui.md`](_/specs/ui.md)

## Pairing

10-char code `[A-Z0-9]`, formatted `XXXXX-XXXXX`.

- ESP32/C3/8266: USB OTG flash from Android/Windows app
- Media player: `alienai.id/mp/` shows pairing code

## Project references

| Project | Use |
|---------|-----|
| `D:\cs_agent` | Referral, settings, msg renderer, billing trace, error handling |
| `D:\alienai_proto` | Shell layout, master/detail, canvas |
| `D:\cs_bots` | Identity model, sync pattern |
| `E:\Project Archive\csa_site_published` | Publish/render, guest HTTP, custom domain; not CSA site editor UI |

## Docs index

| Doc | Contents |
|-----|----------|
| [`_/specs/architecture.md`](_/specs/architecture.md) | Locked system design |
| [`_/specs/identity.md`](_/specs/identity.md) | Identity kinds, grants, alien_id |
| [`_/specs/referral.md`](_/specs/referral.md) | Referral forest, partner/director/root RBAC, admin audit events |
| [`_/specs/chat.md`](_/specs/chat.md) | Chat; Home inbox = prompt only |
| [`_/specs/mention.md`](_/specs/mention.md) | Mentions — bracket text `[@iid:…]`, wire `mention_ids[]`, reload context |
| [`_/specs/inst.md`](_/specs/inst.md) | Instruction macros (`ai.inst`) — LLM prompt steering |
| [`_/specs/sync.md`](_/specs/sync.md) | `_ts` fields, since-delta, indexes, NATS |
| [`_/specs/data_source.md`](_/specs/data_source.md) | Bot data sources — cached Google Sheets (generic sync/chunk tables) |
| [`_/specs/drive.md`](_/specs/drive.md) | Alien AI Drive — owner volume, agent A: mount, CAS + quotas |
| [`_/specs/server.md`](_/specs/server.md) | Crate workspace layout |
| [`_/specs/schema-migrate.md`](_/specs/schema-migrate.md) | YSQL schema bundle hash, boot skip, `c35_migrate` |
| [`_/specs/ui.md`](_/specs/ui.md) | Pages, navigation, components |
| [`_/specs/presentation.md`](_/specs/presentation.md) | Presentations — native Flutter slide decks, 16:9 preview, Option C patching, PPTX export |
| [`_/specs/remote.md`](_/specs/remote.md) | Remote: agent control session + WebRTC data plane (screen, files, media), NATS task scheduler & computer use |
| [`_/specs/browser-remote.md`](_/specs/browser-remote.md) | Remote browser (`type=browser`): Rust agent + Playwright sidecar, same WebRTC UX |
| [`_/specs/plans/2026-09-29-chrome-extension-remote-multitask.md`](_/specs/plans/2026-09-29-chrome-extension-remote-multitask.md) | Chrome extension remote (daily profile): native host, pair web page, OTA, alienai.id download |
| [`_/specs/browser-extension.md`](_/specs/browser-extension.md) | Chrome extension remote (locked spec) — created in CE-W1 Track A |
| [`_/specs/remote-agent.md`](_/specs/remote-agent.md) | Remote agent architecture, multi-platform porting, OTA & watchdog spec |
| [`_/specs/remote-android.md`](_/specs/remote-android.md) | Android Remote Agent (`id.alienai.remote`): dual-app model, WebRTC, MediaProjection, Accessibility & SoM |
| [`_/schemas/identity.sql`](_/schemas/identity.sql) | Identity + grants DDL |
| [`_/schemas/chat.sql`](_/schemas/chat.sql) | Chat + messages |
| [`_/specs/billing.md`](_/specs/billing.md) | Multi-wallet billing, quota, commission |
| [`_/specs/billing-implementation.md`](_/specs/billing-implementation.md) | Billing v2 rollout plan |
| [`_/specs/log.md`](_/specs/log.md) | Audit log + billing trace |
| [`_/schemas/billing.sql`](_/schemas/billing.sql) | Billing DDL |
| [`_/schemas/log.sql`](_/schemas/log.sql) | Log DDL |
| [`_/specs/site.md`](_/specs/site.md) | Sites — `site.*` schema, UITable, guest URLs |
| [`_/specs/mail.md`](_/specs/mail.md) | Platform mail — `mail.*`, CF onboard, vs `site.domain` HTTP |
| [`_/specs/site-ai.md`](_/specs/site-ai.md) | Site @mentions, multi-site context, `site.query.run` catalog |
| [`_/specs/site-builder.md`](_/specs/site-builder.md) | Conversational Site Builder — slide-deck pattern, Rust handle generator, block patching, token cache spec |
| [`_/specs/tx.md`](_/specs/tx.md) | POS — `site.tx_*`, id.alienai UI + model |
| [`_/schemas/site.sql`](_/schemas/site.sql) | Site DDL (`site` schema) |
| [`_/schemas/tx.sql`](_/schemas/tx.sql) | POS DDL (`site.tx_*`) |
| [`_/schemas/proto/`](_/schemas/proto/) | Protobuf wire (`c35/*.proto`) |
