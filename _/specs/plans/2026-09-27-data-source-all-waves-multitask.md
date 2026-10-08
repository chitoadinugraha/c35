# Bot data sources — all waves (master multitask plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth for progress.
>
> **For Chito:** Review this file **before each wave**. Do not start the next wave until the prior **Review gate** is checked off.

**Goal:** Ship **v1** Google Sheet knowledge (lazy sync, RPC, tools, Flutter) and **v2** sharded background refresh on `server_ai` — never on `c35-fetcher`.

**Specs:** [`_/specs/data_source.md`](../data_source.md) · [`spec.md`](../../spec.md)

| Doc | Scope |
|-----|--------|
| [Phase 1 detail](2026-09-27-data-source-google-sheet-multitask.md) | Tracks 1–7 (v1) |
| [Phase 2 detail](2026-09-27-data-source-bg-sync-phase2-multitask.md) | Tracks 1–6 (bg sync) |
| **This file** | End-to-end waves + review gates |

---

## Roadmap (three phases)

```text
Phase 1 (v1)     Phase 2 (bg)              Phase 3 (later)
────────────     ────────────              ───────────────
DDL + crate      due/claim SQL             JetStream queue
Wire RPC         bg_spawn loop             worker consumer
Turn inject      server_ai wire            SessionInit delta
gsheet tools     index + publish           MCP data_source_*
Flutter UI       2-replica QA              google_slide adapter
Deploy + E2E
```

---

## Global constraints (every wave)

- **Not fetcher:** no `mod_fetch` / `c35-fetcher` tasks for bot sheets ([`fetcher.md`](../fetcher.md)).
- **Build:** `cd servers` → `.cache/server`; `cargo build -p server_ai`; `cargo test -p c35_mod_data_source`.
- **App:** `cd clients/app && flutter analyze` when Flutter touched.
- **DDL:** apply `_/schemas/data_source.sql` on cluster YB before prod E2E.
- **Deploy:** `.\_\scripts\deploy\publish_server.ps1` (arm64 buildkit) after server changes.
- **IDs / hash:** Snowflake ids; Blake3 for content/snapshot hashes.
- **Do not commit** unless user asks.

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **P1-W0** | Docs + DDL in repo | — | — | Spec locked; SQL file exists |
| **P1-W1** | Core crate + wire | A=crate, B=proto/RPC | W0 | `cargo build -p server_ai` |
| **P1-W2** | Turn + tools + UI | C=turn hook, D=tools, E=Flutter | W1 | Bot turn injects sheet block |
| **P1-W3** | QA + ops | F=tests/trace, G=DDL apply + publish + E2E | W2 | Manual Telegram/sheet question works |
| **P2-W0** | Phase 2 spec lock | — | P1-W3 | `data_source.md` bg section |
| **P2-W1** | Store + scheduler | 1=SQL, 2=`bg.rs` | P2-W0 | `cargo test -p c35_mod_data_source` |
| **P2-W2** | server_ai boot | 3=wiring | P2-W1 | BG logs on local boot |
| **P2-W3** | Ops polish | 4=logs, 5=index+env | P2-W2 | Index on YB (optional pre-scale) |
| **P2-W4** | Rollout | 6=integration + 2-pod + publish | P2-W3 | One winner per sync per tick |
| **P3** | (doc only) | JetStream, MCP, slides | P2-W4 | Separate plan when scheduled |

**Parallel dispatch (agents):**

- P1-W1: **A + B**
- P1-W2: **C + D + E** (D after `data_source_sync_run` API stable)
- P2-W1: **1 + 2** (2 stubs until 1 merges)
- P2-W3: **4 + 5**

---

## Progress snapshot (codebase — update when executing)

| Area | Status | Notes |
|------|--------|-------|
| `_/schemas/data_source.sql` | Done in repo | Cluster apply = P1-W3 |
| `c35_mod_data_source` | Done | sync, chunk, google_sheet, prompt, store |
| Wire RPC 161–164 | Done | `data_source_rpc.rs`, `session.rs` |
| `channel_prompt_turn` inject | Done | `data_source_prompt_for_bot` |
| `gsheet.*` tools | Done | `tools/builtin/gsheet.rs` |
| Flutter bot UI | Done | `data_source_api.dart`, create flow |
| `data_source_bg_*` | **Not started** | P2-W1–W4 |
| UTF-16 file corruption | **Fixed** | `mod_data_source` `.rs` + docs re-encoded UTF-8 |

---

