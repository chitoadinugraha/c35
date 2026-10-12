# Owner prompt session cache (RAM + L2 NATS) — multitask plan

## Implementation status (2026-10-12)

| Track | Scope | Status |
|-------|--------|--------|
| **S0** | Spec alignment (`chat.md`, `billing.md`, `log.md`, `context-compaction.md`) | **Done** |
| **S1** | `owner_session/*` + registry + tests | **Done** (`owner_session_test.rs`) |
| **S2** | Session lock + `ReqSessionFocus` (`wire_ws`, proto) | **Done** |
| **S3** | `prompt_turn` + `PromptTurnHooks.owner_session` | **Done** |
| **S4** | Session billing + async `billing_cache_put` + post-turn patch | **Done** |
| **S5** | `trace_session_warmup` in warm path | **Done**; composite L2 KV merge optional follow-up |
| **S6** | `bot_session.rs` + `channel_prompt_turn` | **Done** (minimal); task runtime still optional |
| **S7** | Flutter `sessionFocus` + `session_superseded` | **Done** |
| **S8** | CI verify + `publish_server` | **Pending** — run `cargo build -p server_ai`, `cargo test -p c35_mod_chat --test owner_session_test`, `verify_flutter_app.ps1`, then publish |

Encoding: this file is **UTF-8** (no BOM). If an editor shows mojibake, re-open as UTF-8 or run `check_utf8_sources.ps1 -Changed -Fix`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Locked decisions** and **Prerequisites** before dispatch. **Track S0 + S1** first (types + registry, no wire change). **Track S3 + S4** are the critical path for prompt latency and billing safety. **Track S9 (Flutter)** can lag one release if server is backward compatible (session works with focus `chat_id=0` until client ships).

**Goal:** Keep a **server-side** `OwnerPromptSession` on the locked app WebSocket pod: billing snapshot, memory/scope/assets, LRU chat prompt-tails, and **10-message** tool/instruction continuity — so `prompt_turn` reads **RAM** instead of NATS/DB per stage. **Billing settlement and KV write-through stay async**; **no memory/task leaks** on disconnect, supersede, or failed warmups.

**Architecture:** L1 = `Arc<OwnerPromptSession>` owned by the WS handler (`wire_ws`); L2 = optional composite NATS KV snapshot on disconnect/grace (extend `prompt_prepare_cache`); L3 = Yugabyte authority. Warmups are **single-flight** per `(owner_iid)` / `(owner_iid, chat_id)` with explicit `Loading | Ready | Failed` and **no prompt on partial chat rows**. Session **lock** = one active app WS per account (supersede previous). Inspect warmups via **`ai.log`** `topic=trace_session_warmup` (`class=trace`, no NATS fanout).

**Tech stack:** Rust (`mod_chat`, `mod_billing`, `wire_ws`, `c35_nats`, `c35_proto`), Flutter `clients/app`, specs [`billing.md`](../billing.md), [`context-compaction.md`](../context-compaction.md), [`inst.md`](../inst.md), [`log.md`](../log.md), [`nats.md`](../nats.md).

**Related:** [`2026-10-11-user-memory-bundle-mrl256-nats.md`](2026-10-11-user-memory-bundle-mrl256-nats.md), [`2026-10-11-tool-dispatcher-freemium-cache-and-device-presence.md`](2026-10-11-tool-dispatcher-freemium-cache-and-device-presence.md), [`2026-10-11-nats-kv-billing-cache.md`](2026-10-11-nats-kv-billing-cache.md).

---

## Global constraints

