# Context Compaction & Memory Extraction — Multitask Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hard `LIMIT 20` history with token-aware packing, rolling summary compaction on `ai.chat`, hybrid memory extraction (`memory_put`), metered billing via `extra_cost_usd`, optional idle backfill, and minimal Flutter UX for summarized threads.

**Architecture:** New `mod_chat` modules `context_pack`, `context_compact`, `memory_extract` orchestrated from `prompt_turn.rs` before `ChatReq` is built. `ai.chat` gains summary columns; `ai.chat_compact_log` audits compactions. Billing rolls compact + extract cost into parent `req_id` via existing `billing_usage_report(..., extra_cost_usd)`. Idle jobs on NATS `c35.chat.compact.idle` via fetcher cron. UI: summarized chip + compaction line in usage detail (tester/root).

**Tech Stack:** Rust (`mod_chat`, `mod_billing`, `c35-fetcher`), Flutter (`clients/app`), YugabyteDB, NATS, protobuf (minimal).

## Global Constraints

- Read `spec.md`, `_/docs/context-compaction.md`, `_/docs/chat.md`, `_/docs/billing.md` before coding.
- **Never delete** `ai.chat_msg` rows for compaction.
- Compaction failure **fail open** — do not block user turn.
- Subagent `model`: **`inherit`** (repo rule — no `*-fast`).
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p mod_chat`; `cd clients/app && flutter analyze`.
- Do not commit unless user asks.
- Constants from `_/docs/context-compaction.md` — copy verbatim.

---

## Multitask Map

```
Track 0 (Schema)     ──┬──► Track 2 (context_compact)
                       ├──► Track 5 (prompt_turn wire)
                       └──► Track 7 (Flutter chip)

Track 1 (context_pack) ──► Track 5

Track 2 (context_compact) ──┬──► Track 3 (memory_extract)
                            └──► Track 4 (billing meta)

Track 3 + Track 4 ──► Track 5

Track 5 ──► Track 6 (idle worker)

All ──► Track 8 (tests + doc verify)
```

| Track | Focus | Depends |
|-------|-------|---------|
| **0** | DDL: `ai.chat` columns + `ai.chat_compact_log`; `schema.rs` | — |
| **1** | `context_pack.rs` — token estimate, pre-prune, budget pack | — |
| **2** | `context_compact.rs` — LLM summarize, merge, DB update, audit log | 0 |
| **3** | `memory_extract.rs` — batch + per-turn gate → `memory_put` | 2 |
| **4** | `billing_usage_report` meta + `extra_cost_usd` rollup helpers | — |
| **5** | `prompt_turn.rs` + `channel_prompt_turn.rs` integration | 0, 1, 2, 3, 4 |
| **6** | Idle scanner in `c35-fetcher` + NATS handler in `mod_chat` | 5 |
| **7** | Flutter: summarized chip, usage compaction line | 5 |
| **8** | Integration tests, doc cross-check, full verify | all |

**Wave 1 (parallel):** Tracks **0 + 1 + 4** — done
**Wave 2 (parallel):** Tracks **2 + 7** — done
**Wave 3:** Track **3** — done
**Wave 4:** Track **5** — done
**Wave 5:** Track **6** — done
**Wave 6:** Track **8** — done (2026-09-23)

---

## Track 0 — Schema

### Task 0.1: Extend `chat.sql`

**Files:**
- Modify: `_/schemas/chat.sql` (add columns after `meta`)
- Modify: `_/schemas/chat.sql` (append `chat_compact_log` table)
- Modify: `servers/crates/store/src/schema.rs` (no new file — chat.sql already included)

**Add to `ai.chat`:**

```sql
context_summary             TEXT NOT NULL DEFAULT '',
context_summary_upto_msg_id BIGINT NOT NULL DEFAULT 0,
context_compact_ts          TIMESTAMPTZ,
context_compact_req_id      TEXT NOT NULL DEFAULT ''
```

**New table** — see `_/docs/context-compaction.md` § `ai.chat_compact_log`.

- [ ] **Step 1:** Add columns + table to `_/schemas/chat.sql`
- [ ] **Step 2:** Apply migration on dev YB (manual or existing migrate script)
- [ ] **Step 3:** `cd servers && cargo build -p server_ai` — compiles

**Produces:** DDL applied; columns queryable.

---

## Track 1 — Token packing

### Task 1.1: `context_pack.rs`

**Files:**
- Create: `servers/crates/mod_chat/src/context_pack.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` (pub mod + re-exports)
- Create: `servers/crates/mod_chat/tests/context_pack_test.rs`

**Interfaces:**

```rust
// context_pack.rs
pub const CONTEXT_PACK_BUDGET_RATIO: f64 = 0.65;
pub const CONTEXT_RECENT_MSG_MIN: usize = 8;
pub const CONTEXT_RECENT_MSG_MAX: usize = 12;

