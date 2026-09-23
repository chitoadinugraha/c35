# Prompt Run, Subagent Multitask & Computer Use Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Durable server-side prompt execution (JetStream + YB), generic `delegate.run` subagents (topic + goal), billing-safe holds per `req_id`, crash recovery, stop/cancel, safety circuit breakers, research multitask for easy testing, then computer-use subagent.

**Architecture:** `ai.prompt_run` in YugabyteDB is source of truth. JetStream stream `C35_CHAT_PROMPT` subject `c35.prompt.run` dispatches work to queue group `c35-prompt-dispatch`. Live deltas on NATS core `c35.user.{owner_iid}.chat.{chat_id}`. Each run (main or child) is a full `prompt_turn` with `topic_id` + goal text; tools filtered by topic (`*` = any topic; default active topic = `general`). Parent delegates via `delegate.run` tool; child gets own `req_id`, hold, limits. Billing: `billing_gate_with_hold` at start, `billing_usage_report` on success, `billing_reservation_refund` on fail/cancel.

**Tech Stack:** Rust (`mod_chat`, `wire_ws`, `mod_billing`), Flutter (`clients/app`), protobuf (`_/schemas/proto/c35/`), YugabyteDB, NATS JetStream.

## Global Constraints

- Read `spec.md`, `_/docs/chat.md`, `_/docs/billing.md`, `_/docs/remote.md`, `_/docs/inst.md` before coding.
- Default active topic resolves to `general` (not empty string).
- Naming: `ui_` widgets; `l()` / `lError()` on client; contextual `productGet` style on server.
- Verify: `cargo build -p server_ai`; `cargo test -p mod_chat` when tests added; `flutter analyze` in `clients/app`.
- Do not commit unless user asks.
- Subagent model for implementation: **composer-2.5** (not fast).
- `max_turns` default **100**; `max_deliver` JetStream **3**; main tool rounds **24**; computer_use child rounds **16**.

---

## Multitask Map

```
Track 0 (Schema + Proto)  ──┬──► Track 2 (mod_chat prompt_run)
                            ├──► Track 3 (JetStream worker + WS)
                            └──► Track 5 (Flutter proto + fanout)

Track 1 (Inst/Topic/Safety) ──► Track 4 (delegate.run + research)
                            └──► Track 7 (computer_use)

Track 2 + Track 3         ──► Track 4 (delegate.run)
Track 3 + Track 5         ──► Track 6 (Subagent UI card)
Track 4                   ──► Track 7 (computer_use.delegate)
All                       ──► Track 8 (docs + verify)
```

| Track | Focus | Depends |
|-------|-------|---------|
| **0** | `prompt_run.sql`, `chat.proto`, `wire.proto`, schema.rs | — |
| **1** | Topic seeds, inst seeds, device `fail_class`, mention cleanup | — |
| **2** | `mod_chat/src/prompt_run/` CRUD + checkpoint + status | 0 |
| **3** | JetStream consumer, worker loop, WS enqueue, NATS fanout, SIGTERM drain | 0, 2 |
| **4** | `delegate.run` tool, research child, parallel spawn, billing per child | 2, 3 |
| **5** | Flutter: `ReqPromptAbort.req_id`, `PromptRunPush`, WS subscribe | 0 |
| **6** | `ui_subagent_run_card.dart`, stop button, usage per child | 5, 3 |
| **7** | `computer_use` topic, tool confinement, `computer_use.delegate` | 4 |
| **8** | Update `_/docs/chat.md`, `remote.md`; full verify | all |

**Parallel wave 1:** Tracks 0 + 1
**Parallel wave 2:** Tracks 2 + 5 (after 0 proto stable)
**Parallel wave 3:** Tracks 3 + 6
**Parallel wave 4:** Tracks 4 + 7
**Wave 5:** Track 8

---

## NATS & YB (locked)

