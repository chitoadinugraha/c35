# Architecture (LOCKED)

Status: **locked** 2026-09-20

## Overview

c35 is a unified Alien AI platform: personal AI chat, bots (channels), remote devices, IoT, and sites (websites + business/POS later). All actors share one identity table. Clients talk to a multi-crate Rust server over WebSocket with protobuf; data lives in YugabyteDB; realtime updates flow through NATS.

This is **not an MVP** — we assemble the best parts of prior projects on a cleaner foundation.

## Monorepo layout

```
c35/
  .cache/
    server/                    # server cargo target (gitignored)
    agent/                     # remote agent cargo target (gitignored)
  _/
    docs/                      # this directory
    schemas/                   # SQL + proto sources
    scripts/
    mcps/
  servers/                     # server-only Rust workspace
    .cargo/config.toml         # target-dir = "../.cache/server"
    Cargo.toml
    crates/
      proto/
      store/
      wire/
      wire_ws/
      wire_http/
      system/ctx/
      system/trace/
      mod_identity/
      mod_billing/
      mod_referral/
      mod_chat/
      mod_device/
      mod_log/
      mod_skill/
      mod_consumption/
      mod_site/                  # guest renderer + publish + site CRUD
      mod_tx/
    server_ai/                 # thin binary: boot, HTTP/WS, NATS subscribe
    fetcher/                   # thin binary: periodic external sync → NATS (c35-fetcher)
  remotes/                     # agent-only Rust workspace
    .cargo/config.toml         # target-dir = "../.cache/c_remote"
    Cargo.toml
    c_remote_core/
    c_remote_windows/
    c_remote_android/
  clients/
    app/                       # Flutter (alienai)
```

Server crates live under **`servers/crates/`** only — not at repo root. Remotes are a separate workspace with their own cache dir.

## Infrastructure

| Component | Role |
|-----------|------|
| YugabyteDB | Primary store. Schemas: `ai` (platform), `file` (CAS blobs) |
| NATS | Core pub/sub (live fanout) + JetStream (work queues, cron schedules). **Ephemeral** — YB hydrate on recovery. See [nats.md](nats.md) |
| WebSocket | Client sync + prompt stream. Connect: `/v1/ws?since=…&jwt=…&locale=…&tz=…` |
| Alien Beacon | IoT + remote device wire (paired agents) |
| JetStream | `C35_CHAT_PROMPT`, `C35_DEVICE_TASK`, `C35_TASK_SCHEDULE` — dispatch + NATS cron; no YB dispatch polling |
| `c35-proxy-cf-warp` | Cloudflare WARP mesh forward proxy (residential egress for search & web scraping) |
| SearXNG | Meta-search engine routed through CF WARP proxy (`searxng.searx.svc.cluster.local:8080`) |

## Core design principles

1. **One identity table** — user, team, bot, remote, iot, site are all rows in `ai.identity`.
2. **No space picker** — navigation via dedicated pages (Home, Bots, Devices, Sites). Personal AI chat binds to the signed-in `user` identity.
3. **Server-authoritative sync** — cs_bots pattern; no agent-local SQLCipher replica for the Flutter app.
4. **Incremental by `since`** — every syncable row has `created_ts`, `updated_ts`, `deleted_ts`; client sends watermark, server returns delta only.
5. **One round trip per page init** — `ReqSessionInit` / parallel IN queries; never N+1 on page load.
6. **Human-friendly UI** — no technical errors on screen; full detail in server `log` table + NATS live stream for root/admin.
7. **Multi-crate server** — workspace under `servers/` (like `csa_site_published` pattern); `server_ai` stays thin; domain in `servers/crates/mod_*`.
8. **Separate build caches** — `.cache/server`, `.cache/c_remote` (see `.cursor/rules/rust-cache.mdc`).

## Identity (summary)

See [identity.md](identity.md) and [`../schemas/identity.sql`](../schemas/identity.sql).

