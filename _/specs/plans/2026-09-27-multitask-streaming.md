# Multitask message streaming (safe & reliable) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** End-to-end multitask where `delegate.run` children stream live status, text, and trace to the app (per-child stop/state like Cursor), with hard safety limits and no “simulated parallel” when real subagents were eligible.

**Architecture:** Keep `ai.prompt_run` as source of truth and existing `PromptRunPush` + chat fanout (`c35.user.{owner_iid}.chat.{chat_id}`). Close gaps: (1) **steering** so `delegate.run` is fed when user asks to multitask; (2) **fanout** from child insert through terminal status; (3) **client routing** so child `PromptDelta` updates `PromptRunStore`, not only the parent `_promptPending` stream; (4) **rehydrate** children after reconnect; (5) **parent trace** surfaces subagent hops without confusing Prepare `parallel` with multitask.

**Tech Stack:** Rust (`mod_chat`, `wire_ws`), Flutter (`clients/app`), protobuf (`_/schemas/proto/c35/`), YugabyteDB, NATS (core fanout + JetStream `C35_CHAT_PROMPT`).

**Builds on:** [`2026-09-23-prompt-run-multitask.md`](2026-09-23-prompt-run-multitask.md) (worker, delegate, cards). This plan is the **streaming + reliability + UX** slice not fully closed in that doc.

## Global Constraints

- Read `spec.md`, `_/specs/chat.md`, `_/specs/inst.md`, `_/specs/billing.md` before coding.
- Verify: `cd servers && cargo build -p server_ai`; `cargo test -p mod_chat` when tests added; `cd clients/app && flutter analyze` + targeted `flutter test`.
- Subagent model for implementation: **inherit** (not `*-fast`).
- Do not commit unless user asks.
- Safety defaults (locked for this plan): `max_deliver` **3**; child `max_turns` **100**; parent tool rounds **24**; `DELEGATE_WAIT_SECS` **300**; **max 4** parallel `delegate.run` per parent hop; **max delegate depth 1** (child cannot call `delegate.run`).
- `prompt_run.kind` CHECK: `main` | `research` | `computer_use` | `site_build` only — never persist `general` as kind.

---

## Problem statement (current gaps)

| Gap | Symptom |
|-----|---------|
| Inst cache / compose | `inst.task.multitask_delegate` in YB but not in `inst_list_cached` → no `tool_include:delegate.run` |
| RAG trim | `delegate.run` ranked but dropped; web tools win on “multitask” phrasing |
| No fanout on child insert | Cards appear late or missing until worker publishes |
| Child `PromptDelta` routing | Fanout uses child `req_id`; `chat_conn` only appends to `_promptPending[parent]` → **child stream dropped** |
| Inline parent `prompt_run` | Parent row stuck `queued` without `prompt_run_finish` (fix landed in `wire_ws`; verify deployed) |
| Invalid child `kind` | Model passes `kind=general` → DB CHECK failure, no `prompt_run` row → `multitask_real: false` |
| Reconnect | `PromptRunStore` empty; old messages show no subagent cards |
| Trace UX | Prepare `parallel` looks like multitask; parent sheet has no subagent summary |

---

## Target UX (acceptance)

### Message bubble (parent assistant turn)

1. User sends multitask-capable prompt (or `@research` / inst-matched phrase).
2. While parent runs: existing parent thought/stream unchanged.
3. **As each `delegate.run` starts:** one **subagent card** appears under the bubble with label, **Queued → Running → Done/Failed/Cancelled**, spinner while live, **Stop** while live.
4. Expanded card: live thought/text for **that child `req_id`**, usage strip, nested trace sheet.
5. Parent **Stop** cancels parent + all children (`prompt_run_cancel_children`).
6. Final assistant text synthesizes child summaries (or honest limit message for wall-clock demos).

### Trace (parent message sheet)

```
Prepare          (compose_parallel — not multitask)
Tool run         Subagent · research · running · …req_tail  [delegate.run]
Tool run         Subagent · research · done · …req_tail     [delegate.run]
Reply            (parent synthesis)
```

Optional v2 in same plan Track 6: **Multitask** section listing child `req_id` + status with “open child trace”.

### MCP / ops

