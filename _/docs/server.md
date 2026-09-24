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
| Remote agents | `remotes/` | `.cache/c_remote` |

Each workspace has its own `Cargo.toml` and `.cargo/config.toml`. Cluster binaries (`server_ai`, `fetcher`, `node_stats`) live in the server workspace.

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
  fetcher/                     # thin binary (c35-fetcher Deployment)
    src/main.rs
    Cargo.toml
  node_stats/                  # thin binary (c35-node-stats DaemonSet)
    src/main.rs
    Cargo.toml
  server_ai/                   # thin binary (c35-server Deployment)
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
target-dir = "../.cache/c_remote"

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

`.cache/` is gitignored (see `servers/.cargo/config.toml` → `target-dir`).

| Script | What it cleans |
|--------|----------------|
| `.\cleanup.ps1` | Rust cache + cluster buildkit (both) |
| `.\_\scripts\dev\cleanup_rust_cache.ps1` | Local `.cache/server`, `.cache/c_remote`, `.cache/rust` |
| `.\_\scripts\deploy\cleanup_buildkit.ps1` | Cluster buildkit Docker layer cache |

Rust trim (default): stale artifacts older than 30 days (`cargo sweep` when installed, else file-age prune).  
Full wipe: `.\cleanup.ps1 -Full` or `cargo clean` in `servers/` / `remotes/`.

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

**Computer use** (tasks, skills, shell) runs over the agent control session only — never WebRTC. Full spec: [remote.md](remote.md).

| Crate | Role |
|-------|------|
| `mod_device` | Pairing, agent session registry, presence |
| `mod_task` | Task CRUD, JetStream dispatch, `TaskRunPush` fanout |

## Deployment

Target cluster: `btm.alienai.id` (k3s-btm, **arm64**).

- Push arm64 images to `hsg.ocir.io`
- Connect to cluster services via `.cluster.local` (Tailscale split DNS)
- Secrets: plaintext in cluster OK (private registry)

### `c35-server` HA

| Item | Value |
|------|-------|
| Replicas | **2** |
| Rolling update | `maxUnavailable: 0`, `maxSurge: 1` — always at least one pod ready |
| Pod identity | `NODE_NAME`, `POD_NAME` env from downward API (`spec.nodeName`, `metadata.name`) |
| Snowflake worker | `POD_NAME` → FNV-1a hash → `C35_WORKER_ID` bits (override with env `C35_WORKER_ID`) — see [snowflake.md](snowflake.md) |
| CAS storage | `emptyDir` at `/data/cas` — ephemeral per pod (stateless for ops) |

Manifest: [`_/deployments/c35-server/deployment.yaml`](../deployments/c35-server/deployment.yaml).

### `c35-node-stats` DaemonSet

One reporter pod per k8s node; samples host CPU/RAM/net, OS mounts (`/`, `/var/log`), and PVC usage (YB + NATS), publishes protobuf `StatsPush` on NATS every ~2s.

| Item | Value |
|------|-------|
| Namespace | `c35` (or cluster default for ops) |
| Binary | `c_node_stats` (`servers/node_stats/`) |
| Subjects | `c35.stats.node.{node_name}`, `c35.stats.volume.{namespace}.{pvc_name}` |
| Relay | `server_ai` WS `ReqStatsSubscribe` → root Flutter dashboard |
| Manifests | [`_/deployments/c35-node-stats/`](../deployments/c35-node-stats/) |

### `c35-fetcher` Deployment

Singleton periodic external sync — FX rates, LLM model catalog, future fetch tasks.

| Item | Value |
|------|-------|
| Replicas | **1** |
| Binary | `c35_fetcher` (`servers/fetcher/`) |
| Framework | `mod_fetch` — `FetchTask` trait + interval runner |
| Tasks (initial) | `fx_rate` (hourly, Open Exchange Rates + markup), `llm_catalog` (30m, Gemini API) |
| Persist | YB (`billing_fx_rate`, `llm_model`) |
| Fanout | NATS `c35.fetch.fx`, `c35.fetch.llm_catalog` |
| Consumers | `c35-server` pods subscribe at boot; in-memory FX + `llm_catalog_reload` |

Full spec: [fetcher.md](fetcher.md). Manifest: [`_/deployments/c35-fetcher/`](../deployments/c35-fetcher/) (implementation pending).

**Stateless:** no PVC. Same secrets as `c35-server` (YB, NATS, `OPENEXCHANGERATES_APP_ID`, `GEMINI_API_KEY`).

### Stateful inventory (cluster ops)

