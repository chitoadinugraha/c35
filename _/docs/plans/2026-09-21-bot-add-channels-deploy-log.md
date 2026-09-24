# Bot Add + Channel Pairing + Deploy + Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the full Bots page add flow (empty-state UX, 2-step wizard, Telegram + WhatsApp Meta + WhatsApp QR pair), deploy `channel-whatsapp-device` on btm (arm64), and ensure every channel lifecycle event is persisted to `ai.log` and published on NATS `log.{owner_iid}.{dv}.{topic}` per `_/docs/log.md`.

**Architecture:** One `identity(kind=bot, type=chat)` per chat bot; channels live in `meta.channels[]`. Step 1 uses new `identity_put`; step 2 calls existing `channel_*_connect` invoke RPCs plus new `channel_whatsapp_pair_*` WS RPCs. Server orchestrates QR pair (NATS `c35.act.channel.whatsapp.device.pair` → worker); worker + server write via shared `mod_log::log_put` which INSERTs then NATS-publishes `LogPush`. Flutter ports pairing UI from `D:\cs_agent\clients\app\lib\widgets\io\io_bot_add.dart`.

**Tech Stack:** Flutter (`clients/app`), Rust (`servers/crates/*`, `servers/channel_whatsapp_device`), protobuf (`_/schemas/proto/c35/`), YugabyteDB, NATS, k3s-btm (arm64, OCIR `hsg.ocir.io`).

## Global Constraints

- Read `spec.md` + `_/docs/ui.md` + `_/docs/identity.md` + `_/docs/log.md` + `_/docs/sync.md` before coding.
- Naming: `ui_` widgets, `page_` pages, `l()` / `lError()` on client; `ca.L()` / `tracing` on server.
- Bot model: `kind=bot`, `type=chat`; platforms in `meta.channels[]` only — never `type=telegram`.
- Pair code (devices): 10 chars `[A-Z0-9]`, display `XXXXX-XXXXX`.
- Log: single `ai.log` table; NATS subject `log.{owner_iid}.{dv}.{topic}`; never log secrets.
- Cluster: btm.alienai.id, **linux/arm64**, in-cluster DNS `.svc.cluster.local`.
- Verify: `cargo build -p server_ai` + `cargo build -p channel_whatsapp_device` for Rust; `flutter analyze` in `clients/app`.
- Do not commit unless user asks.

---

## Multitask Map

```
Track 0 (Proto) ─────────────┬──► Track 2A (mod_log)
                             ├──► Track 2B (identity_put)
                             ├──► Track 2C (channel pair server)
                             └──► Track 2D (channel connect logs)

Track 3 (WA worker logs) ──► depends Track 2A

Track 4 (Deploy + cluster) ──► depends Track 2C + Track 3 (can start manifest review in parallel)

Track 1 (Flutter UI) ────────► parallel with Track 0 (mock dialogs OK until proto lands)

Track 5 (Flutter wire) ──────► after Track 0 + Track 2

Track 6 (Verify E2E) ────────► after Track 4 + Track 5

Parallel start (day 1):
  • Agent A → Track 0
  • Agent B → Track 1 (UI shell, no server)
  • Agent C → Track 2A (mod_log) once proto regen slot known
After Track 0:
  • Agent D → Track 2B + 2C (server handlers)
  • Agent E → Track 3 (worker log fixes)
  • Agent F → Track 4 (build + deploy + smoke)
After Track 2 + 5:
  • Agent G → Track 6 (E2E pair on cluster)
```

---

## Track 0 — Proto contracts (blocks server + client wire)

### Task 0.1: `identity_put` in `identity.proto`

**Files:**
- Modify: `_/schemas/proto/c35/identity.proto`
- Modify: `_/schemas/proto/c35/wire.proto`

**Interfaces — produces:**

```protobuf
message ReqIdentityPut {
  int64 iid = 1;              // 0 = create
  string kind = 2;            // bot
  string type = 3;            // chat
  string name = 4;
  string pic = 5;
  string alien_id = 6;        // optional
  string meta_json = 7;       // { "inst_base": "...", "channels": [] }
}

message ResIdentityPut {
  IdentityListRow row = 1;
}
```

