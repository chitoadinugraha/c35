# Context compaction & memory extraction (LOCKED)

Status: **locked** 2026-09-23

## Overview

Long prompt threads exceed model context windows. c35 manages this with **three layers** — each with a different reliability job:

| Layer | Purpose | Reliability |
|-------|---------|-------------|
| **Recent verbatim window** | Last K turns unchanged in the prompt | Highest — local references |
| **Rolling summary** | Narrative continuity for older turns | Good (~95% normal chat) |
| **Long-term memory** (`ai.memory`) | Durable facts that must survive compaction | Highest for extracted facts |

**UI rule:** Full message history stays in `ai.chat_msg`. Compaction affects **prompt assembly only** — never delete rows.

**Billing rule:** Compaction and memory-extraction LLM calls are **metered** (allowance → on-demand wallet). Rolled into the triggering turn's `req_id` when possible. See [billing.md](billing.md) § Context compaction billing.

---

## Current state (pre-ship)

| Piece | Today |
|-------|--------|
| History | Last **20 messages** hard count (`prompt_turn.rs`, `channel_prompt_turn.rs`) |
| Screenshot prune | `prune_previous_screenshots()` in tool loop (computer use) |
| Memory retrieve | `memory_retrieve()` → system prompt block |
| Memory write | `memory_put()` exists; **no extraction wired** |
| Context meter UI | `UiContextMeter` — hidden at 0 tokens; determinate ring when > 0 |

---

## Prompt assembly (target)

```
[system + inst + memory block + mention context]
[CONVERSATION SUMMARY]          ← ai.chat.context_summary (when set)
[recent verbatim messages]      ← token-packed, newest-first fill
[current user message + attachments]
```

Compaction runs **before** `ChatReq` is built when estimated tokens exceed threshold.

---

## Schema

### `ai.chat` (add columns)

```sql
context_summary           TEXT NOT NULL DEFAULT '',
context_summary_upto_msg_id BIGINT NOT NULL DEFAULT 0,  -- msgs with id <= this are summarized
context_compact_ts        TIMESTAMPTZ,                  -- last successful compact
context_compact_req_id    TEXT NOT NULL DEFAULT ''      -- req_id that last compacted
```

- `context_summary_upto_msg_id = 0` → no summary yet.
- Summary covers all messages with `id <= context_summary_upto_msg_id` (deleted/error rows excluded from re-summarize input).

### `ai.chat_compact_log` (audit)

One row per compaction event (user-visible trace + billing debug).

