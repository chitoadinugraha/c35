# c35 — Alien AI Platform

> **Status:** Architecture locked (2026-09-20). This file is the **project spec** entry point. Canonical module specs live in [`_/docs/`](_/docs/README.md).

## Goal

Rebuild Alien AI on a clean, expandable foundation — not a minimal MVP. Copy proven pieces from existing projects, then improve. Finish fast with tight structure.

## Repo layout

```
c35/
  .cache/
    server/               # server cargo target (gitignored)
    agent/                # remote agent cargo target (gitignored)
  _/                      # docs, scripts, schemas, mcps
  clients/app/            # Flutter (alienai)
  servers/                # server workspace (crates + server_ai binary)
  remotes/                # agent workspace (c_remote_*)
```

## Locked decisions (summary)

| Topic | Decision |
|-------|----------|
| Identity | Unified `ai.identity` table; every actor gets snowflake `id` (iid) — see [`_/docs/snowflake.md`](_/docs/snowflake.md) |
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

Full detail: [`_/docs/architecture.md`](_/docs/architecture.md)

## Infrastructure

- **YB** — primary store (`ai` platform + `site` payload + file CAS in `ai.file_blob_*`)
- **NATS** — core pub/sub + JetStream (ephemeral); YB hydrate on recovery — [`_/docs/nats.md`](_/docs/nats.md)
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

- Home = personal AI chat (binds to `user` identity, not a space)
- Master/detail on large screens; drawer on small screens
- Canvas = end drawer on mobile; toggle hidden when no canvas content
- Chat: pin, archive, `#tag` from title, archive-below
- Friendly errors only (never red screen); technical detail in server log

Full UI spec: [`_/docs/ui.md`](_/docs/ui.md)

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
| [`_/docs/architecture.md`](_/docs/architecture.md) | Locked system design |
| [`_/docs/identity.md`](_/docs/identity.md) | Identity kinds, grants, alien_id |
| [`_/docs/chat.md`](_/docs/chat.md) | Chat; Home inbox = prompt only |
| [`_/docs/inst.md`](_/docs/inst.md) | Instruction macros (`ai.inst`) — LLM prompt steering |
| [`_/docs/sync.md`](_/docs/sync.md) | `_ts` fields, since-delta, indexes, NATS |
| [`_/docs/server.md`](_/docs/server.md) | Crate workspace layout |
| [`_/docs/ui.md`](_/docs/ui.md) | Pages, navigation, components |
| [`_/docs/remote.md`](_/docs/remote.md) | Remote: agent control session + WebRTC data plane (screen, files, media) |
| [`_/docs/remote-agent.md`](_/docs/remote-agent.md) | Remote agent architecture, multi-platform porting, OTA & watchdog spec |
| [`_/schemas/identity.sql`](_/schemas/identity.sql) | Identity + grants DDL |
| [`_/schemas/chat.sql`](_/schemas/chat.sql) | Chat + messages |
| [`_/docs/billing.md`](_/docs/billing.md) | Multi-wallet billing, quota, commission |
| [`_/docs/billing-implementation.md`](_/docs/billing-implementation.md) | Billing v2 rollout plan |
| [`_/docs/log.md`](_/docs/log.md) | Audit log + billing trace |
| [`_/schemas/billing.sql`](_/schemas/billing.sql) | Billing DDL |
| [`_/schemas/log.sql`](_/schemas/log.sql) | Log DDL |
| [`_/docs/site.md`](_/docs/site.md) | Sites — `site.*` schema, UITable, guest URLs |
| [`_/docs/mail.md`](_/docs/mail.md) | Platform mail — `mail.*`, CF onboard, vs `site.domain` HTTP |
| [`_/docs/site-ai.md`](_/docs/site-ai.md) | Site @mentions, multi-site context, `site.query.run` catalog |
| [`_/docs/tx.md`](_/docs/tx.md) | POS — `site.tx_*`, id.alienai UI + model |
| [`_/schemas/site.sql`](_/schemas/site.sql) | Site DDL (`site` schema) |
| [`_/schemas/tx.sql`](_/schemas/tx.sql) | POS DDL (`site.tx_*`) |
| [`_/schemas/proto/`](_/schemas/proto/) | Protobuf wire (`c35/*.proto`) |