Wire: `identity_put = 31` on `WsReq` / `WsRes` (pick next free slot after `log_list = 87` → use **88** if free, else renumber in plan execution).

- [ ] **Step 1:** Add messages to `identity.proto`
- [ ] **Step 2:** Add `ReqIdentityPut` / `ResIdentityPut` to `WsReq` / `WsRes` oneof in `wire.proto`
- [ ] **Step 3:** Regen protobuf (Task 0.4)

---

### Task 0.2: WhatsApp QR pair + pair push in `channel.proto`

**Files:**
- Modify: `_/schemas/proto/c35/channel.proto`
- Modify: `_/schemas/proto/c35/wire.proto`

**Interfaces — produces:**

```protobuf
message ReqChannelWhatsappPairStart {
  int64 bot_iid = 1;
  string channel_id = 2;   // empty = server assigns new ULID
}

message ReqChannelWhatsappPairWatch {
  int64 bot_iid = 1;
  string channel_id = 2;
}

message ReqChannelWhatsappPairAbort {
  int64 bot_iid = 1;
  string channel_id = 2;
}

message ResChannelWhatsappPair {
  bool ok = 1;
  string error = 2;
  int64 bot_iid = 3;
  BotChannelDoc channel = 4;
  string qr_raw = 5;
  string phone = 6;
}

// Unsolicited WS push while pair dialog open (from NATS ev → WS fanout)
message ChannelPairPush {
  int64 bot_iid = 1;
  string channel_id = 2;
  string status = 3;         // pairing | connected | error | disconnected
  string qr_raw = 4;
  string phone = 5;
  string error_message = 6;
}
```

Wire slots (InvokeReq unused — pair is WS for live push):
- `WsReq`: `channel_whatsapp_pair_start = 32`, `channel_whatsapp_pair_watch = 33`, `channel_whatsapp_pair_abort = 34`
- `WsRes`: matching `ResChannelWhatsappPair` + unsolicited `channel_pair_push = 71`

Reference: `D:\cs_agent\_\protos\agent\v1\wire.proto` (`ReqWhatsappPairStart` et al.) and c35 NATS subjects in `servers/channel_whatsapp_device/src/nats.rs`.

- [ ] **Step 1:** Add messages to `channel.proto`
- [ ] **Step 2:** Wire into `WsReq` / `WsRes`
- [ ] **Step 3:** Regen protobuf

---

### Task 0.3: Extend `BotChannelDoc` for linked device

**Files:**
- Modify: `_/schemas/proto/c35/channel.proto`

Add optional fields used by worker (stored in JSON meta, surfaced on wire):

```protobuf
message BotChannelDoc {
  // existing fields …
  string provider = 3;       // meta_api | linked_device
  string error_message = 7;
}
```

- [ ] **Step 1:** Add fields without breaking existing generated code consumers
- [ ] **Step 2:** Regen protobuf

---

### Task 0.4: Regenerate protobuf

**Files:**
- Regen: `servers/crates/proto/`
- Regen: `clients/app/lib/c/pb/c35/`

- [ ] **Step 1:** Run repo protoc / build.rs flow (`cargo build -p c35_proto` triggers build.rs)
- [ ] **Step 2:** `cargo build -p server_ai`
- [ ] **Step 3:** `cd clients/app && flutter analyze`

---

## Track 1 — Flutter UI (parallel with Track 0)

### Task 1.1: `UiMasterDetail` empty collapse

**Files:**
- Modify: `clients/app/lib/widgets/ui/ui_master_detail.dart`
- Modify: `clients/app/lib/pages/page_bots.dart`
- Modify: `clients/app/lib/pages/page_devices.dart` (align devices empty behavior)

**Behavior:**
- New param: `collapseWhenEmpty` + `isEmpty` callback or `listEmpty` bool.
- When `wide && listEmpty`: render **nav only** (bots) or **master only** (devices) at full width — no empty master/detail columns.
- Empty copy: `'No bots yet\nTap + to add'` / `'No devices yet\nTap + to add'`.