```sql
CREATE TABLE IF NOT EXISTS ai.chat_compact_log (
    id                  BIGINT PRIMARY KEY,
    chat_id             BIGINT NOT NULL REFERENCES ai.chat(id),
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    req_id              TEXT NOT NULL DEFAULT '',       -- parent turn req_id (billing anchor)
    trigger             TEXT NOT NULL DEFAULT 'threshold',  -- threshold | idle
    msgs_summarized     INT NOT NULL DEFAULT 0,
    tokens_in           INT NOT NULL DEFAULT 0,
    tokens_out          INT NOT NULL DEFAULT 0,
    cost_usd            NUMERIC(12, 6) NOT NULL DEFAULT 0,
    model               TEXT NOT NULL DEFAULT '',
    summary_before_len  INT NOT NULL DEFAULT 0,
    summary_after_len   INT NOT NULL DEFAULT 0,
    memory_writes       INT NOT NULL DEFAULT 0,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Canonical DDL: extend [`../schemas/chat.sql`](../schemas/chat.sql).

---

## Constants (locked)

| Constant | Value | Notes |
|----------|-------|-------|
| `CONTEXT_PACK_BUDGET_RATIO` | `0.65` | Fraction of model limit for history + summary |
| `CONTEXT_COMPACT_THRESHOLD_RATIO` | `0.70` | Compact when estimate exceeds this |
| `CONTEXT_RECENT_MSG_MIN` | `8` | Always keep at least this many recent msgs verbatim |
| `CONTEXT_RECENT_MSG_MAX` | `12` | Cap verbatim tail after packing |
| `CONTEXT_COMPACT_MODEL` | `gemini-2.0-flash` | Cheap model for summarize + extract |
| `CONTEXT_IDLE_MINUTES` | `45` | Idle backfill after last message |
| `CONTEXT_IDLE_MIN_MSGS` | `4` | Minimum msgs before idle extract |
| `MEMORY_EXTRACT_MAX_PER_TURN` | `2` | Cap writes per turn |
| `MEMORY_EXTRACT_CONFIDENCE_MIN` | `0.85` | Below → skip write |

Model context limits (client meter + server pack):

| Model family | Limit |
|--------------|-------|
| Default (non-Gemini) | `128_000` |
| Gemini | `1_000_000` |

---

## Phase 1 — Token-aware packing (no LLM)

Replace `LIMIT 20` with **token budget packing**.

### Algorithm (`context_pack`)

1. Resolve `model_limit` from `ChatReq.model` (same rules as `UiContextMeter`).
2. `budget = model_limit * CONTEXT_PACK_BUDGET_RATIO`.
3. Load candidate history: all msgs with `id > context_summary_upto_msg_id`, `id < user_msg_id`, `deleted_ts IS NULL`, `status <> 'error'`, `ORDER BY id DESC`.
4. **Pre-prune** each candidate (prompt-only; DB unchanged):
   - Strip `blocks_json` tool blobs → `[tool output omitted from history]`
   - Strip inline JPEG from attachments in history
   - Truncate `thought` to 500 chars in history
5. Estimate tokens: `ceil(char_count / 4)` per message (fast; refine later with tokenizer).
6. Pack newest-first until `budget - summary_tokens - system_reserve` exhausted.
7. Ensure at least `CONTEXT_RECENT_MSG_MIN` messages kept if they exist.
8. Reverse to chronological order for `ChatReq.history`.

### Fail open

If packing fails, fall back to `LIMIT 20` (current behavior) and log warning.

---

## Phase 2 — Rolling summary (compaction)

### When to compact

Before building `ChatReq`, estimate:

```
total = system + memory + summary + packed_history + user_message
```

If `total > model_limit * CONTEXT_COMPACT_THRESHOLD_RATIO` → run `context_compact(chat_id, req_id, trigger="threshold")`.

Compaction is **synchronous** on the critical path only when threshold hit; must complete before LLM turn. Target &lt; 3s (flash model).

### `context_compact` steps

1. Select msgs to summarize: `context_summary_upto_msg_id < id <= (latest_msg_id - CONTEXT_RECENT_MSG_MIN)`.
2. **Pre-prune** same as Phase 1.
3. LLM call (structured JSON output):

```json
{
  "summary": "…",
  "decisions": ["…"],
  "open_tasks": ["…"],
  "entities": { "site_iid": "…", "names": ["…"] }
}
```

4. Merge: `new_summary = merge(old_summary, batch_summary)` with prompt instruction **preserve all IDs, numbers, decisions; do not invent**.
5. `UPDATE ai.chat SET context_summary, context_summary_upto_msg_id, context_compact_ts, context_compact_req_id`.
6. Insert `ai.chat_compact_log`.
7. Return `(tokens_in, tokens_out, cost_usd)` for billing rollup.

### Re-summarize policy

- Summarize **batches** of messages, not the entire thread every time.
- Never summarize the verbatim recent window.
- Max summary length: `8000` chars; if exceeded, run a compress-summary pass (same cheap model).

### Reliability guardrails

| Risk | Mitigation |
|------|------------|
| Summary drift | Structured schema; merge-with-preserve prompt; cap re-summary depth |
| Lost IDs | Regex extract `iid:`, `PID`, `req_id` before summarize; inject into summary footer |
| User surprise | Optional UI chip: "Earlier messages summarized" |
| Compact failure | Fail open → token-packed truncation; trace `compact_skipped` reason |
| Blocked reply | Compaction failure **never** fails the user turn |

---

## Phase 3 — Memory extraction

### Categories (`ai.memory.category`)

| Category | Examples | Write? |
|----------|----------|--------|
| `preference` | "always use IDR", "prefer concise answers" | Yes |
| `fact` | "calorie goal 2000", "shop PID xyz" | Yes |
| `task` | "open task: fix login bug" | Yes (compact mainly) |
| `ephemeral` | weather, one-off trivia | **Never** |

Dedup: `memory_put` uses `content_hash` (blake3 of `key:content`) — upsert on key per owner.

### Triggers (hybrid — locked)

| Trigger | When | Aggressiveness | Billing |
|---------|------|----------------|---------|
| **On compact** | `context_compact()` after summarize | High — extract from batch being summarized | Parent `req_id` |
| **Per-turn gate** | End of successful `prompt_turn` | Low — max 2 high-confidence facts | Same `req_id` |
| **Idle backfill** | `last_msg_ts` &gt; 45 min, ≥ 4 msgs, unprocessed | Medium | Separate `req_id`; best-effort |

### Per-turn gate

After assistant message saved, optional cheap LLM call:

```json
{ "candidates": [{ "category": "fact", "key": "calorie_goal", "content": "2000 kcal/day", "confidence": 0.92 }] }
```

Only write when `confidence >= MEMORY_EXTRACT_CONFIDENCE_MIN` and category ≠ `ephemeral`.

Skip gate when: `tool_mode = ask`, turn errored, or `tokens_out < 50`.

### Idle backfill

- NATS subject: `c35.chat.compact.idle` (JetStream or core + fetcher-style worker).
- Body: `{ "chat_id", "owner_iid" }`.
- Enqueue: cron in `c35-fetcher` every 15m scanning `ai.chat` where `kind='prompt'` and idle criteria met.
- **No billing gate** — skip job if allowance + wallet cannot cover estimated cost; do not error.
- Does **not** block user turns.

### Retrieve (unchanged)

`memory_retrieve()` at turn start → `## Memory` block in system prompt. Embeddings: **not billed** (platform COGS) unless abuse detected later.

