# Prompt follow-up queue + mid-run steer (Option B)

> **Status:** implemented (v1 — server queue/steer, WS, channels, app enqueue while busy; composer queue strip optional follow-up)  
> **Goal:** Server-side follow-up queue and tool-boundary **steer** for Home (`prompt_run`) and channels (WhatsApp/Telegram). **Option B caps:** Lite = no queue; all other **user** plans = queue max **5**; global per-turn steer abuse cap.

**Read first:** [`spec.md`](../../spec.md), [`_/docs/chat.md`](../chat.md), [`_/docs/channels.md`](../channels.md), [`_/docs/billing-plans.md`](../billing-plans.md), [`_/docs/inst.md`](../inst.md) (steer is **not** `ai.inst`).

---

## Product rules (locked for this plan)

| Surface | While turn **running** | Before turn starts (debounce) |
|---------|------------------------|-------------------------------|
| **App composer** | Enter → **queue**; row **Steer** → deliver at next tool round | Normal `ReqPrompt` |
| **Channels** | Inbound → **steer by default**; overflow → **queue** if plan allows | Merge into one user text (existing 1.8s debounce + append) |
| **Lite** | No queue (`queue_max = 0`); steer up to `steer_max`; then friendly reject | Debounce merge only |
| **Plus / Pro / Ultra** | Steer + queue up to **5** pending rows per active `req_id` | Debounce merge |

**Separate from** JetStream **priority dispatch** (`priority_queue`, `queue_priority_multiplier` in `caps_json`) — UI must label **“Follow-ups while AI is working”** vs **“Priority when servers are busy”**.

**Invariants**

1. At most **one** active turn per `chat_id` (no parallel `prompt_cluster_turn` for same chat).
2. Steer / queue drain only **between tool rounds** (same checkpoint as `cancel`).
3. Caps enforced on **server** using `owner_iid` billing row (channels: owner personal plan via existing `billing_resolve`).
4. Duplicate channel webhooks: idempotent on `(bot_iid, channel_id, external_msg_id)` when enqueueing follow-up.

---

## Schema changes

### 1. New table: `ai.prompt_followup` (required)

Authoritative server queue. Not client state.

```sql
CREATE TABLE IF NOT EXISTS ai.prompt_followup (
    id                  TEXT PRIMARY KEY,              -- ULID
    req_id              TEXT NOT NULL,                 -- active turn (Home prompt_run or channel turn)
    chat_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL,
    seq                 INT NOT NULL,                  -- FIFO within req_id (monotonic assign)
    kind                TEXT NOT NULL,                 -- steer | queue
    status              TEXT NOT NULL DEFAULT 'pending',
    text                TEXT NOT NULL DEFAULT '',
    attachments_json    TEXT NOT NULL DEFAULT '[]',
    source              TEXT NOT NULL DEFAULT 'app',   -- app | channel
    external_dedup_key  TEXT,                          -- optional: platform dedup
    reject_reason       TEXT,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_ts        TIMESTAMPTZ,
    CONSTRAINT chk_prompt_followup_kind CHECK (kind IN ('steer', 'queue')),
    CONSTRAINT chk_prompt_followup_status CHECK (
        status IN ('pending', 'delivered', 'rejected', 'cancelled')
    ),
    CONSTRAINT chk_prompt_followup_source CHECK (source IN ('app', 'channel'))
);

CREATE INDEX IF NOT EXISTS idx_prompt_followup_req_pending
    ON ai.prompt_followup (req_id, seq)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_prompt_followup_chat_pending
    ON ai.prompt_followup (chat_id, created_ts DESC)
    WHERE status = 'pending';

CREATE UNIQUE INDEX IF NOT EXISTS uq_prompt_followup_external_dedup
    ON ai.prompt_followup (external_dedup_key)
    WHERE external_dedup_key IS NOT NULL AND status = 'pending';
```

**Files:** [`_/schemas/prompt_followup.sql`](../../_schemas/prompt_followup.sql) (new) + [`_/schemas/migrations/`](../../_schemas/migrations/) `YYYYMMDD_prompt_followup_v1.sql` for live clusters.

**No FK to `ai.prompt_run`** (channel turns may not have a row yet in v1); logical coupling via `req_id` + lifecycle hooks.

### 2. `ai.prompt_run` — small extension (recommended)

Channels do not insert `prompt_run` today. Add a **lightweight registration** so “active turn” is one query for Home + channel:

```sql
-- Extend kind enum
ALTER TABLE ai.prompt_run DROP CONSTRAINT IF EXISTS chk_prompt_run_kind;
ALTER TABLE ai.prompt_run ADD CONSTRAINT chk_prompt_run_kind CHECK (
    kind IN ('main','research','computer_use','site_build','channel')
);

-- Optional: count steers without scanning followup table on hot path
ALTER TABLE ai.prompt_run ADD COLUMN IF NOT EXISTS steer_delivered_count INT NOT NULL DEFAULT 0;
```