- [ ] **Step 1:** Add collapse logic to `UiMasterDetail`
- [ ] **Step 2:** Wire `PageBots` — `listEmpty: store.bots.isEmpty && !store.loadingBots`
- [ ] **Step 3:** `flutter analyze`

---

### Task 1.2: Bots `+` menu

**Files:**
- Create: `clients/app/lib/widgets/bots/ui_bot_add_menu.dart`
- Modify: `clients/app/lib/pages/page_bots.dart`

**UI:**
- `PopupMenuButton` with single item: **New Chat Bot** → opens wizard (Task 1.3).
- Mirror: `clients/app/lib/widgets/devices/ui_device_add_menu.dart`.

- [ ] **Step 1:** Implement menu widget
- [ ] **Step 2:** Add as `UiPage.trailing` on bots page
- [ ] **Step 3:** `flutter analyze`

---

### Task 1.3: 2-step bot wizard dialog

**Files:**
- Create: `clients/app/lib/widgets/bots/in_bot_create.dart`
- Create: `clients/app/lib/widgets/bots/io_channel_pick_grid.dart`
- Port from: `D:\cs_agent\clients\app\lib\widgets\io\io_bot_add.dart`, `io_space_configure.dart`

**Step 1 — Info:**
- Avatar picker (reuse settings avatar pattern if exists, else initials)
- Name (required)
- Instructions (`inst_base` multiline)

**Step 2 — Channels (side by side):**

```
┌──────────────── WhatsApp ────────────────┐  ┌──────────── Telegram ────────────┐
│  [Meta API icon]    [QR Pair icon]       │  │  [Telegram icon]                 │
│  Meta Cloud API     Scan QR              │  │  Bot API token                   │
│  (+ Add another channel)                 │  │                                  │
└──────────────────────────────────────────┘  └──────────────────────────────────┘
```

- Chips for already-added channels (platform + status).
- **Skip for now** / **Finish** when ≥1 channel connected or user skips (bot exists with zero channels).

- [ ] **Step 1:** Stepper dialog shell (`Step 1/2`, Back/Next/Done)
- [ ] **Step 2:** Step 1 form fields
- [ ] **Step 3:** Step 2 grid layout + channel list
- [ ] **Step 4:** `flutter analyze`

---

### Task 1.4: Channel pairing sub-dialogs (port from cs_agent)

**Files:**
- Create: `clients/app/lib/widgets/bots/io_channel_telegram_connect.dart`
- Create: `clients/app/lib/widgets/bots/io_channel_whatsapp_meta_connect.dart`
- Create: `clients/app/lib/widgets/bots/io_channel_whatsapp_pair.dart`
- Reference: `D:\cs_agent\clients\app\lib\widgets\io\io_bot_add.dart` (lines 69–674)

**Dependencies:** `qr_flutter` (check `clients/app/pubspec.yaml`; add if missing).

Each dialog:
- Progress log panel (step/total) like cs_agent
- Friendly errors only in UI; technical detail via server log
- Returns `BotChannelDoc` on success

- [ ] **Step 1:** Telegram connect dialog
- [ ] **Step 2:** WhatsApp Meta dialog (webhook URL + verify token copy)
- [ ] **Step 3:** WhatsApp QR dialog (QrImageView, cancel → abort pair)
- [ ] **Step 4:** `flutter analyze`

---

## Track 2A — Shared `mod_log` (INSERT + NATS publish)

### Task 2A.1: Create `mod_log` crate

**Files:**
- Create: `servers/crates/mod_log/Cargo.toml`
- Create: `servers/crates/mod_log/src/lib.rs`
- Modify: `servers/Cargo.toml` workspace members
- Modify: `servers/crates/server_ai/Cargo.toml` (or binary crate) — add dep

**Interfaces — produces:**

```rust
pub struct LogPut<'a> {
    pub owner_iid: i64,
    pub kind: &'a str,       // conn | error | system | llm | tool | task
    pub topic: &'a str,      // connected | disconnected | error | msg_received | pair_start | qr | …
    pub dv: &'a str,         // client device id; worker uses "channel-wa-device"
    pub req_id: Option<&'a str>,
    pub chat_id: Option<i64>,
    pub device_iid: Option<i64>,
    pub text: &'a str,
    pub meta: serde_json::Value,
}

pub async fn log_put(pool: &PgPool, nats: Option<&async_nats::Client>, row: LogPut<'_>) -> Result<i64>;
```

