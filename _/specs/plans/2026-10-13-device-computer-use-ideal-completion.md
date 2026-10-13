# @device computer use — ideal completion (no handoffs, honest status)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **Regression anchor:** Home prompt `@iid:98063412749627392` (VM1) — open Google Forms, create **Test Pendaftaran** with fields **nama**, **gender**, **alamat**. Parent `req_id` `103367660427071488`, child `103367679410491392` (Oct 13 2026): delegate **ok**, tools ran on correct `device_iid`, but child final text was a **give-up** (“Blank form … not responding”) that did **not** match `reply_looks_like_computer_use_handoff` → status **done** → parent echoed incomplete work as success.

**Goal:** Multi-step @device UI goals (forms, wizards, installers) finish on the remote machine when physically possible, or fail with a **clear incomplete** outcome — never “please click” prose and never `ok: true` when the goal was not met.

**Architecture:** Three layers stay separate (per `prompt-run-test.mdc` / `read-spec-before-implement.mdc`):

1. **`ai.inst`** — when to delegate, anti-handoff copy, domain hints (Google Forms tab clutter, keyboard fallbacks). No new Rust phrase lists for non-web tools beyond mechanical gates below.
2. **Mechanical gates (Rust)** — child cannot mark **done** with handoff/give-up text; delegate tool JSON reflects **incomplete**; parent must not parrot child handoffs (`inst.device.operate` already says this — enforce in code).
3. **Client** — long `computer_use` turns must not leave a stale **Connection failed** badge when the server completed (`chat_conn` / `page_ai_home`).

**Tech stack:** `mod_chat` (prompt_run, tool_loop, delegate, computer_use, checkpoint), `_/schemas/inst.sql` + live `inst_put`, Flutter `clients/app`, MCP `prompt_compose` / `prompt_run` (owner **99000**, VM1 mention).

## Global constraints

- No provider web grounding (`web-grounding-cluster-only.mdc`).
- Device steering in **`inst.sql`** + live DB; Rust only for mechanical context and computer_use/web pipelines.
- `device_iid` snowflakes: always `json_device_iid_field` + `device_iid_resolve` on delegate children (`mention_ids` sync already added — keep covered by tests).
- UTF-8 sources; verify per `verify-after-edit.mdc` (`cargo build -p server_ai`, `compose_test` / `delegate_tool_test`, `verify_flutter_app.ps1` for client).
- Chito device MCP tests: `owner_iid=99000`, VM1 `98063412749627392` (`device-control-chito.mdc`).
- Do not commit unless the user asks.

---

## Success criteria (acceptance)

| Check | How |
|-------|-----|
| Child uses VM1 `device_iid` on every `device.*` hop | Trace / `tool_exec` args |
| No final assistant text asking the user to click/type through UI | `prompt_run` child summary + parent `text` |
| Delegate `ok: false` when child gave up or handoff phrasing | `computer_use.delegate` tool result JSON |
| Parent states outcome honestly (“could not complete …”) without numbered user steps | `prompt_run` parent |
| Optional stretch: form visible on VM1 with title + 3 fields | Manual screenshot on device |
| App chat: no false **Connection failed** when `ai.chat_msg` has assistant row for `req_id` | Repro + fix |

**MCP golden phrase (run before/after each wave):**

```text
@iid:98063412749627392 buka google form, buat form baru dengan judul Test Pendaftaran, dengan field nama, gender, alamat
```

Assert: `inst.device.operate` in `inst_ids`; `computer_use.delegate` **fed**; child has `device.screenshot` + `device.input`; parent `text` does not match handoff/give-up patterns; delegate `ok` matches goal completion policy.

---

## Problem map (gaps vs ideal)

| Gap | Evidence | Layer |
|-----|----------|--------|
| Give-up prose not detected | Child ended with “not responding” / “multiple tabs” — not in handoff list | `computer_use.rs` |
| `ok: true` when summary incomplete | `delegate_result_json` uses `status == "done"` only | `delegate.rs` |
| Parent echoes child | Parent LLM after successful delegate | inst + optional parent mechanical wrap |
| Handoff retry may exhaust rounds then accept bad text | `tool_loop` `continue` without terminal fail | `tool_loop.rs` + prompt_run finish |
| Forms-specific friction (tabs, template gallery) | Child re-ran `shell.run` chrome, repeated clicks | `inst` playbook |
| False connection failed | WS drop during long turn | Flutter chat |

---

## File map