---

## Billing (summary)

Full detail: [billing.md](billing.md) § Context compaction billing.

| Event | `req_id` | Gate | Deduct |
|-------|----------|------|--------|
| Main turn | user `req_id` | `billing_gate_with_hold` | `billing_usage_report` |
| Compact on threshold | **same** parent `req_id` | Already held | `extra_cost_usd` on parent report |
| Per-turn memory extract | **same** parent `req_id` | Already held | `extra_cost_usd` |
| Idle compact + extract | `compact-{chat_id}-{snowflake}` | **None** | `billing_usage_report` if affordable; else skip |
| Token pack / screenshot prune | — | — | Free |

`ai.log.meta` for parent turn:

```json
{
  "compaction_cost_usd": 0.002,
  "compaction_tokens_in": 1200,
  "compaction_tokens_out": 400,
  "memory_extract_writes": 1
}
```

---

## UI

| Surface | Behavior |
|---------|----------|
| `UiContextMeter` | Hidden at 0 tokens; determinate ring when &gt; 0 (shipped) |
| Context detail dialog | Optional line: "Includes ~X compaction" when `meta.compaction_cost_usd > 0` |
| Chat header / thread | Subtle chip when `context_summary <> ''`: "Earlier messages summarized" (tester/root first) |
| Message list | **Unchanged** — full history visible |

---

## Server modules (target layout)

```
servers/crates/mod_chat/src/
  context_pack.rs      # token estimate, pre-prune, budget pack
  context_compact.rs   # rolling summary LLM + chat row update
  memory_extract.rs    # gate + batch extract → memory_put
  memory.rs            # existing retrieve + put
```

Integration point: `prompt_turn.rs` (and `channel_prompt_turn.rs` for bot_peer prompt path).

---

## Wire / proto

No client sync of `context_summary` in Phase 1–3. Optional later:

- `Chat.context_summary_present: bool` on sync for chip
- `ReqPromptUsage` breakdown fields

Phase 1–3: server-only; UI chip driven by new optional field on `ResPromptEnd` or trace JSON.

---

## Testing

| Test | Crate |
|------|-------|
| Token pack respects budget | `mod_chat` unit |
| Compact merges summary, updates upto_msg_id | `mod_chat` integration (mock LLM) |
| Memory extract dedupes by key | `mod_chat` unit |
| Billing extra_cost on parent req_id | `mod_billing` + `mod_chat` |
| Fail open when compact errors | `mod_chat` integration |
| `UiContextMeter` zero hide | `clients/app` widget test (shipped) |

Verify: `cargo test -p mod_chat`; `cargo build -p server_ai`; `flutter analyze`.

---

## Related docs

- [chat.md](chat.md) — chat kinds, prompt turns
- [billing.md](billing.md) — metered usage, compaction billing
- [remote.md](remote.md) — screenshot prune (computer use)
- [log.md](log.md) — `ai.log` audit rows

Implementation plan: [`plans/2026-09-23-context-compaction-multitask.md`](plans/2026-09-23-context-compaction-multitask.md)