| Piece | Value |
|-------|--------|
| JetStream stream | `C35_CHAT_PROMPT` |
| Work subject | `c35.prompt.run` |
| Queue group | `c35-prompt-dispatch` |
| ack_wait | 60s (heartbeat extend) |
| max_deliver | 3 |
| Live fanout | `c35.user.{owner_iid}.chat.{chat_id}` |
| Optional trace fanout | `c35.user.{owner_iid}.prompt.{req_id}` |
| State store | `ai.prompt_run` (YB) — **not** NATS KV |

JetStream message body (minimal):

```json
{"req_id":"…","owner_iid":123,"chat_id":456}
```

---

## Track 0 — Schema + Proto

### Task 0.1: `prompt_run.sql`

**Files:**
- Create: `_/schemas/prompt_run.sql`
- Modify: `servers/crates/store/src/schema.rs` (include + apply order after `chat`)

```sql
CREATE TABLE IF NOT EXISTS ai.prompt_run (
    req_id              TEXT PRIMARY KEY,
    chat_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL,
    parent_req_id       TEXT,
    kind                TEXT NOT NULL DEFAULT 'main',
    status              TEXT NOT NULL DEFAULT 'queued',
    topic_id            TEXT NOT NULL DEFAULT 'general',
    device_iid          BIGINT NOT NULL DEFAULT 0,
    text                TEXT NOT NULL DEFAULT '',
    mention_ids_json    JSONB NOT NULL DEFAULT '[]',
    tool_mode           TEXT NOT NULL DEFAULT 'agent',
    model               TEXT NOT NULL DEFAULT '',
    attachments_json    TEXT NOT NULL DEFAULT '[]',
    locale              TEXT NOT NULL DEFAULT '',
    cancel_requested    BOOLEAN NOT NULL DEFAULT FALSE,
    turn_count          INT NOT NULL DEFAULT 0,
    max_turns           INT NOT NULL DEFAULT 100,
    fail_class          TEXT,
    fail_reason         TEXT,
    checkpoint_json     JSONB NOT NULL DEFAULT '{}',
    budget_usd_cap      NUMERIC(12, 6) NOT NULL DEFAULT 0.50,
    accumulated_cost_usd NUMERIC(12, 6) NOT NULL DEFAULT 0,
    tokens_in           INT NOT NULL DEFAULT 0,
    tokens_out          INT NOT NULL DEFAULT 0,
    cost_usd            NUMERIC(12, 6) NOT NULL DEFAULT 0,
    duration_ms         INT NOT NULL DEFAULT 0,
    lease_pod           TEXT,
    lease_expires_ts    TIMESTAMPTZ,
    delivery_count      INT NOT NULL DEFAULT 0,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_prompt_run_status CHECK (
        status IN ('queued','running','waiting_child','done','failed','cancelled')
    ),
    CONSTRAINT chk_prompt_run_kind CHECK (
        kind IN ('main','research','computer_use','site_build')
    )
);

CREATE INDEX IF NOT EXISTS idx_prompt_run_chat ON ai.prompt_run (chat_id, created_ts DESC);
CREATE INDEX IF NOT EXISTS idx_prompt_run_parent ON ai.prompt_run (parent_req_id) WHERE parent_req_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_run_owner_status ON ai.prompt_run (owner_iid, status, updated_ts DESC);
```

### Task 0.2: Proto messages

**Files:**
- Modify: `_/schemas/proto/c35/chat.proto`
- Modify: `_/schemas/proto/c35/wire.proto` (if push on WsRes)

Add to `chat.proto`:

```protobuf
message ReqPromptAbort {
  int64 chat_id = 1;
  string req_id = 2;   // NEW: empty = legacy chat-level abort
}

message PromptRunPush {
  string req_id = 1;
  string parent_req_id = 2;
  string kind = 3;
  int64 device_iid = 4;
  string status = 5;
  string label = 6;
  string topic_id = 7;
  int32 turn_count = 8;
  int32 tokens_in = 9;
  int32 tokens_out = 10;
  double cost_usd = 11;
  int32 duration_ms = 12;
  string fail_class = 13;
  string fail_reason = 14;
}

message PromptRunJob {
  string req_id = 1;
  int64 owner_iid = 2;
  int64 chat_id = 3;
}
```

Add `PromptRunPush prompt_run_push = <next_id>;` to `WsRes` in `wire.proto`.