**Implementation rules (from `_/docs/log.md`):**
1. `INSERT INTO ai.log` with snowflake id
2. Build `c35_proto::Log` row
3. Publish NATS subject: `log.{owner_iid}.{dv}.{topic}` with protobuf `LogPush { row }`
4. If NATS unavailable: warn + continue (row still in DB)
5. Never store tokens, session blobs, or API keys in `text` / `meta`

- [ ] **Step 1:** Scaffold crate + `log_put`
- [ ] **Step 2:** Unit test: mock pool optional; at minimum compile test
- [ ] **Step 3:** `cargo build -p server_ai`

---

### Task 2A.2: Refactor existing server log writers to use `mod_log`

**Files:**
- Modify: `servers/crates/mod_chat/src/turn_tracer.rs` — call `mod_log::log_put` instead of raw INSERT (keep billing fields)
- Modify: `servers/crates/mod_billing/src/billing_turn.rs` — same where applicable

- [ ] **Step 1:** Wire `TurnTracer` through `mod_log`
- [ ] **Step 2:** `cargo build -p server_ai`
- [ ] **Step 3:** Confirm LLM rows still insert with `cost_usd`

---

## Track 2B — `identity_put` server handler

### Task 2B.1: Implement `identity_put`

**Files:**
- Create: `servers/crates/mod_identity/src/identity_put.rs`
- Modify: `servers/crates/mod_identity/src/lib.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`

**Logic:**
- `iid = 0`: INSERT `ai.identity` with `kind`, `type`, `owner_iid = caller`, merge `meta_json`
- `iid > 0`: UPDATE name/pic/meta if caller owns or has admin grant
- Validate: `kind=bot` → `type` must be `chat`
- Return `IdentityListRow` (same shape as `identity_list`)
- Log: `log_put` topic `bot_create` or `bot_update`, kind `system`

**Meta schema for wizard step 1:**

```json
{
  "inst_base": "You are a helpful assistant for …",
  "channels": []
}
```

- [ ] **Step 1:** Implement handler + ownership check
- [ ] **Step 2:** Wire `WsReq.identity_put` in `session.rs`
- [ ] **Step 3:** `cargo build -p server_ai`

---

### Task 2B.2: Bot instructions in channel turns

