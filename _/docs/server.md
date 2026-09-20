# Server layout (LOCKED)

Status: **locked** 2026-09-20 · Phase 1 scaffold **started**

See also **[structure.md](structure.md)** for full file tree and per-crate conventions.

## Why multi-crate

Monolithic server (cs_agent-style) recompiles everything on every change. `csa_site_published` splits domain into small crates → faster iteration, clear boundaries, easier testing.

c35 follows the **csa workspace pattern**, but crates live under **`servers/`** — server-only, not at repo root.

## Two Rust workspaces

| Workspace | Path | Cache dir |
|-----------|------|-----------|
| Server | `servers/` | `.cache/server` |
| Remote agents | `remotes/` | `.cache/agent` |

Each workspace has its own `Cargo.toml` and `.cargo/config.toml`.

## Server workspace

```
servers/
  .cargo/config.toml
  Cargo.toml
  crates/                      # all server library crates
    proto/
    store/
    wire/
    wire_ws/
    wire_http/
    system/
      ctx/
      trace/
    mod_identity/
    mod_billing/
    mod_referral/
    mod_chat/
    mod_device/
      mod_log/
      mod_skill/                 # Phase 7
      mod_consumption/           # Phase 7
      mod_site/                  # Phase 8
      mod_tx/                    # Phase 9
  server_ai/                   # thin binary
    src/main.rs
    Cargo.toml
```

### `servers/Cargo.toml`

```toml
[workspace]
resolver = "2"
members = [
  "crates/proto",
  "crates/store",
  "crates/wire",
  "crates/wire_ws",
  "crates/wire_http",
  "crates/system/ctx",
  "crates/system/trace",
  "crates/mod_identity",
  "crates/mod_billing",
  "crates/mod_referral",
  "crates/mod_chat",
  "crates/mod_device",
  "crates/mod_log",
  "crates/mod_site",
  "server_ai",
]
```

Add new `mod_*` under `servers/crates/` when a domain page needs isolation.

### `servers/.cargo/config.toml`

```toml
[build]
target-dir = "../.cache/server"

[profile.dev]
debug = 1
split-debuginfo = "unpacked"

[target.x86_64-pc-windows-msvc]
linker = "rust-lld.exe"
```

Build from `servers/`:

```bash
cd servers && cargo build -p server_ai
```

## Remote agent workspace

```
remotes/
  .cargo/config.toml
  Cargo.toml
  c_remote_core/
  c_remote_windows/
  c_remote_android/
```

### `remotes/.cargo/config.toml`

```toml
[build]
target-dir = "../.cache/agent"

[profile.dev]
debug = 1
split-debuginfo = "unpacked"

[target.x86_64-pc-windows-msvc]
linker = "rust-lld.exe"
```

Build from `remotes/`:

```bash
cd remotes && cargo build -p c_remote_windows
```

## Cache cleanup

`.cache/` is gitignored. Delete subdirs independently:

- `rm -rf .cache/server` — server build artifacts only
- `rm -rf .cache/agent` — agent build artifacts only

## Crate responsibilities

All paths relative to `servers/crates/`.

### Foundation

| Crate | Role |
|-------|------|
| `proto` | Protobuf types (prost), shared enums |
| `store` | YB pool, migrations runner, generic `since_list()` helpers |
| `wire` | Invoke req/res framing, error types |
| `wire_ws` | WebSocket handler, session, sync push |
| `wire_http` | HTTP routes (auth, upload, health) |

### System

| Crate | Role |
|-------|------|
| `system/ctx` | `Ctx { pool, nats, uid, iid, … }` passed into handlers |
| `system/trace` | Structured logging; bridges to `ai.log` |

### Domain (`mod_*`)

| Crate | Role | Phase |
|-------|------|-------|
| `mod_identity` | Sign-in, alien_id, team, auth_session | 1 |
| `mod_billing` | Wallets, quota, balance | 1 |
| `mod_referral` | Referral tree, codes, shares | 3 |
| `mod_chat` | Chat, ChatMsg, prompt, renderer data | 4 |
| `mod_log` | Log write, NATS fanout, admin filter | 5 |
| `mod_device` | Remote + IoT pairing, presence, skills | 6 |
| `mod_site` | Site CRUD stub → POS later | 8 |

Each `mod_*` crate:

- Owns its SQL queries (via `store` helpers)
- Exposes fns called from `wire_ws` / invoke router
- Does **not** depend on other `mod_*` crates unless necessary (prefer `store` + `proto`)

### Server binary

`servers/server_ai/` — thin:

- Load config / secrets
- Connect YB + NATS
- Run migrations (`_/schemas/*.sql`)
- Mount `wire_http` + `wire_ws`
- Subscribe NATS internal subjects
- Register invoke handlers that delegate to `mod_*`

No business logic in `server_ai/src/main.rs` beyond wiring.

## Dependency direction

```
server_ai
  → wire_ws, wire_http
    → mod_*, system/ctx, system/trace
      → store, proto
```

`mod_*` must not depend on `wire_ws` or `server_ai`.

## Proto sharing with remotes

Remotes need a subset of wire/proto types. Options (pick at scaffold time):

1. **`servers/crates/proto`** published as path dep from remotes (`path = "../servers/crates/proto"`)
2. **`_/schemas/proto/`** as source; both workspaces generate/build from same defs

Prefer (2) long-term; (1) is fine for Phase 0.

## Schema boot

On server start, apply in order (see [`../schemas/README.md`](../schemas/README.md)):

1. `_/schemas/identity.sql`
2. `_/schemas/billing.sql`
3. `_/schemas/chat.sql`
4. `_/schemas/log.sql`
5. `_/schemas/embed.sql`
6. `_/schemas/skill.sql`
7. `_/schemas/consumption.sql`
8. `_/schemas/site.sql`
9. `_/schemas/tx.sql`
10. `_/schemas/file.sql` (when needed)

Set `C35_DB_MIGRATE=1` on boot. Implemented in `c35_store::migrate_apply`.

## Invoke / RPC pattern

Match existing Alien conventions:

- Protobuf `InvokeReq` / `InvokeRes` over WS or HTTP
- Methods routed in `wire_ws` to `mod_*` handlers
- Naming: `referral_tree_get`, `identity_put`, `chat_list`

## Remotes

| Crate | Role |
|-------|------|
| `c_remote_core` | Shared pairing UI, cluster connection |
| `c_remote_windows` | Windows automation (port from cs_agent agent_windows) |
| `c_remote_android` | Android automation |

Remotes register as `identity(kind=remote, type=…)` on pair. Wire: Alien Beacon + WS to server.

## Deployment

Target cluster: `btm.alienai.id` (k3s-btm, **arm64**).

- Push arm64 images to `hsg.ocir.io`
- Connect to cluster services via `.cluster.local` (Tailscale split DNS)
- Secrets: plaintext in cluster OK (private registry)

## What we copy from csa_site_published

- Workspace + `mod_*` naming (relocated under `servers/crates/`)
- Thin server binary
- `store` crate for DB
- `wire_*` split
- Dev profile settings for fast Windows builds

## What we do not copy

- Root-level `crates/` directory — server crates stay under `servers/`
- CSA-specific site modules wholesale — only the **pattern**
- MQTT/QUIC wire crates until IoT phase needs them (add `wire_beacon` later)