Regenerate: run existing proto gen script or document manual regen step.

---

## Track 1 — Inst, Topics, Device Safety

### Task 1.1: Topic seeds

**Files:**
- Modify: `_/schemas/topic.sql`

```sql
INSERT INTO ai.topic (id, label_key, inst, extend, sort) VALUES
('computer_use', 'topic.computer_use.label',
 'Desktop automation: always screenshot first, use SoM when stuck, verify each action, stop after 2 identical errors.',
 'general', 30),
('research', 'topic.research.label',  -- already exists, verify
 'Deep research: web.search, web.visit, web.research with citations.',
 'general', 10)
ON CONFLICT (id) DO NOTHING;
```

### Task 1.2: Inst seeds

**Files:**
- Modify: `_/schemas/inst.sql`

- `inst.mention.device_read` — phrases: what's on screen, show screen → `tool_include:device.screenshot`, `tool_exclude:device.input,device.command`
- `inst.task.delegate_research` — triggers delegate for compare/multi-region
- Update `inst.core.assistant` — remove blanket computer-use paragraph (move to computer_use topic)

### Task 1.3: Remove blanket `mention_force_tools` for devices

**Files:**
- Modify: `servers/crates/mod_chat/src/mention_registry.rs`

Only force `device.screenshot` on device mention (not input/command).

### Task 1.4: Device tool `fail_class`

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/device.rs`
- Modify: `servers/crates/mod_device/src/remote_signaling.rs` (map errors)

Return structured JSON:

```json
{"ok": false, "error": "...", "fail_class": "fatal_auth|fatal_offline|fatal_env|transient", "retryable": false}
```

Map: access denied → `fatal_auth`; agent offline → `fatal_offline`; timeout → `transient`.

### Task 1.5: Mark `device.screenshot` readonly

**Files:**
- Modify: `device.rs` tool macro — `readonly: true` on screenshot tool only.

---

## Track 2 — `mod_chat` prompt_run module

### Task 2.1: Create `prompt_run/mod.rs`

**Files:**
- Create: `servers/crates/mod_chat/src/prompt_run/mod.rs`
- Create: `servers/crates/mod_chat/src/prompt_run/store.rs`
- Create: `servers/crates/mod_chat/src/prompt_run/checkpoint.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`

**Interfaces (produces):**

```rust
pub struct PromptRunRow { /* mirrors table */ }

