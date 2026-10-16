# Product notifications (all platforms) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Subagent **model: inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Deliver **interrupting** notifications (reminders, `notify.send`, task done, new mail, new guest order, later chat) on **Android, iOS, Windows, and web** through **one server pipeline** (`notify_emit` → `ai.notify` → `notify_deliver`), with CSA-grade client behavior (presence skip, foreground gate, per-category Android channels, Windows session helper + toasts) **without** CSA MQTT.

**Architecture:**

- **Producers** (hooks, `notify.schedule`, **`notify.send`**) call `notify_emit` → `notify_deliver`.
- **Sync** (`SyncPush`, `TaskRunPush`, billing) stays for UI refresh; **alerts** use the notify pipeline.
- **Presence:** `ai.app_conn` per `client_id`. Live socket for that install → NATS `NotifyPush`; skip FCM for that `client_id` (same rule as CSA `account_push_offline`).
- **Mobile / web Flutter:** `ChatConn` WS + `NotifyRouter` (resumed → banner; not resumed → local / web `Notification`).
- **Windows (locked):** User-session helper **`alienai_notify.exe`** (not a SCM Windows Service, **not** `alienai_remote_windows`) **owns the outbound user WS** for desktop presence and `NotifyPush` when background notify is enabled. **`alienai.exe` connects to the helper as an IPC client** (`127.0.0.1:19831`). Helper stays running; app attaches/detaches. Flutter may keep a **second** WS for Home RPC in v1, but **must not** register duplicate `app_conn` for the same desktop install when helper is healthy (see Wave 4).
- **`notify.send`:** Chat tool; **default recipient = caller**. Optional `target_iid` only if staff access allows.

**CSA reference:** `D:\csa_site_published\crates\mod_account\src\client.rs`, `GatewayNotif.kt`, `notif_open.dart`, `agent_desktop` (`ipc.rs`, `notify/windows.rs`) — **WS instead of MQTT** on the helper.

**Tech stack:** `c35_mod_notify`, `c35_fcm`, `wire_ws`, NATS app lane, Flutter, `clients/notify_desktop` (Rust), `wire.proto`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`notify.md`](../notify.md) · [`sync.md`](../sync.md) · [`2026-10-08-user-notify-multitask.md`](2026-10-08-user-notify-multitask.md) (reminders done).

---

## Wire: NATS subjects, WS, and what clients listen for

### App realtime lane (owner = recipient `owner_iid`)

| Layer | Subject / endpoint | Payload | Who publishes | Who consumes |
|-------|-------------------|---------|---------------|--------------|
| **NATS (deliver)** | `c35.user.{owner_iid}.app.notify` | Encoded `WsRes` with `body = NotifyPush` (proto field **214**) | `notify_deliver` after claim | `server_ai` WS fanout to every open app WS for that user |
| **WS subscribe (server)** | _(internal)_ `c35.user.{owner_iid}.app.>` | Many tails (`balance`, `inbox`, `notify`, …) | Various modules | One NATS subscription per user WS in `wire_ws::user_app_nats_fanout` |
| **WS connect (client)** | `GET /v1/ws?jwt=…&since=…&locale=…&tz=…` | Bidirectional `WsReq` / `WsRes` | Client | Flutter `ChatConn`, **`alienai_notify`** (Windows helper) |
| **WS optional narrow** | `GET /v1/ws?jwt=…&lane=notify` (Wave 4 W6) | Only `app.notify` fanout | Helper only | Reduces traffic on 24/7 helper |

Helper: `c35_nats::user_app_subject_notify(iid)` → `c35.user.{iid}.app.notify`. Decode: `user_app_fanout_decode` when tail == `notify` → `WsRes` with `NotifyPush`. Code: `servers/crates/system/nats/src/user_app.rs`, `servers/crates/wire_ws/src/session.rs`.

**Clients do not subscribe to NATS directly.** They only **listen on the WebSocket** for unsolicited `WsRes` where:

```text
WsRes.body == NotifyPush { id, title, body, route_json, category? }
```

Flutter: `chat_conn.dart` → `onNotifyPush`. Windows helper: same decode path; optional forward to Flutter via IPC `notify_push`.

### Schedule (server only — clients do not listen)

| NATS | Role |
|------|------|
| `c35.schedule.notify.{notify_id}` | JetStream `@at` schedule (headers like task schedules) |
| `c35.notify.fire.{notify_id}` | Fire target; handler calls `notify_deliver` |
| Stream `C35_NOTIFY_SCHEDULE` | See [`nats.md`](../nats.md), [`notify.md`](../notify.md) |

### Related app-lane subjects (sync, not `NotifyPush`)

| NATS tail | Use | Alert in this plan? |
|-----------|-----|---------------------|
| `…app.site_order` | `SyncPush.tx` — POS refresh | Keep sync; **also** `notify_emit` for staff alert |
| `…app.inbox` | Chat sidebar sync (future) | Deferred Wave 6 |
| `…app.task_run` | Task progress | Keep push; **also** `notify_emit` on terminal status |