- **No provider web grounding** on LLM bodies (`web-grounding-cluster-only.mdc`).
- **UTF-8** sources; `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after edits.
- **Rust:** `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_chat -p c35_mod_billing` for touched crates.
- **Flutter:** `.\_\scripts\dev\verify_flutter_app.ps1` when wire/client changes.
- **Cluster:** `publish_server.ps1` when shipping; **Publish summary** from `.cache/publish-perf/latest.json`.
- **Do not remove** `ai.memory`, `ai.scope_instruction`, billing tables, or `ai.mention_bundle` / `ai.hint_bundle` (composer cold start).
- **Do not commit** unless user asks.

---

## Prerequisites (repo state)

| Piece | Status |
|--------|--------|
| NATS KV billing / memory / scope bundles | Shipped (`billing_cache_*`, `memory_bundle_*`, `scope_inst_*`) |
| Connect warmup tasks | `billing_cache_warmup`, `prompt_prepare_cache_on_connect` (background) |
| Pod-local `ai.inst` | `inst_cache` + NATS invalidation |
| `trace_stages` / `StageClock` | `turn_tracer.rs` |
| Post-turn billing report | Already `tokio::spawn` in `prompt_turn.rs` |

---

## Locked product decisions

| Topic | Decision |
|--------|----------|
| Session lock | **One** active Home app WS per `owner_iid`; new connect **supersedes** old (`WsRes` `session_superseded` or close with known code). |
| Chat LRU | Up to **K** chats (default **8**) touched in **24h** per connection; evict LRU; prompt tail **~30 msgs** + compaction summary (same as `history_prefetch`). |
| UI pagination | `chat_msg_list` lazy pages **do not** extend prompt cache; only **focus** / **first page** / **new message** updates cache. |
| Continuity | **10 user messages** after tool-heavy assistant turn; **no time TTL**; reset on chat switch; store compose hints (`force_tools`, `inst_suffix`, commerce/catalog boosts) — not full tool catalog. |
| Billing on prompt path | **Read** quota/balance/freemium from **session RAM** (0 NATS). **Hold gate:** allowance-fast path = **no DB**; balance/hold path = **at most one** idempotent DB touch before LLM/tool loop, never before parallel prepare if allowance-trusted. **Settle / `billing_cache_put` / `billing_notify`** = **async** after assistant row persisted (existing spawn + session patch). |
| Warmup vs prompt race | Prompt may **wait** up to `C35_SESSION_WARM_WAIT_MS` (default **150**) on focused chat `Loading`; then **degrade** (L2 NATS → DB) or fail closed with user-visible error — **never** compose from partial history. |
| L2 NATS | Keep for reconnect/grace/MCP/bot workers; **stop per-turn KV read** when L1 `Ready`. Optional v2: single `owner_session_{iid}` protobuf snapshot. |
| Bot / task | **Separate** runtime keys (`BotPromptRuntime`, `TaskPromptRuntime`); same patterns, **no** app session lock. |
| Trace | One `ai.log` row per warmup completion: `kind=system`, `meta.topic=trace_session_warmup`, `stages[]` like `trace_stages`. |

---

## Parallel track map

```text
Track S0 (spec)           Track S1 (core session)
────────────────          ─────────────────────────
S0 chat + session doc     S1 Types + StageClock warm
                          S2 Registry + leak guards
                                    |
Track S2 (wire)           Track S3 (prompt_turn)
────────────────          ───────────────────────
S2a Session lock          S3 Read path integration
S2b Focus + warmup RPC    S3 Chat cache + continuity
                                    |
Track S4 (billing async)  Track S5 (trace + L2)
────────────────          ─────────────────────
S4 Gate split + events    S5 Warmup trace log_put
S4 No blocking put        S5 KV write-through
                                    |
Track S6 (bot/task)       Track S7 (client)
────────────────          ─────────────────────
S6 channel + task runtime S7 Flutter focus + supersede
                                    |
                          Track S8 (verify + ship)
                          ─────────────────────
                          S8 Tests leak + latency
                          S8 publish_server
