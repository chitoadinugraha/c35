# Bot data source background sync (phase 2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh stale bot data sources on a timer inside **`server_ai`**, sharded across replicas, reusing `data_source_sync_run` — so channel turns rarely pay Google latency without involving `c35-fetcher`.

**Architecture:** Each `server_ai` pod runs `data_source_bg_spawn`: periodic due scan → `FOR UPDATE SKIP LOCKED` claim → bounded concurrent `data_source_sync_run` (same path as lazy sync + manual RPC). Optional `status=syncing` during claim. Later (out of scope here): JetStream work queue per [`chat.md`](../chat.md).

**Tech Stack:** Rust / tokio / sqlx / `c35_mod_data_source` / existing `reqwest` HTTP client from `mod_chat::tools::http_client`.

**Spec:** [`_/specs/data_source.md`](../data_source.md) (Background sync section). **Master plan (all waves + review gates):** [`2026-09-27-data-source-all-waves-multitask.md`](2026-09-27-data-source-all-waves-multitask.md). **Prerequisite:** phase 1 shipped — [`2026-09-27-data-source-google-sheet-multitask.md`](2026-09-27-data-source-google-sheet-multitask.md).

## Global constraints

- Read `spec.md`, [`data_source.md`](../data_source.md), [`fetcher.md`](../fetcher.md) — **do not** register tasks in `c35-fetcher` / `mod_fetch`.
- Build from `servers/` → `.cache/server` (`.cursor/rules/rust-cache.mdc`).
- `mod_data_source` must not depend on `wire_ws` or `server_ai`.
- Reuse env `DATA_SOURCE_SYNC_TTL_SEC`; add `DATA_SOURCE_BG_*` only (see spec).
- Verify: `cargo build -p server_ai`; `cargo test -p c35_mod_data_source`; add tests for due-query + claim logic.
- Deploy: `publish_server.ps1` after merge (arm64 buildkit). No `min` bump unless wire break (none expected).
- Do not commit unless user asks.

---

## File map (targets)

| Path | Responsibility |
|------|----------------|
| `servers/crates/mod_data_source/src/bg.rs` | Due list, claim, spawn loop, semaphore |
| `servers/crates/mod_data_source/src/config.rs` | `DATA_SOURCE_BG_*` parsers |
| `servers/crates/mod_data_source/src/store.rs` | `sync_due_list`, `sync_claim_start`, `sync_claim_end` SQL |
| `servers/crates/mod_data_source/src/lib.rs` | export `data_source_bg_spawn` |
| `servers/server_ai/src/main.rs` | call `data_source_bg_spawn` with shared HTTP client |
| `_/schemas/data_source.sql` | optional index + `syncing` status comment |
| `_/specs/data_source.md` | keep in sync if behavior changes |
| `_/deployments/c35-server/` (or env template) | document BG env defaults |

---

## Multitask map

```text
Track 0 (doc lock)     ──► done in repo before code (data_source.md)

Wave 1 (parallel):
  Track 1 — store + due/claim SQL + unit tests
  Track 2 — bg loop + config + exports in mod_data_source

Wave 2:
  Track 3 — server_ai wiring + HTTP client lifetime

Wave 3 (parallel):
  Track 4 — metrics / tracing + log_tail-friendly messages
  Track 5 — optional YB index migration + cluster apply note

Wave 4:
  Track 6 — integration test (C35_TEST_DB=1) + manual two-replica checklist

Out of scope (phase 3 doc only):
  JetStream C35_DATA_SOURCE_SYNC, SessionInit delta, MCP data_source_* tools
```

| Track | Owner focus | Depends | Delivers |
|-------|-------------|---------|----------|
| **1** | SQL + store | — | Due selection, claim/release, tests with sqlx offline/mock |
| **2** | `bg.rs` scheduler | 1 | `data_source_bg_spawn`, semaphore, error backoff |
| **3** | `server_ai` | 2 | Production loop running on boot |
| **4** | Observability | 2 | `tracing` fields: `data_source_id`, `owner_iid`, `reason=bg` |
| **5** | DDL index | 1 | `idx_data_source_sync_due` on `(synced_ts)` partial |
| **6** | QA | 3, 4 | Test + rollout checklist |