# Phase 1 — v1 (Google Sheets)

## P1-W0 — Docs + DDL

- [x] `_/specs/data_source.md` locked
- [x] `_/schemas/data_source.sql`
- [x] `spec.md` + `_/specs/README.md` links
- [ ] **Review gate P1-W0:** spec matches cs_bots behavior you want

---

## P1-W1 — Core + wire (parallel)

### Track A — `c35_mod_data_source`

- [x] Crate in workspace; CSV/chunk/sync/retrieve/prompt/google_sheet
- [x] `cargo test -p c35_mod_data_source` (unit)
- [ ] Fix any UTF-16 corrupted sources (`prompt.rs`, etc.) if build breaks on other machines

### Track B — Proto + RPC

- [x] `data_source.proto`, wire fields, Dart pb
- [x] `data_source_list/put/delete/sync` + owner checks
- [x] `cargo build -p server_ai`

- [ ] **Review gate P1-W1:** RPC list/put/sync from WS or integration test; no fetcher code touched

---

## P1-W2 — Product path (parallel)

### Track C — Channel turn

- [x] `data_source_prompt_for_bot` before memory on channel turn
- [ ] Optional: Home bot / `prompt_turn` same hook (document if skipped)

### Track D — LLM tools

- [x] `gsheet.read` / `append` / `update` + invalidate
- [ ] Trace: append → invalidate → next turn sees row (manual once)

### Track E — Flutter

- [x] Sheet URL on bot create; `data_source_put` + `data_source_sync`
- [x] `flutter analyze` on touched files
- [ ] Bot settings: list sources + manual Refresh (if not in UI yet, add task)

- [ ] **Review gate P1-W2:** Create bot with sheet → ask cell value in channel without `gsheet.read` in trace

---

## P1-W3 — QA + deploy

### Track F — Tests & tracing

- [ ] `tracing::info` on sync: `data_source_id`, `row_count`, hash changed (lazy path)
- [ ] Optional `C35_TEST_DB=1` integration test (insert binding, mock CSV)
- [ ] MCP note: `data_source_*` tools = phase 3 (not blocking v1)

### Track G — Ops

- [ ] Apply `data_source.sql` on `c35` YB (btm)
- [ ] `GOOGLE_SERVICE_ACCOUNT_PATH` or public sheet on cluster
- [ ] `publish_server.ps1` if server changed since last deploy
- [ ] Manual E2E: edit sheet → wait TTL or tap Refresh → bot answer updates

- [ ] **Review gate P1-W3:** v1 live on cluster; lazy sync only (no bg loop yet)

---

# Phase 2 — Background sync (`server_ai`)

Spec: [`data_source.md`](../data_source.md) · Detail: [phase 2 plan](2026-09-27-data-source-bg-sync-phase2-multitask.md)

## P2-W0 — Architecture lock

- [x] Document: bg on `server_ai`, sharded, not fetcher
- [x] Env table: `DATA_SOURCE_BG_*`
- [ ] **Review gate P2-W0:** agree defaults (TTL 120s, tick 30s, batch 8, concurrent 2)

---

## P2-W1 — Store + loop (parallel)

### Track 1 — `store.rs` + `config.rs`

- [ ] `data_source_bg_enabled`, `data_source_bg_tick_sec`, `data_source_bg_batch`, `data_source_bg_max_concurrent`
- [ ] `sync_due_ids(pool, ttl_sec, limit)` with stuck `syncing` guard (5 min)
- [ ] `sync_claim(pool, id) -> bool` sets `status=syncing`
- [ ] Ensure `data_source_sync_run` / `sync_upsert_*` leaves `ok` or `error`, not stuck `syncing`
- [ ] Tests: due vs fresh `synced_ts`; claim exclusivity
- [ ] `cargo test -p c35_mod_data_source`

### Track 2 — `bg.rs`

- [ ] `data_source_bg_sync_one` → claim → `data_source_sync_run` → errors via `sync_upsert_error`
- [ ] `data_source_bg_spawn(pool, http)` — interval tick, semaphore max concurrent
- [ ] Early return when `!data_source_bg_enabled()`
- [ ] Export from `lib.rs`; `cargo build -p c35_mod_data_source`

- [ ] **Review gate P2-W1:** unit tests green; optional local run with fake due row (SQL) shows claim + sync attempt

---

## P2-W2 — `server_ai` wiring

### Track 3

