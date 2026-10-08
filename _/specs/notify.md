# User notifications (LOCKED)

Status: **locked** 2026-10-08

Home chat can schedule a notification to the signed-in user ("notify me in 5 seconds", "notify me when this is finished") and deliver it through one pipeline. The history list reads `ai.notify`. `ai.log` stores one delivery audit event.

Track breakdown (schema, Rust, Flutter, verification): [plans/2026-10-08-user-notify-multitask.md](plans/2026-10-08-user-notify-multitask.md). This page locks subjects, statuses, and deliver rules. Implement tracks S1-C1 from that plan plus this page.

See also [sync.md](sync.md) (app lane), [event.md](event.md) (`user.notified`), [log.md](log.md), [nats.md](nats.md) (`C35_NOTIFY_SCHEDULE`), [ui.md](ui.md) (avatar history), [inst.md](inst.md) (`inst.task.notify`).

DDL (track S1): [`../schemas/notify.sql`](../schemas/notify.sql). Ids are snowflakes (`c35_store::snowflake_id`).

## Inbox (`ai.notify`)

Mutable inbox and schedule. Statuses:

| status | Meaning |
|--------|---------|
| `scheduled` | Waiting for `fire_at` (NATS `@at`) |
| `waiting` | Held until the current turn ends (`when=turn`) |
| `sent` | Deliver claimed. `channels` filled. `sent_ts` set |
| `read` | User opened it (`ReqNotifyRead`) |
| `cancelled` | Caller cancelled while `scheduled` or `waiting` |

Columns: `id`, `owner_iid`, `title`, `body`, `fire_at`, `status` (default `scheduled`), `channels` (default empty), `route_json` (default `{}`), `req_id`, `created_ts`, `updated_ts`, `sent_ts`, `read_ts`, `deleted_ts`. Check `chk_notify_status` allows only the five statuses above.

Indexes: `idx_notify_inbox` (owner, `created_ts`, `id`, live rows), `idx_notify_due` (`fire_at` where `scheduled`), `idx_notify_wait_req` (`req_id` where `waiting`), `idx_notify_owner_sync` (`owner_iid`, `updated_ts`).

Limits: `title` 120 chars, `body` 500 chars, `delay_sec` 0..=604800 (7 days). Empty title is rejected.

`channels` is a comma-separated subset of `app`, `local`, `fcm`, written once at deliver (example `app,fcm`). Empty means no install was reachable; the row is still `sent` so history shows it.

Stale `scheduled` rows are not polled. Due fire is NATS `@at` plus boot hydrate.

## Presence (`ai.app_conn`)

Source of truth for "this install has a live app socket" (multi-pod). The in-process signaling map is not.

| Column | Role |
|--------|------|
| `owner_iid` | Signed-in user |
| `client_id` | Install id (same string the app socket already sends) |
| `resumed` | App in foreground |
| `updated_ts` | Heartbeat |

Primary key `(owner_iid, client_id)`. `updated_ts` older than 45 seconds is offline. Client heartbeats every 20 seconds via `ReqAppPresence`. WebSocket close deletes that `(owner_iid, client_id)` row.

## Tokens (`ai.fcm_token`)

| Column | Role |
|--------|------|
| `owner_iid` | Signed-in user |
| `client_id` | Same install id as `ai.app_conn` |
| `token` | FCM registration token |
| `platform` | `android` or `ios` (`chk_fcm_platform`) |
| `updated_ts` | Last `ReqNotifyTokenPut` |

Primary key `(owner_iid, client_id)`. Desktop and web have no FCM. A closed desktop app sees the inbox row on the next `notify.list`.

Credentials: `FIREBASE_SERVICE_ACCOUNT_PATH` or existing `GOOGLE_APPLICATION_CREDENTIALS_JSON`. Missing credentials disables FCM; deliver still writes the history row.

## Deliver

One function: `notify_deliver`. Pure plan (unit-tested, no DB):

```text
plan_delivery(conns, tokens, now) -> { nats: bool, fcm_tokens: Vec, channels: String }
```

Per `client_id`:

- A conn is live when `updated_ts > now - 45s`.
- Live app socket: publish one `NotifyPush` on `c35.user.{iid}.app.notify` and skip FCM for that `client_id`.
- No live app socket: FCM data message for that `client_id` token.
- `nats` is true when any live conn exists (one push for the owner, not one per conn).
- FCM targets are tokens whose `client_id` has no live conn.

`channels` (history, sorted `app`, `local`, `fcm`, joined with `,`):

- `app` if any live conn has `resumed`
- `local` if any live conn has `resumed = false`
- `fcm` if any FCM target

The client (`NotifyRouter`) chooses the shade from its own resumed flag (same rule as CSA `GatewayNotif`: shade suppressed while resumed):

- Resumed: in-app banner only.
- Not resumed: local notification only.

FCM payload is data-only (`title`, `body`, `notify_id`, `route_json`, `type=user_notify`) so Android and iOS use the same router as the app lane. Tap opens history, or `route_json.chat_id` / `route_json.path` when set.

Claim before send (one pod wins). Zero rows means another pod already delivered; stop.

```sql
UPDATE ai.notify
SET status = 'sent', channels = $2, sent_ts = NOW(), updated_ts = NOW()
WHERE id = $1 AND status IN ('scheduled', 'waiting') AND deleted_ts IS NULL
RETURNING id;
```

After a successful claim, emit `user.notified` (below), then publish `NotifyPush` when `nats`, then FCM for the token list.

## Audit (`user.notified`)