**Parallel wave 1:** Tracks **1 + 2** (2 can stub store until 1 lands — interface first).  
**Parallel wave 3:** Tracks **4 + 5**.  
**Wave 4:** Track **6**.

---

## Track 1 — Store: due rows + claim

### Task 1.1: Config helpers

**Files:** `mod_data_source/src/config.rs`

- [ ] Add `data_source_bg_enabled() -> bool` — env `DATA_SOURCE_BG_ENABLED`, default `true`
- [ ] Add `data_source_bg_tick_sec()`, `data_source_bg_batch()`, `data_source_bg_max_concurrent()` with spec defaults
- [ ] Unit test: unset env → defaults

### Task 1.2: Due list query

**Files:** `mod_data_source/src/store.rs`

- [ ] `sync_due_ids(pool, ttl_sec, limit) -> Vec<i64>` — join `data_source` + `data_source_sync`, `deleted_ts IS NULL`, status in `ok|error|stale`, `synced_ts` older than TTL, order by `synced_ts ASC`, `LIMIT`
- [ ] Exclude rows already `status = 'syncing'` with `updated_ts` within last **5 min** (stuck guard)

### Task 1.3: Claim / release

**Files:** `mod_data_source/src/store.rs`

- [ ] `sync_claim(pool, data_source_id) -> bool` — `UPDATE ai.data_source_sync SET status='syncing', updated_ts=NOW() WHERE data_source_id=$1 AND status <> 'syncing'`; return rows_affected == 1
- [ ] Document: lazy sync may still run `sync_run` without claim — claim is **bg-only** anti-duplication; `sync_run` remains idempotent via hash
- [ ] On `sync_run` completion (existing code): ensure status returns to `ok` or `error` (not left `syncing`)

### Task 1.4: Tests

**Files:** `mod_data_source/tests/bg_store_test.rs` or extend existing tests

- [ ] `#[sqlx::test]` or `C35_TEST_DB=1` integration: insert binding + old `synced_ts` → appears in due list
- [ ] Fresh `synced_ts` → not due
- [ ] `cargo test -p c35_mod_data_source`

---

## Track 2 — Background loop (`bg.rs`)

### Task 2.1: Single sync worker

**Files:** `mod_data_source/src/bg.rs`, `lib.rs`

- [ ] `async fn data_source_bg_sync_one(pool, http, id)` — `sync_claim` → if false skip; else `data_source_sync_run`; on Err call `sync_upsert_error`
- [ ] Always clear `syncing` on exit (success path via existing upsert_ok; error path via upsert_error)

### Task 2.2: Tick loop

- [ ] `pub fn data_source_bg_spawn(pool, http)` — if `!data_source_bg_enabled()` return early (no task)
- [ ] `tokio::spawn`: `interval(DATA_SOURCE_BG_TICK_SEC)`, first tick after immediate optional scan (match `embed_cache_evict_spawn` pattern)
- [ ] Per tick: `due_ids = sync_due_ids(...)`; for each id spawn with **semaphore** `DATA_SOURCE_BG_MAX_CONCURRENT`
- [ ] Use `tokio::sync::Semaphore`; do not unbounded `spawn` per id

### Task 2.3: Backoff on errors

- [ ] If `status=error`, due query still picks row after TTL — optionally add `DATA_SOURCE_BG_ERROR_BACKOFF_SEC` (default **300**) by comparing `updated_ts` when status is error (YAGNI: ship with TTL only first; document in spec if added)

### Task 2.4: Export + build

- [ ] `pub use bg::data_source_bg_spawn` from crate root
- [ ] `cargo build -p c35_mod_data_source`

