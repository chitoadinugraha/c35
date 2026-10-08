# User notifications — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline.
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/specs/sync.md`](../sync.md) · [`_/specs/event.md`](../event.md) · [`_/specs/log.md`](../log.md) · [`_/specs/nats.md`](../nats.md) · [`_/specs/inst.md`](../inst.md) · [`prompt-run-test.mdc`](../../../.cursor/rules/prompt-run-test.mdc)

**Goal:** Let Home chat schedule a user notification (“notify me in 5 seconds”, “notify me when this is finished”) and deliver it through one pipeline: in-app banner when that install is resumed, local notification when the app socket is up but backgrounded, FCM only when that install has no live app socket. The user opens a history list from `ai.notify`. `ai.log` stores one delivery audit event.

**Architecture:**

- **Inbox and schedule** live in `ai.notify` (mutable: `scheduled` / `waiting` / `sent` / `read` / `cancelled`). **Do not** store the inbox on `ai.log`.
- **Audit:** after a successful deliver, `event_emit` kind `user.notified` (`class=event`) with `notify_id`, `channels`, `title`. Ops reads that via `log_tail`. The app history screen reads `ai.notify` only.
- **Presence** is `ai.app_conn` (owner + `client_id`, `resumed`, heartbeat). The in-process `remote_signaling` app map is not the source of truth (multi-pod).
- **Tokens** are `ai.fcm_token` (owner + `client_id`). Desktop and web have no FCM; a closed desktop app sees the row on next `notify.list`.
- **One deliver function** `notify_deliver`. Per `client_id`: live socket → NATS `c35.user.{iid}.app.notify` and skip FCM for that token; no live socket → FCM data message. The **client** chooses banner vs local shade from its own resumed flag (same rule as CSA `GatewayNotif`: shade suppressed while resumed). Server copies `app_conn.resumed` into `channels` for history (`app`, `local`, `fcm`).
- **When:** `delay_sec` / `fire_at` uses NATS `@at` on `C35_NOTIFY_SCHEDULE` (same header style as `hydrate_task_schedules`). `when=turn` inserts `status=waiting` on the current `req_id`; `prompt_run_finish` calls `notify_release_waiting`.
- **Steering** is `inst.task.notify` in `inst.sql`. Tool JSON describes parameters only.

**Tech stack:** YSQL `ai.notify` / `ai.app_conn` / `ai.fcm_token`, Rust `c35_mod_notify` + `c35_fcm`, protobuf `wire.proto`, NATS JetStream schedules, Flutter `firebase_messaging` + `flutter_local_notifications`, `ai.inst`.

**CSA reference (behavior, not a port of chat MQTT):** `D:\csa_site_published` `account_push_offline` skips devices with a live wire; `GatewayNotif.onMqttChatTopic` shows the shade unless `appResumed`. CSA has no user reminder tool and no notification history table.

## Global constraints

- Read `spec.md`, `sync.md`, `event.md`, `log.md`, `nats.md`, `inst.md` before coding. Revise those docs in track D1 before behavior lands.
- App UI pushes use `c35.user.{iid}.app.notify` only. Do not publish notification payloads on `c35.user.{iid}.ev.*`.
- `ai.log` stays append-only. New event kind `user.notified` only. Do not add a `notify` value to `chk_log_kind`.
- Inst steering in `inst.sql`. Git seed is not live — document `inst_put` for deploy.
- No provider web grounding. No Chromium STT.
- Build from `servers/`: `cargo build -p server_ai`. Tests: `cargo test -p c35_store`, `cargo test -p c35_mod_notify`, `cargo test -p c35_mod_chat` when those crates change.
- Flutter: `._\scripts\dev\verify_flutter_app.ps1` after Dart edits.
- After any `.rs` / `.md` / `.sql` / `.proto` / `.dart` edit: `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Do not commit unless the user asks.
- Snowflake ids via `c35_store::snowflake_id`.
- FCM service account: `FIREBASE_SERVICE_ACCOUNT_PATH` or existing `GOOGLE_APPLICATION_CREDENTIALS_JSON`. Missing credentials disables FCM; deliver still writes the history row.

## Explicitly out of scope

