# Bot data sources (Google Sheets sync) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship cs_bots-style **cached + indexed** Google Sheet knowledge for c35 bots so channel/home bot turns load context from YB (FTS + embed retrieval), with lazy sync and optional `gsheet.*` tools for writes.

**Architecture:** New crate `c35_mod_data_source` owns generic sync/chunk/retrieve + `google_sheet` adapter. Bindings live in `ai.data_source` (not cs_bots `ai.asset`). `channel_prompt_turn` calls `data_source_prompt_for_bot` before LLM. Wire RPCs for Flutter bot wizard. Port logic from `D:\cs_bots\servers\alienai\src\integrations\{asset_chunk,google_sheet}.rs` and `tools/builtin/gsheet.rs`.

**Tech Stack:** Rust (`mod_data_source`, `mod_chat`, `mod_llm`, `wire_ws`), SQL [`_/schemas/data_source.sql`](../../schemas/data_source.sql), protobuf `c35/wire.proto`, Flutter (`clients/app` bots UI), tests with `C35_TEST_DB=1`.

## Global Constraints

- Read [`spec.md`](../../spec.md), [`_/specs/data_source.md`](../../docs/data_source.md), [`_/specs/identity.md`](../../docs/identity.md), [`_/specs/channels.md`](../../docs/channels.md), [`_/specs/sync.md`](../../docs/sync.md) before coding.
- Bots: `kind=bot`, `type=chat`; channels stay in `meta.channels[]` only.
- Do **not** add cs_bots `ai.asset` / `asset_integration` tables.
- IDs: snowflake; content/snapshot hashes: **blake3** hex.
- Syncable binding rows use `created_ts` / `updated_ts` / `deleted_ts` on `ai.data_source`.
- Constants (single module `mod_data_source/src/config.rs`):
  - `DATA_SOURCE_SYNC_TTL_SEC` env, default **120**
  - `DATA_SOURCE_SMALL_ROW_LIMIT` = **50**
  - `DATA_SOURCE_RETRIEVE_LIMIT` = **8**
  - `DATA_SOURCE_RETRIEVE_TIMEOUT_SEC` = **4**
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_data_source`; `cd clients/app && flutter analyze`.
- Deploy: `.\_\scripts\deploy\publish_server.ps1` after server changes.
- Apply DDL on cluster YB before rollout (`data_source.sql`).
- Do not commit unless user asks.

---

## File map (target)

| Path | Responsibility |
|------|----------------|
| `_/schemas/data_source.sql` | DDL (done) |
| `_/specs/data_source.md` | Locked spec (done) |
| `servers/crates/mod_data_source/` | Crate: sync, chunk, retrieve, google_sheet adapter |
| `servers/crates/mod_chat/src/channel_prompt_turn.rs` | Inject `data_source_prompt_for_bot` |
| `servers/crates/mod_chat/src/tools/builtin/gsheet.rs` | LLM tools |
| `servers/crates/mod_chat/src/tools/mod.rs` | Register gsheet tools |
| `_/schemas/proto/c35/wire.proto` + `data_source.proto` | RPC messages |
| `servers/crates/wire_ws/src/session.rs` | Dispatch WS handlers |
| `servers/crates/mod_chat/src/data_source_rpc.rs` | `data_source_list/put/delete/sync` |
| `clients/app/lib/c/bot/data_source_api.dart` | Invoke RPCs |
| `clients/app/lib/widgets/bots/io_channel_pick_grid.dart` | Real sheet URL flow |
| `clients/app/lib/widgets/bots/in_bot_create.dart` | Stop using `meta.assets` strings |

---

## Multitask map

```
Track 0 (DDL apply + doc links)     — done in repo; cluster apply in Track 7

Parallel wave 1:
  • Agent A → Track 1 (mod_data_source crate + unit tests)
  • Agent B → Track 2 (proto + RPC handlers)
  • Agent C → Track 4 (gsheet tools) — after Track 1 public API stable

Track 3 (channel_prompt_turn hook) ──► after Track 1

Parallel wave 2:
  • Agent D → Track 3
  • Agent E → Track 5 (Flutter UI)

Track 6 (integration tests + MCP note) ──► after Tracks 3–5