### Domain events (not the notification payload)

| Subject | Use |
|---------|-----|
| `c35.user.{owner_iid}.ev.notified` | Audit after deliver (`user.notified` in `ai.log`) — **not** what the app shades on |

**Hard rule:** Notification bodies on **`c35.user.{iid}.app.notify` only**, not `ev.*`.

### Presence and FCM (deliver inputs)

| Store | Updated by |
|-------|------------|
| `ai.app_conn` | `ReqAppPresence` on WS (`client_id`, `resumed`), heartbeat 20s; row deleted on WS close |
| `ai.fcm_token` | `ReqNotifyTokenPut` (android/ios only) |

---

## Global constraints

- No provider web grounding; no Chromium STT.
- `alienai_notify.exe` = **user session**; `alienai_remote_windows.exe` = **device agent** — different binaries, mutex, IPC ports; safe to install both.
- Helper is a **user-logon process** (tray or background), not SYSTEM Windows Service (toasts + JWT need user session).
- FCM data-only; missing credentials → inbox row still written.
- Product emits = server hooks + tools; phrase steering for reminders stays `inst.task.notify`; add `inst.staff.notify` for cross-user send ([`prompt-run-test.mdc`](../../.cursor/rules/prompt-run-test.mdc)).
- UTF-8; [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc). Do not commit unless user asks.

---

## Gap analysis

| Area | Today | Target |
|------|-------|--------|
| `notify.schedule` / list / cancel | Done | Unchanged |
| **`notify.send`** | Missing | Immediate send; default self; staff → other user |
| Mail / order / task | Sync or dead hooks | `notify_emit` |
| Windows | No offline alert | Helper owns WS + toasts; app = IPC client |
| FCM | Disabled in client | Enable when `google-services.json` present |

---

## Locked contracts (Wave 0 before code)

### Categories (`route_json.category` + optional `NotifyPush.category`)

| category | Android channel id |
|----------|-------------------|
| `reminder` | `user_notify` |
| `task` | `alien_system` |
| `mail` | `alien_system` |
| `site_order` | `alien_site_order` (or `alien_system` v1) |
| `chat` | deferred (`alien_chat` …) |
| `system` | `alien_system` |

### `notify_emit` (internal)

Insert `ai.notify` → `notify_deliver`. Optional `dedupe_key` (90s memory or DB partial unique per owner).

### `notify.send` (tool)

| Arg | Rule |
|-----|------|
| `title`, `body` | Required |
| `category` | Optional, default `system` |
| `route` | Optional object → `route_json` |
| `target_iid` | **Omit or = caller** → deliver to caller. **Else** → require **`notify_send_to_user(caller, target)`** (staff: `partner` \| `director` \| `root` via existing `staff_tool_eligible`, or dedicated grant — pick one in D0 and document in `notify.md`) |
| `delay_sec` | **Not** on `notify.send` (use `notify.schedule`) |

Audit: `user.notified` meta includes `category`, optional `sent_by_iid` when `target_iid != caller`.

**Default:** everyone with the tool can notify **self**. Cross-user is **staff-only** (not arbitrary `owner_iid`).

### Windows helper (`alienai_notify.exe`)

| Item | Value |
|------|--------|
| Process | Long-lived after login / “Background notifications” on |
| **Server connection** | Outbound **WS** (helper is NATS/client-of-server) |
| **Desktop app** | **IPC client** to helper — not the other way around |
| `client_id` | `win-notify-{stable_machine_id}` |
| IPC listen | `127.0.0.1:19831` (CSA-compatible event names where cheap) |
| Presence | Helper sends `ReqAppPresence` every 20s; `resumed` from IPC `set_focus` from Flutter |
| Toast | Helper shows WinRT when `NotifyPush` and Flutter reports **not** `(visible && resumed)` |
| Flutter v1 | `ChatConn` may still open full WS for RPC; **skip** `ReqAppPresence` on Flutter when IPC reports `helper_ok` (single desktop `app_conn` row) |

### Sync vs alert

| Event | Sync | Alert |
|-------|------|-------|
| Guest order | `app.site_order` → `SyncPush.tx` | `notify_emit` per staff uid |
| Mail | JSON hook | `notify_emit` |
| Task | `TaskRunPush` | `notify_emit` on terminal status |

---

## Out of scope

MQTT FG service; iOS PushKit; full `GatewayNotif` port (Wave 6); Web Push SW (Wave 5B); email/SMS lanes; proxying **all** Home RPC through helper (v2).

---

## Wave 0 — Spec (sequential)