| File | Responsibility |
|------|----------------|
| `servers/crates/mod_chat/src/prompt/computer_use.rs` | Handoff + **incomplete/give-up** detection, shared hints |
| `servers/crates/mod_chat/src/prompt/tool_loop.rs` | Reject bad final text; cap handoff retries → force tool hop or fail |
| `servers/crates/mod_chat/src/prompt_run/worker.rs` | On finish: block `done` if final msg incomplete (computer_use) |
| `servers/crates/mod_chat/src/prompt_run/checkpoint.rs` | Optional: treat “N handoff rejects” like stuck_ui |
| `servers/crates/mod_chat/src/tools/builtin/delegate.rs` | `ok`, `goal_met`, `incomplete_reason` from child summary + status |
| `_/schemas/inst.sql` | `inst.device.operate`, `inst.computer_use`, optional `inst.device.google_forms` |
| `servers/crates/mod_chat/tests/delegate_tool_test.rs` | Delegate JSON when summary handoff |
| `servers/crates/mod_chat/tests/computer_use_completion_test.rs` (new) | Phrase unit tests |
| `clients/app/lib/c/chat/chat_conn.dart` | Reconcile pending prompt on reconnect / msg pull |
| `clients/app/lib/pages/page_ai_home.dart` | `_promptCutOnDisconnect` vs server completion |
| `_/specs/remote.md` | Document completion semantics for `computer_use.delegate` |
| `_/scripts/deploy/` or dev | `inst_put` path when NATS unavailable from laptop |

---

## Wave 1 — Truthful completion (server, parallel tracks)

### Track A: Detection (`computer_use.rs`)

**Files:**
- Modify: `servers/crates/mod_chat/src/prompt/computer_use.rs`
- Create: `servers/crates/mod_chat/tests/computer_use_completion_test.rs`

**Interfaces:**
- Produces: `reply_looks_like_computer_use_incomplete(text: &str) -> bool` (give-up: “blocked by”, “not responding”, “unable to”, “could not complete”, “multiple tabs”, “template is not”, Indonesian equivalents).
- Produces: `computer_use_final_text_acceptable(text: &str) -> bool` = not handoff and not incomplete.

- [ ] **Step 1:** Add failing tests for Oct 13 child snippet and for good completion sentence.
- [ ] **Step 2:** Implement detectors; extend `reply_looks_like_computer_use_handoff` only where clearly user-directed (keep list maintainable — prefer `incomplete` for model give-up).
- [ ] **Step 3:** `cargo test -p c35_mod_chat computer_use` from `servers/`.

### Track B: Child cannot finish “done” with bad text (`tool_loop.rs` + `worker.rs`)

**Files:**
- Modify: `servers/crates/mod_chat/src/prompt/tool_loop.rs` (~704–720)
- Modify: `servers/crates/mod_chat/src/prompt_run/worker.rs` (status transition before `prompt_run_finish`)

**Behavior:**
- In `tool_loop`, count handoff/incomplete rejects per turn; after **3** rejects without a tool call, inject a stronger user part: “You must call device.screenshot or device.input now — final text without a tool is not allowed until the goal is done.”
- If at **round cap** final text still fails `computer_use_final_text_acceptable`, do **not** return success text — return a fixed assistant message: “Automation stopped before completing: …” (no user steps) and set checkpoint fatal class `fatal_incomplete` (new) or reuse `stuck_ui`.

- [ ] **Step 1:** Unit test in `tool_loop` or `computer_use_completion_test` for reject counting logic (extract small fn if needed).
- [ ] **Step 2:** Wire worker to map `fatal_incomplete` → `status=failed`, `fail_class=fatal_incomplete`.
- [ ] **Step 3:** Re-run MCP golden `prompt_run`; child should be **failed** or complete with good text — not **done** + give-up.