**Files:**
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs`

**Logic:**
- Load bot `meta_json` → read `inst_base` string
- Prepend to system prompt block (before global inst macros)

- [ ] **Step 1:** Fetch bot meta by `bot_iid`
- [ ] **Step 2:** Inject `inst_base` into system prompt
- [ ] **Step 3:** `cargo build -p server_ai`

---

## Track 2C — Channel pair server (`mod_channel`)

### Task 2C.1: WhatsApp linked channel prepare/abort/watch

**Files:**
- Create: `servers/crates/mod_channel/src/whatsapp/pair.rs`
- Modify: `servers/crates/mod_channel/src/whatsapp/mod.rs`
- Modify: `servers/crates/mod_channel/src/store.rs`
- Reference: `D:\cs_agent\server\src\channel\whatsapp\pair.rs`, `D:\c35\servers\channel_whatsapp_device\README.md`

**Functions — produces:**

```rust
pub async fn channel_whatsapp_pair_start(pool, owner_iid, bot_iid, channel_id, nats, worker_url) -> Result<ResChannelWhatsappPair, String>;
pub async fn channel_whatsapp_pair_watch(pool, owner_iid, bot_iid, channel_id) -> Result<ResChannelWhatsappPair, String>;
pub async fn channel_whatsapp_pair_abort(pool, owner_iid, bot_iid, channel_id, worker_url) -> Result<(), String>;
```

**pair_start flow:**
1. Verify bot owned by caller
2. Upsert channel in `meta.channels[]`: `platform=whatsapp`, `provider=linked_device`, `status=pairing`
3. Set `session.pair_watch_until_ms = now + 5min` in channel JSON (see identity.md example)
4. Deactivate sibling linked WhatsApp channels same owner (`README.md` one-channel-per-account)
5. `log_put` topic `pair_start`
6. NATS publish `c35.act.channel.whatsapp.device.pair` (`ActChannelWhatsappPair`)
7. HTTP POST `{WHATSAPP_WORKER_URL}/v1/channel/{channel_id}/restart` with bot_iid query/body
8. Return current QR/status from meta

**pair_watch:** extend `pair_watch_until_ms` by +2min (app heartbeat every ~3s)

**pair_abort:** clear session fields, status `disconnected`, worker `/stop`, log `pair_abort`

- [ ] **Step 1:** Implement store helpers (`channel_patch_session`, `pair_watch_touch`, `deactivate_siblings`)
- [ ] **Step 2:** Implement pair.rs handlers
- [ ] **Step 3:** `cargo build -p server_ai`

---

### Task 2C.2: NATS pair event → WS `ChannelPairPush` fanout

**Files:**
- Create: `servers/crates/mod_channel/src/pair_fanout.rs`
- Modify: `servers/crates/wire_ws/src/session.rs`

**Logic:**
- On WS connect, subscribe NATS `c35.ev.channel.{owner_iid}.>` (or per-bot subject)
- On `EvChannelPairUpdate` JSON → map to `ChannelPairPush` → send `WsRes { channel_pair_push }` to client
- Also update bot meta when worker publishes connected + phone

Reference worker publish: `servers/channel_whatsapp_device/src/manager.rs` `publish_pair_update`.

- [ ] **Step 1:** NATS subscriber task per WS session (same pattern as billing fanout in `session.rs`)
- [ ] **Step 2:** Wire WS handlers for pair start/watch/abort
- [ ] **Step 3:** `cargo build -p server_ai`

---

### Task 2C.3: Connect RPC logging (Telegram + Meta WhatsApp)

**Files:**
- Modify: `servers/crates/mod_channel/src/telegram/connect.rs`
- Modify: `servers/crates/mod_channel/src/whatsapp/connect.rs`

Add `log_put` calls:
- topic `connected` on success (meta: platform, channel_id, bot_iid)
- topic `error` on failure (no secrets)

- [ ] **Step 1:** Telegram connect logs
- [ ] **Step 2:** WhatsApp Meta connect logs
- [ ] **Step 3:** `cargo build -p server_ai`

---

## Track 3 — WhatsApp worker log completeness + NATS publish

### Task 3.1: Fix `channel_log` to use spec topics + NATS

**Files:**
- Modify: `servers/channel_whatsapp_device/src/db.rs`
- Modify: `servers/channel_whatsapp_device/Cargo.toml` — depend on `c35_mod_log` OR duplicate minimal publish (prefer shared crate)
- Modify: `servers/channel_whatsapp_device/src/manager.rs`

**Changes:**
1. Replace hardcoded `topic = 'channel'` with `topic = kind` where kind ∈:
   - `pair_start`, `qr`, `connected`, `disconnected`, `error`, `pair_expired`, `pair_abort`, `msg_received`, `msg_sent`, `worker_stop`
2. Map event kind → log `kind`: `error` → `error`, else `system`
3. After INSERT, publish `log.{owner_iid}.channel-wa-device.{topic}` via `LogPush`
4. Add **`msg_received`** log on `Event::Message` (truncate text to 120 chars in log; full text only in NATS msg.in)

**Example log row (msg_received):**

```text
text: "Inbound from +628…: Hello…"
meta: { "channel": { "bot_iid", "channel_id", "event": "msg_received", "msg_id", "peer_id" } }
```

- [ ] **Step 1:** Refactor `channel_log` → call `mod_log::log_put` with `dv = "channel-wa-device"`
- [ ] **Step 2:** Add missing `msg_received` + `msg_sent` (outbound path in `outbound.rs`)
- [ ] **Step 3:** `cargo build -p channel_whatsapp_device`

---

### Task 3.2: Worker inbound → server pipeline log (server side)

**Files:**
- Modify: `servers/crates/mod_channel/src/inbound.rs`

When `channel_inbound_handle` processes NATS `EvChannelMsgIn`:
- `log_put` topic `msg_received`, kind `system`, chat_id after peer chat ensured

- [ ] **Step 1:** Add log on inbound turn start
- [ ] **Step 2:** `cargo build -p server_ai`

---

## Track 4 — Deploy channel worker + server config on cluster

### Task 4.1: Server env — `WHATSAPP_WORKER_URL`

**Files:**
- Modify: `_/deployments/c35-server/deployment.yaml`
- Modify: cluster secret `c35-server-env` (document in plan, apply via existing bootstrap script)

**Value:**

```yaml
- name: WHATSAPP_WORKER_URL
  value: "http://channel-whatsapp-device.c35.svc.cluster.local:8080"