| Item | Why |
|------|-----|
| Chat message / call / site-order push | Separate products. This pipeline is the shared deliver function they can call later. |
| iOS PushKit / VoIP | Not a reminder. |
| Replacing `ai.log` or adding inbox columns to it | Locked append-only trace/event store. |
| Polling `ai.notify` for due rows | Due fire is NATS `@at` + boot hydrate. Deliver may delete stale `app_conn` rows it already read. |
| Email or Telegram as a fourth lane | App, local, FCM only. |

## Locked data model

`_/schemas/notify.sql` (new). Register in `servers/crates/store/src/schema.rs` after `log` (`NOTIFY_SQL` + `SCHEMA_APPLY_ORDER`).

```sql
CREATE TABLE IF NOT EXISTS ai.notify (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    title           TEXT NOT NULL DEFAULT '',
    body            TEXT NOT NULL DEFAULT '',
    fire_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status          VARCHAR(16) NOT NULL DEFAULT 'scheduled',
    channels        TEXT NOT NULL DEFAULT '',
    route_json      JSONB NOT NULL DEFAULT '{}',
    req_id          VARCHAR(64) NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_ts         TIMESTAMPTZ,
    read_ts         TIMESTAMPTZ,
    deleted_ts      TIMESTAMPTZ,
    CONSTRAINT chk_notify_status CHECK (
        status IN ('scheduled', 'waiting', 'sent', 'read', 'cancelled')
    )
);

CREATE INDEX IF NOT EXISTS idx_notify_inbox
    ON ai.notify (owner_iid, created_ts DESC, id DESC)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_notify_due
    ON ai.notify (fire_at)
    WHERE status = 'scheduled' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_notify_wait_req
    ON ai.notify (req_id)
    WHERE status = 'waiting' AND deleted_ts IS NULL AND req_id <> '';

CREATE INDEX IF NOT EXISTS idx_notify_owner_sync
    ON ai.notify (owner_iid, updated_ts);

CREATE TABLE IF NOT EXISTS ai.app_conn (
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    client_id       TEXT NOT NULL,
    resumed         BOOLEAN NOT NULL DEFAULT FALSE,
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (owner_iid, client_id)
);

CREATE INDEX IF NOT EXISTS idx_app_conn_owner
    ON ai.app_conn (owner_iid, updated_ts DESC);

CREATE TABLE IF NOT EXISTS ai.fcm_token (
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    client_id       TEXT NOT NULL,
    token           TEXT NOT NULL,
    platform        VARCHAR(16) NOT NULL DEFAULT '',
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (owner_iid, client_id),
    CONSTRAINT chk_fcm_platform CHECK (platform IN ('android', 'ios'))
);
```

Limits: `title` 120 chars, `body` 500 chars, `delay_sec` 0..=604800 (7 days). Empty title rejected.

`channels` is a comma-separated subset of `app`, `local`, `fcm`, written once at deliver (example `app,fcm`). Empty means no install was reachable; the row is still `sent` so history shows it.

Stale presence: `updated_ts` older than 45 seconds is offline. Client heartbeats every 20 seconds via `ReqAppPresence`. WS close deletes that `(owner_iid, client_id)` row.

## Locked deliver rules

Pure function (unit-tested, no DB):

```text
plan_delivery(conns, tokens, now) -> { nats: bool, fcm_tokens: Vec, channels: String }
```

- A conn counts as live when `updated_ts > now - 45s`.
- `nats = true` when any live conn exists (one `NotifyPush` on `c35.user.{iid}.app.notify`).
- FCM targets = tokens whose `client_id` has **no** live conn.
- `channels`: include `app` if any live conn has `resumed`; include `local` if any live conn has `resumed = false`; include `fcm` if any FCM target. Sort `app`, `local`, `fcm`. Join with `,`.

Client (`NotifyRouter`), on `NotifyPush` or an FCM data message while the process is alive:

- App resumed → in-app banner only. Do not post a local notification.
- App not resumed → local notification. Do not also show the banner.

FCM payload is **data-only** (`title`, `body`, `notify_id`, `route_json`) so Android/iOS use the same router as the app lane. Tapping opens history, or `route_json.chat_id` / `route_json.path` when set.

Claim before send (one pod wins):

```sql
UPDATE ai.notify
SET status = 'sent', channels = $2, sent_ts = NOW(), updated_ts = NOW()
WHERE id = $1 AND status IN ('scheduled', 'waiting') AND deleted_ts IS NULL
RETURNING id;
```

Zero rows → another pod already delivered; stop.

## Locked wire