pub async fn prompt_run_insert(pool, row: &PromptRunRow) -> Result<()>;
pub async fn prompt_run_get(pool, req_id: &str) -> Result<Option<PromptRunRow>>;
pub async fn prompt_run_status_set(pool, req_id: &str, status: &str, fail_class: Option<&str>, fail_reason: Option<&str>) -> Result<()>;
pub async fn prompt_run_checkpoint_save(pool, req_id: &str, checkpoint: &Value, turn_count: i32, tokens_in: i32, tokens_out: i32, cost_usd: f64) -> Result<()>;
pub async fn prompt_run_cancel_request(pool, req_id: &str) -> Result<bool>;
pub async fn prompt_run_cancel_children(pool, parent_req_id: &str) -> Result<()>;
pub async fn prompt_run_is_cancelled(pool, req_id: &str) -> Result<bool>;
pub async fn prompt_run_lease_touch(pool, req_id: &str, pod: &str, ttl_secs: i64) -> Result<()>;
pub fn prompt_run_should_stop(row: &PromptRunRow) -> Option<&'static str>; // turn_cap, budget, cancel, fatal checkpoint
```

### Task 2.2: Tests

**Files:**
- Create: `servers/crates/mod_chat/tests/prompt_run_test.rs`

Test: insert → checkpoint → cancel → status transitions.

---

## Track 3 — JetStream Worker + WS

### Task 3.1: JetStream stream bootstrap

**Files:**
- Create: `_/deployments/nats/prompt-stream.yaml` (or document in `_/deployments/nats/README.md`)
- Create: `servers/crates/mod_chat/src/prompt_run/jetstream.rs`

Ensure stream `C35_CHAT_PROMPT` with workqueue retention on `c35.prompt.run`.

### Task 3.2: Worker loop

**Files:**
- Create: `servers/crates/mod_chat/src/prompt_run/worker.rs`
- Modify: `servers/server_ai/src/main.rs` — spawn worker on boot when NATS present

Worker flow:

1. Consume `c35.prompt.run` (queue group `c35-prompt-dispatch`)
2. Load `prompt_run` from YB; if `fail_class` fatal in checkpoint → ACK + fail
3. `delivery_count++`; if `> max_deliver` → fail + ACK
4. `billing_gate_with_hold` (idempotent if already held)
5. Call refactored `prompt_turn` with cancel check + checkpoint save each hop
6. On terminal: settle or refund billing; ACK message
7. Publish `PromptRunPush` + `PromptDelta` to `c35.user.{owner_iid}.chat.{chat_id}`

### Task 3.3: WS enqueue (replace inline spawn)

**Files:**
- Modify: `servers/crates/wire_ws/src/session.rs`

`prompt_req_put`:

1. INSERT `prompt_run` from `ReqPrompt`
2. Publish JetStream job
3. Subscribe fanout (or rely on existing user chat subscription)
4. Remove direct `tokio::spawn(prompt_turn)` (feature flag `PROMPT_RUN_WORKER=1` for gradual rollout optional)

### Task 3.4: Abort by req_id

**Files:**
- Modify: `wire_ws/src/session.rs` — `ReqPromptAbort.req_id`
- Call `prompt_run_cancel_request`; cancel children if parent

### Task 3.5: SIGTERM drain

**Files:**
- Modify: `servers/server_ai/src/main.rs`

On shutdown signal: stop consumer, checkpoint in-flight, do not ACK (let redelivery).

### Task 3.6: NATS fanout helper

**Files:**
- Create: `servers/crates/mod_chat/src/prompt_run/fanout.rs`

`prompt_run_fanout_publish(nats, owner_iid, chat_id, push: PromptRunPush)`

---

## Track 4 — `delegate.run` + Research Multitask

### Task 4.1: Hold constants

**Files:**
- Modify: `servers/crates/mod_billing/src/billing_on_demand.rs` or new constants file

```rust
pub const CHILD_HOLD_USD: f64 = 0.05;
pub const COMPUTER_USE_HOLD_USD: f64 = 0.10;
pub const MAIN_BUDGET_USD: f64 = 0.50;
pub const CHILD_BUDGET_USD: f64 = 0.20;
```

### Task 4.2: `delegate.run` tool

**Files:**
- Create: `servers/crates/mod_chat/src/tools/builtin/delegate.rs`
- Modify: `servers/crates/mod_chat/src/tools/mod.rs`

```rust
// Parent-only tool (topics: general, research, device)
name: "delegate.run"
parameters: {
  topic_id: string required,      // e.g. "research"
  goal: string required,
  kind: string optional,          // default from topic_id
  label: string optional,
  device_iid: integer optional,
  parallel_group: string optional
}
```

Execute:

1. Check `billing_can_afford_tool(owner, CHILD_HOLD_USD)`
2. Create child `prompt_run` row (`parent_req_id = ctx.req_id`)
3. Publish JetStream job for child
4. Wait for child terminal (subscribe or poll YB with timeout)
5. Return `{ ok, summary, child_req_id, tokens, cost, fail_class }`

### Task 4.3: Parallel delegate in parent

Parent LLM may call `delegate.run` multiple times in one hop; worker collects parallel children via `tokio::join` when parent tool handler batches (or sequential wait — v1 sequential OK, parallel v1.1).

### Task 4.4: Research inst

**Files:**
- Modify: `_/schemas/inst.sql`

`inst.mention.research` add: for multi-part questions, call `delegate.run` with `topic_id=research` per sub-question.

### Task 4.5: Tests

**Files:**
- Create: `servers/crates/mod_chat/tests/delegate_tool_test.rs`

Mock pool; verify child row created with parent link.

---

## Track 5 — Flutter Proto + WS

### Task 5.1: Regenerate Dart pb

After proto change, regen `clients/app/lib/c/pb/c35/chat.pb.dart` etc.

### Task 5.2: `ChatConn` handlers

**Files:**
- Modify: `clients/app/lib/c/chat/chat_conn.dart`

- Handle `PromptRunPush` on WS stream
- `promptAbort(chatId, reqId)` pass `req_id`

### Task 5.3: Prompt run store (lightweight)

**Files:**
- Create: `clients/app/lib/c/store/prompt_run_store.dart`

Map `req_id → PromptRunPush` for UI cards.

---

## Track 6 — Subagent UI Card

### Task 6.1: Widget

**Files:**
- Create: `clients/app/lib/widgets/ai/ui_subagent_run_card.dart`

Shows: label, status spinner, stop button, expandable trace (`UiMsgTraceLoader` with child `req_id`), `UiMsgUsage` when `PromptUsagePrefs.showUsageStats`.

### Task 6.2: Integrate in home chat

**Files:**
- Modify: `clients/app/lib/pages/page_ai_home.dart`

When `PromptRunPush` with `parent_req_id` set → render card under streaming assistant message.

### Task 6.3: Tests

**Files:**
- Create: `clients/app/test/ui_subagent_run_card_test.dart`

---

## Track 7 — Computer Use Subagent

### Task 7.1: Confine device tools to `computer_use` topic

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/device.rs`