### Track C: Delegate tool honesty (`delegate.rs`)

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/delegate.rs` (`delegate_result_json`)
- Modify: `servers/crates/mod_chat/tests/delegate_tool_test.rs`

**Produces:** JSON fields:

```json
{
  "ok": false,
  "goal_met": false,
  "incomplete": true,
  "incomplete_reason": "child_summary_handoff_or_give_up",
  "summary": "...",
  "status": "done|failed|cancelled"
}
```

- `ok` = `status == "done" && goal_met`
- `goal_met` = `computer_use_final_text_acceptable(summary)` when `kind == "computer_use"` (else `status == "done"`).

- [ ] **Step 1:** Test `delegate_result_json` with handoff summary + `status=done` → `ok: false`.
- [ ] **Step 2:** Implement; ensure `computer_use.delegate` and `delegate.run` share helper.
- [ ] **Step 3:** `cargo test -p c35_mod_chat delegate`.

---

## Wave 2 — Better automation (inst + compose)

### Track D: Live inst + Forms playbook (`inst.sql`)

**Files:**
- Modify: `_/schemas/inst.sql` — `inst.computer_use`, `inst.device.operate`
- Optional new row: `inst.device.google_forms` (task, `topics: {device}`, phrases: `google form`, `forms.google`, `buat form`, priority 158)

**Inst content (English, seed):**
- Before clicking templates: `device.screenshot` som=true; prefer **one** Chrome window — `shell.run` to focus or close extra tabs only when screenshot shows tab strip clutter.
- Template gallery: click **Blank** / **Blank quiz** via som badge or `device.input` keyboard (Tab to template, Enter) if click misses twice.
- After editor opens: set title, add questions via **+** / “Add question”, field types Short answer / Multiple choice for gender.
- Explicit: opening `forms.google.com` is **not** completion.

**Deploy:**
- [ ] Run seed migration path used by cluster OR document `inst_put` from pod with NATS (agent env failed before).
- [ ] `prompt_compose` golden phrase → `inst.device.operate` + forms inst if added.

### Track E: Parent hop after delegate (inst-only first; mechanical if needed)

**Preferred:** Strengthen `inst.device.operate` body:

- If `computer_use.delegate` returns `goal_met: false` or `incomplete: true`, hop 2: either **one** retry delegate with narrowed goal (“close extra Chrome tabs, open blank form, set title …”) OR reply: “I could not finish on VM1: …” — **never** paste child’s click instructions.

**If model still handoffs after inst live:**

- [ ] Add small Rust helper in parent tool result formatting (where delegate JSON is injected into context) appending: `SYSTEM: delegate incomplete — do not instruct user to click; state failure briefly.`
- [ ] Avoid `compose_force` unless `prompt_compose` shows delegate not **fed** on hop 1.

---

## Wave 3 — Agent + client reliability

### Track F: VM1 agent UX (optional, if clicks miss)

**When:** Screenshots show correct page but clicks ineffective.

- [ ] Verify `screenshot_after` marker feedback in trace; if markers wrong, open issue in `mod_device` / agent input path (`_/specs/remote.md`).
- [ ] Consider default `som: true` for `device.screenshot` in `computer_use` topic only (tool default or inst — not global Home).

### Track G: Flutter “Connection failed” reconciliation

**Files:**
- `clients/app/lib/c/chat/chat_conn.dart` (`_failAll`, reconnect)
- `clients/app/lib/pages/page_ai_home.dart` (`_promptCutOnDisconnect`)

- [ ] On WS reconnect, for each pending `req_id`, `msgsPullFromServer` / lookup assistant msg; clear error if `error_text` empty and assistant exists.
- [ ] Do not call `_failAll` for prompts older than X s if server stream still active (narrow scope — test with 40s computer_use).

- [ ] `.\_\scripts\dev\verify_flutter_app.ps1`

---

## Wave 4 — Verification & docs

- [ ] `cd servers && cargo build -p server_ai && cargo test -p c35_mod_chat`
- [ ] Restart local `server_ai` on `:10000`; MCP `prompt_run` golden phrase (99000).
- [ ] Manual: VM1 desktop shows form or clear failure in chat.
- [ ] Update `_/specs/remote.md` § computer use: `goal_met`, incomplete delegate, child `failed` vs parent messaging.
- [ ] Cluster: publish server image + `inst_put` job after merge.

---

## Self-review (spec coverage)

| Requirement | Task |
|-------------|------|
| No user handoff | A, B, D, E |
| Correct device_iid | Existing tests + golden MCP |
| Honest ok/fail | C, B |
| Forms scenario | D, golden MCP |
| Connection failed | G |
| Inst live on cluster | D deploy step |

---

## Execution order (recommended)

```text
Wave 1 (parallel): A + B + C  →  MCP golden (expect honest fail or real complete)
Wave 2: D → E → MCP golden again
Wave 3: G (F only if clicks still miss in trace)
Wave 4: docs + cluster
```

**Out of scope (unless user asks):** Unified extension `browser.page.act` for Forms (extension not required for desktop Chrome UI); full visual LLM judge of “form complete”; increasing `COMPUTER_USE_MAX_*` caps without evidence of turn_cap stops.