```
kind:  user | team | bot | remote | iot | site
type:  subtype within kind (windows, android, chat, switch, business, …)
id:    snowflake iid (PK)
alien_id: optional globally unique slug (was "handle")
owner_iid: user or team that owns this identity (self for user/team)
```

**Do not** use compound kinds like `remote-windows`. Use `kind=remote, type=windows`.

## Sync (summary)

See [sync.md](sync.md).

- Client caches `ResSessionInit` + recent chats in Flutter secure storage (protobuf).
- On connect, server returns changes since `?since=` only.
- Realtime pushes: `c35.user.{iid}.balance`, `.quota`, `.settings`, `.profile`, …
- Logs: `log.{iid}.{dv}.{topic}` (topics: `sign-in`, `prompt`, `connected`, …)

## UI (summary)

See [ui.md](ui.md).

- Shell from `alienai_proto`; appbar/error handling from `cs_agent`.
- Referral tree + settings: copy `cs_agent` exactly (adapt wire to new identity schema).
- Bots: 3-pane master/detail.
- Sites: Devices-like master/detail + tabs; prompt-primary layout editor ([`site.md`](site.md)).
- Devices: combined remote + IoT list; tabs differ by `kind`.
- Remote: control plane = agent ↔ server session; data plane = WebRTC (screen, files, media) — see [remote.md](remote.md).

## Pairing

| Target | Method |
|--------|--------|
| Remote agent | 10-char `[A-Z0-9]` code, display `XXXXX-XXXXX` |
| ESP32/C3/8266 | USB OTG flash from Android/Windows native lib |
| Media player | Web page `alienai.id/mp/` shows code; user adds from app |

## Build order

See [roadmap.md](roadmap.md) for full phase map.

| Phase | Deliverable |
|-------|-------------|
| 0 | `_/schemas/` + `_/docs/` — **foundation + skill/consumption/web/tx specs locked** |
| 1 | `servers/` workspace + `mod_identity` + `mod_billing` + `wire_ws` + `ResSessionInit` |
| 2 | Flutter shell + Home chat (master/detail, canvas drawer) |
| 3 | `mod_referral` + Referral/Settings pages (port cs_agent) |
| 4 | `mod_chat` + message renderer (tokens, cost, duration) |
| 5 | `mod_log` + NATS live log viewer (root) |
| 6 | `mod_device` + remotes pairing + Devices page |
| 7 | `mod_skill` + `mod_consumption` (personal tools) |
| 8 | `mod_site` + Sites page (UITable tabs, prompt `web.builder`, guest render) |
| 9 | `mod_tx` + POS editor (id.alienai UX; `site.tx_*` tables) |

## Deferred (vision)

| Feature | Notes |
|---------|-------|
| Self-learning skills | v1: manual teach + catalog; self-healing TBD |
| Skill marketplace payments | Catalog schema ready |
| IoT custom firmware | Alien Beacon live update |
| Channels | Telegram, WhatsApp Meta API, WhatsApp device (wa-rust) |
| Direct user chat | Schema reserved; UI deferred |
| File CAS / auto backup | Needs `file.sql` blob strategy |
| HR / payroll / presence | Policy JSON in site_config; modules later |

## Reference projects

| Path | Borrow |
|------|--------|
| `D:\cs_agent` | Referral, settings, msg trace UI, friendly errors, billing display |
| `D:\alienai_proto` | Shell, master/detail, canvas, avatar menu layout |
| `D:\cs_bots` | Identity table shape, server sync model |
| `E:\Project Archive\csa_site_published` | Publish/render pipeline, guest HTTP router, custom domain |

## Coding rules (from prior projects)

- Parallelize server work; prefer single IN query over loops.
- One `ReqSessionInit` (or page-equivalent) per screen load.
- Snowflake IDs ([snowflake.md](snowflake.md)); blake3 for hashing where applicable.
- Naming: `account_get`, `chat_list`, `identity_put` (contextual, lexical).
- Server log: `ca.L()` / trace crate; client: `l()`, `lError()`, `lFatal()` — never `print`.
- UI prefixes: `ui_`, `io_`, `in_`.
