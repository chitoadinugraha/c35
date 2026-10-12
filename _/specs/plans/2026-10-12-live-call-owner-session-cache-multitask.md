# Live Call owner-session hydration (faster setup) — multitask plan

## Implementation status

| Track | Scope | Status |
|-------|--------|--------|
| **L0** | Spec alignment (`live-call.md`, `billing.md`, `log.md`) | **Pending** |
| **L1** | `owner_session` live hydrate API (`mod_chat`) | **Pending** |
| **L2** | `live_start_rpc` early warm + gate from L1 | **Pending** |
| **L3** | Google setup path (primary) | **Pending** |
| **L4** | OpenAI / Grok setup parity | **Pending** |
| **L5** | Mention handover (MBB) reuse hydrate | **Pending** |
| **L6** | `trace_live_setup` + metrics | **Pending** |
| **L7** | Chat tail from session LRU (optional chat_id) | **Pending** |
| **L8** | Tests, verify, `publish_server` | **Pending** |

Encoding: **UTF-8** (no BOM). Run `check_utf8_sources.ps1 -Changed -Fix` after edits.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Locked decisions** before dispatch. **L0 + L1** first. **L3** is the critical path for perceived “call connects faster”. **L4** can lag one wave if Google-only ship is acceptable. **Do not** route Live retail through Alien AI pool or change frontier billing invariants.

**Goal:** Cut **time-to-first-audio** on Live Call by reusing **`OwnerPromptSession` L1** (billing snapshot, memory, scope, user context) and **non-blocking owner-bundle warm**, without merging Live into `prompt_turn` or chat LRU continuity.

**Architecture:** Live stays on `/v1/live/ws` + `mod_live`. At **`ReqLiveStart`** and again at **Gemini `setupComplete`**, read owner bundles from **`owner_session_get(owner_iid)`** when the Home app WS (or headless MCP-style attach) already warmed L1 on **this pod**; otherwise **`owner_session_attach_for_prompt`** + **`owner_session_ensure_owner_warm`** with wait traced **outside** live billing. **Frontier pool** gate unchanged (`live_billing_gate_nats`). Setup work currently duplicated in `google.rs` (`user_prompt_context_get`, cold billing KV, serial DB) moves behind **`live_owner_hydrate`**. Optional: seed **recent chat tail** from session chat LRU when `ticket.chat_id` matches a **Ready** cache entry.

**Tech stack:** Rust (`mod_chat::owner_session`, `mod_live`, `mod_billing`, `wire_ws`), specs [`live-call.md`](../live-call.md), [`chat.md`](../chat.md), [`billing.md`](../billing.md), [`log.md`](../log.md).

**Related:** [`2026-10-12-owner-prompt-session-cache-multitask.md`](2026-10-12-owner-prompt-session-cache-multitask.md) (Home/MCP session), [`live-call.md`](../live-call.md) (MBB, tools, frontier pool).

---

## Global constraints

