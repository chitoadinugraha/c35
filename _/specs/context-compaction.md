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
| Memory retrieve | `memory_retrieve()` (hybrid: pinned + vector + FTS) → system prompt block |
| Memory write | `memory_put()` with write-time embedding; extracted via turn gate, compaction, and idle backfill |
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
context_window            INT NOT NULL DEFAULT 0        -- 0 = default at read time
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
| `CONTEXT_PACK_BUDGET_RATIO` | `0.65` | Fraction of the **selected** context window for history + summary |
| `CONTEXT_COMPACT_THRESHOLD_RATIO` | `0.70` | Compact when the **full unsummarized** estimate is >= this fraction of the selected window |
| `CONTEXT_RECENT_MSG_MIN` | `8` | Always keep at least this many recent msgs verbatim |
| `CONTEXT_RECENT_MSG_MAX` | `12` | Cap verbatim tail after packing |
| `CONTEXT_COMPACT_MODEL` | `c35_mod_llm::CHEAP_MODEL` (`gemini-3.1-flash-lite`) | Cheap model for summarize + extract |
| `CONTEXT_IDLE_MINUTES` | `45` | Idle backfill after last message. **Disabled** unless `C35_CONTEXT_IDLE_COMPACT=1` (fetcher does not register the task). Per-turn memory extract stays on |
| `CONTEXT_IDLE_MIN_MSGS` | `4` | Minimum msgs before idle extract |
| `MEMORY_EXTRACT_MAX_PER_TURN` | `2` | Cap writes per turn |
| `MEMORY_EXTRACT_CONFIDENCE_MIN` | `0.85` | Below → skip write |

Per-chat window (`ai.chat.context_window`, `0` = default at read time; do not backfill):

| | |
|--|--|
| Allowed steps | `32768`, `65536`, `131072`, `262144`, `524288` |
| Default (`stored = 0`) | `min(128_000, model ceiling)`. Alien slugs and Gemini still default to **128_000** |
| Alien slugs (`alienai`, `auto`, `alien`, `cloud`, empty) | Picker ceiling `1_000_000` |
| Gemini (`model` contains `gemini`) | Model ceiling `1_048_576`; picker max **512k** (`524288`) |
| Other models | Picker ceiling = `model_context_limit` (128_000) |

A set above the picker ceiling is rejected. Packing uses `0.65` of the **resolved** window, not the raw model ceiling.

`ResPromptEnd.usage` carries token counts only (`ceil(chars/4)`), never instruction text, tool schemas, or memory. Slices: instructions, memory, context (mentions, site, time, location), tools, conversation. The meter bar is each slice divided by the selected window.

---

## Phase 1 — Token-aware packing (no LLM)

Replace `LIMIT 20` with **token budget packing**.

### Algorithm (`context_pack`)

1. Resolve the selected window: `context_window_resolve(model, ai.chat.context_window)`.
2. `budget = selected_window * CONTEXT_PACK_BUDGET_RATIO`.
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

Before building `ChatReq`, estimate the **full unsummarized thread** (not the packed tail of 8–12 messages):

```
total = system + summary + token_estimate(all history rows not yet summarized) + user_message
```

If `total >= selected_window * CONTEXT_COMPACT_THRESHOLD_RATIO` → run `context_compact(chat_id, req_id, trigger="threshold")`, then repack.

Manual compact (`ReqChatCompact`, wire field 176) uses the same `context_compact` path even under 70%. If there are fewer unsummarized rows than `CONTEXT_RECENT_MSG_MIN`, the response is `ran=false` (not an error). Billing uses `billing_usage_report` with `req_id` `compact-{chat_id}-{snowflake}`.

### Title refresh (same compact call)

Compact JSON includes `title` (<= 48 characters). Apply it only when `ai.chat.meta` does not contain `title_locked: true` and the current title is empty, `Chat`, or equal to `chat_title_from_text` of the first user message. Fan out like `chat_title_set`. A title written from the tool loop sets `meta.title_locked = true` so meal/expense titles are not overwritten.

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
  "entities": { "site_iid": "…", "names": ["…"] },
  "title": "short title"
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

## Phase 3 — Memory extraction & recall (v2)

### Categories (`ai.memory.category`)

| Category | Examples | Write? |
|----------|----------|--------|
| `identity` | "user name is Alice", "lives in Singapore" | Yes (pinned recall) |
| `preference` | "always use IDR", "prefer concise answers" | Yes (pinned recall) |
| `fact` | "calorie goal 2000", "shop PID xyz" | Yes |
| `task` | "open task: fix login bug" | Yes (compact mainly) |
| `ephemeral` | weather, one-off trivia | **Never** |

Dedup & Embedding: `memory_put` uses `content_hash` (blake3 of `key:content`) — upsert on key per owner, computing document embedding at write time into `embedding_json`.

### Model & Billing

- Extractor and compact both call `c35_mod_llm::CHEAP_MODEL` (`gemini-3.1-flash-lite`).
- Billing cost computed using the actual resolved model name via `billing_cost_usd(&resolved_model, in_tok, out_tok)`.

### Extractor v2 Actions

The extractor receives recent conversation plus top existing memories for context, outputting structured JSON actions:

```json
{
  "actions": [
    { "op": "add", "category": "preference", "key": "diet_preference", "content": "vegetarian", "confidence": 0.95 },
    { "op": "delete", "category": "preference", "key": "old_diet", "content": "", "confidence": 0.95 }
  ]
}
```

Legacy `candidates` output is also supported for backward compatibility:
```json
{ "candidates": [{ "category": "fact", "key": "calorie_goal", "content": "2000 kcal/day", "confidence": 0.92 }] }
```

- `op = "add" | "update"`: writes via `memory_put` when `confidence >= MEMORY_EXTRACT_CONFIDENCE_MIN` (0.85) and category ≠ `ephemeral`.
- `op = "delete"`: soft-deletes (`deleted_ts = NOW()`) only on explicit user contradiction/retraction with `confidence >= 0.90`.

### Triggers (hybrid — locked)

| Trigger | When | Aggressiveness | Billing |
|---------|------|----------------|---------|
| **On compact** | `context_compact()` after summarize | High — extract from batch being summarized | Parent `req_id` |
| **Per-turn gate** | End of successful `prompt_turn` | Low — max 2 high-confidence facts | Same `req_id` |
| **Idle backfill** | `last_msg_ts` > 45 min, ≥ 4 msgs, unprocessed. **Off** unless `C35_CONTEXT_IDLE_COMPACT=1` | Medium | Separate `req_id`; best-effort |

### Per-turn gate

After assistant message saved, cheap LLM call against last turn(s).
Skip gate when: `tool_mode = ask`, turn errored, or `assistant_text` is empty.

### Hybrid Retrieval (`memory_retrieve`)

1. **Pinned / Core Facts**: Load up to 3 active memories where `category IN ('identity', 'preference')` ordered by `updated_ts DESC`.
2. **Vector Similarity Search**: One query embedding computed via `embed_cached`. Cosine similarity against stored `embedding_json` of owner's active memories, keeping candidates with similarity >= `MEMORY_SIM_FLOOR` (0.50).
3. **FTS Search (Keyword fallback)**: Query via `plainto_tsquery('english', $q)` for lexical matches.
4. **Merge & Deduplicate**: Merge pinned + vector matches + FTS matches, deduplicating by key, capped at `MEMORY_RECALL_LIMIT` (8) rows.

System prompt injection:
```markdown
## Memory
Known facts about the user. Use naturally without reciting. If the user's current message contradicts a stored fact, follow the user.
- key: content
```

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