```

**Suggested dispatch:** **S0 + S1** parallel → **S2 + S3** parallel → **S4** → **S5** → **S6** (optional same release) → **S7** → **S8**.

---

# Track S0 — Spec alignment

- [x] **S0.1** Add section **Owner prompt session** to [`chat.md`](../chat.md): L1/L2/L3, session lock, focus RPC, chat LRU, continuity 10 msgs, warmup trace topic.
- [x] **S0.2** Update [`billing.md`](../billing.md) § NATS KV: session RAM is primary on WS; async settle; event patches into session.
- [x] **S0.3** Cross-link [`context-compaction.md`](../context-compaction.md): session cache mirrors compaction-aware tail only.
- [x] **S0.4** Note in [`log.md`](../log.md): `trace_session_warmup` inspection (`log_tail`, SQL filter).

**Review gate:** No contradiction with billing ACID settlement or `billing_usage_dedupe (owner_iid, req_id)`.

---

# Track S1 — Core session runtime (`mod_chat`)

### S1.1 — Types and state machine

**Files (create):**

- `servers/crates/mod_chat/src/owner_session/mod.rs`
- `servers/crates/mod_chat/src/owner_session/state.rs`
- `servers/crates/mod_chat/src/owner_session/chat_cache.rs`
- `servers/crates/mod_chat/src/owner_session/continuity.rs`

**Interfaces (produce):**

```rust
pub enum WarmState { Absent, Loading, Ready, Failed }
pub struct OwnerPromptSession { /* owner_iid, conn_id, billing, memory, scope, assets, chats Lru, focused_chat_id, continuity per chat, revision */ }
pub struct SessionHandle { session: Arc<OwnerPromptSession>, /* abort warmups */ }

pub async fn owner_session_ensure(registry, owner_iid, conn_id) -> Arc<OwnerPromptSession>;
pub fn owner_session_get(registry, owner_iid) -> Option<Arc<OwnerPromptSession>>;

pub async fn chat_cache_warm(session, pool, nats, chat_id) -> Result<()>; // single-flight
pub async fn chat_cache_wait_ready(session, chat_id, max_wait: Duration) -> WarmState;

