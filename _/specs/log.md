# Log (LOCKED)

Status: **locked** 2026-09-20

## Overview

**One table** for audit timeline + billing trace — no separate `usage` or `log_billing` table (cs_agent pattern).

**Domain events** (sign-in, meal logged, channel connected): [event.md](event.md) — NATS `c35.user.{iid}.ev.{slug}`. **LLM/tool trace** stays in this table only (no NATS).

Legacy admin tail subject `log.{iid}.{dv}.{topic}` is deprecated; new lifecycle code uses [event.md](event.md).

See also [billing.md](billing.md), [sync.md](sync.md), [notify.md](notify.md).

User notification inbox is `ai.notify`. `ai.log` only gets the `user.notified` event (`class=event`; meta `notify_id`, `channels`, `title`). Ops reads that via `log_tail`. The app history screen reads `ai.notify`.

Canonical DDL: [`../schemas/log.sql`](../schemas/log.sql)

---

## `ai.log`

Append-only. Syncable via `_ts` (tombstones rare; prefer append).

| Column | Purpose |
|--------|---------|
| `owner_iid` | User identity (sync owner) |
| `kind` | `conn` \| `error` \| `system` \| `llm` \| `tool` \| `task` |
| `topic` | NATS tail topic: `sign-in`, `prompt`, `connected`, … |
| `dv` | Client device id |
| `req_id` | Correlates `chat_msg`, billing dedupe |
| `chat_id`, `task_id`, `device_iid` | Context refs |
| `text` | Human-readable summary (never secrets). **Events:** English only at emit ([event.md](event.md)); user locales render from catalog at read. **Trace:** turn summary as today. |
| `model` | LLM model id when `kind=llm` |
| `tokens_in`, `tokens_out`, `duration_ms` | Turn metrics |
| `cost_usd` | **Server-only** billable amount; client rows = 0 |
| `meta` | Small JSON (codes, ids) |

---

## Who writes what

| Origin | Examples | `cost_usd` |
|--------|----------|------------|
| Client app | sign-in, UI error, settings | `0` |
| Server | LLM turn, tool, task run | `> 0` when billable |
| Root live tail | NATS fanout after insert | — |

Client: `l()`, `lError()`, `lFatal()` — never `print`.

---

## Live log (root/admin)

After insert → publish NATS:

```
log.{owner_iid}.{dv}.{topic}
```

Root UI subscribes with wildcard; filter by user, device, topic.

---

## Billing link

Billable LLM turn:

1. Insert `log` with `kind=llm`, `cost_usd`, `req_id`
2. `billing_usage_dedupe` + deduct `billing_wallet` (native amount via `billing_fx_rate`; same txn)
3. Matching `chat_msg` carries same `req_id` + token fields for UI

---

## Sync

```sql
WHERE owner_iid = $user AND updated_ts > $since
ORDER BY updated_ts ASC
```

Admin/global tail uses server-side query or NATS — not full log sync to client.

---

## Index

```sql
(owner_iid, updated_ts)          -- user delta sync
(chat_id, created_ts DESC)       -- per-chat history
(req_id)                         -- trace lookup
(owner_iid, kind, created_ts DESC) -- filtered views
(meta->>'tool', created_ts DESC) -- partial: kind=tool, class=trace (migration 20260927)
```

---

## Tool execution analytics

Cluster tool hops are stored as **`kind=tool`**, **`class=trace`**, with **`meta.tool`** (dotted id, e.g. `device.screenshot`) and **`meta.ok`**; failures also use **`topic=tool_error`**. Voice or other tool rows without **`meta.tool`** are excluded from tool usage reports.

**Device screenshots:** `device.screenshot` / `device.input` (with image) set **`meta.screenshot`** `{ hash, url, width, height, som, marker }` on the tool row; JPEG bytes live in CAS + **`ai.tool_artifact`** (14d TTL). `output_preview` omits `image_base64`.

**Admin RPC:** `ReqAdminLogReport` with **`group_tools=true`** (root only, same `since_ms` / `until_ms` / optional `owner_iid` / `limit` as the log summary). Response widgets add:

- Total tool executions in range
- Table **`tool_id | calls | ok | fail | avg_ms`** (top N by call count)
- Weekly call totals (UTC week start, last 12 weeks in range)

**Ad-hoc SQL** (same filters as the report):

```sql
SELECT meta->>'tool' AS tool_id, COUNT(*) AS calls
FROM ai.log
WHERE deleted_ts IS NULL AND kind = 'tool' AND class = 'trace'
  AND COALESCE(meta->>'tool', '') <> ''
  AND created_ts >= NOW() - INTERVAL '30 days'
GROUP BY 1 ORDER BY 2 DESC;
```