- `device.screenshot`: `topics: ["*"]`, `always: ["device", "computer_use"]`, `readonly: true`
- `device.input`, `device.command`: `topics: ["computer_use"]`, `always: ["computer_use"]`

### Task 7.2: `computer_use.delegate` alias

Either alias `delegate.run` with `kind=computer_use` or dedicated tool wrapping `delegate.run` with device_iid required.

### Task 7.3: Stricter child limits in worker

When `kind == computer_use`:

- `max_tool_rounds = 16`
- `max_device_input = 12`
- `max_screenshots = 20`
- Error fingerprint ≥2 → fatal

### Task 7.4: Stuck screenshot detection

**Files:**
- Modify: `servers/crates/mod_chat/src/prompt_run/checkpoint.rs`

Store last 3 screenshot hashes; if all equal → inject stop hint / fail `stuck_ui`.

---

## Track 8 — Docs & Verify

### Task 8.1: Docs

- Update `_/docs/chat.md` — prompt_run implementation matches doc
- Update `_/docs/remote.md` — computer_use delegate, multitask definition
- Add `_/docs/prompt-run.md` — architecture reference

### Task 8.2: Verify

```powershell
cargo build -p server_ai
cargo test -p mod_chat
cd clients/app; flutter analyze
cd clients/app; flutter test test/ui_subagent_run_card_test.dart
```

---

## Billing Safety Checklist (every track touching execution)

- [ ] `billing_gate_with_hold(req_id)` at run start (idempotent)
- [ ] `billing_can_afford_tool` before each child spawn
- [ ] `accumulated_cost_usd >= budget_usd_cap` → cancel + refund
- [ ] `billing_reservation_refund(req_id)` on fail/cancel/circuit-break
- [ ] `billing_usage_report` only once per req_id (check reservation status)
- [ ] Parallel children: sum holds must pass `gate_can_start`

---

## Test Prompts (manual QA)

```
@research compare Rust vs Go for CLI tools        → 2 research subagents
@research weather in Jakarta, Singapore, Tokyo   → 3 parallel research children
@Chito-PC what's on screen                       → main, screenshot only
@Chito-PC open Notepad and type hello            → computer_use subagent
Stop child mid-run                               → child cancelled, parent gets partial
Kill server pod mid-run                          → another pod resumes from checkpoint
```

---

## Execution Handoff

**Wave 1 (now):** Tracks 0 + 1 — schema/proto + inst/topic/safety
**Wave 2:** Tracks 2 + 5 — prompt_run module + Flutter proto
**Wave 3:** Track 3 — worker + WS
**Wave 4:** Tracks 4 + 6 — delegate + UI card
**Wave 5:** Track 7 — computer_use
**Wave 6:** Track 8 — docs + verify
