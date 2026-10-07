# Device live telemetry + MCP `device_list` pagination — multitask plan

**Date:** 2026-10-06  
**Status:** planned  
**Goal:** Agents report **battery / charging / power source**; server measures **cloud RTT** on the control WebSocket; fan out **live telemetry on NATS** (not YB); extend **`device_list` / `device_get`** with overlay + **search/pagination**; Flutter Devices row shows **battery when on battery**.

> **For agentic workers:** Dispatch one `Task` per track below. Model: **inherit** only. Verify per `verify-after-edit.mdc` after each track.

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| Telemetry durability | **No YB writes** for battery, charging, RTT, or quality — ephemeral server state + NATS only |
| Presence / `last_seen` | Keep existing cadence (~30s NATS presence, ~60s YB `last_seen_ts_ms`) — unchanged |
| Fanout | **B:** dedicated subject `c35.user.{owner_iid}.app.device_telemetry` + `DeviceTelemetryPush` on `WsRes` |
| Agent upload interval | **10s** battery/power report on control WS (single protobuf frame) |
| Cloud RTT | **Server** measures WS Ping/Pong RTT; store **EMA** (α ≈ 0.3); publish with telemetry fanout |
| `power_source` | `ac` \| `battery` \| `unknown` |
| `charging` | `bool` — meaningful on Android; Windows may set `false` on AC, `true` when charging over USB if detectable |
| Browser agents | Send `unknown` / omit `battery_pct` — no error |
| MCP `device_list` default | Document **`limit: 10`** for LLM calls; omit `limit` = **no cap** (backward compatible) |
| Sort (list API) | Pinned grant first → `sort_order` → `last_seen_ts_ms` DESC → `id` DESC |
| Stale telemetry | `telemetry_age_ms > 30_000` → treat cloud/battery fields as stale in MCP + UI |
| Quality buckets | `good` &lt; 150ms, `fair` &lt; 400ms, `poor` ≥ 400ms (tune in one constant) |

---

## Architecture

```text
Agent (10s) ──WsReq AgentTelemetryReport──► server_ai (agent_session)
Server (each Pong) ──► EMA cloud_rtt_ms ──► DashMap device_iid → DeviceLiveTelemetry
Server (10s tick or on change) ──NATS──► c35.user.{owner}.app.device_telemetry
                                                      │
Flutter app WS ◄── user_app_fanout_decode ────────────┘
MCP device_list / device_get ◄── merge DashMap overlay (session pod)
```

**Multi-pod:** v1 = in-memory on the pod that holds the agent WS; MCP may return stale `telemetry_age_ms` if routed to another pod. Optional **v2 track:** JetStream KV `c35_device_live` / `device/{device_iid}` (same pattern as `c35_stats`) — not in v1 scope unless MCP gaps appear in prod.

---

## Multitask map (9 tracks)

| Track | Name | Depends on | Delivers |
|-------|------|------------|----------|
| **P** | Proto + docs lock | — | `device.proto`, `remote.proto`, `wire.proto`, `sync.md`, `remote.md` |
| **S** | Server telemetry core | P | `mod_device` live map, NATS fanout, agent WS handler, RTT in `agent_session` |
| **R** | `device_list` / `device_get` API | S (overlay types) | `mcp_device_list` opts, HTTP MCP args, inst MCP mirror |
| **W** | Windows agent | P | Battery + 10s telemetry send |
| **A** | Android agent | P | BatteryManager + 10s telemetry |
| **B** | Browser agent | P | No-op / unknown telemetry (stub in shared core) |
| **F** | Flutter app UI | S | `DeviceTelemetryCache`, row battery chip, optional RTT subtitle |
| **M** | MCP / inst polish | R | Schemas, tool descriptions, `device_list_http` args |
| **V** | Verify + regression | all | `cargo build`, `verify_flutter_app`, manual MCP checklist |

### Parallel waves

| Wave | Tracks (parallel) |
|------|-------------------|
| **1** | **P** |
| **2** | **S** + **B** (stub only) |
| **3** | **W** + **A** + **R** |
| **4** | **F** + **M** |
| **5** | **V** |

---

## Track P — Proto + docs

### Proto (`_/schemas/proto/c35/`)

**`device.proto`** — add:

```protobuf
enum DevicePowerSource {
  DEVICE_POWER_SOURCE_UNSPECIFIED = 0;
  DEVICE_POWER_SOURCE_AC = 1;
  DEVICE_POWER_SOURCE_BATTERY = 2;
  DEVICE_POWER_SOURCE_UNKNOWN = 3;
}

// Agent → server on control WS (WsReq body).
message AgentTelemetryReport {
  int32 battery_pct = 1;          // 0–100; omit or -1 if unknown
  DevicePowerSource power_source = 2;
  bool charging = 3;
}

// NATS app lane + WsRes fanout (server → app).
message DeviceTelemetryPush {
  int64 device_iid = 1;
  int64 updated_ts_ms = 2;
  int32 cloud_rtt_ms = 3;         // 0 = unknown
  string cloud_quality = 4;       // good | fair | poor | unknown
  int32 battery_pct = 5;          // -1 unknown
  DevicePowerSource power_source = 6;
  bool charging = 7;
}
```