`trace_get` / `msg_get`: `multitask_real`, `subagents[]`, `subagent_traces{}` (shipped in inst MCP; keep aligned with server fields).

---

## Multitask map

```
Track A (Steering)     ──► Track D (E2E verify)
Track B (Server fanout + safety) ──► Track C (Client streaming)
Track B + Track C      ──► Track D
Track E (Rehydrate)    ──► Track D
Track F (Trace UX)     ──► Track D
```

| Track | Focus | Depends |
|-------|--------|---------|
| **A** | Inst pick + `tool_include` force-feed `delegate.run`; kind normalization | — |
| **B** | Child lifecycle fanout; parent `waiting_child`; caps; depth guard | — |
| **C** | `chat_conn` child delta routing; card ordering; live updates | B (fanout) |
| **E** | Load children from YB/API when opening chat or scrolling history | B |
| **F** | Trace labels, optional multitask section; `concurrent_kind` docs | C |
| **D** | Tests, `prompt_run` MCP regression, `chat.md` | A–F |

**Parallel wave 1:** A + B  
**Parallel wave 2:** C + E  
**Wave 3:** F  
**Wave 4:** D  

## Status (2026-09-27)

- [x] **Track A — Steering (code)** — `inst.task.multitask_delegate`, force-feed `delegate.run`, `prompt_run_kind_normalize`; verified `cargo test -p c35_mod_chat`.
- [ ] **Track A — Ops** — Apply `inst.sql` UPDATE on cluster; inst cache invalidation or server rollout before live `prompt_compose` sees the row.
- [ ] **Tracks B–F (remainder)** — Fanout, client child deltas, rehydrate, trace UX still open (B.2 kind normalize done).

---

## Track A — Steering (real multitask, not simulation)

### Task A.1: Ensure multitask inst is live in runtime cache

**Files:** `_/schemas/inst.sql` (seed already); ops: `inst_put` or migrate apply.

- [ ] Confirm row `inst.task.multitask_delegate` enabled in YB.
- [ ] After apply, hit server with NATS `c35.inst.inst.task.multitask_delegate` invalidation OR rollout restart so `inst_list_cached()` includes it.
- [ ] `prompt_compose` on phrase *"can you multitask 2 time…"* → `inst_ids` contains `inst.task.multitask_delegate`.

### Task A.2: Force-include wins over RAG trim

**Files:** `servers/crates/mod_chat/src/compose/mod.rs`, tests in `servers/crates/mod_chat/tests/mention_registry_test.rs` or new `compose_inst_include_test.rs`.

- [x] When `inst_tool_directives` returns `delegate.run` in **include** list, tool must be in **fed** set even if lexical/vector ranker would trim it (same pattern as existing `always` / mention force tools).
- [x] Test: matched multitask inst + general topic → `selected_tools` contains `delegate.run` (`compose_multitask_inst_force_feeds_delegate_run`).

### Task A.3: Inst copy — wall-clock honesty

**Files:** `_/schemas/inst.sql` body for `inst.task.multitask_delegate`.

- [x] Keep explicit: no fake 1 Hz counters; use `delegate.run` for independent cognitive subtasks or explain limits.

---

## Track B — Server streaming & safety

### Task B.1: Fanout on child insert + status transitions

**Files:** `servers/crates/mod_chat/src/tools/builtin/delegate.rs`, `prompt_run/fanout.rs`, `prompt_run/store.rs`.

- [ ] After `prompt_run_insert` for child, if `ctx.nats` present: `prompt_run_fanout_publish` with status `queued` (and `parent_req_id` on push).
- [ ] On worker status changes (`running`, terminal), publish push again (worker may already; ensure **first** push happens at insert so UI shows card immediately).
- [ ] Set parent `prompt_run` status `waiting_child` while `delegate_run_exec` blocks (update parent row + optional push).

### Task B.2: Normalize / validate child `kind`

**Files:** `delegate.rs`, `prompt_run/store.rs` (`prompt_run_kind_default`).

- [x] If `args.kind` missing or invalid for CHECK constraint, use `prompt_run_kind_default(topic_id)` (e.g. `general` topic → **`main`**, not `general`).
- [x] Reject with clear tool error if model passes unknown kind string before insert.
- [x] Test: `prompt_run_kind_normalize_rejects_general_kind` in `delegate_tool_test.rs`.