| Monitor | Path / source | Stateful? | Action when high |
|---------|---------------|-----------|------------------|
| Node boot disk | `/` on host | — | cleanup logs, resize node disk |
| Node logs | `/var/log` | — | rotate, truncate |
| YB data | PVC `yb-data` (`oci-bv`, Retain) | **Yes** | expand disk, add tserver |
| NATS JetStream | `emptyDir` on `nats-0` | **No** | hydrate from YB via `c35-server` |
| c35 CAS | `emptyDir` per pod | Ephemeral | move to PVC later if needed |

**Stateless (no volume row):** `c35-server`, `c35-fetcher`, `channel-whatsapp-device`, `coturn`.

### Channel worker (`channel-whatsapp-device`)

WhatsApp linked-device (QR pair) runs as a separate deployment in namespace `c35`.

| Item | Value |
|------|-------|
| In-cluster DNS | `http://channel-whatsapp-device.c35.svc.cluster.local:8080` |
| Server env | `WHATSAPP_WORKER_URL` — set on `c35-server` deployment; used by `mod_channel` pair start/abort to call worker HTTP (`/v1/channel/{channel_id}/restart`, `/stop`) |
| Shared secret | `c35-server-env` — `NATS_URL`, `NATS_USER`, `NATS_PASS`, `YB_*` (bootstrap via `.\_\scripts\deploy\bootstrap_c35_secret.ps1`) |
| NATS TLS CA | `nats-ca` secret mounted at `/nats-ca/ca.crt` (`NATS_CA` on both server and worker) |

**Publish (arm64 → OCIR → rollout):**

```powershell
.\_\scripts\deploy\publish_channel_whatsapp_device.ps1
.\_\scripts\deploy\publish_server.ps1
```

Worker first when pairing is needed; republish server after handler changes that consume `WHATSAPP_WORKER_URL`.

**Expected worker startup logs** (`kubectl logs -n c35 deploy/channel-whatsapp-device --tail=80`):

```
[wa-device] Yugabyte connected
[wa-device] NATS connected url=tls://nats-client.nats.svc.cluster.local:4222
```

If NATS auth or CA is wrong, startup shows `[wa-device] NATS unavailable: …` instead — pair and inbound message routing will not work.

**NATS subjects (channel pair + messaging):**

| Subject | Direction | Purpose |
|---------|-----------|---------|
| `c35.act.channel.whatsapp.device.pair` | server → worker | Start/restart QR pair (`ActChannelWhatsappPair`) |
| `c35.ev.channel.{owner_iid}.{bot_iid}.{channel_id}.pair` | worker → server | Pair status push (`EvChannelPairUpdate`: pairing, connected, error, …) |
| `c35.ev.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.in` | worker → server | Inbound WhatsApp message |
| `c35.act.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.send` | server → worker | Outbound send |
| `c35.act.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.typing` | server → worker | Outbound typing / voice recording state (`ActChannelMsgTyping`) |

Server WS clients receive pair updates via NATS fanout → `ChannelPairPush` (see `mod_channel` and [channels.md](channels.md)).

**NATS subjects (device task dispatch):**

| Subject | Direction | Purpose |
|---------|-----------|---------|
| `c35.act.device.{device_iid}.task.run` | server → agent (JetStream workqueue) | `ActDeviceTaskRun` |
| `c35.ev.device.{device_iid}.task.{run_id}` | agent → server | `EvDeviceTaskProgress` / `EvDeviceTaskDone` |
| `c35.ev.device.{device_iid}.presence` | agent ↔ server | `EvDevicePresence` |
| `c35.user.{owner_iid}.task_run` | server → client WS | `TaskRunPush` |

JetStream streams `C35_CHAT_PROMPT`, `C35_DEVICE_TASK`, `C35_TASK_SCHEDULE`. Queue groups `c35-prompt-dispatch`, `c35-task-dispatch`. No YB dispatch polling — see [remote.md](remote.md), [nats.md](nats.md).

**NATS** — server **2.15**, JetStream on **`emptyDir`** (no PVC). YB is source of truth; `c35_nats` + `nats_boot.rs` hydrate on connect/reconnect. Upgrade: [`_/scripts/deploy/nats_ephemeral_upgrade.ps1`](../scripts/deploy/nats_ephemeral_upgrade.ps1). Crate: `servers/crates/system/nats/`.

**Channel log topics** — worker and server write lifecycle rows to `ai.log` and publish `log.{owner_iid}.{dv}.{topic}` (see [log.md](log.md)). Canonical topic list: `pair_start`, `qr`, `connected`, `disconnected`, `pair_abort`, `pair_expired`, `error`, `msg_received`, `msg_sent`. Worker uses `dv = channel-wa-device`; server channel handlers use `dv = c35-server`. Full writer/when table: `plans/2026-09-21-bot-add-channels-deploy-log.md` (Log event catalog).

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