- [ ] **D0.1** [`notify.md`](../notify.md): categories, `notify_emit`, `notify.send` + access, wire table (above), Windows helper model, tiers.
- [ ] **D0.2** [`sync.md`](../sync.md): `app.notify` row; sync vs alert; optional `lane=notify`.
- [ ] **D0.3** [`ui.md`](../ui.md): tap routes from `route_json`.
- [ ] **D0.4** [`log.md`](../log.md): `user.notified` meta `sent_by_iid`, `category`.
- [ ] **D0.5** `inst.sql` + live `inst_put`: extend `inst.task.notify` if needed; add **`inst.staff.notify`** for “send notification to user X” → `notify.send` with `target_iid` (staff inst only includes tool for privileged roles).

---

## Wave 1 — Server (parallel)

### S1 — `notify_emit` + proto `NotifyPush.category`

- `servers/crates/mod_notify/src/emit.rs`, deliver FCM map, `wire.proto` field 5, tests.

### S2 — Mail hook → `notify_emit`

### S3 — Guest order → `notify_emit` per staff (+ keep `SyncPush`)

### S4 — Task terminal → `notify_emit`

### S5 — Tool `notify.send`

- `servers/crates/mod_notify/src/send.rs` — `notify_send_to_user(pool, caller, target) -> Result<()>`
- `servers/crates/mod_chat/src/tools/builtin/notify.rs` — `NotifySendTool`: default `owner_iid = ctx.owner_iid`; if `target_iid` set and != caller, call gate; then `notify_emit` immediate.
- Tool def: `topics: ["general"]`, `rag_phrases` for “send notification”, “notify user”; **no** `requires_global_roles` on struct — runtime gate inside exec (or split `notify.send` public vs `admin.notify.send` — prefer **one tool**, server enforces).
- Register tool in catalog; seed `inst.staff.notify` with `include_tools: [notify.send]` for staff workflows only if cross-user phrases needed; self-send works from existing `inst.task.notify` via `include_tools: [notify.send]` or shared inst body update (D0.5).
- Tests: caller 33000 → self OK; caller 33000 → 99000 forbidden; staff 99000 → 33000 OK when role allows.

**Verify:** `cargo test -p c35_mod_notify`, `cargo build -p server_ai`.

---

## Wave 2 — Mobile FCM + channels (parallel)

- M1: Enable FCM credentials path.
- M2: `local_notif.dart` multi-channel from `category`.
- M3: Site `order_ring` on `site_order` notify.

---

## Wave 3 — Flutter routing (parallel)

- F1: `notif_open.dart`, routes for mail / site / task / `path`.
- F2: Client dedup with POS `SyncPush`.
- F3: Task UI + `NotifyPush` category `task`.

---

## Wave 4 — Windows `alienai_notify` (sequential core)

### W0 — Crate `clients/notify_desktop/`, binary `alienai_notify.exe`

### W1 — Session bundle (DPAPI); helper loads JWT; refresh on 401

### W2 — **Helper hosts WS** to `/v1/ws`; decode `NotifyPush` only (or full fanout v1); presence heartbeats

### W3 — WinRT toast + AUMID (port CSA `notify/windows.rs`)

### W4 — **IPC server** (helper listens): `set_focus`, `hello` from Flutter; `notify_push`, `notify_tapped` to Flutter; Flutter **connects as client** on app start

### W5 — Flutter Windows: spawn helper on login; `NotifyDesktopClient`; when helper OK, **do not** double-register `app_conn` from `ChatConn`; on `notify_push` IPC, run `NotifyRouter` in Dart

### W6 (optional) — `lane=notify` on WS for helper only

### W7 — Ship `alienai_notify.exe` in Windows app ZIP; mutex `Local\AlienAI-Notify-Singleton` (distinct from remote agent)

**Verify:** Helper running, Flutter closed → toast on `notify_emit`; Flutter foreground → IPC suppresses toast, in-app banner only.

---

## Wave 5 — Web

- P1: `Notification` API when tab hidden.
- P2 (deferred): Web Push + `ai.web_push`.

---

## Wave 6 — Chat native (deferred)

`GatewayNotif` when `app.inbox` push exists.

---

## Verification matrix

| Check | Action |
|-------|--------|
| `notify.send` self | MCP `tool_exec` / `prompt_run` 33000 |
| `notify.send` other | Staff 99000 → allowed target; non-staff → error |
| NATS subject | Unit: `user_app_subject_notify(99000)` |
| Reminder regression | `prompt_run`: “notify me in 5 seconds” |
| Windows | Helper WS up; app IPC; toast + tap |
| Flutter | `verify_flutter_app.ps1` |

---

## Dispatch map

| Wave | Tracks | Depends |
|------|--------|---------|
| 0 | D0 | — |
| 1 | S1–S5 | 0 |
| 2 | M1–M3 | 1 |
| 3 | F1–F3 | 1–2 |
| 4 | W0–W7 | 1 |
| 5 | P1 | 1 |

**First batch:** Wave 0 + 1 (include **S5 `notify.send`**) + Wave 4 W0–W4 (helper WS + IPC) + Wave 3 F1.

---

## Publish summary

Fill from `.cache/publish-perf/latest.json` after server / Windows ZIP publish.