pub fn model_context_limit(model: &str) -> i32;  // 128_000 or 1_000_000 if gemini

pub fn token_estimate(text: &str) -> i32;  // ceil(len/4)

pub fn history_prune_for_prompt(role: &str, content: &str, blocks_json: &str) -> String;

pub struct PackedHistory {
    pub messages: Vec<ChatHistoryMsg>,
    pub tokens_est: i32,
    pub dropped_count: i32,
}

pub fn context_pack_history(
    summary: &str,
    rows: &[(String, String, String)],  // (role, content, blocks_json) DESC id order
    model: &str,
    system_tokens_est: i32,
    user_tokens_est: i32,
) -> PackedHistory;
```

- [ ] **Step 1:** Write failing tests in `context_pack_test.rs`:

```rust
#[test]
fn pack_keeps_minimum_recent() { /* 10 msgs, tiny budget → at least CONTEXT_RECENT_MSG_MIN */ }

#[test]
fn pack_respects_budget() { /* sum tokens <= budget */ }

#[test]
fn prune_strips_blocks_json() { /* blocks → placeholder */ }
```

- [ ] **Step 2:** `cargo test -p mod_chat context_pack` — FAIL
- [ ] **Step 3:** Implement `context_pack.rs`
- [ ] **Step 4:** Tests PASS

**Produces:** `context_pack_history`, `model_context_limit`, `token_estimate`.

---

## Track 2 — Rolling summary

### Task 2.1: `context_compact.rs`

**Files:**
- Create: `servers/crates/mod_chat/src/context_compact.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Create: `servers/crates/mod_chat/tests/context_compact_test.rs`

**Interfaces:**

```rust
pub const CONTEXT_COMPACT_THRESHOLD_RATIO: f64 = 0.70;
pub const CONTEXT_COMPACT_MODEL: &str = "gemini-2.0-flash";

pub struct CompactResult {
    pub tokens_in: i32,
    pub tokens_out: i32,
    pub cost_usd: f64,
    pub msgs_summarized: i32,
    pub memory_writes: i32,  // filled by track 3 hook
}

pub fn should_compact(
    model: &str,
    system_tokens: i32,
    summary_tokens: i32,
    history_tokens: i32,
    user_tokens: i32,
) -> bool;

pub async fn context_compact(
    pool: &PgPool,
    http: &Client,
    chat_id: i64,
    owner_iid: i64,
    req_id: &str,
    user_msg_id: i64,
    trigger: &str,  // "threshold" | "idle"
) -> Result<Option<CompactResult>>;
```

**LLM prompt (locked):** System instructs JSON output with `summary`, `decisions[]`, `open_tasks[]`, `entities{}`. Merge prompt preserves IDs verbatim.

- [ ] **Step 1:** Test `should_compact` thresholds (pure fn)
- [ ] **Step 2:** Test merge helper `summary_merge(old, new) -> String`
- [ ] **Step 3:** Implement DB read/write + `chat_compact_log` insert
- [ ] **Step 4:** Wire `llm_generate_chain` / existing gemini helper with `CONTEXT_COMPACT_MODEL`
- [ ] **Step 5:** `cargo test -p mod_chat context_compact` — PASS

**Produces:** `context_compact()`, `should_compact()`.

---

## Track 3 — Memory extraction

### Task 3.1: `memory_extract.rs`