**`remote.proto`** — re-export or duplicate `AgentTelemetryReport` if agents only import `remote` crate (match existing pattern for agent-bound messages).

**`wire.proto`**

- `WsReq`: add `AgentTelemetryReport agent_telemetry_report = <next free>` (agent → server).
- `WsRes`: add `DeviceTelemetryPush device_telemetry_push = <next free>` (already have `device_presence_push = 178`).

Regenerate Dart + Rust protos (project’s usual codegen script / CI step).

### Docs

| File | Section |
|------|---------|
| `_/docs/sync.md` | New row: `c35.user.{iid}.app.device_telemetry` → `WsRes` (`DeviceTelemetryPush`) |
| `_/docs/remote.md` | § Presence — telemetry **not** in YB; 10s NATS; fields table |
| `_/docs/mcp-security.md` | `device_list` optional `q`, `limit`, `cursor`, `type`, `online_only` |

**Verify:** `cargo build -p server_ai` after codegen (proto compile only).

---

## Track S — Server telemetry core

### New module

| File | Responsibility |
|------|----------------|
| `servers/crates/mod_device/src/device_telemetry.rs` | `DeviceLiveTelemetry` struct, `DashMap<i64, …>`, EMA RTT, `quality_from_rtt`, `telemetry_overlay_json()` |
| `servers/crates/mod_device/src/device_telemetry_fanout.rs` | `device_telemetry_push(nats, owner_iid, push)` |

### NATS

| File | Change |
|------|--------|
| `servers/crates/system/nats/src/user_app.rs` | `user_app_subject_device_telemetry(owner_iid)` |
| `servers/crates/system/nats/src/user_app.rs` | `user_app_fanout_decode` — handle tail `device_telemetry` like `device_presence` |

### Agent WS

| File | Change |
|------|--------|
| `servers/crates/wire_ws/src/agent_session.rs` | On `Message::Pong`, record RTT vs last ping instant; call `device_telemetry_note_rtt(device_iid, rtt_ms)` |
| `servers/crates/mod_device/src/remote_signaling.rs` | `dispatch_agent_req`: handle `AgentTelemetryReport` → update live map + schedule fanout |
| `servers/crates/wire_ws/src/agent_session.rs` | Spawn 10s interval per session: `device_telemetry_publish_if_dirty(owner_iid, device_iid)` (coalesce battery + RTT) |

**Rules**

- Do **not** merge telemetry into `agent_presence_heartbeat` YB patch.
- Fanout payload: full `DeviceTelemetryPush` inside `WsRes` on subject `device_telemetry`.

### Unit tests (`mod_device`)

- EMA + quality bucket boundaries.
- Stale age helper.

**Verify:** `cd servers && cargo test -p c35_mod_device` (new tests), `cargo build -p server_ai`.

---

## Track R — `device_list` / `device_get`

### Rust

| File | Change |
|------|--------|
| `servers/crates/mod_device/src/mcp_device.rs` | `DeviceListOpts { q, limit, cursor, type_filter, online_only }`; SQL with grant join (mirror `identity_list` pin/sort); keyset `id < cursor` |
| `servers/crates/mod_device/src/mcp_device.rs` | Merge `device_telemetry::overlay(device_iid)` into each row + `device_get` |
| `servers/crates/wire_http/src/mcp_agent.rs` | Parse optional args from `args_json` for `device_list` |

**Response shape (additive)**

```json
{
  "device_iid": "...",
  "name": "...",
  "cloud_online": true,
  "telemetry": {
    "cloud_rtt_ms": 87,
    "cloud_quality": "good",
    "battery_pct": 62,
    "power_source": "battery",
    "charging": false,
    "telemetry_age_ms": 3200
  },
  "next_cursor": "..."
}
```

**`online_only`:** filter using existing `cloud_online_from_meta` + live map age (device considered offline if presence stale).

**Verify:** MCP `device_list` with `owner_iid=99000`, `q=DESKTOP`, `limit=5`; `device_get` shows telemetry when agent connected.

---

## Track W — Windows agent

| File | Change |
|------|--------|
| `remotes/c_remote_core/src/device_power.rs` (new) | `device_power_snapshot() -> (battery_pct, power_source, charging)` via `GetSystemPowerStatus` |
| `remotes/c_remote_core/src/conn_ws.rs` | 10s task: encode `WsReq { agent_telemetry_report }` → `write.send(Binary)` |
| `remotes/c_remote_core/src/lib.rs` | `mod device_power` |

Windows laptop: `battery_pct` + `on_battery`; desktop on AC: `power_source=ac`, `battery_pct=-1`.

**Verify:** `cd remotes && cargo build -p c_remote_windows`; paired device → server logs / MCP overlay.

---

## Track A — Android agent