---

## Track 3 — `server_ai` wiring

### Task 3.1: HTTP client

**Files:** `server_ai/src/main.rs`

- [ ] Reuse `c35_mod_chat::tools::http_client(Duration::from_secs(60))` (same as tool index / sync on turn)
- [ ] After `embed_cache_evict_spawn`, call `c35_mod_data_source::data_source_bg_spawn(pool.clone(), embed_http.clone())`
- [ ] `server_ai` `Cargo.toml` already depends on `mod_chat`; add direct `c35_mod_data_source` dep if not present

### Task 3.2: Verify boot

- [ ] `cargo build -p server_ai`
- [ ] Local run with `DATA_SOURCE_BG_ENABLED=1` and `RUST_LOG=c35_mod_data_source=info` — observe tick logs without panic when YB empty

---

## Track 4 — Observability

### Task 4.1: Structured logs

- [ ] `info!` on start/complete: `data_source_id`, `duration_ms`, `hash_changed`, `row_count`
- [ ] `warn!` on fetch failure with `error_msg` truncated
- [ ] Prefix `[c35:data_source]` for `log_tail` / MCP grep

### Task 4.2: Trace (optional)

- [ ] `tracing::span` around `data_source_bg_sync_one` — no `ai.log` row (not a user event per `event.md`)

---

## Track 5 — DDL + deploy env

### Task 5.1: Index (optional but recommended)

**Files:** `_/schemas/data_source.sql`

- [ ] Add:

```sql
CREATE INDEX IF NOT EXISTS idx_data_source_sync_due
    ON ai.data_source_sync (synced_ts ASC)
    WHERE status IN ('ok', 'error', 'stale');
```

- [ ] Apply on cluster YB before relying on bg at scale

### Task 5.2: K8s env

- [ ] Add to `c35-server` deployment manifest or documented defaults: `DATA_SOURCE_BG_*` (no secrets)
- [ ] Confirm **no** changes to `c35-fetcher` deployment

---

## Track 6 — Integration & rollout

### Task 6.1: DB integration test

- [ ] `C35_TEST_DB=1` test: due → claim → `sync_run` mock or stub adapter (if Google not callable in CI, test claim/due only)
- [ ] Document skip when no SA path in CI

### Task 6.2: Two-replica manual checklist

- [ ] Scale `c35-server` to 2 pods
- [ ] One sheet binding with `synced_ts` forced old (SQL)
- [ ] Watch logs: exactly one pod runs sync for that id per cycle
- [ ] Both pods serve turn with fresh chunks after sync

### Task 6.3: Publish

- [ ] `.\_\scripts\deploy\publish_server.ps1`
- [ ] Publish summary in agent reply

---

## Agent assignment cheat sheet

| Track | Key files |
|-------|-----------|
| 1 | `mod_data_source/src/store.rs`, `config.rs`, tests |
| 2 | `mod_data_source/src/bg.rs`, `lib.rs` |
| 3 | `server_ai/src/main.rs`, `Cargo.toml` |
| 4 | `bg.rs`, `sync.rs` log lines |
| 5 | `data_source.sql`, deployment YAML |
| 6 | tests + manual QA doc in this file |

---

## Phase 3 pointer (do not implement in phase 2)

Document only in [`data_source.md`](../data_source.md):

- JetStream stream `C35_DATA_SOURCE_SYNC`, subject `c35.data_source.sync`
- Queue group `c35-data-source-sync` on `server_ai` worker role
- Scheduler publishes jobs instead of calling `sync_run` inline when `PROMPT_WORKER_MODE` / worker split ships

---

## Success criteria

- Stale bindings refresh within ~`TTL + tick` without any channel message
- N `server_ai` replicas do not duplicate export for the same `data_source_id` in the same tick (SKIP LOCKED + claim)
- `c35-fetcher` binary and docs unchanged
- Lazy sync + manual RPC behavior unchanged