**Files:**
- Create: `servers/crates/mod_chat/src/memory_extract.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: `servers/crates/mod_chat/src/context_compact.rs` (call batch extract after summarize)
- Create: `servers/crates/mod_chat/tests/memory_extract_test.rs`

**Interfaces:**

```rust
pub const MEMORY_EXTRACT_MAX_PER_TURN: usize = 2;
pub const MEMORY_EXTRACT_CONFIDENCE_MIN: f64 = 0.85;

#[derive(Deserialize)]
pub struct MemoryCandidate {
    pub category: String,
    pub key: String,
    pub content: String,
    pub confidence: f64,
}

pub async fn memory_extract_batch(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    transcript: &str,
) -> Result<Vec<MemoryCandidate>>;

pub async fn memory_extract_apply(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    candidates: &[MemoryCandidate],
) -> Result<i32>;  // write count

pub async fn memory_extract_turn_gate(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    bot_iid: Option<i64>,
    source_req_id: &str,
    user_text: &str,
    assistant_text: &str,
) -> Result<i32>;
```

- [ ] **Step 1:** Test `memory_extract_apply` skips `confidence < 0.85` and `ephemeral`
- [ ] **Step 2:** Test dedup via `memory_put` same key upserts
- [ ] **Step 3:** Implement batch + gate LLM calls (flash model)
- [ ] **Step 4:** Hook `context_compact` → `memory_extract_batch` on summarized transcript
- [ ] **Step 5:** Tests PASS

**Produces:** `memory_extract_batch`, `memory_extract_turn_gate`, `memory_extract_apply`.

---

## Track 4 — Billing rollup

### Task 4.1: Compaction cost in `extra_cost_usd`

**Files:**
- Modify: `servers/crates/mod_billing/src/billing_turn.rs` (extend meta when extra > 0)
- Create: `servers/crates/mod_chat/src/context_billing.rs` (rollup helper)
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs` (consume in track 5)

**Interfaces:**

```rust
// context_billing.rs
pub struct ContextBillingExtra {
    pub compaction_cost_usd: f64,
    pub compaction_tokens_in: i32,
    pub compaction_tokens_out: i32,
    pub memory_extract_cost_usd: f64,
    pub memory_extract_writes: i32,
}

impl ContextBillingExtra {
    pub fn total_extra_usd(&self) -> f64;
    pub fn to_log_meta(&self) -> serde_json::Value;
}
```

- [ ] **Step 1:** Unit test `total_extra_usd` sums correctly
- [ ] **Step 2:** Extend `billing_usage_report` meta merge to include compaction fields when present
- [ ] **Step 3:** `cargo test -p mod_billing` — PASS

**Produces:** `ContextBillingExtra`, log meta shape locked in `_/docs/billing.md`.

---

## Track 5 — `prompt_turn` integration

### Task 5.1: Replace `LIMIT 20` path

**Files:**
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs`
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs`
- Create: `servers/crates/mod_chat/tests/prompt_context_integration_test.rs`

**Flow (locked):**

```
1. Load chat.context_summary + context_summary_upto_msg_id
2. Load history rows id > upto AND id < user_msg_id ORDER BY id DESC (no LIMIT)
3. context_pack_history(...)
4. If should_compact(...) → context_compact(...) → accumulate ContextBillingExtra
5. Re-pack after compact if summary changed
6. Build ChatReq.history = [optional summary as system-side user msg] + packed msgs
7. After successful turn → memory_extract_turn_gate(...)
8. billing_usage_report(..., extra_cost_usd = context_extra.total_extra_usd())
```

**Summary injection shape:**

```rust
// Prepend as single history msg (role assistant or user per gemini convention):
ChatHistoryMsg {
    role: "user".into(),
    content: format!("[CONVERSATION SUMMARY]\n{}", summary),
}
```

Only when `summary` non-empty.

- [ ] **Step 1:** Integration test with mock pool / stub compact (or test DB)
- [ ] **Step 2:** Replace SQL `LIMIT 20` in both prompt_turn files
- [ ] **Step 3:** Wire compact + billing + turn gate
- [ ] **Step 4:** `cargo test -p mod_chat prompt_context` — PASS
- [ ] **Step 5:** `cargo build -p server_ai`