Track 7 (deploy + manual E2E) ──► after Track 6
```

**Dependency summary**

| Track | Blocks | Blocked by |
|-------|--------|------------|
| 1 | 3, 4, 6 | — |
| 2 | 5, 6 | — |
| 3 | 6, 7 | 1 |
| 4 | 6 | 1 |
| 5 | 7 | 2 |
| 6 | 7 | 3, 4, 5 |
| 7 | — | 6 |

---

## Track 1 — `c35_mod_data_source` crate

### Task 1.1: Scaffold crate

**Files:**
- Create: `servers/crates/mod_data_source/Cargo.toml`
- Create: `servers/crates/mod_data_source/src/lib.rs`
- Modify: `servers/Cargo.toml` workspace members + `server_ai` / `mod_chat` deps

**Exports:** `data_source_sync_run`, `data_source_sync_if_stale`, `data_source_sync_invalidate`, `data_source_prompt_for_bot`, `data_source_chunk_retrieve`, `google_sheet_read_csv`, `parse_sheet_url`.

- [ ] **Step 1:** Add crate to workspace; `pub use` from `lib.rs`.
- [ ] **Step 2:** `cargo build -p c35_mod_data_source` (empty lib compiles).

### Task 1.2: CSV + chunking (port cs_bots)

**Files:**
- Create: `servers/crates/mod_data_source/src/csv.rs`
- Create: `servers/crates/mod_data_source/src/chunk.rs`

Port `parse_csv`, `sheet_csv_chunk_rows`, `snapshot_hash`, `chunk_content_hash` from cs_bots `asset_chunk.rs`.

- [ ] **Step 1:** Unit tests for quoted CSV and row chunk keys.
- [ ] **Step 2:** `cargo test -p c35_mod_data_source csv`

### Task 1.3: Store layer

**Files:**
- Create: `servers/crates/mod_data_source/src/store.rs`

SQL: `data_source_list_for_bot`, `data_source_get`, `data_source_put`, `data_source_soft_delete`, sync upsert, chunk delete/insert, `chunks_full_text`, `chunk_candidates_fts`.

- [ ] **Step 1:** Implement with sqlx; owner_iid checks in callers.
- [ ] **Step 2:** Integration test behind `C35_TEST_DB=1` (optional `#[ignore]`).

### Task 1.4: Google Sheet adapter

**Files:**
- Create: `servers/crates/mod_data_source/src/google_sheet.rs`

Port read URL, optional SA bearer, `parse_sheet_url`, write helpers for append/update (used by tools).

- [ ] **Step 1:** `google_sheet_read_csv(http, config) -> String`.
- [ ] **Step 2:** Test with fixture CSV string (no network).

### Task 1.5: Sync + retrieve

**Files:**
- Create: `servers/crates/mod_data_source/src/sync.rs`
- Create: `servers/crates/mod_data_source/src/retrieve.rs`
- Create: `servers/crates/mod_data_source/src/prompt.rs`

Implement pipeline per [`data_source.md`](../data_source.md). Use `c35_mod_llm::{embed_cached, embed_text, …}` like `mod_chat::memory`.

- [ ] **Step 1:** `data_source_sync_run` happy path + hash-unchanged short circuit.
- [ ] **Step 2:** `data_source_chunk_retrieve` FTS + embed rank with timeout.
- [ ] **Step 3:** `data_source_prompt_for_bot` small vs large sheet branches.

---

## Track 2 — Wire RPC

### Task 2.1: Protobuf

**Files:**
- Create: `_/schemas/proto/c35/data_source.proto`
- Modify: `_/schemas/proto/c35/wire.proto` — add `data_source_list`, `data_source_put`, `data_source_delete`, `data_source_sync` on `WsReq`/`WsRes` (pick unused field numbers after `bot_peer_list = 29`).

`DataSourceDoc`: id, bot_iid, source_kind, name, config_json, sync_status, row_count, synced_ts_ms, updated_ts_ms.

- [ ] **Step 1:** Regenerate Dart + Rust pb (project script / `build_proto` per repo convention).
- [ ] **Step 2:** `cargo build -p c35_wire_types` (or whichever crate hosts pb).

### Task 2.2: RPC handlers

**Files:**
- Create: `servers/crates/mod_chat/src/data_source_rpc.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` — re-export
- Modify: `servers/crates/wire_ws/src/session.rs` — dispatch

Handlers call `mod_data_source` store + `data_source_sync_run` for `data_source_sync`.

Access control: caller == `owner_iid`; verify `bot_iid` owned by caller.

- [ ] **Step 1:** `data_source_list` / `put` / `delete`.
- [ ] **Step 2:** `data_source_sync` returns status row.
- [ ] **Step 3:** `cargo build -p server_ai`.

---

## Track 3 — Bot turn integration

### Task 3.1: Inject prompt block

**Files:**
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs`

After `bot_inst_base`, before `memory_retrieve` (or after memory — pick one and document; **recommended: before memory** so sheet facts stay prominent):

```rust
let ds_block = c35_mod_data_source::data_source_prompt_for_bot(pool, &http, bot_iid, &prompt_text).await;
system = c35_mod_data_source::data_source_prompt_merge(&system, &ds_block);
```

Add `TurnTracer` meta line `data_source` with sync ms / chunk count (optional).

- [ ] **Step 1:** Wire call; empty block when no bindings.
- [ ] **Step 2:** Manual trace: no `gsheet.read` tool hop when answer is in sheet.

### Task 3.2: Home bot prompt (optional same PR or follow-up)

**Files:**
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs` — only if `bot_iid` present on turn