### Task B.3: Parallel delegate caps & depth guard

**Files:** `delegate.rs`, `servers/crates/mod_chat/src/prompt/tool_loop.rs` or `ToolContext`.

- [ ] `ToolContext` carries `parent_req_id` + `delegate_depth` (0 on main turn).
- [ ] Child `TurnCtx`: `delegate_depth = 1`; `delegate.run` tool **not registered** or exec returns `fail_class: fatal` “nested delegate not allowed”.
- [ ] Count active children for parent (`queued|running|waiting_child`); if ≥ **4**, bail tool with retryable error.
- [ ] Test: fifth parallel delegate in one hop rejected.

### Task B.4: Inline parent `prompt_run_finish`

**Files:** `servers/crates/wire_ws/src/session.rs` (verify merged).

- [ ] Parent row reaches `done`/`failed`/`cancelled` after inline `prompt_turn`.
- [ ] Integration: YB query after WS turn — parent not left `queued`.

### Task B.5: Child delta fanout (worker)

**Files:** `prompt_run/worker.rs` (already calls `prompt_run_fanout_delta`).

- [ ] Confirm child `req_id` on `WsRes` for deltas (not parent).
- [ ] Add metric/log line when fanout fails (non-fatal but visible in `ai.log` trace).

### Task B.6: Tracer subagent meta (deploy)

**Files:** `turn_tracer.rs` (shipped).

- [ ] `tool_result` for `delegate.run` includes `meta.subagent` + `concurrent_kind: subagent`.
- [ ] Prepare branches use `concurrent_kind: compose_parallel`.

---

## Track C — Client message streaming

### Task C.1: Route child `PromptDelta` to `PromptRunStore`

**Files:** `clients/app/lib/c/chat/chat_conn.dart`, `prompt_run_store.dart`, test `clients/app/test/chat_conn_multitask_test.dart` (new).

- [ ] On `PromptDelta`: if `reqId` matches a known child in `PromptRunStore` **or** `PromptRunStore` has entry with that `req_id`, call `appendDelta(reqId, text, thought)` and **do not** require `_promptPending[reqId]`.
- [ ] If `reqId` is parent’s pending prompt, keep existing behavior.
- [ ] On `PromptEnd`/`PromptFail` for child `req_id`: update push status via new helper or second `PromptRunPush` (prefer push from server; client may patch status from end if needed).

### Task C.2: Parent stream vs child stream ordering

**Files:** `page_ai_home.dart`, `ui_subagent_run_card.dart`.

- [ ] Render `_subagentRunCards` **above** final markdown when streaming (already above content when error; ensure visible during parent `promptBusy` when children exist).
- [ ] Sort children by `created_ts` or stable `req_id` (add optional `seq` to `PromptRunPush` v2 if needed — YAGNI: sort by `req_id` until painful).

### Task C.3: Stop per subprocess

**Files:** existing `promptAbort(reqId: child)` — verify.

- [ ] Manual test: Stop on card → child `cancelled`, parent continues or fails gracefully.
- [ ] Parent stop → children cancelled (server `prompt_run_cancel_children`).

### Task C.4: Blocks / thought on parent only

- [ ] Child `blocks_json` on fanout (if any) stay on child trace; do not merge into parent bubble unless product asks.

---

## Track E — Rehydrate after reconnect

### Task E.1: RPC or WS snapshot for children

**Files:** `_/schemas/proto/c35/chat.proto` (optional `ReqPromptRunList { parent_req_id }`), `wire_ws`, `mod_chat/prompt_run/store.rs`.

- [ ] Add `prompt_run_list_children(pool, parent_req_id)` query (exists pattern in store tests).
- [ ] Expose via WS or REST on chat open / `msg_get` path used by app.
- [ ] Flutter: when building message list, for each assistant `req_id`, fetch children once and `PromptRunStore.put` each `PromptRunPush`.

### Task E.2: Clear store on chat switch

**Files:** `page_ai_home.dart` or `chat_store.dart`.

- [ ] `PromptRunStore.clear()` when changing `chat_id` (avoid wrong parent linkage).

---

## Track F — Trace UX

### Task F.1: Parent trace sheet