```

Also ensure `NATS_URL`, `NATS_USER`, `NATS_PASS`, `NATS_CA` match worker (already on server deployment via secret).

- [ ] **Step 1:** Add env var to deployment manifest
- [ ] **Step 2:** Document secret keys in `_/docs/server.md` (short section)

---

### Task 4.2: Build + push arm64 images

**Commands:**

```powershell
# WhatsApp worker
.\_\scripts\deploy\publish_channel_whatsapp_device.ps1

# Server (after Track 2 merged)
.\_\scripts\deploy\publish_server.ps1
```

**Verify locally before push:**
```powershell
cargo build -p channel_whatsapp_device --release
cargo build -p server_ai --release
```

- [ ] **Step 1:** Run `publish_channel_whatsapp_device.ps1` (buildkit arm64 → OCIR)
- [ ] **Step 2:** Confirm rollout: `kubectl rollout status deploy/channel-whatsapp-device -n c35`
- [ ] **Step 3:** In-pod smoke: `curl -fsS http://127.0.0.1:8080/healthz`
- [ ] **Step 4:** Publish server after handler changes land

---

### Task 4.3: Cluster smoke — worker NATS + DB

**Files:** none (ops)

```powershell
# Pod logs
kubectl logs -n c35 deploy/channel-whatsapp-device --tail=80

# Expect: Yugabyte connected, NATS connected (not "NATS unavailable")
```

**DB check (MCP user-yb):**

```sql
SELECT id, kind, topic, text, created_ts
FROM ai.log
WHERE topic IN ('pair_start','qr','connected','disconnected','error','msg_received')
ORDER BY created_ts DESC
LIMIT 20;
```

- [ ] **Step 1:** Worker pod healthy on arm64 node
- [ ] **Step 2:** NATS connected (no warn on startup)
- [ ] **Step 3:** Document expected log lines in `_/docs/server.md` channel section

---

## Track 5 — Flutter API wiring

### Task 5.1: Client APIs

**Files:**
- Create: `clients/app/lib/c/bot/bot_api.dart`
- Create: `clients/app/lib/c/channel/channel_api.dart`
- Modify: `clients/app/lib/c/chat/chat_conn.dart`
- Modify: `clients/app/lib/c/bot/bot_store.dart`

**bot_api.dart:**

```dart
Future<ResIdentityPut> identityPut(ReqIdentityPut req);
Future<ResBotPeerList> botPeerList(int botIid);
Future<ResChatStop> chatStop(int chatId, bool stopped);
Future<ResChatSend> chatSend(int chatId, String text);
```

**channel_api.dart:**

```dart
Future<ResChannelTelegramConnect> telegramConnect(ReqChannelTelegramConnect req);  // invoke
Future<ResChannelWhatsappMetaConnect> whatsappMetaConnect(ReqChannelWhatsappMetaConnect req);  // invoke
Future<ResChannelWhatsappPair> whatsappPairStart(int botIid, {String channelId = ''});
Future<ResChannelWhatsappPair> whatsappPairWatch(int botIid, String channelId);
Future<void> whatsappPairAbort(int botIid, String channelId);
Stream<ChannelPairPush> onChannelPairPush;  // from ChatConn WS unsolicited
```