Next free `WsReq.body` / `WsRes.body` field number is **210** (209 is `img_generate`).

| Field | Message |
|------|---------|
| 210 | `ReqNotifyList` / `ResNotifyList` |
| 211 | `ReqNotifyRead` / `ResNotifyRead` |
| 212 | `ReqNotifyTokenPut` / `ResNotifyTokenPut` |
| 213 | `ReqAppPresence` / `ResAppPresence` |
| 214 | `NotifyPush` on `WsRes` only (unsolicited) |

```protobuf
message NotifyItem {
  int64 id = 1;
  string title = 2;
  string body = 3;
  string status = 4;
  string channels = 5;
  int64 fire_at_ms = 6;
  int64 sent_ts_ms = 7;
  int64 read_ts_ms = 8;
  int64 created_ts_ms = 9;
  string route_json = 10;
}
message ReqNotifyList { int32 limit = 1; bool unread_only = 2; }
message ResNotifyList { repeated NotifyItem items = 1; }
message ReqNotifyRead { repeated int64 ids = 1; } // empty = all status sent -> read
message ResNotifyRead { int32 updated = 1; }
message ReqNotifyTokenPut { string client_id = 1; string token = 2; string platform = 3; }
message ResNotifyTokenPut {}
message ReqAppPresence { string client_id = 1; bool resumed = 2; }
message ResAppPresence {}
message NotifyPush {
  int64 id = 1;
  string title = 2;
  string body = 3;
  string route_json = 4;
}
```

NATS subject helper in `servers/crates/system/nats/src/user_app.rs`:

```rust
pub fn user_app_subject_notify(owner_iid: i64) -> String
// "c35.user.{owner_iid}.app.notify"
```

`user_app_fanout_decode`: tail `notify` decodes `WsRes` the same way as `inbox`.

## Locked schedule

New stream next to `C35_TASK_SCHEDULE` in `servers/crates/system/nats/src/streams.rs`:

| Name | Subjects | Notes |
|------|----------|--------|
| `C35_NOTIFY_SCHEDULE` | `c35.schedule.notify.>`, `c35.notify.fire.>` | `allow_msg_schedules`, `allow_msg_ttl` |

Publish (copy header style from `hydrate_task_schedules`):

- subject `c35.schedule.notify.{id}`
- `Nats-Schedule`: `@at {fire_at RFC3339}`
- `Nats-Schedule-Target`: `c35.notify.fire.{id}`
- `Nats-Schedule-TTL`: `24h` when `fire_at` is within 24h, else `168h`

`delay_sec = 0` calls `notify_deliver` inline. No NATS schedule.

Hydrate inside the existing single-leader boot path (`server_ai` `nats_boot.rs`, same advisory lock as task schedules): rows with `status = 'scheduled'`, `deleted_ts IS NULL`, `fire_at > now() - interval '2 minutes'`. If `fire_at <= now()`, call `notify_deliver` instead of publishing a schedule.

Fire consumer queue group `c35-notify-fire`. Payload JSON `{ "notify_id": i64 }`. Handler calls `notify_deliver`.

`prompt_run_finish` (success or fail) calls `notify_release_waiting(owner_iid, req_id)`, which selects `status = 'waiting'` for that `req_id` and delivers each row. Title/body were stored at schedule time.

## Locked tools

| Tool | Mutates | Args |
|------|---------|------|
| `notify.schedule` | yes | `title`, `body`, optional `delay_sec` **or** `fire_at` (RFC3339), optional `when` = `delay` (default) \| `turn`, optional `route` `{chat_id, path}` |
| `notify.list` | no | optional `limit` (default 20, max 50), optional `unread_only` |
| `notify.cancel` | yes | `id` — only `scheduled` or `waiting` owned by caller → `cancelled` |

`when=turn` ignores delay and sets `status=waiting`, `req_id` = `ToolContext` req id. `when=delay` with `delay_sec=0` delivers now.

Errors: `{ "error": "bad_args" }` with a short message. Never schedule for another `owner_iid`.

Register in `servers/crates/mod_chat/src/tools/builtin/mod.rs` and `tools/mod.rs` the same way as `MailListTool`.

### Inst (`inst.task.notify`)

Phrases (substring): `notify me`, `remind me`, `ingatkan`, `notification`, `in 5 seconds`, `in 5 sec`, `kabari saya`, `kasih tahu saya`.