Defer if Home bot does not use `bot_iid` today; document in `data_source.md` if deferred.

- [ ] **Step 1:** Confirm scope with `chat.md` (Home = user prompt only) — **skip v1** unless explicit bot_iid on delegated turns.

---

## Track 4 — LLM tools

### Task 4.1: `gsheet.read` / `append` / `update`

**Files:**
- Create: `servers/crates/mod_chat/src/tools/builtin/gsheet.rs`
- Modify: `servers/crates/mod_chat/src/tools/builtin/mod.rs`
- Modify: tool registry / topic eligibility for bot channel topic

Resolve binding by `bot_iid` from `TurnCtx` (extend `TurnCtx` if needed with `bot_iid: Option<i64>` — channel turn already has bot context).

On append/update: `data_source_sync_invalidate`.

- [ ] **Step 1:** `gsheet.read` returns CSV (prefer post-sync cache metadata in response).
- [ ] **Step 2:** Write tools behind SA env; clear error when path missing.
- [ ] **Step 3:** `cargo test -p c35_mod_chat` if tool tests exist.

---

## Track 5 — Flutter bot UI

### Task 5.1: API client

**Files:**
- Create: `clients/app/lib/c/bot/data_source_api.dart`

Methods: `dataSourceList`, `dataSourcePut`, `dataSourceDelete`, `dataSourceSync`.

- [ ] **Step 1:** Wire to WS invoke matching proto.

### Task 5.2: Replace asset string picker

**Files:**
- Modify: `clients/app/lib/widgets/bots/io_channel_pick_grid.dart` — sheet URL dialog → `config` map
- Modify: `clients/app/lib/widgets/bots/in_bot_create.dart` — on finish, `dataSourcePut` per sheet instead of `meta.assets`
- Modify: `_/specs/ui.md` — bot wizard assets step documents Google Sheet link

Flow: user picks Google Sheets → paste URL → server parses id/gid → `data_source_put` with `bot_iid` after bot created (two-step: create bot, then attach sources, or put with bot_iid on final submit).

- [ ] **Step 1:** List attached sources on bot detail/settings.
- [ ] **Step 2:** "Refresh now" calls `data_source_sync`.
- [ ] **Step 3:** `flutter analyze`.

---

## Track 6 — Tests & observability

### Task 6.1: Rust tests

**Files:**
- Create: `servers/crates/mod_data_source/tests/sync_test.rs`
- Port patterns from `D:\cs_bots\servers\alienai\tests\google_sheet_test.rs` (URL parse only if no DB)

- [ ] **Step 1:** Unit tests always run.
- [ ] **Step 2:** DB integration `#[ignore]` documented in crate README or doc.

### Task 6.2: Log / trace

- [ ] **Step 1:** `tracing::info` on sync: `data_source_id`, `row_count`, `chunks`, `hash_changed`.
- [ ] **Step 2:** Optional `ai.log` trace row kind `data_source_sync` on failure (not event bus v1).

---

## Track 7 — Deploy & E2E

### Task 7.1: Database

- [ ] Apply `_/schemas/data_source.sql` on `c35` YB (btm or dev).

### Task 7.2: Server publish

- [ ] `.\_\scripts\deploy\publish_server.ps1`
- [ ] Set `GOOGLE_SERVICE_ACCOUNT_PATH` on cluster if write tools needed.

### Task 7.3: Manual E2E checklist

- [ ] Create bot, attach public Google Sheet (product FAQ).
- [ ] Telegram message asking specific cell value → answer correct; trace shows `data_source` inject, no remote read per hop.
- [ ] Edit sheet → wait TTL or tap Refresh → new value in reply.
- [ ] `gsheet.append` → row appears in sheet + next turn sees row.

---

## Phase 2 (out of scope for this plan)

**Background sync plan:** [`2026-09-27-data-source-bg-sync-phase2-multitask.md`](2026-09-27-data-source-bg-sync-phase2-multitask.md)

| Item | Notes |
|------|--------|
| `google_slide` adapter | Same tables; new `source_kind` |
| `server_ai` background sync (sharded) | Per-pod scheduler; **not** `c35-fetcher` — see linked plan |
| `bot_data_source` junction | Multi-bot share one sheet |
| SessionInit delta sync | Offline bot settings |
| MCP `data_source_*` tools | Agent ops |

---

## Agent assignment cheat sheet

| Track | Owner focus | Key files |
|-------|-------------|-----------|
| 1 | Rust core | `mod_data_source/**` |
| 2 | Wire | `wire.proto`, `data_source_rpc.rs`, `session.rs` |
| 3 | Turn hook | `channel_prompt_turn.rs` |
| 4 | Tools | `tools/builtin/gsheet.rs` |
| 5 | Flutter | `data_source_api.dart`, bot wizard |
| 6 | QA | tests + tracing |
| 7 | Ops | DDL + publish + E2E |