**Files:** `clients/app/lib/c/trace/trace_view.dart`, `ui_msg_trace_sheet.dart`.

- [ ] Tool branches: prefer `traceSubagentLabelFromLog` (shipped).
- [ ] Optional section header when ≥1 tool log has `meta.subagent`: **Multitask (N children)** with chips linking to child `req_id` (opens child trace sheet).

### Task F.2: Docs

**Files:** `_/specs/chat.md` (new subsection **Multitask / subagents**).

- [ ] Document wire: `PromptRunPush`, child `PromptDelta` `req_id`, abort, limits.
- [ ] Clarify Prepare `parallel` ≠ subagent multitask.

---

## Track D — Verification

### Task D.1: Rust tests

- [ ] `compose` includes `delegate.run` when multitask inst matches.
- [ ] `delegate` kind normalization + max children.
- [ ] `prompt_run_finish` on inline path (mock pool or integration).

### Task D.2: Flutter tests

- [ ] `chat_conn` routes delta to `PromptRunStore` for child `req_id`.
- [ ] `trace_view` subagent label (existing).

### Task D.3: MCP regression (33000)

```text
prompt_compose { text: "can you multitask…", owner_iid: 33000 }
  → selected_tools contains delegate.run

prompt_run {
  text: "Multitask: two delegate.run topic_id=research — goal1: 2+2 number only; goal2: 3+3 number only",
  mention_ids: ["research"],
  owner_iid: 33000
}

trace_get { req_id: "<parent>", owner_iid: 33000 }
  → multitask_real: true, subagents.length >= 2
  → parent trace has tool/delegate.run with subagent.child_req_id
```

### Task D.4: Manual app checklist (99000)

- [ ] Retry multitask phrase after Track A deployed → cards appear, live text in expand, stop works.
- [ ] Kill WS, reconnect → cards reappear for last turn (Track E).

---

## Safety & reliability checklist (non-negotiable)

| Control | Mechanism |
|---------|-----------|
| Billing | `billing_can_afford_tool` per child spawn; holds per `req_id` |
| Turn/budget caps | Existing `prompt_run_should_stop`, child `budget_usd_cap` |
| No infinite delegate tree | Depth = 1 |
| No spawn storm | Max 4 children per parent per hop |
| No invalid kinds | Normalize to `main` / `research` / … |
| Crash recovery | JetStream `max_deliver` 3; YB `prompt_run` status |
| Cancel | `ReqPromptAbort.req_id` + cancel children |
| No false “parallel” in trace | `concurrent_kind` + docs |

---

## Out of scope (follow-up plans)

- True wall-clock scheduled tasks (1 Hz counter) — use honest UX or future `mod_task` scheduler, not LLM loop.
- Merging full child traces into parent sheet without navigation (optional v2).
- Moving all turns to JetStream-only (inline fallback remains for dev).

---

## File index (primary touchpoints)

| Area | Paths |
|------|--------|
| Delegate + fanout | `servers/crates/mod_chat/src/tools/builtin/delegate.rs`, `prompt_run/fanout.rs`, `worker.rs` |
| Compose / inst | `compose/mod.rs`, `inst_macro.rs`, `inst_cache.rs`, `_/schemas/inst.sql` |
| WS | `servers/crates/wire_ws/src/session.rs` |
| Trace | `servers/crates/mod_chat/src/turn_tracer.rs` |
| Client | `clients/app/lib/c/chat/chat_conn.dart`, `c/store/prompt_run_store.dart`, `widgets/ai/ui_subagent_run_card.dart`, `pages/page_ai_home.dart`, `c/trace/trace_view.dart` |
| Proto | `_/schemas/proto/c35/chat.proto` (only if `ReqPromptRunList` added) |
| Docs | `_/specs/chat.md`, this plan |

---

## References

- Prior plan: [`2026-09-23-prompt-run-multitask.md`](2026-09-23-prompt-run-multitask.md)
- Inst steering: [`_/specs/inst.md`](../inst.md)
- Prompt steering rules: `.cursor/rules/prompt-steering.mdc`
- Device topic plan (stats): [`2026-09-27-device-topic-inst-tool-stats.md`](2026-09-27-device-topic-inst-tool-stats.md) (orthogonal)