`include_tools`: `notify.schedule`, `notify.list`, `notify.cancel`.

`exclude_tools`: `web.search`.

Body (lock this text):

```text
[NOTIFY] User wants a notification to themselves. Call notify.schedule. For "in N seconds/minutes" set delay_sec (minutes * 60). For a clock time set fire_at RFC3339 in the user timezone from context. For "notify me when you are done" / "if finished" set when=turn (delivers when this turn ends). Summarize from tool JSON: id, status, fire_at. Use notify.list when they ask what reminders they have. Use notify.cancel only when they name one to drop.
```

Priority 120. `kind=task`, `scope=global`.

## Multitask map

```text
WAVE 1 (parallel)
  D1  Docs: notify.md + index rows in README, sync, event, log, nats, ui
  S1  notify.sql + schema.rs registration + sql parse test

WAVE 2 (parallel, after S1; D1 should be merged in spirit — follow this plan if doc lags)
  P1  wire.proto messages + user_app subject/decode
  N1  c35_mod_notify store + plan_delivery + deliver claim (FCM trait mocked)
  F1  c35_fcm HTTP v1 sender (disabled when creds missing)

WAVE 3 (after N1 + P1; F1 joins deliver)
  W1  WS handlers: list, read, token, presence; delete app_conn on socket close
  H1  C35_NOTIFY_SCHEDULE + hydrate + fire consumer
  T1  Home tools notify.schedule / list / cancel + inst.sql

WAVE 4 (after W1 + H1 + T1)
  C1  Flutter router, banner, local notif, FCM, history page, presence heartbeat
  R1  prompt_compose + prompt_run on 33000; cargo + flutter verify
```

| Wave | Track | Depends | Deliverable |
|------|-------|---------|-------------|
| 1 | D1 | — | `_/specs/notify.md` and doc cross-links |
| 1 | S1 | — | `_/schemas/notify.sql` applied by migrate bundle |
| 2 | P1 | — | proto field numbers 210–214, `user_app_subject_notify` |
| 2 | N1 | S1 | `c35_mod_notify` with unit tests |
| 2 | F1 | — | `c35_fcm` send_all, no-op when disabled |
| 3 | W1 | P1, N1 | RPC + presence |
| 3 | H1 | N1 | schedule + fire |
| 3 | T1 | N1 | tools + inst seed |
| 4 | C1 | W1, P1 | Flutter cascade |
| 4 | R1 | T1, C1, H1 | MCP + build evidence |

---

## Wave 1

### Task D1 — Spec doc

**Files:**

- Create: `_/specs/notify.md`
- Modify: `_/specs/README.md` (row after `log.md`)
- Modify: `_/specs/sync.md` app-lane table — add `c35.user.{iid}.app.notify` → `WsRes` `NotifyPush`
- Modify: `_/specs/event.md` catalog — `user.notified` / slug `notified` / `$name notified: $title` / meta `notify_id`, `channels`, `title`
- Modify: `_/specs/log.md` — one paragraph: user notification inbox is `ai.notify`; `ai.log` gets `user.notified` only
- Modify: `_/specs/nats.md` — `C35_NOTIFY_SCHEDULE` subjects
- Modify: `_/specs/ui.md` — avatar entry **Notifications** opens history (unread count from `ReqNotifyList`)

**Acceptance:** A reader can implement tracks S1–C1 from `notify.md` plus this plan without inventing subjects or statuses.

### Task S1 — Schema

**Files:**

- Create: `_/schemas/notify.sql` (SQL in **Locked data model**, verbatim)
- Modify: `servers/crates/store/src/schema.rs` — `NOTIFY_SQL`, insert `("notify", NOTIFY_SQL)` immediately after `("log", LOG_SQL)`
- Test: `servers/crates/store/src/migrate.rs` — `sql_stmts_parses_notify_sql` asserts statement count >= 8 and that `idx_notify_due` and `idx_notify_wait_req` appear

**Run:** `cd servers && cargo test -p c35_store sql_stmts_parses_notify_sql schema_expected_tables -- --nocapture`

**Expected:** `ai.notify`, `ai.app_conn`, `ai.fcm_token` in `schema_expected_tables`.

---

## Wave 2

### Task P1 — Protobuf and app subject

**Files:**