**Produces:** End-to-end prompt path using compaction.

---

## Track 6 — Idle worker

### Task 6.1: Fetcher scan + NATS handler

**Files:**
- Modify: `servers/crates/mod_chat/src/context_compact.rs` (add `trigger = "idle"`, separate req_id)
- Create: `servers/crates/mod_chat/src/context_idle.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: fetcher crate (find existing periodic job pattern in `c35-fetcher`)

**Idle enqueue query:**

```sql
SELECT c.id, c.owner_iid FROM ai.chat c
WHERE c.kind = 'prompt' AND c.deleted_ts IS NULL
  AND c.last_msg_ts < NOW() - INTERVAL '45 minutes'
  AND (SELECT COUNT(*) FROM ai.chat_msg m WHERE m.chat_id = c.id AND m.deleted_ts IS NULL) >= 4
  AND (c.context_compact_ts IS NULL OR c.context_compact_ts < c.last_msg_ts)
LIMIT 50
```

**Handler:** `context_idle_process(chat_id, owner_iid)` → generate `req_id = compact-{chat_id}-{snowflake}` → `context_compact` + `memory_extract_batch` → `billing_usage_report` if `billing_can_afford_tool`-style check passes; else skip.

- [ ] **Step 1:** Implement `context_idle.rs` handler
- [ ] **Step 2:** Subscribe in `server_ai` or worker on `c35.chat.compact.idle`
- [ ] **Step 3:** Add fetcher cron job (15m) to publish idle candidates
- [ ] **Step 4:** Manual test on dev cluster

**Produces:** Idle backfill path.

---

## Track 7 — Flutter UI

### Task 7.1: Summarized chip + usage line

**Files:**
- Modify: `servers/crates/wire_ws` or proto if adding `summary_present` on prompt end frame (optional — can use trace JSON first)
- Modify: `clients/app/lib/c/store/chat_store.dart` (flag per active chat)
- Modify: `clients/app/lib/pages/page_ai_home.dart` (chip near context meter)
- Modify: `clients/app/lib/widgets/ai/ui_context_meter.dart` (detail dialog compaction line)

**Minimum ship (no proto change):**

- Add `contextSummaryPresent` to chat row via sync `meta` JSON key `context_summary_present: true` set server-side on compact (update `chat.meta`).

- [ ] **Step 1:** Server sets `chat.meta.context_summary_present = true` on first compact
- [ ] **Step 2:** Flutter reads meta on active chat — show muted chip "Earlier messages summarized"
- [ ] **Step 3:** `UiContextMeter` detail: if trace/meta has `compaction_cost_usd`, show "Includes ~X compaction"
- [ ] **Step 4:** `flutter analyze` — clean

**Produces:** Visible UX for testers; no user confusion on long threads.

---

## Track 8 — Verify & docs

### Task 8.1: Full verification

- [ ] `cd servers && cargo test -p mod_chat`
- [ ] `cd servers && cargo build -p server_ai`
- [ ] `cd clients/app && flutter test test/ui_context_meter_test.dart`
- [ ] `cd clients/app && flutter analyze`
- [ ] Cross-check `_/docs/context-compaction.md` matches implementation constants
- [ ] Cross-check `_/docs/billing.md` meta JSON matches `ContextBillingExtra::to_log_meta`

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Compact adds latency on hot path | Flash model; only when > 70%; async idle for non-blocking extract |
| Double billing | Single `req_id` dedupe; compact cost only in `extra_cost_usd` once |
| Summary hallucination | Structured JSON + preserve-ID footer + memory extract |
| Empty wallet idle jobs | Skip silently |
| Multi-pod duplicate idle | `chat_compact_ts` check + optional lease column later |

---

## Out of scope (later)

- Client sync of full `context_summary` text
- Tokenizer-accurate counts (tiktoken) — start with char/4
- User-facing "memory manager" settings UI
- Compaction for `bot_peer` staff prompts (Phase 2 — `channel_prompt_turn` included in track 5 but lower priority)
