# Remote Agent Pairing + Workspace Scaffold

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]` checkbox syntax.

**Goal:** End-to-end device pairing — Rust agent shows large `XXXXX-XXXXX` code on startup; Flutter app types code; device appears in Devices list and agent connects to server.

**Architecture:** Unpaired agent calls HTTP `pair/register` → server creates `ai.identity(kind=remote, owner_iid=0, meta.pairing_code)`. App claims via existing `InvokeReq.device_pair`. Agent polls until `session_key` issued, saves local config, opens WS control session. See [`_/docs/remote.md`](../../_/docs/remote.md).

**Tech Stack:** Rust (`remotes/`, `mod_device`, `wire_http`), Flutter (`clients/app` — claim UI **already done**), protobuf, YugabyteDB.

**Reference ports:**
- `D:\cs_bots\agents\desktop_node\src\pair.rs`
- `D:\cs_bots\agents\desktop_node\src\pair_window.rs`
- `D:\cs_bots\_\docs\device_pairing.md`

## Global constraints

- Pair code: 10 chars `[A-Z0-9]`, display `XXXXX-XXXXX` (`spec.md`).
- Agent UI: **Rust only** — Win32 pair window on Windows first.
- TTL: 5 minutes; re-roll only on expiry or Unpair.
- Verify: `cargo build -p server_ai`; `cargo build -p c_remote_windows` (from `remotes/`); `flutter analyze` in `clients/app`.
- Read `spec.md`, `_/docs/remote.md`, `_/docs/structure.md` before coding.

---

## Multitask map

```
Track 0 (Proto lock)     ──► done in device.proto (register/poll messages)

Track A (Server register) ──┬──► Track D (agent pair.rs HTTP client)
Track B (Server poll)     ──┘
Track C (remotes scaffold)──► Track E (pair_window Win32 UI)
Track F (conn_ws stub)    ──► after D (session after paired)

Parallel wave 1 (no deps):
  • Agent A → Track C (remotes workspace Cargo.toml + c_remote_core stub)
  • Agent B → Track A (device_pair_register)
  • Agent C → Track B (device_pair_poll + session_key in claim)

Parallel wave 2 (needs wave 1):
  • Agent D → Track D (c_remote_core/pair.rs)
  • Agent E → Track E (c_remote_windows pair_window + main loop)

Parallel wave 3 (integration):
  • Agent F → Track F (conn_ws minimal + EvDevicePresence)
  • Agent G → Track G (manual E2E + fix claim to issue session_key)

