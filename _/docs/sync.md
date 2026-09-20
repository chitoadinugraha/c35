# Sync & realtime (LOCKED)

Status: **locked** 2026-09-20

## Model

**Server-authoritative**, cs_bots-style. Flutter holds a **read cache** (secure storage); YB is source of truth. No SQLCipher replica on client or agent for app data.

Remote agents (`remotes/*`) may keep local state for execution, but sync to server through the same identity + wire protocol.

## Timestamp convention

Every **syncable** row has:

| Column | Purpose |
|--------|---------|
| `created_ts` | Row creation (TIMESTAMPTZ) |
| `updated_ts` | Last mutation; **sync watermark** |
| `deleted_ts` | NULL = live; set = tombstone (soft delete) |

Use `_ts` suffix consistently across all syncable tables (not `_at`).

On any UPSERT: `updated_ts = NOW()`. On soft delete: set `deleted_ts = NOW()` and bump `updated_ts`.

## WebSocket connect

```
GET /v1/ws?since=<unix_ms>&jwt=<token>&locale=<locale>&tz=<timezone>
```

| Param | Purpose |
|-------|---------|
| `since` | Client watermark; server sends rows with `updated_ts > since` |
| `jwt` | Auth session |
| `locale`, `tz` | User prefs for server-side formatting |

## Session init (one round trip)

After WS auth, client sends **`ReqSessionInit`**. Server responds **`ResSessionInit`** with parallel-fetched slices (only deltas since `since` where applicable):

- profile, settings
- billing balance, commission
- quota (5h ring, weekly ring)
- device/client registry snapshot
- any other page-zero data

**Rule:** never fetch balance, quota, profile as separate HTTP calls on app open.

Server implementation: single handler fans out parallel queries (tokio `join!` or IN queries).

## Delta sync pattern

Generic query shape per collection:

```sql
SELECT *
FROM ai.{table}
WHERE owner_iid = $1
  AND updated_ts > $2          -- since
  AND ($3::timestamptz IS NULL OR updated_ts <= $3)  -- optional upper bound
ORDER BY updated_ts ASC
LIMIT $4
```

Include tombstones (`deleted_ts IS NOT NULL`) in delta so client can remove local cache entries.

### Required indexes

Per owner-scoped syncable table:

```sql
CREATE INDEX idx_{table}_sync
  ON ai.{table} (owner_iid, updated_ts);
```

For live rows only (optional partial, use when table is large):

```sql
CREATE INDEX idx_{table}_sync_live
  ON ai.{table} (owner_iid, updated_ts)
  WHERE deleted_ts IS NULL;
```

Append-only `log` table:

```sql
CREATE INDEX idx_log_sync ON ai.log (owner_iid, updated_ts);
```

Identity profile row (keyed by id, not owner):

```sql
CREATE INDEX idx_identity_sync ON ai.identity (id, updated_ts);
```

List by kind for Devices/Bots pages:

```sql
CREATE INDEX idx_identity_owner_kind
  ON ai.identity (owner_iid, kind, updated_ts)
  WHERE deleted_ts IS NULL;
```

## Client local cache

Stored in Flutter secure storage as protobuf bytes:

| Key | Content |
|-----|---------|
| `ResSessionInit` | Last full/delta session snapshot |
| `since` | Watermark unix ms |
| Recent chat list | Last N chats metadata |
| Recent chat messages | Last N messages per active chat |

On app launch: render **stale cache immediately**, connect WS, apply delta, update UI.

Older chat messages: paginate from server on scroll (not full local sync).

## NATS subjects

### User realtime (push after DB write)

```
c35.user.{iid}.balance
c35.user.{iid}.commission
c35.user.{iid}.quota
c35.user.{iid}.settings
c35.user.{iid}.profile
```

Client subscribes after WS auth. Payload: protobuf delta or full slice for that topic.

### Live log (admin/root)

```
log.{iid}.{dv}.{topic}
```

| Part | Example |
|------|---------|
| `iid` | User identity id |
| `dv` | Device/client id (DV) |
| `topic` | `sign-in`, `sign-out`, `prompt`, `connected`, `disconnected`, `error`, … |

Root/admin UI subscribes with wildcard filter; table-backed `ai.log` is canonical store.

## Log table

Single table for audit + billing trace. Full spec: [log.md](log.md), DDL: [`../schemas/log.sql`](../schemas/log.sql).

```
kind: conn | error | system | llm | tool | task
req_id, chat_id, task_id, device_iid
tokens_in, tokens_out, duration_ms, cost_usd
owner_iid, dv, topic
created_ts, updated_ts
```

Billable LLM rows set `cost_usd`; client `l()` rows sync with `cost_usd = 0`. Dedupe via `billing_usage_dedupe` — see [billing.md](billing.md).

## Wire messages (proto)

Defined in [`../schemas/proto/c35/`](../schemas/proto/c35/). See [`../schemas/proto/README.md`](../schemas/proto/README.md).

| Proto | Purpose |
|-------|---------|
| `wire.proto` | `WsReq` / `WsRes`, `InvokeReq` / `InvokeRes` |
| `session.proto` | `ReqSessionInit` / `ResSessionInit` |
| `sync.proto` | `ReqSync` / `ResSync`, `SyncPush` |
| `chat.proto` | `Chat`, `ChatMsg`, prompt, stop, send |
| `billing.proto` | `BillingAccount`, top-up, push deltas |
| `log.proto` | `Log`, `LogPush` |

All collections on wire mirror SQL rows; timestamps as `*_ms` int64.

## Rules

1. Always parallelize server fetches; use IN queries over loops.
2. One init request per page/screen load.
3. Proto encodes only **changes since since** on reconnect, not full DB dump.
4. Index every syncable table on `(owner_iid, updated_ts)` before shipping.
5. Tombstone via `deleted_ts`; never hard-delete syncable rows in normal operation.