| File | Change |
|------|--------|
| `remotes/c_remote_android/.../RemoteAgentService.kt` | `BatteryManager` snapshot helper |
| Rust JNI or existing bridge | Prefer **Kotlin → Rust** callback if WS loop is Rust; else periodic Kotlin push into Rust WS sender (match project pattern) |

Must report `charging` from `BATTERY_STATUS_CHARGING` / `FULL`.

**Verify:** Emulator or device; MCP `device_get` shows battery while unplugged.

---

## Track B — Browser agent

| File | Change |
|------|--------|
| `remotes/c_remote_browser` or `c_remote_core` | Shared 10s tick sends `power_source=unknown`, `battery_pct=-1`, `charging=false` **or** skip send entirely (server publishes RTT-only telemetry) |

Do not block session if telemetry send fails.

**Verify:** Browser device online; `cloud_rtt_ms` populated, battery absent.

---

## Track F — Flutter app

| File | Change |
|------|--------|
| `clients/app/lib/c/device/device_telemetry_cache.dart` (new) | Like `DevicePresenceCache`; `apply(DeviceTelemetryPush)` |
| `clients/app/lib/c/chat/chat_conn.dart` | Handle `WsRes.deviceTelemetryPush` stream |
| `clients/app/lib/pages/page_devices.dart` | Subscribe; pass telemetry into row builder |
| `clients/app/lib/widgets/devices/ui_device_row.dart` | Optional `batteryPct`, `onBattery`, `cloudRttMs` — show `NN%` chip next to **cloud** dot when `onBattery && batteryPct >= 0` |
| `clients/app/lib/widgets/devices/ui_device_detail.dart` | Optional subtitle: “Cloud latency ~87 ms” when fresh |

Tooltip cloud dot: include RTT when `cloud_quality != unknown`.

**Verify:** `.\_\scripts\dev\verify_flutter_app.ps1`; manual Devices page with Windows + Android.

---

## Track M — MCP / inst mirror

| File | Change |
|------|--------|
| `_/mcps/inst/src/device.ts` | Same SQL opts as Rust; telemetry overlay **SQL cannot see RTT** — document that **HTTP `device_list` via server** is source of truth for telemetry; inst DB tool returns DB fields only **or** call `agentPost('device_list')` for parity (prefer mirror HTTP for list when telemetry needed) |
| `_/mcps/inst/src/device_agent.ts` | Pass `q`, `limit`, `cursor`, `type`, `online_only` in `device_list_http` |
| MCP tool descriptions | State default `limit: 10` for agents; “use `device_get` for one device” |

**Decision:** `device_list` in **inst DB** gets pagination/search only; **telemetry fields only on server `mcp_device_list`** (HTTP agent). Update inst `device.ts` description to say telemetry requires `device_list_http` / cluster MCP.

**Verify:** `cd _/mcps/inst && npm run build`; Cursor MCP reload.

---

## Track V — Verification checklist

- [ ] Agent connected 30s → NATS subject receives `device_telemetry` (~10s interval).
- [ ] YB `meta` unchanged by telemetry (spot-check `SELECT meta FROM ai.identity WHERE id = ?` during session).
- [ ] `device_list { "limit": 10 }` returns ≤10 rows + `next_cursor` when more exist.
- [ ] `device_list { "q": "chrome" }` filters by name.
- [ ] Prompt / tool: “what’s my battery on DESKTOP?” → `device_list` + `device_get` with overlay.
- [ ] Flutter: battery chip visible on battery power only.
- [ ] `check_utf8_sources.ps1 -Changed -Fix` on touched sources.

**Deploy:** `publish_server.ps1` after server changes; remote agents per `publish_remote_agent.ps1` when W/A/B ship.

---

## Out of scope (follow-ups)

| Item | Notes |
|------|--------|
| JetStream KV `c35_device_live` | If MCP hits wrong pod |
| WebRTC path RTT / “direct vs TURN” | Separate from cloud RTT |
| IoT / Alien Beacon | Reuse `AgentTelemetryReport` when those agents share WS |
| `inst` SQL `device_list` telemetry | Use HTTP server list for live fields |
| Home LLM `device.list` builtin tool | Add only if product wants in-chat listing without MCP |

---

## Task checklist (copy for execution)

### P
- [ ] P.1 Proto messages + wire field numbers
- [ ] P.2 Codegen Rust/Dart
- [ ] P.3 `sync.md` + `remote.md` + `mcp-security.md`

### S
- [ ] S.1 `device_telemetry.rs` + tests
- [ ] S.2 NATS subject + fanout decode
- [ ] S.3 Agent report handler + 10s publisher + RTT on Pong

### R
- [ ] R.1 `DeviceListOpts` SQL + cursor
- [ ] R.2 Overlay on list/get + MCP args

### W / A / B
- [ ] W.1 Windows power + WS send
- [ ] A.1 Android battery + WS send
- [ ] B.1 Browser stub

### F
- [ ] F.1 Cache + chat_conn
- [ ] F.2 `UiDeviceRow` + detail copy

### M
- [ ] M.1 inst pagination + HTTP args + docs

### V
- [ ] V.1 Full verify + publish notes