- Modify: `_/schemas/proto/c35/wire.proto` — messages and oneof fields **210–214** exactly as **Locked wire**
- Modify: `servers/crates/system/nats/src/user_app.rs` — `user_app_subject_notify`, decode tail `notify`
- Test: existing `user_app` tests if present; else a small test that `user_app_subject_notify(99000)` equals `c35.user.99000.app.notify` and a round-trip `WsRes` with `NotifyPush` decodes

Regenerate Dart/Rust protobuf the way this repo already does (search `prost` build or `._/scripts` proto gen; do not hand-edit generated `*.pb.dart` if a script exists).

### Task N1 — `c35_mod_notify`

**Create:** `servers/crates/mod_notify/` (`Cargo.toml` package `c35_mod_notify`, deps `c35_store`, `c35_proto`, `c35_nats`, `c35_mod_event`, `sqlx`, `serde_json`, `chrono`, `tokio`). Add to `servers/Cargo.toml` workspace members and `server_ai` dependencies.

**Produces:**

```rust
pub enum NotifyWhen { Delay, Turn }

pub struct NotifyPut {
    pub owner_iid: i64,
    pub title: String,
    pub body: String,
    pub delay_sec: u32,
    pub fire_at: Option<DateTime<Utc>>,
    pub when: NotifyWhen,
    pub req_id: String,
    pub route_json: serde_json::Value,
}

pub struct DeliveryPlan {
    pub nats: bool,
    pub fcm_tokens: Vec<String>,
    pub channels: String,
}

pub fn plan_delivery(conns: &[AppConn], tokens: &[FcmTok], now: DateTime<Utc>) -> DeliveryPlan;

pub async fn notify_put(pool, nats, put: NotifyPut) -> Result<NotifyRow>;
pub async fn notify_deliver(pool, nats, fcm: &dyn FcmSend, id: i64) -> Result<()>;
pub async fn notify_release_waiting(pool, nats, fcm, owner_iid: i64, req_id: &str) -> Result<u32>;
pub async fn notify_list(pool, owner_iid, limit, unread_only) -> Result<Vec<NotifyItem>>;
pub async fn notify_mark_read(pool, owner_iid, ids: &[i64]) -> Result<i32>;
pub async fn notify_cancel(pool, owner_iid, id: i64) -> Result<bool>;
pub async fn app_presence_put(pool, owner_iid, client_id, resumed) -> Result<()>;
pub async fn app_presence_delete(pool, owner_iid, client_id) -> Result<()>;
pub async fn fcm_token_put(pool, owner_iid, client_id, token, platform) -> Result<()>;
```

`FcmSend` trait: `async fn send_data(&self, tokens: &[String], data: HashMap<String, String>)`. Tests use a mock.

`notify_put` validates lengths and delay. `Delay` + `delay_sec==0` and no `fire_at` calls `notify_deliver`. Otherwise insert `scheduled` and publish the NATS schedule (no-op publish trait in unit tests). `Turn` inserts `waiting`.

`notify_deliver` loads live conns + tokens, `plan_delivery`, claim UPDATE, publish `NotifyPush` when `nats`, `FcmSend` for tokens, then `event_emit` `user.notified`.

**Tests (no DB):**

- resumed conn only → `channels == "app"`, `nats`, no fcm
- background conn only → `channels == "local"`, `nats`, no fcm
- token only → `channels == "fcm"`, no nats
- resumed client A + token for client B → `channels == "app,fcm"` and fcm list is B only
- stale conn (`updated_ts` 46s ago) + token for same client → fcm, not nats
- both resumed and background conns → `channels == "app,local"`

### Task F1 — FCM sender

**Create:** `servers/crates/system/fcm/` package `c35_fcm`. Port the HTTP v1 approach from `D:\csa_site_published\crates\system\fcm\src\lib.rs` (JWT service account, `messages:send`). Data map only: `title`, `body`, `notify_id`, `route_json`, `type=user_notify`. Android priority high. `enabled()` false when credentials are absent; `send_data` returns Ok and logs once.

No VoIP path.

---

## Wave 3

### Task W1 — WebSocket

**Files:** `servers/crates/wire_ws/src/session.rs` (and a small `notify_rpc.rs` if `session.rs` would grow by more than ~150 lines).