- [ ] `c35_mod_data_source` dep on `server_ai` if needed
- [ ] `main.rs`: after `embed_cache_evict_spawn`, `data_source_bg_spawn(pool, http_client)`
- [ ] Reuse `mod_chat::tools::http_client(60s)`
- [ ] `cargo build -p server_ai`
- [ ] Local: `RUST_LOG=c35_mod_data_source=info`, `DATA_SOURCE_BG_ENABLED=1`

- [ ] **Review gate P2-W2:** single pod ticks without panic; lazy sync on turn still works

---

## P2-W3 — Ops polish (parallel)

### Track 4 — Observability

- [ ] Log prefix `[c35:data_source]`; fields `reason=bg`, `duration_ms`, `hash_changed`
- [ ] No `event_emit` for bg sync in v2 (unless catalog extended later)

### Track 5 — DDL + K8s

- [ ] Add `idx_data_source_sync_due` to `data_source.sql`
- [ ] Apply index on cluster
- [ ] Document `DATA_SOURCE_BG_*` in c35-server deployment (no fetcher changes)

- [ ] **Review gate P2-W3:** grep pod logs for bg completion; index exists on YB

---

## P2-W4 — Rollout

### Track 6

- [ ] `C35_TEST_DB=1`: due + claim (skip live Google if no SA in CI)
- [ ] **Two-replica test:** scale `c35-server` to 2; force old `synced_ts`; one pod syncs per cycle
- [ ] Stale sheet refreshes within ~`TTL + tick` with **no** user message
- [ ] `publish_server.ps1` + Publish summary
- [ ] Confirm `c35-fetcher` deployment unchanged

- [ ] **Review gate P2-W4:** production bg sync signed off

---

# Phase 3 — Out of scope until P2-W4 done

Document only ([`data_source.md`](../data_source.md)):

| Item | Notes |
|------|--------|
| JetStream `C35_DATA_SOURCE_SYNC` | Queue group on `server_ai` worker |
| `google_slide` adapter | Same tables, new `source_kind` |
| `bot_data_source` junction | Multi-bot share one sheet |
| SessionInit delta | Offline bot settings sync |
| MCP `data_source_list` / `data_source_sync` | Agent ops |

- [ ] **Review gate P3:** separate multitask plan when you prioritize this wave

---

## Agent cheat sheet (all waves)

| Wave | Tracks | Primary paths |
|------|--------|----------------|
| P1-W1 | A | `servers/crates/mod_data_source/**` |
| P1-W1 | B | `data_source.proto`, `mod_chat/data_source_rpc.rs`, `wire_ws/session.rs` |
| P1-W2 | C | `mod_chat/channel_prompt_turn.rs` |
| P1-W2 | D | `mod_chat/tools/builtin/gsheet.rs` |
| P1-W2 | E | `clients/app/lib/c/bot/**`, `io_channel_pick_grid.dart`, `in_bot_create.dart` |
| P1-W3 | F,G | tests, `_/schemas/data_source.sql`, publish script |
| P2-W1 | 1,2 | `store.rs`, `config.rs`, `bg.rs` (new) |
| P2-W2 | 3 | `server_ai/src/main.rs` |
| P2-W3 | 4,5 | `bg.rs`, `sync.rs`, deployments |
| P2-W4 | 6 | cluster QA, publish |

---

## Verification quick reference

| After wave | Command / check |
|------------|-----------------|
| P1-W1 | `cd servers && cargo build -p server_ai && cargo test -p c35_mod_data_source` |
| P1-W2 | `flutter analyze` + channel prompt trace |
| P1-W3 | YB tables exist; manual E2E |
| P2-W1 | `cargo test -p c35_mod_data_source` |
| P2-W2 | `cargo build -p server_ai`; local bg logs |
| P2-W4 | 2-pod log check; `publish_server.ps1` |

---

## Success criteria (full program)

1. Bot channel turns load sheet context from YB (FTS/embed), with lazy sync on stale TTL.
2. User can attach sheet at bot create and refresh manually via RPC.
3. `gsheet.append` / `update` invalidate; next turn or bg refresh picks up changes.
4. Background scheduler on every `server_ai` replica refreshes due bindings without duplicate Google export.
5. Fetcher remains FX/catalog only.

---

## Chito sign-off (copy when reviewing)

```
[ ] P1-W0  [ ] P1-W1  [ ] P1-W2  [ ] P1-W3   — v1 ready
[ ] P2-W0  [ ] P2-W1  [ ] P2-W2  [ ] P2-W3  [ ] P2-W4   — bg sync ready
[ ] P3 planned separately
```