**Channel turn start:** `INSERT ai.prompt_run` (`kind='channel'`, `status='running'`, …) with same `req_id` as inbound.  
**Channel turn end:** `prompt_run_finish` → `done` / `failed` / `cancelled` (same as worker).

**Alternative (smaller DDL, worse ergonomics):** skip `kind='channel'` and use only `ai.prompt_followup` + in-memory `req_id` on debouncer — **not recommended** (reconnect/hydrate harder).

### 3. Billing — **data only** (no new columns)

Add keys inside existing `ai.billing_plan.caps_json`:

| Plan slug | `prompt_followup_queue_max` | `prompt_followup_steer_max` |
|-----------|----------------------------|----------------------------|
| `lite` | **0** | **3** |
| `plus`, `pro`, `ultra` | **5** | **20** |
| `bot.*`, `device.*` | inherit owner check on channel (use **owner** user plan for peer caps) | same |

Seed `UPDATE` in [`_/schemas/billing.sql`](../../_schemas/billing.sql) + migration snippet.

Rust: `billing_caps_followup(owner_iid) -> (queue_max, steer_max)` reading `caps_json` with defaults `(0, 3)` if missing.

### 4. Proto / wire (required)

[`_/schemas/proto/c35/chat.proto`](../../_schemas/proto/c35/chat.proto):

```protobuf
enum PromptFollowupKind {
  PROMPT_FOLLOWUP_KIND_UNSPECIFIED = 0;
  PROMPT_FOLLOWUP_KIND_STEER = 1;
  PROMPT_FOLLOWUP_KIND_QUEUE = 2;
}

message ReqPromptFollowupPut {
  int64 chat_id = 1;
  string req_id = 2;              // empty → server resolves active run for chat_id
  string text = 3;
  string attachments_json = 4;
  PromptFollowupKind kind = 5;
}

message ResPromptFollowupPut {
  string id = 1;
  string req_id = 2;
  int32 queue_depth = 3;          // pending queue rows for this req_id
  bool rejected = 4;
  string reject_reason = 5;        // plan_cap | no_active_run | steer_cap | duplicate
}

message PromptFollowupRow {
  string id = 1;
  string req_id = 2;
  int64 chat_id = 3;
  PromptFollowupKind kind = 4;
  string status = 5;
  string text = 6;
  int32 seq = 7;
  int64 created_ts_ms = 8;
}

message ReqPromptFollowupList {
  int64 chat_id = 1;
  string req_id = 2;
}

message ResPromptFollowupList {
  repeated PromptFollowupRow items = 1;
  string active_req_id = 2;
}

message ReqPromptFollowupCancel {
  string id = 1;                   // delete one queued row (not delivered steer)
}
```

[`_/schemas/proto/c35/wire.proto`](../../_schemas/proto/c35/wire.proto): add `ReqPromptFollowupPut`, `ReqPromptFollowupList`, `ReqPromptFollowupCancel` to `WsReq`; fanout `PromptFollowupPush` on `c35.user.{owner_iid}.chat.{chat_id}` (optional `seq` + list snapshot).

**Do not** overload `ReqPrompt` for follow-ups while busy — keeps idempotency and billing holds clean.

### 5. What we are **not** changing

- `ai.inst` / topic / compose — no phrase steering for follow-ups (optional later: one-line runtime hint in tool_loop, not a seed).
- `ai.chat_msg` schema — steer delivery inserts a **user** row at deliver time (existing columns).
- JetStream stream `C35_CHAT_PROMPT` — still one job per **turn start**; follow-ups do not publish new jobs.

---

## Architecture

```
Inbound (app WS / channel NATS)
  → resolve active req_id for chat_id
  → if none: normal turn start (ReqPrompt / channel debounce)
  → if active:
       prompt_followup_put(kind=steer|queue)
       enforce caps → insert row OR reject
       NATS fanout PromptFollowupPush

prompt_cluster_turn / tool_loop (each round start)
  → prompt_followup_drain_pending(req_id)
       FOR EACH pending steer (FIFO): merge into history + user chat_msg + mark delivered
       increment steer_delivered_count; enforce steer_max
  → after turn terminal: prompt_followup_flush_queue(req_id)
       IF queue rows pending: start **next** user turn (new req_id) with concatenated or sequential policy (v1: **one** new turn per queued item, FIFO)
```

**Queue-after-turn policy (v1):** each **queue** row starts a **new** `req_id` / `prompt_run` after previous finishes (simplest billing + UX). **Steer** rows never start a new run.

**Channel debouncer change:** replace single `pending: Option<Job>` overwrite with `prompt_followup_put` when `typing == true`; when `typing == false`, keep debounce timer but **append** text to scheduled job (pre-turn coalesce).

---

## Implementation tracks