- **No provider web grounding** on Gemini/OpenAI Live JSON (`web-grounding-cluster-only.mdc`).
- **Live billing:** **Frontier pool only** — do not consume Alien AI allowance for live seconds; do not replace `live_billing_settle` / per-second accrual with prompt-turn token settle.
- **Session lock:** Live Call **must not** call `owner_session_supersede` — only **`owner_session_get`** or **`owner_session_attach_for_prompt`** (headless `headless-live-{owner_iid}` conn_id).
- **UTF-8** sources; `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- **Rust:** `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_chat -p c35_mod_live`.
- **Cluster:** `publish_server.ps1` when shipping; **Publish summary** from `.cache/publish-perf/latest.json`.
- **Talk mode:** unchanged (already uses Home `prompt_turn` + WS session).

---

## Locked product decisions

| Topic | Decision |
|--------|----------|
| Scope of reuse | **Owner bundle only** (billing KV snapshot, memory bundle, scope bundle, `UserPromptContext`). **Not** chat LRU continuity, **not** `TurnContinuity`, **not** full `prompt_turn` prepare. |
| Concurrent Home WS + Live | **Allowed.** Live reads L1 if present; does not tear down app WS session. |
| Live-only (no Home WS) | **Headless warm** at `live_start_rpc` (same as MCP attach), wait up to **`C35_LIVE_BUNDLE_WAIT_MS`** (default **5000**), trace separately. |
| Billing gate at start | Use **`session_billing_snapshot`** → `cached_to_billing_row` when L1 ready; else existing **`billing_cache_get`** / DB path. **Hold + frontier** logic unchanged. |
| Setup tracing | New **`trace_live_setup`** (`kind=system`, `class=trace`, `meta.stages[]` like `trace_stages`). **Not** folded into `trace_prepare` / `llm_turn`. |
| Bundle wait tracing | Reuse **`trace_session_bundle_wait`** when blocking on owner bundle before live setup clock starts. |
| Chat history on live | If `ticket.chat_id > 0` and session chat cache **Ready**, use cached prefetch tail for `live_recent_msgs`; else existing SQL. |
| Device list block | **Keep DB query** in v1 (fresher online bit); optional v2: cache in session from WS warm. |
| Providers | **L3 Google first** (`live_google_proxy_run`); OpenAI/Grok share hydrate helper in **L4**. |

---

## Parallel track map

```text
Track L0 (spec)              Track L1 (hydrate API)
────────────────             ───────────────────────
L0 live-call + billing       L1 live_owner_hydrate.rs
L0 log trace_live_setup      L1 exports + unit tests
                                      |
Track L2 (start RPC)         Track L3 (Google setup)
────────────────             ───────────────────────
L2 warm + gate snapshot      L3 parallel setup + trace
L2 ticket optional session   L3 chat tail from LRU (L7)
                                      |
Track L4 (other providers)   Track L5 (MBB handover)
────────────────             ───────────────────────
L4 openai + grok             L5 reuse hydrate on swap
                                      |
Track L6 (trace)             Track L8 (ship)
────────────────             ───────────────────────
L6 trace_live_setup          L8 integration tests
                             L8 publish_server
```

**Suggested dispatch:** **L0 + L1** parallel → **L2 + L3** parallel → **L5 + L6** → **L4** (optional same release) → **L7** → **L8**.

---

# Track L0 — Spec alignment

- [ ] **L0.1** [`live-call.md`](../live-call.md): new section **Owner session hydration (L1)** — shared RAM with Home WS on same pod; headless warm when Live starts without WS; explicit **non-goals** (no chat continuity, no prompt_turn).
- [ ] **L0.2** [`billing.md`](../billing.md): Live start may read **`BillingGateCached`** from owner session for gate speed; **frontier pool routing unchanged**.
- [ ] **L0.3** [`log.md`](../log.md): document **`trace_live_setup`** and filter examples (`topic = 'trace_live_setup'`, `req_id` = live `req_id`).
- [ ] **L0.4** Cross-link from [`chat.md`](../chat.md) Owner prompt session → Live Call hydration.

**Review gate:** No contradiction with frontier-only Live billing table in `live-call.md`.

---

# Track L1 — Live hydrate API (`mod_chat`)

**Files (create):**

- `servers/crates/mod_chat/src/owner_session/live_hydrate.rs`

**Interfaces (produce):**

```rust
pub struct LiveOwnerHydrate {
    pub user_ctx: UserPromptContext,
    pub memory: Option<UserMemoryBundle>,
    pub scope: Option<ScopeInstructionBundle>,
    pub billing: Option<BillingGateCached>,
    pub session_cache_hit: bool,
}

/// Attach or reuse session; ensure warm; optional wait (ms returned).
pub async fn owner_session_prepare_for_live(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    max_bundle_wait: Duration,
    req_id_for_trace: &str,
) -> (Arc<OwnerPromptSession>, LiveOwnerHydrate, u64);

