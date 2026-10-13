# Prompt Prepare Pipeline Latency & Unified Embedding — Multitask Plan

## Context & Problem Statement
On prompt execution, turns experienced prepare latencies of 1s to 6.5s due to:
1. **Double Sequential Embedding WAN Calls**:
   - `retrieval_query_embed` requested 256 dimensions for memory RAG.
   - Stage 3 `tool_find_vector` requested 768 dimensions for tool RAG.
   - Both calls ran sequentially, paying double transatlantic/WAN HTTP latency (250–400ms each, up to 1.8s–2.0s under load).
2. **Delayed Embedding Dispatch**:
   - Query embedding did not dispatch until Stage 1 database queries completed.
3. **Session Bundle Wait Polling (25ms sleep)**:
   - `owner_session_wait_owner_bundle` polled in a 25ms `tokio::time::sleep` loop.
   - Sequential warmup in `warm.rs` caused bundle wait timeouts (up to 150ms or cold fallbacks).
4. **Redundant DB Queries Bypassing Warm L1 State**:
   - `user_prompt_context_get` was pre-warmed in `OwnerPromptSession`, but Stage 1 re-queried `ai.identity` and `ai.user_setting` on every turn.
5. **Synchronous Asset Document Embeddings**:
   - Uncached asset candidate documents in `user_asset_rag` blocked the turn for up to a 2500ms timeout.

---

## Architectural Decisions

### 1. Unified Matryoshka Representation Learning (MRL) Embedding
Google Gemini's `text-embedding-004` natively supports Matryoshka embeddings.
- Request **one** 768-dimensional query embedding per turn.
- Tool RAG consumes the full 768-dimensional vector.
- Memory & User Asset RAG consume the first 256 dimensions sliced and L2-normalized (`&v[..256]` via `l2_normalize_256`).
- **Eliminates Call #2 entirely**.

### 2. Early Prefetch at Turn Entry ($t = 0$)
- In `prompt_turn.rs`, spawn the single 768-dim embedding future as soon as `req.text` is normalized (line ~550).
- Runs concurrently while `persist_handle` executes and Stage 1 parallel DB queries resolve.
- By the time Stage 2 and Stage 3 need vectors, the embedding is already resolved or in its final milliseconds.

### 3. Event-Driven `Notify` for Session Bundle Readiness
- Add `bundle_notify: Arc<tokio::sync::Notify>` to `OwnerPromptSession`.
- `warm.rs` notifies all waiters as soon as billing, memory, scope, and user context are populated.
- Replaces the 25ms polling loop with instantaneous ($0\text{ms}$) wakeup.

### 4. Concurrent Warmup in `warm.rs`
- In `owner_session_warm_owner_bundle`, join `billing_cache_warmup`, `memory_bundle_warmup`, `scope_instruction_warm_owner_bundle`, and `user_prompt_context_get` using `tokio::join!`.
- Reduces session warmup wall time from $\sum(T)$ to $\max(T)$.

### 5. L1 Cache Hit for User Context & Last Assistant
- In Stage 1, check `session.read_state().user_ctx`. If present, return in 0ms without querying Postgres.
- In `user_asset_rag`, do not stall turns with 2500ms synchronous embedding timeouts for uncached documents; prioritize cached entries and lexical matching.

---

## Implementation Tracks

- [ ] **Track 1: `OwnerPromptSession` Readiness Event**
  - Add `ready_notify` to `OwnerPromptSession`.
  - Signal `ready_notify.notify_waiters()` in `warm.rs` and update `owner_session_wait_owner_bundle` to await the notify.
  - Parallelize `warm.rs` with `tokio::join!`.

- [ ] **Track 2: Unified Early Query Embedding**
  - Create `UnifiedQueryEmbed` struct holding both 768-dim and MRL 256-dim vectors.
  - Spawn unified embedding at turn entry in `prompt_turn.rs`.
  - Pass the pre-computed 256-dim vector to memory/assets and 768-dim vector to `tool_find_vector` via `ComposeTurnOpts`.

- [ ] **Track 3: Session State Reuse in Stage 1**
  - Read `user_ctx` from `session.read_state().user_ctx` when populated.
  - Cap document embed wait in `user_asset_rag` so missing asset docs don't stall turns for 2.5s.

- [ ] **Track 4: Verification & Benchmarking**
  - Build Rust crates: `cargo build -p server_ai`.
  - Run unit tests: `cargo test -p c35_mod_chat`.
  - Test live prompt turn `"sekarang hari apa"` and verify `trace_stages` wall time.