Flutter app: NO WORK for pairing v1 (claim dialog exists). Optional Track H: show online after presence.
```

---

## Track A — `device_pair_register` (server)

**Files:**
- Create: `servers/crates/mod_device/src/device_pair_register.rs`
- Modify: `servers/crates/mod_device/src/lib.rs`
- Modify: `servers/crates/wire_http/src/lib.rs` (or new `device.rs` routes)

**Handler `device_pair_register(pool, req) -> ResDevicePairRegister`:**

1. Generate code: 10 × `[A-Z0-9]` (crypto RNG), format display `XXXXX-XXXXX`.
2. `device_secret = "sec_" + ulid/random 32+`.
3. `expires_at = NOW() + 5 minutes`.
4. `INSERT ai.identity`:
   - `kind = 'remote'`, `type = req.device_type` (default `windows`)
   - `owner_iid = 0` (unowned)
   - `name = req.device_name`
   - `meta = { pairing_code, device_secret, pairing_expires_ms, agent_version }`
5. Return `{ code: display, device_secret, expires_in_sec: 300 }`.

**Collision:** retry generate if `pairing_code` exists and not expired.

- [ ] **Step 1:** Implement register handler + code generator
- [ ] **Step 2:** `POST /v1/device/pair/register` JSON handler
- [ ] **Step 3:** `cargo build -p server_ai`

---

## Track B — `device_pair_poll` + fix claim (server)

**Files:**
- Create: `servers/crates/mod_device/src/device_pair_poll.rs`
- Modify: `servers/crates/mod_device/src/device_pair.rs` (issue `session_key` on claim)
- Modify: `servers/crates/mod_device/src/lib.rs`

**Poll `GET /v1/device/pair/poll?secret=…`:**

```sql
SELECT id, owner_iid, meta, (meta->>'pairing_expires_ms')::bigint AS exp_ms
FROM ai.identity
WHERE meta->>'device_secret' = $1 AND deleted_ts IS NULL
```

| Condition | Response |
|-----------|----------|
| not found | `{ status: "expired" }` |
| `exp_ms < now` and still unowned | `{ status: "expired" }` |
| `owner_iid = 0` | `{ status: "pending" }` |
| `owner_iid > 0` | `{ status: "claimed", session_key, device_iid }` |

**Fix `device_pair` (claim):** after assign owner, set `meta.session_key` (new random), remove `pairing_code` + `device_secret`, set `pairing_claimed_ms`.

- [ ] **Step 1:** Implement poll handler
- [ ] **Step 2:** Update claim to write `session_key`
- [ ] **Step 3:** `cargo build -p server_ai`

---

## Track C — `remotes/` workspace scaffold

**Files:**
- Create: `remotes/Cargo.toml` (workspace)
- Create: `remotes/c_remote_core/Cargo.toml`, `src/lib.rs`, stubs
- Create: `remotes/c_remote_windows/Cargo.toml`, `src/main.rs`, `src/lib.rs`

**Workspace members:** `c_remote_core`, `c_remote_windows`

**`c_remote_core` deps:** `c35_proto` (path `../servers/crates/proto`), `tokio`, `reqwest`, `serde`, `serde_json`, `tracing`

**`c_remote_windows` deps:** `c_remote_core`, `tray-icon`, `tao` (tray later)

- [ ] **Step 1:** Workspace + empty crates compile
- [ ] **Step 2:** `cd remotes && cargo build -p c_remote_windows`

---

## Track D — `c_remote_core/pair.rs`

**Files:**
- Create: `remotes/c_remote_core/src/config.rs`
- Create: `remotes/c_remote_core/src/pair.rs`
- Modify: `remotes/c_remote_core/src/lib.rs`

**Port from cs_bots `pair.rs`:**

| Function | Purpose |
|----------|---------|
| `config_path()` | `%LOCALAPPDATA%\AlienAI\config.json` |
| `session_key_load()` | read paired state |
| `session_key_save(key, device_iid)` | after claimed |
| `session_key_clear()` | unpair |
| `pair_register(base_url, name, type)` | POST register |
| `pair_poll(base_url, secret)` | GET poll → `Pending \| Claimed \| Expired` |

Env: `C35_SERVER_URL` or default from config.

- [ ] **Step 1:** Implement HTTP client functions
- [ ] **Step 2:** Unit test poll JSON parsing (no network)
- [ ] **Step 3:** `cargo build -p c_remote_core`

---

## Track E — `c_remote_windows` pair window + main loop

**Files:**
- Create: `remotes/c_remote_windows/src/pair_window.rs` (port cs_bots Win32)
- Create: `remotes/c_remote_windows/src/pair_loop.rs`
- Modify: `remotes/c_remote_windows/src/main.rs`

**`main.rs` flow:**

```
if session_key_load().is_some() → conn_ws::run() (stub OK for v1)
else → pair_loop::run()
```

**`pair_loop::run()`:**

1. Spawn `PairWindow`
2. Loop: register → `window.set_code()` → poll every 2s until `Claimed` or `Expired`
3. On expired → re-register (new code)
4. On claimed → save config, close window, start conn stub

**Pair window UI:**
- Always-on-top
- Large `XXXXX - XXXXX` (slashed zero, tabular figures)
- Countdown timer
- Hint: `Enter this in Alien AI → Devices → Pair with Code`
- Console fallback if Win32 fails

- [ ] **Step 1:** Port `pair_window.rs` from cs_bots
- [ ] **Step 2:** Wire `pair_loop.rs`
- [ ] **Step 3:** Manual test: run agent → see code → app pairs → agent exits pair mode

---

## Track F — `conn_ws` stub (post-pair)

**Files:**
- Create: `remotes/c_remote_core/src/conn_ws.rs`
- Create: `remotes/c_remote_core/src/presence.rs`

**Minimal v1:**
- Connect `wss://{host}/v1/ws?jwt={session_key}` (or dedicated agent endpoint — document in remote.md if different)
- Send `EvDevicePresence { online: true }` on connect
- Read loop logs frames (no task exec yet)

If agent auth uses `session_key` as device token, add `mod_device::agent_auth` in a follow-up task.

- [ ] **Step 1:** WS connect + presence
- [ ] **Step 2:** Document agent auth wire in `_/docs/remote.md`

---

## Track G — E2E verification

- [ ] Agent shows code on Windows
- [ ] Flutter Devices → Add → enter code → device row appears
- [ ] Agent poll returns claimed; config.json written
- [ ] Agent reconnects without showing pair window
- [ ] Unpair (tray, follow-up) clears config and shows new code

---

## Track H — (optional) Flutter online indicator

**Files:** `clients/app/lib/c/device/device_store.dart` — subscribe presence push when added later.

Out of scope for pairing v1 unless trivial.

---

## Agent assignment cheat sheet

| Agent | Tracks | Est. | Depends |
|-------|--------|------|---------|
| **A** | C | 1h | — |
| **B** | A | 1.5h | — |
| **C** | B | 1.5h | — |
| **D** | D | 1h | C |
| **E** | E | 2h | C, D |
| **F** | F | 1h | B, D |
| **G** | G | 30m | all |

**Critical path:** (B,C parallel) → (A,B) → D → E → G. A can run fully parallel to B,C.

---

## Out of scope (follow-up plans)

- WebRTC human remote viewer (`remote.proto` signaling)
- `mod_task` + JetStream dispatch
- Android agent pair UI
- Tray Unpair/Quit (pair v1 can use console; tray in quick follow-up)
- `ai.device_pairing` separate table (using `identity.meta` for v1)

---

## Self-review

| Requirement | Track |
|-------------|-------|
| Rust-only pair UI | E |
| Large 10-digit code | E |
| App types code | existing — no work |
| Server register | A |
| Server poll | B |
| session_key on claim | B |
| remotes workspace | C |
| remote.md pairing section | done |