`ai.log` stays append-only. After a successful deliver, `event_emit` kind `user.notified` (`class=event`). Meta: `notify_id`, `channels`, `title`. English line: `$name notified: $title`. Ops reads that via `log_tail`.

The app history screen reads `ai.notify` only. There is no `notify` value on `chk_log_kind`. The notification payload (`NotifyPush`) is not published on `c35.user.{iid}.ev.*`. Catalog: [event.md](event.md).

## Wire

Next free `WsReq.body` / `WsRes.body` field number is **210** (209 is `img_generate`).

| Field | Message |
|------|---------|
| 210 | `ReqNotifyList` / `ResNotifyList` |
| 211 | `ReqNotifyRead` / `ResNotifyRead` |
| 212 | `ReqNotifyTokenPut` / `ResNotifyTokenPut` |
| 213 | `ReqAppPresence` / `ResAppPresence` |
| 214 | `NotifyPush` on `WsRes` only (unsolicited) |

`NotifyItem`: `id`, `title`, `body`, `status`, `channels`, `fire_at_ms`, `sent_ts_ms`, `read_ts_ms`, `created_ts_ms`, `route_json`.

`ReqNotifyList`: `limit` (default 20, clamp 1..=50), `unread_only`. `ReqNotifyRead`: repeated `ids` (empty = all `sent` -> `read`). `ReqNotifyTokenPut`: `client_id`, `token`, `platform`. `ReqAppPresence`: `client_id`, `resumed`. `NotifyPush`: `id`, `title`, `body`, `route_json`.

NATS subject helper `user_app_subject_notify(owner_iid)` -> `c35.user.{owner_iid}.app.notify`. Fanout tail `notify` decodes `WsRes` the same way as `inbox`. App lane row: [sync.md](sync.md).

Read and cancel only rows with `owner_iid` = caller. Reject empty `client_id`.

## Schedule (`C35_NOTIFY_SCHEDULE`)

JetStream stream next to `C35_TASK_SCHEDULE`. Subjects: `c35.schedule.notify.>`, `c35.notify.fire.>`. Flags: `allow_msg_schedules`, `allow_msg_ttl`. Queue group `c35-notify-fire`. See [nats.md](nats.md).

Publish (same header style as `hydrate_task_schedules`):

- subject `c35.schedule.notify.{id}`
- `Nats-Schedule`: `@at {fire_at RFC3339}`
- `Nats-Schedule-Target`: `c35.notify.fire.{id}`
- `Nats-Schedule-TTL`: `24h` when `fire_at` is within 24h, else `168h`

`when=delay` (default): `delay_sec = 0` and no `fire_at` calls `notify_deliver` inline (no NATS schedule). Otherwise insert `status=scheduled` and publish the schedule.

`when=turn`: ignore delay. Insert `status=waiting`, `req_id` = current `ToolContext` req id. `prompt_run_finish` (success or fail) calls `notify_release_waiting(owner_iid, req_id)`, which delivers each waiting row. Title and body were stored at schedule time. A notify failure must not fail the turn.

Hydrate on the existing single-leader boot path (same advisory lock as task schedules): `status = 'scheduled'`, `deleted_ts IS NULL`, `fire_at > now() - interval '2 minutes'`. If `fire_at <= now()`, call `notify_deliver` instead of publishing a schedule.

Fire payload JSON: `{ "notify_id": i64 }`. Handler calls `notify_deliver`.

## Tools

Steering is `inst.task.notify` in `inst.sql` (`kind=task`, `scope=global`, priority 120). Git seed is not live; deploy with `inst_put`. Tool JSON describes parameters only.

| Tool | Mutates | Args |
|------|---------|------|
| `notify.schedule` | yes | `title`, `body`, optional `delay_sec` or `fire_at` (RFC3339), optional `when` = `delay` (default) or `turn`, optional `route` `{chat_id, path}` |
| `notify.list` | no | optional `limit` (default 20, max 50), optional `unread_only` |
| `notify.cancel` | yes | `id`. Only `scheduled` or `waiting` owned by the caller becomes `cancelled` |

`include_tools`: `notify.schedule`, `notify.list`, `notify.cancel`. `exclude_tools`: `web.search`.

Phrases (substring): `notify me`, `remind me`, `ingatkan`, `notification`, `in 5 seconds`, `in 5 sec`, `kabari saya`, `kasih tahu saya`.

`rag_phrases`: `notify me`, `remind me`, `ingatkan`, `kabari saya`, `kasih tahu saya`, `in 5 seconds`.

Inst body:

```text
[NOTIFY] User wants a notification to themselves. Call notify.schedule. For "in N seconds/minutes" set delay_sec (minutes * 60). For a clock time set fire_at RFC3339 in the user timezone from context. For "notify me when you are done" / "if finished" set when=turn (delivers when this turn ends). Summarize from tool JSON: id, status, fire_at. Use notify.list when they ask what reminders they have. Use notify.cancel only when they name one to drop.
```

Tool result JSON: `id`, `status`, `fire_at`, `channels`. After immediate deliver, `status` is `sent` and `channels` is filled. Errors: `{ "error": "bad_args" }` with a short message. Never schedule for another `owner_iid`.

## UI

Avatar menu **Notifications** opens the history page. Unread count comes from `ReqNotifyList`. Tap marks `ReqNotifyRead`. Banner tap does the same plus route. See [ui.md](ui.md).

On resume and pause the app sends `ReqAppPresence`. Every 20 seconds while the socket is up. On start, `ReqNotifyTokenPut` when FCM yields a token (mobile). Desktop and web no-op the token put.