| Track | Work | Depends |
|-------|------|---------|
| **0** | SQL + proto + `caps_json` seeds + codegen | — |
| **1** | `mod_chat/prompt_followup/` — put, list, cancel, drain, caps | 0 |
| **2** | `tool_loop.rs` + worker `cancel_watch` — call drain at round boundary | 1 |
| **3** | `wire_ws` handlers + fanout; `prompt_run` channel registration | 1, 2 |
| **4** | `mod_channel` inbound + debounce integration; default steer | 1, 3 |
| **5** | Flutter composer queue UI + store sync from WS | 3 |
| **6** | `billing_plan_format.dart` + plan copy | 0 |
| **7** | Tests + docs (`chat.md`, `channels.md`) + MCP note | all |

**Parallel wave 1:** 0  
**Wave 2:** 1 + 6  
**Wave 3:** 2 + 3  
**Wave 4:** 4 + 5  
**Wave 5:** 7  

**Subagent model:** `inherit` only (per repo rules).

---

## Track details

### Track 1 — Server module

- `prompt_followup_active_req(pool, chat_id) -> Option<req_id>`  
  - Prefer `ai.prompt_run WHERE chat_id AND status IN ('queued','running','waiting_child') ORDER BY created_ts DESC LIMIT 1`
- `prompt_followup_put` — assign `seq`, check `queue_max` (count `kind=queue` pending), check `steer_max` (delivered + pending steer)
- `prompt_followup_drain_steers` — called from tool_loop; builds `[MID-RUN USER REFINEMENT]\n{text}` appended as user message in history
- `prompt_followup_cancel` — user removes queued row before delivery
- On `prompt_run` cancel/finish: mark pending followups `cancelled` or auto-flush queue per policy

### Track 2 — Tool loop safety

- Drain **before** each LLM call (after previous tools complete).
- If drain fails (DB), log and continue turn — do not crash worker.
- Cap steers per turn: reject further puts with `reject_reason=steer_cap`.

### Track 3 — WebSocket

- While busy, client sends `ReqPromptFollowupPut` instead of second `ReqPrompt`.
- List on composer open / `PromptRunPush` status `running`.
- Abort unchanged (`ReqPromptAbort`); cancels pending followups for that `req_id`.

### Track 4 — Channels

- `external_dedup_key = "{platform}:{bot_iid}:{channel_id}:{external_msg_id}"`
- Overflow message (Lite / full queue): short ID/EN reply via existing outbound path (not `BOT_BUSY_REPLY` unless bot limiter fires).
- Bot concurrency limiter unchanged.

### Track 5 — Flutter

- `PromptFollowupStore` per chat — sync from `ResPromptFollowupList` + push.
- Composer: queued strip, Steer / delete; busy → send enqueues (`kind=queue`); Steer button → `kind=steer`.
- Remove `if (promptBusy) return` block in `_composerSend` for text-only follow-ups — route to `promptFollowupPut`.

### Track 6 — Billing UI

- Lite: **“Follow-ups while busy: not included”** (or “1 correction only” if you expose steer_max 3 in copy).
- Plus+: **“Queue up to 5 messages while AI is working”**.
- Keep existing priority queue line for Pro/Ultra.

---

## Verification

```powershell
cd servers
cargo test -p mod_chat prompt_followup
cargo build -p server_ai
```

```powershell
cd clients/app
flutter analyze
flutter test test/chat_store_test.dart
```

**Manual**

1. Home: start long tool turn → queue 2 messages → steer 1 → assert trace shows extra user hop before next tool.
2. Lite account: 4th steer rejected; queue put rejected.
3. Plus: 6th queue rejected.
4. Channel: two WhatsApp texts during typing → one turn, both in history (steer + or merged).
5. Reconnect app → list matches DB.

---

## Rollout / stability

1. Ship server + caps **before** UI (follow-ups via MCP/invoke only for smoke test) — optional.
2. Feature flag `C35_PROMPT_FOLLOWUP=1` on server (default off one release) — optional but recommended.
3. No `min` bump (wire additive proto).
4. Monitor: `prompt_followup` reject rate, steer count per turn, channel overflow replies.

---

## Open decisions (defaults chosen above)

| Question | Default in this plan |
|----------|----------------------|
| Lite mid-run | Steer allowed up to `steer_max`; no queue rows |
| Queue after turn | Each queue item → **new** `req_id` turn (FIFO) |
| Channel `prompt_run` row | **Yes** (`kind=channel`) |
| Bot plan caps | Use **owner** user plan for `bot_peer` follow-ups |

---

## Schema change checklist (summary)

| Change | Type |
|--------|------|
| `ai.prompt_followup` | **NEW TABLE** |
| `ai.prompt_run.kind` + `steer_delivered_count` | **ALTER** (recommended) |
| `billing_plan.caps_json` keys | **SEED / UPDATE** only |
| `chat.proto` + `wire.proto` | **ADD** messages |
| `ai.inst` | **none** |