- `ReqNotifyList` / `Read` / `TokenPut` / `AppPresence` call `c35_mod_notify`. `limit` default 20, clamp 1..=50. Read and cancel only `owner_iid = caller`.
- On socket start, `client_id` comes from the existing device/client header the app already sends (search `X-` client id or WS query `dv` / `client_id` — use that string, do not invent a second id). First frame may be `ReqAppPresence`.
- On socket close: `app_presence_delete(caller, client_id)`.
- Reject empty `client_id`.

### Task H1 — Schedule fire

**Files:** `streams.rs`, `hydrate.rs`, `nats_boot.rs`, new consumer started from `server_ai` next to other JetStream consumers.

- Ensure stream `C35_NOTIFY_SCHEDULE`.
- `hydrate_notify_schedules` beside `hydrate_task_schedules`.
- Consumer on `c35.notify.fire.>` queue `c35-notify-fire` → `notify_deliver`.
- `prompt_run_finish` in `mod_chat` calls `notify_release_waiting` for that `req_id`. Failure to notify must not fail the turn; log and continue.

### Task T1 — Tools and inst

**Files:**

- Create: `servers/crates/mod_chat/src/tools/builtin/notify.rs`
- Modify: `builtin/mod.rs`, `tools/mod.rs` register `NotifyScheduleTool`, `NotifyListTool`, `NotifyCancelTool`
- Modify: `_/schemas/inst.sql` — `inst.task.notify` INSERT + UPDATE mirror of `inst.task.mail_read` (text in **Locked tools**)
- `mod_chat` Cargo.toml depends on `c35_mod_notify`

Tool result JSON:

```json
{ "id": 1, "status": "scheduled", "fire_at": "2026-10-08T10:00:00Z", "channels": "" }
```

After immediate deliver, `status` is `sent` and `channels` is filled.

`rag_phrases`: `notify me`, `remind me`, `ingatkan`, `kabari saya`, `kasih tahu saya`, `in 5 seconds`.

---

## Wave 4

### Task C1 — Flutter

**Files (create):**

- `clients/app/lib/core/notify/notify_router.dart` — `show(NotifyPush, {required bool resumed})` implements banner XOR local
- `clients/app/lib/core/notify/local_notif.dart`
- `clients/app/lib/core/notify/fcm_service.dart` — mobile only; stub on desktop/web that no-ops
- `clients/app/lib/widgets/notify/ui_notify_banner.dart`
- `clients/app/lib/pages/notify/page_notify_history.dart`

**Modify:** app shell WS decode for `NotifyPush`; avatar menu entry; on resume/pause send `ReqAppPresence`; every 20s while the socket is up; on start `ReqNotifyTokenPut` when FCM yields a token.

Dependencies: `flutter_local_notifications`, `firebase_messaging` (mobile). Follow existing Firebase/google config if present; if the Android app has no `google-services.json`, land the code behind a no-op and say so in the track result — do not invent a Firebase project.

History page: `ReqNotifyList`, tap marks `ReqNotifyRead`, pull to refresh. Banner tap does the same plus route.

Widget test: `NotifyRouter` with `resumed: true` does not call the local-notif port; `resumed: false` does.

### Task R1 — Verification

1. `cd servers && cargo test -p c35_mod_notify`
2. `cd servers && cargo build -p server_ai`
3. `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`
4. `._\scripts\dev\verify_flutter_app.ps1` if Dart changed
5. MCP `prompt_compose` owner `33000` phrases:
   - `notify me in 5 seconds to stretch` → `inst_ids` contains `inst.task.notify`, `selected_tools` contains `notify.schedule`
   - `what notifications do I have` → `notify.list`
6. MCP `prompt_run` owner `33000` for the 5-second phrase: hop 1 is `notify.schedule`, tool JSON `status` is `scheduled` or `sent`, `text` echoes that id. Do not claim fixed without this output.

Live `inst_put` of `inst.task.notify` before `prompt_compose` if the running server has an empty inst cache for that id.

---

## Self-check

| Requirement | Track |
|-------------|---------|
| “notify me in 5 sec” | T1 `delay_sec` + H1 `@at` |
| “notify me when finished” | T1 `when=turn` + H1 `notify_release_waiting` |
| App if resumed, else local, else FCM | N1 `plan_delivery` + C1 `NotifyRouter` |
| History table, not `ai.log` | S1 `ai.notify`; D1 event audit only |
| Indexes for inbox, due, waiting req | S1 |
| CSA per-device FCM skip | N1 rule: FCM only when that `client_id` has no live conn |