**Wizard orchestration in `in_bot_create.dart`:**
1. `identityPut` → get `bot_iid`
2. On channel tile tap → open sub-dialog with `bot_iid` preset
3. On success → append to local channel list; refresh bots nav
4. Finish → close wizard, select new bot

- [ ] **Step 1:** Extend `ChatConn` (invoke + new WS RPCs + pair push listener)
- [ ] **Step 2:** Implement APIs
- [ ] **Step 3:** Wire wizard to APIs
- [ ] **Step 4:** `flutter analyze`

---

## Track 6 — End-to-end verification

### Task 6.1: Manual pair test checklist

**Preconditions:** Server + worker deployed; user signed in on app.

- [ ] **Step 1:** Bots page empty → single pane message + `+`
- [ ] **Step 2:** New Chat Bot → step 1 name/instructions → creates bot in nav
- [ ] **Step 3:** Step 2 → WhatsApp QR → QR renders within 10s
- [ ] **Step 4:** Scan QR → status `connected`, phone shown, bot nav row updated
- [ ] **Step 5:** Send WhatsApp message to paired number → appears in Bots master (bot_peer row)
- [ ] **Step 6:** Telegram token connect on same bot → second channel chip visible

---

### Task 6.2: Log + NATS verification

**DB (MCP):** After pair + one inbound message, expect rows:

| topic | kind | dv |
|-------|------|-----|
| `pair_start` | system | channel-wa-device or server dv |
| `qr` | system | channel-wa-device |
| `connected` | system | channel-wa-device |
| `msg_received` | system | channel-wa-device (+ server on turn) |

**NATS:** Root live log viewer (when built) or temporary subscriber:

```bash
# nats sub "log.{owner_iid}.>"  (replace owner_iid)
```

Confirm protobuf `LogPush` or JSON debug payload matches inserted row.

- [ ] **Step 1:** Query `ai.log` — all lifecycle topics present
- [ ] **Step 2:** Confirm no secrets in `text`/`meta`
- [ ] **Step 3:** NATS subject matches `log.{owner_iid}.{dv}.{topic}` per `_/docs/log.md`

---

### Task 6.3: Regression checks

```powershell
cargo build -p server_ai
cargo build -p channel_whatsapp_device
cd clients/app; flutter analyze
```

- [ ] **Step 1:** All three pass
- [ ] **Step 2:** Existing bots page conversation send/stop still works

---

## Log event catalog (canonical)

All writers MUST use these `topic` values (adjust only via doc update):

| topic | kind | Writer | When |
|-------|------|--------|------|
| `bot_create` | system | server | identity_put create |
| `bot_update` | system | server | identity_put update |
| `pair_start` | system | server + worker | QR flow begins |
| `qr` | system | worker | New QR emitted |
| `connected` | system | server/worker | Channel ready |
| `disconnected` | system | worker | WA session dropped |
| `pair_abort` | system | server/worker | User cancelled |
| `pair_expired` | system | worker | Watch lease expired |
| `error` | error | any | Failure (no secrets) |
| `msg_received` | system | worker + server | Inbound message |
| `msg_sent` | system | worker | Outbound send ok |

`dv` values:
- Flutter client: session device id
- `channel-whatsapp-device` worker: `"channel-wa-device"`
- c35-server channel handlers: `"c35-server"`

---

## Risk notes

1. **LogPush not previously published anywhere** — Track 2A is prerequisite for spec compliance; worker-only INSERT was insufficient.
2. **WhatsApp worker README references old cs-server paths** — c35 pair orchestration lives in `mod_channel`; update README after Task 2C.
3. **One WhatsApp linked account per owner** — enforce in pair_start to avoid worker stopping duplicates mid-pair.
4. **arm64 only** — do not push amd64 images to btm cluster.

---

## Doc updates (after implementation)

- [ ] `_/docs/ui.md` — bots empty state + add wizard (short)
- [ ] `_/docs/identity.md` — `identity_put` RPC + wizard meta
- [ ] `_/docs/log.md` — channel topic catalog (link to this plan table)
- [ ] `_/docs/server.md` — WHATSAPP_WORKER_URL, deploy commands, NATS subjects
- [ ] `servers/channel_whatsapp_device/README.md` — c35 server function names