pub fn session_billing_snapshot(session) -> BillingGateCached; // clone from RAM
pub fn session_memory_retrieve(session, ...) -> MemoryRetrieveResult; // dot product in RAM
```

- [ ] **S1.1** Define `ChatFocusCache` (mirror `HistoryPrefetch` + `bound_device_iid` + sticky meta hash).
- [ ] **S1.2** `TurnContinuity` with `turns_remaining: u8` (init 10), decrement on **user** message in that chat.
- [ ] **S1.3** Unit tests: continuity decay, LRU eviction order, revision monotonicity.

### S1.2 — Registry and leak prevention

**Files:**

- `servers/crates/mod_chat/src/owner_session/registry.rs`

- [ ] **S1.4** `OwnerSessionRegistry`: `DashMap<owner_iid, SessionEntry>` where `SessionEntry` holds `Arc<OwnerPromptSession>`, `conn_id`, `JoinSet` / `AbortHandle` for warmups, `Instant` last_touch.
- [ ] **S1.5** **`owner_session_supersede(owner_iid, new_conn_id)`**: abort all warmup tasks, unsubscribe NATS listeners, drop old `Arc` (old WS gets terminal flag).
- [ ] **S1.6** **`owner_session_drop(conn_id)`** on WS close: if conn still owner of session, schedule teardown (or decrement; with lock, conn is unique owner).
- [ ] **S1.7** Hard caps: `C35_SESSION_MAX_CHATS` (default 8), `C35_SESSION_MAX_MEMORY_ITEMS` (reuse bundle cap), log warn if exceeded.
- [ ] **S1.8** Test: supersede aborts in-flight warmup; registry empty after drop; no orphaned tasks (`tokio::time::pause` + `JoinSet`).

**Review gate:** `cargo test -p c35_mod_chat owner_session`.

---

# Track S2 — Wire protocol + `wire_ws`

### S2a — Session lock

**Files:**

- `_/schemas/proto/c35/session.proto` — `SessionSuperseded`, optional `ResSessionInit.session_epoch`
- `servers/crates/wire_ws/src/session.rs`

- [ ] **S2.1** On WS accept after auth: `owner_session_supersede(caller_iid, conn_id)`; register `SessionHandle` in task-local or struct on connection loop.
- [ ] **S2.2** On WS drop: `owner_session_teardown(conn_id)` — abort warmups, unsubscribe billing/memory/scope fanout for this session.
- [ ] **S2.3** Proto + Flutter: handle superseded (show toast, reconnect or exit).

### S2b — Focus and warmup RPC

**Files:**

- `_/schemas/proto/c35/wire.proto` + `session.proto` — `ReqSessionFocus { chat_id, last_seen_msg_id }`, `ResSessionFocus { warming, revision }`
- `servers/crates/wire_ws/src/session.rs` — handler
- `clients/app/lib/c/chat/chat_conn.dart` — call on thread open

- [ ] **S2.4** `session_focus` validates chat ownership; starts `chat_cache_warm` + updates `focused_chat_id`.
- [ ] **S2.5** `chat_msg_list` handler: after successful first page for `kind=prompt`, **also** `chat_cache_warm` (idempotent).
- [ ] **S2.6** Connect path: replace scattered spawns with `owner_session_warm_owner_bundle` (billing + memory + scope + assets + identity) — still **non-blocking** for `SessionInit` response.

**Review gate:** `cargo build -p server_ai`; manual WS: two tabs → second supersedes first.

---

# Track S3 — `prompt_turn` integration

**Files:**

- `servers/crates/mod_chat/src/prompt_turn.rs`
- `servers/crates/mod_chat/src/context_compact.rs` — `prepare_prompt_history_with_prefetch` from session cache

- [ ] **S3.1** Add optional `session: Option<Arc<OwnerPromptSession>>` to internal prepare path (wire passes from WS; MCP passes `None` → legacy path).
- [ ] **S3.2** Replace `billing_cache_get(nats)` with `session_billing_snapshot` when session present.
- [ ] **S3.3** Replace `memory_retrieve_with_nats` / `scope_instruction_load_for_prompt_nats` with session readers when `Ready`.
- [ ] **S3.4** `history_prefetch`: if `chat_cache_wait_ready` → use cached `HistoryPrefetch`; else existing DB path.
- [ ] **S3.5** `chat_setup`: use cached `bound_device_iid` + sticky meta when chat cache `Ready`; skip redundant SELECTs.
- [ ] **S3.6** Apply `TurnContinuity` before compose (merge `catalog_force_tools` / inst suffix).
- [ ] **S3.7** On successful turn: append user/assistant to chat cache; recompute continuity; **do not** block on this (in-memory only).
- [ ] **S3.8** `trace_stages`: add `meta.session_cache_hit` booleans per stage; `meta.warmup_wait_ms` if waited.

**Review gate:** `prompt_run` / MCP unchanged behavior with `session=None`; compare `trace_stages` before/after on 99000 — `billing_resolve`, `memory`, `history_prefetch` ms drop.

---

# Track S4 — Billing async (no prompt-time bloat)

**Files:**

- `servers/crates/mod_billing/src/billing_cache.rs`
- `servers/crates/mod_billing/src/billing_push.rs`
- `servers/crates/mod_chat/src/owner_session/billing.rs`
- `servers/crates/mod_chat/src/prompt_turn.rs`

**Locked behavior:**

| Step | Sync on prompt critical path? |
|------|-------------------------------|
| Read plan/balance/allowance | **No DB** — session RAM |
| `billing_freemium_applies` | Session RAM (`is_freemium` on snapshot) |
| Allowance ≥ hold | **No DB** — `billing_gate_trusted_allowance_fast` **session variant** (skip `billing_reservation` SELECT if session tracks `recent_req_ids` LRU for idempotency **or** keep single SELECT only when hold required) |
| Balance / hold required | **One** idempotent `billing_reservation` before **tool loop / LLM** — run **in parallel** with compose Stage 1–3 where safe; `tokio::select!` barrier before `prompt_cluster_turn` |
| `billing_cache_put` on miss | Move to **`tokio::spawn`** — never await on turn start |
| Post-turn settle | Keep **`tokio::spawn`**; on success **`session_billing_apply_delta`** + async `billing_cache_put` |

- [ ] **S4.1** `session_billing_apply_delta(session, post_settle_row)` — patch allowance/balance in RAM.
- [ ] **S4.2** Subscribe session to existing billing push path (`billing_notify_owner` / user app fanout): invalidate or patch session on top-up, external consume.
- [ ] **S4.3** Refactor `prompt_turn` billing block: parallel **compose start** + **hold** only when not allowance-trusted; document in code comment.
- [ ] **S4.4** Remove await `billing_cache_put` on turn start (spawn only).
- [ ] **S4.5** Test: freemium + paid allowance paths — 0 `billing_account` queries on turn 2+ with hot session (use query counter mock or integration test with `EXPLAIN` logging flag).

**Review gate:** No double-hold, no settle without hold; `billing_usage_dedupe` still keyed on parent `req_id`.

---

# Track S5 — Warmup trace + L2 write-through

**Files:**

- `servers/crates/mod_chat/src/owner_session/trace.rs`
- `servers/crates/mod_chat/src/prompt_prepare_cache.rs` — delegate to session snapshot put

- [ ] **S5.1** `session_warmup_trace_put(pool, owner_iid, meta)` using `log_put`, `kind=system`, `req_id=warmup:{conn_id}:{run_id}`, `duration_ms`, `stages` from `StageClock`.
- [ ] **S5.2** Log `outcome: cancelled` on supersede abort.
- [ ] **S5.3** On session teardown (grace): optional composite snapshot to NATS (v1: keep existing three buckets; write-through from session bytes).
- [ ] **S5.4** Hydrate L1 from L2 on WS connect when `prompt_prepare_cache_purge_if_expired` allows.

**Review gate:** `log_tail` shows `trace_session_warmup` for connect + focus; `class=trace` not on NATS user fanout.

---

# Track S6 — Bot and task runtimes (same release or +1)

**Files:**

- `servers/crates/mod_chat/src/bot_session.rs` (or `owner_session/bot.rs`)
- `servers/crates/mod_chat/src/channel_prompt_turn.rs`
- `servers/crates/mod_task/` — hook on `task_run` start

- [ ] **S6.1** `BotPromptRuntime` keyed `(owner_iid, bot_iid)`: owner billing snapshot, `memory_bundle` with `bot_iid`, channel chat tail optional.
- [ ] **S6.2** `channel_prompt_turn` use bot runtime when worker process holds it (WA device manager); fallback DB.
- [ ] **S6.3** `TaskPromptRuntime` keyed `(owner_iid, task_run_id)` — minimal; tear down on terminal status.
- [ ] **S6.4** Warmup trace with `meta.runtime: bot | task`.

**Review gate:** Bot channel turn still bills correctly; no global registry leak (task runtime dropped on done).

---

# Track S7 — Flutter client

**Files:**

- `clients/app/lib/c/chat/chat_conn.dart`
- Chat screen / store — on open thread

- [ ] **S7.1** After `SessionInit`, WS stays open; on chat open call `sessionFocus(chatId)`.
- [ ] **S7.2** Handle `session_superseded` — reconnect single flight.
- [ ] **S7.3** Do **not** duplicate server cache client-side (no change to SessionInit payload size).

**Review gate:** `verify_flutter_app.ps1`.

---

# Track S8 — Verification and ship

- [ ] **S8.1** Unit: registry leak, LRU, continuity 10, warmup single-flight, supersede cancel.
- [ ] **S8.2** Integration: connect → focus → two prompts; `trace_stages` regression; `trace_session_warmup` present.
- [ ] **S8.3** Prompt during `Loading`: assert wait or degrade per env; no empty history compose.
- [ ] **S8.4** Load test (optional): 100 connect/disconnect cycles — `OwnerSessionRegistry` len → 0; task count stable.
- [ ] **S8.5** `check_no_provider_grounding.ps1 -Changed` if LLM paths touched.
- [ ] **S8.6** `publish_server.ps1` + **Publish summary**.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Stale billing on second device | Session lock + event patch from `billing_notify_owner` |
| Prompt uses partial warmup | `Loading` barrier + fail closed |
| Memory leak on NATS sub | `owner_session_teardown` drops `Subscriber` with conn |
| Hold race without DB | Barrier before LLM/tools; idempotent `req_id` |
| MCP/regression | `session=None` legacy path until MCP optional warm |

---

## Out of scope (v1)

- Merging NATS buckets into one protobuf snapshot (optional S5 follow-up).
- Removing `ai.mention_bundle` / `ai.hint_bundle`.
- Sticky routing / session migration between pods without L2 hydrate.
- Full `prompt_turn` rewrite for channel bots (S6 minimal).

---

## Execution handoff

After Chito approves this plan, dispatch **one subagent per track** (S0–S8) per `plan-execution.mdc`, model `inherit`, verify per `verify-after-edit.mdc` before merge.