pub fn live_hydrate_from_session(session: &OwnerPromptSession) -> LiveOwnerHydrate;
```

- [ ] **L1.1** Implement `live_hydrate_from_session` (clone RAM fields; set `session_cache_hit` when billing+memory+scope present).
- [ ] **L1.2** Implement `owner_session_prepare_for_live`: `owner_session_attach_for_prompt` with conn_id prefix `headless-live-{owner_iid}` only when no existing session; `ensure_owner_warm`; `wait_owner_bundle_traced` when `max_bundle_wait > 0`.
- [ ] **L1.3** Env: **`C35_LIVE_BUNDLE_WAIT_MS`** (default **5000**); document fallback to `C35_SESSION_MCP_BUNDLE_WAIT_MS` only if unset (optional).
- [ ] **L1.4** Export from `owner_session/mod.rs` + `lib.rs`.
- [ ] **L1.5** Unit test: hydrate from populated session state; cache_hit flags.

**Review gate:** `cargo test -p c35_mod_chat owner_session`.

---

# Track L2 — `live_start_rpc` (early warm)

**Files:**

- `servers/crates/mod_live/src/rpc.rs`
- `servers/crates/mod_live/src/session.rs` (optional: store `session_revision` on ticket)

- [ ] **L2.1** After offer resolve, **before** `live_billing_gate`: call `owner_session_prepare_for_live` with `max_bundle_wait = Duration::from_millis(C35_LIVE_BUNDLE_WAIT_MS)` and trace req_id = `live_req_id(...)`.
- [ ] **L2.2** Change `live_billing_gate_nats` to accept optional `BillingGateCached` from hydrate; skip `billing_cache_get` when snapshot present (still run **hold** + frontier checks).
- [ ] **L2.3** Pass `Arc<OwnerPromptSession>` into `live_session_register` (ticket field) OR store only `LiveOwnerHydrate` snapshot on ticket if session Arc is awkward across pods — **prefer Arc on ticket** for same-pod handover refresh.
- [ ] **L2.4** Return `ResLiveStart` unchanged on wire; optional internal log line `live_start hydrate wait_ms=… cache_hit=…`.

**Review gate:** `live_start_rpc` tests / manual start with Live enabled; gate still fails closed when quota exhausted.

---

# Track L3 — Google setup hot path

**Files:**

- `servers/crates/mod_live/src/google.rs`
- `servers/crates/mod_live/src/setup.rs` (new — shared setup orchestration)

- [ ] **L3.1** Extract **`live_google_setup_context`** from `live_google_proxy_run` preamble (devices, mention, inst, tools) into `setup.rs` with `StageClock`.
- [ ] **L3.2** Replace `user_prompt_context_get` with **`ticket.hydrate.user_ctx`** (or refresh from session if `session.revision` bumped).
- [ ] **L3.3** Run **independent** work concurrently after hydrate: `live_inst_text`, `live_mention_context`, `staff_view_load`, `site_capability_view_for_mention`, device SQL — use `tokio::join!` where safe.
- [ ] **L3.4** Start **`connect_async(Gemini)`** in parallel with DB-heavy join (MBB spec: minimize dead air — overlap network with hydration).
- [ ] **L3.5** Emit **`trace_live_setup`** once before first audio proxy loop (`meta.stages`: `bundle_wait`, `devices`, `mention`, `inst`, `tools`, `gemini_connect`, `setup_send`).
- [ ] **L3.6** Record `meta.session_cache_hit`, `meta.hydrate_wait_ms` on trace row.

**Review gate:** Compare `trace_live_setup` wall ms before/after on 99000 — target **≥30%** drop on `user_context` + billing gate segment when Home WS was open ≥5s.

---

# Track L4 — OpenAI / Grok parity

**Files:**

- `servers/crates/mod_live/src/openai.rs`
- `servers/crates/mod_live/src/grok.rs`

- [ ] **L4.1** Share `setup.rs` helpers for user_ctx / time_block / device block / site block from `LiveOwnerHydrate`.
- [ ] **L4.2** Same parallel connect + `trace_live_setup` pattern as L3.

**Review gate:** Smoke one non-Google offer in dev if configured.

---

# Track L5 — Mention handover (make-before-break)

**Files:**

- `servers/crates/mod_live/src/google.rs` (handover task)

- [ ] **L5.1** On MBB rebuild, call `live_hydrate_from_session` if ticket still holds `Arc<OwnerPromptSession>` instead of re-querying `user_prompt_context_get`.
- [ ] **L5.2** Re-run mention + caps + tool_select only (not full device list if unchanged — compare `device_iids` hash optional).

**Review gate:** Manual mention switch during call; no regression in `live: make-before-break hot swap completed` logs.

---

# Track L6 — Tracing

**Files:**

- `servers/crates/mod_live/src/trace.rs` (new)
- `servers/crates/mod_log` usage pattern from `owner_session/trace.rs`

- [ ] **L6.1** `live_setup_trace_put(pool, nats, owner_iid, req_id, duration_ms, clock, meta)`.
- [ ] **L6.2** Ensure **`class=trace`**; no NATS user fanout (same as `trace_session_warmup`).

**Review gate:** `log_tail` shows `trace_live_setup` per call; bundle wait remains `trace_session_bundle_wait`.

---

# Track L7 — Chat tail from session LRU (optional same release)

**Files:**

- `servers/crates/mod_chat/src/owner_session/chat_cache.rs`
- `servers/crates/mod_live/src/google.rs` — `live_recent_msgs`

- [ ] **L7.1** Add `chat_cache_history_rows(session, chat_id) -> Option<Vec<HistoryRow>>` when `WarmState::Ready`.
- [ ] **L7.2** In setup, if `ticket.chat_id` matches and cache ready, skip `live_recent_msgs` SQL.

**Review gate:** Live with `chat_id` set on start; `meta.chat_cache_hit` true in `trace_live_setup`.

---

# Track L8 — Tests, verify, ship

- [ ] **L8.1** `mod_live` unit test: `live_billing_gate_nats` uses injected cached billing (no DB mock heavy).
- [ ] **L8.2** Integration-style test: populate `OwnerPromptSession` in registry, call hydrate helper, assert `LiveOwnerHydrate.session_cache_hit`.
- [ ] **L8.3** `cargo build -p server_ai`; `cargo test -p c35_mod_chat -p c35_mod_live`.
- [ ] **L8.4** Manual: Home WS open → start Live → compare `trace_live_setup` vs cold Live-only start.
- [ ] **L8.5** `.\_\scripts\deploy\publish_server.ps1`; Publish summary.

**Review gate:** No change to Talk or Home `trace_stages` regressions; Live frontier billing invariants hold.

---

## Success metrics (Chito / 99000)

| Metric | Where | Target (warm L1) |
|--------|--------|------------------|
| Owner bundle wait | `trace_session_bundle_wait` | 0 ms when WS already warm |
| Live setup wall | `trace_live_setup.duration_ms` | Meaningful drop vs baseline (log compare) |
| Time to `setupComplete` | client / server logs | Lower p50 when app was foreground |
| Billing gate at start | `trace_live_setup` stage `billing_gate` | &lt;200 ms with session snapshot |

---

## Out of scope (v2)

- Caching paired-device rows in L1 (online freshness).
- Cross-pod session (sticky sessions / L2 KV composite for Live).
- Flutter changes (Live UI already shows timer; no new RPC required for v1).
- Merging Live socket with Home WS single connection.

---

## Agent dispatch checklist

1. Read **Locked decisions** + [`live-call.md`](../live-call.md) MBB section.
2. Wave 1: **L0 + L1**
3. Wave 2: **L2 + L3** (+ **L6** trace helper early in L3)
4. Wave 3: **L5**, **L7**, **L4**
5. Wave 4: **L8**

Do not claim done without **`trace_live_setup`** on a real call and before/after timings in the reply.
