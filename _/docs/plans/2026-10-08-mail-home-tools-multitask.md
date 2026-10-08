# Home assistant mail tools — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline.
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/docs/mail.md`](../../../_/docs/mail.md) · [`_/docs/inst.md`](../../../_/docs/inst.md) · [`_/docs/chat.md`](../../../_/docs/chat.md) · [`prompt-run-test.mdc`](../../../.cursor/rules/prompt-run-test.mdc)

**Goal:** Expose platform mail (already on WS via `mod_mail` + `PageMail`) to the **Home assistant** as cluster tools: list mailboxes, list/read messages, send mail, and optional mark-read/archive — with **`ai.inst`** steering and MCP `prompt_compose` / `prompt_run` verification.

**Architecture:**

- **No duplicate mail logic.** New `mail.*` tools in `c35_mod_chat` call the same `MailService` paths as `mail_*_rpc` in `c35_mod_mail` (`list`, `get`, `send`, `mark_read`, `archive_messages`, `mailbox_list` via `mailbox` module).
- **Access** = existing `access::mail_access` (root / partner **or** any `mail.mailbox_member` row). Personal mailbox auto-provision via `ensure_personal_on_first_access` on first use (same as app).
- **Steering** lives in **`ai.inst`** (`inst.sql` seeds + live `inst_put`); tool bodies = JSON schema + `ToolDefinition::description` only (per `prompt-run-test.mdc`).
- **CAS for send attachments:** build `MailCas` from `cas_dir_default()` + env secret (same pattern as `expense.rs` / `img.rs`), not a new `ToolContext` field.

**Tech stack:** Rust `c35_mod_chat` + `c35_mod_mail`, `inst.sql`, optional `mod_chat` integration tests; MCP `prompt_compose` / `prompt_run` (`owner_iid` 33000 regression, 99000 manual).

**CSA note:** `D:\csa_site_published` @ `e34b9bf2` had **RPC + Flutter mail UI**, not Home `mail.*` tools. This plan is **new** assistant surface on top of shipped c35 `mod_mail`.

## Global constraints

- Read `spec.md` and `_/docs/mail.md` before coding; update `mail.md` if tool behavior is normative.
- Do **not** add provider web grounding or Chromium STT (workspace rules).
- Inst steering in **`inst.sql`**; git seed alone is not live — document `inst_put` for deploy.
- Build: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_chat` when tests added.
- Flutter unchanged unless we add chat blocks for mail (out of scope v1).
- Do not commit unless user asks.
- No `mail_domain_*` / `mail_mailbox_admin_*` in Home tools v1 (admin panel / staff tools stay separate).

## Explicitly out of scope (v1)

| Item | Notes |
|------|--------|
| `mail.broadcast` / mailing-list send from chat | App UI only; add v2 if needed |
| Inbound webhook / CF onboard changes | Already M2 |
| Expense auto-parse from `expense@alienai.id` | Separate track in `tx.md`; optional Wave 3 hook only |
| Flutter `PageMail` changes | Tools only |
| Staff `admin.*` mail domain CRUD via assistant | Use admin UI / MCP SQL |

## Tool catalog (v1)

| Tool id | Mutates | Wraps |
|---------|---------|--------|
| `mail.mailbox.list` | no | Personal + site mailboxes caller can access (`mail_mailbox_list_rpc` / `mailbox::list_for_caller`) |
| `mail.list` | no | `MailService::list` — `direction` in \| out, optional `mailbox_id`, `limit`, `before_message_id`, `is_archived` |
| `mail.get` | no | `MailService::get` — full body for one `message_id` |
| `mail.send` | yes | `MailService::send` — `to_addr`, `subject`, `body_text`, optional `body_html`, `mailbox_id`, `attachments[]` (`path` `/fs/...`) |
| `mail.mark_read` | yes | `MailService::mark_read` — optional v1.1 same wave if cheap |
| `mail.archive` | yes | `MailService::archive_messages` — optional v1.1 |

**JSON shape:** Thin LLM-friendly maps (truncate list previews — server already caps list body ~240 chars). Include `mailbox_id`, `message_id`, `from`, `to`, `subject`, `status`, `is_read`, `created_ts_ms`; omit raw HTML in list responses unless `mail.get`.

**Errors:** Return `{ "error": "forbidden" }` / clear message when `mail_access` false; never leak other users’ mailboxes.

---

## Multitask map

```
WAVE 0 — Spec lock (parallel, docs only)
  D1  Update mail.md § Home tools + access matrix
  D2  Inst wording draft (read vs send vs list mailboxes)

WAVE 1 — Server library hook (single track)
  L1  c35_mod_mail: export small helpers for tools (optional protobuf→JSON) + unit test with pool skip/mock

WAVE 2 — Tools + registration (parallel after L1)
  T1  mod_chat builtin mail.rs — list/get/send (+ mailbox.list)
  T2  Register tools in tools/mod.rs dispatcher
  T3  mod_chat Cargo.toml → c35_mod_mail dependency

WAVE 3 — Inst + RAG (parallel with late W2)
  I1  inst.sql: inst.task.mail_read, inst.task.mail_send, inst.task.mail_mailbox
  I2  rag_phrases on ToolDefinition (ID/EN cues)

WAVE 4 — Verification
  V1  Rust: mail_tool_test or tool_exec harness (caller with fixture mailbox)
  V2  MCP prompt_compose + prompt_run phrases (33000)
  V3  UTF-8 check + cargo build server_ai

WAVE 5 — Optional follow-up
  O1  inst.task.mail_expense_ingest pointer (read-only: explain forward to expense@)
  O2  mail.broadcast tool + inst (v2)
```

### Suggested agent assignments

| Wave | Agent | Track | Deliverable |
|------|-------|-------|-------------|
| 0 | A | D1 | `mail.md` tools section |
| 0 | B | D2 | Inst body text in plan → paste into `inst.sql` in I1 |
| 1 | C | L1 | `mod_mail` exports if needed |
| 2 | D | T1–T3 | `mail.rs` + registration + dep |
| 3 | E | I1–I2 | `inst.sql` rows |
| 4 | F | V1–V3 | tests + MCP evidence |

---

## Wave 0 — Docs

### Task D1 — `mail.md` assistant tools section

**Files:** [`_/docs/mail.md`](../../../_/docs/mail.md)

**Add:**

- Table of `mail.*` tool ids and parity with `ReqMail*` RPCs.
- Clarify **Home chat inbox** (`ai.chat` prompt) ≠ **platform mail** (`mail.message`).
- Access: partner/root menu vs mailbox member-only users both use tools when `mail_access` true.
- Send: outbound must use caller-writable mailbox; default personal mailbox when `mailbox_id` omitted.

**Acceptance:** Doc matches intended v1 catalog; no contradiction with `ui.md` Mail entry.

### Task D2 — Inst steering draft

**Content to lock (paste into `inst.sql` in Wave 3):**

| inst id | When | include_tools | Behavior |
|---------|------|---------------|----------|
| `inst.task.mail_read` | User asks to read/check/list email, inbox, unread | `mail.mailbox.list`, `mail.list`, `mail.get`, `mail.mark_read` | List mailboxes if multiple; then list or get; summarize from tool JSON; mark read when user read a specific message |
| `inst.task.mail_send` | User asks to send/compose/reply email | `mail.send`, `mail.mailbox.list` | Confirm to/subject from user text; call `mail.send`; report queued/sent status from tool JSON |
| `inst.task.mail_mailbox` | “What’s my email address?” / which inboxes | `mail.mailbox.list`, `account.get` | Prefer `mail.mailbox.list` for addresses; `account.get` for profile email only |

**Phrases (examples):** `baca email`, `cek inbox`, `kirim email`, `email saya`, `unread mail`, `read my messages`, `send an email to`.

**exclude_tools:** On read inst, exclude `mail.send`; on send inst, exclude `web.search` if needed to reduce derail (mirror `expense` inst pattern).

---

## Wave 1 — `mod_mail` tool surface

### Task L1 — Shared helpers (minimal)

**Files:**

- [`servers/crates/mod_mail/src/lib.rs`](../../../servers/crates/mod_mail/src/lib.rs) — re-export if new module
- Optional: `servers/crates/mod_mail/src/tool_json.rs` — `mail_message_to_json(&MailMessage) -> Value`

**Requirements:**

- Helpers are pure mapping; no new business rules.
- If `MailService` methods are sufficient, skip new module — tools call `MailService::new(pool, Some(cas))` directly.

**Acceptance:** `cargo build -p c35_mod_mail` clean.

---

## Wave 2 — `mod_chat` tools

### Task T1 — `tools/builtin/mail.rs`

**Files:**

- Create [`servers/crates/mod_chat/src/tools/builtin/mail.rs`](../../../servers/crates/mod_chat/src/tools/builtin/mail.rs)
- Edit [`servers/crates/mod_chat/src/tools/builtin/mod.rs`](../../../servers/crates/mod_chat/src/tools/builtin/mod.rs)

**Pattern:** Copy structure from [`bot_inbox.rs`](../../../servers/crates/mod_chat/src/tools/builtin/bot_inbox.rs) + service calls from [`mod_mail/src/rpc.rs`](../../../servers/crates/mod_mail/src/rpc.rs).

**Implementation notes:**

1. `mail_svc(ctx) -> MailService` — `MailCas { pool: ctx.pool.clone(), cas_dir: cas_dir_default(), cas_secret: ... }` (secret from env, same as img tools).
2. `mail.mailbox.list` — call `mailbox` list API used by `mail_mailbox_list_rpc` (factor shared fn in `mod_mail` if rpc inline today).
3. `mail.list` — default `mailbox_id` 0 → personal; `direction` required enum `in` \| `out`.
4. `mail.get` — require `message_id`; optional `mailbox_id`.
5. `mail.send` — require `to_addr`, `subject`, `body_text`; validate write access via `resolve_mailbox(..., write=true)` inside service.
6. Map `String` errors from service to `anyhow` / JSON `{ "error": "..." }`.

**tool! macros:**

- `topics`: include `mail`, `general`
- `rag_phrases`: ID/EN per D2
- `readonly: true` for list/get/mailbox.list; false for send/mark_read/archive

### Task T2 — Dispatcher registration

**File:** [`servers/crates/mod_chat/src/tools/mod.rs`](../../../servers/crates/mod_chat/src/tools/mod.rs)

Register all new tools in `build_default_dispatcher()` near account/drive tools.

### Task T3 — Dependency

**File:** [`servers/crates/mod_chat/Cargo.toml`](../../../servers/crates/mod_chat/Cargo.toml)

Add `c35_mod_mail = { path = "../mod_mail", package = "c35_mod_mail" }` and `c35_mod_file` if not already used for CAS in mail.rs.

**Acceptance:** `cargo build -p server_ai` succeeds.

---

## Wave 3 — `inst.sql`

### Task I1 — Seed rows

**File:** [`_/schemas/inst.sql`](../../../_/schemas/inst.sql)

Insert/update three inst rows from D2 with:

- `kind = 'task'`, `scope = 'home'` (match `inst.task.expense` / `inst.task.bot_inbox` patterns)
- `phrases[]`, `include_tools`, `exclude_tools`, `priority` consistent with neighbors
- `ON CONFLICT (id) DO UPDATE` blocks like existing seeds

**Live deploy note in PR:** run `inst_put` for each id on cluster.

### Task I2 — Tool metadata

Ensure each `tool!` `description` states parameters clearly (inst references tool ids only).

**Acceptance:** `prompt_compose` shows `inst.task.mail_*` + fed tools for sample phrases.

---

## Wave 4 — Verification

### Task V1 — Rust tests

**File:** `servers/crates/mod_chat/tests/mail_tool_test.rs` (new) or extend existing harness.

**Cases (minimum):**

- Tool registration: `mail.list` resolves in dispatcher.
- Exec with `owner_iid` without `mail_access` → error JSON (use 33000 without partner/member if fixture allows).
- Optional: sqlx test with seeded `mail.mailbox` + message if repo has mail fixtures; else document MCP-only verification.

Run: `cargo test -p c35_mod_chat mail_tool` (or full crate).

### Task V2 — MCP prompt pipeline

**owner_iid:** `33000` for regression.

| Phrase | Expect |
|--------|--------|
| `apa email saya di alienai` | `inst.task.mail_mailbox` or read inst; `mail.mailbox.list` fed |
| `baca email terbaru` | `mail.list` hop 1 when fixture has mail |
| `kirim email ke test@example.com subjek halo isi hai` | `mail.send` hop 1 (may fail outbound in dev — assert tool called + queued/failed status in trace) |

Commands: `prompt_compose`, `prompt_run` per `prompt-run-test.mdc`.

### Task V3 — Repo checks

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
cd servers; cargo build -p server_ai
.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed
```

---

## Wave 5 — Optional

### Task O1 — Expense forwarding hint

**Files:** [`_/docs/tx.md`](../../../_/docs/tx.md), optional thin `inst.task.mail_forward_expense`

Steer: “forward receipt to `expense@alienai.id`” — **no parser** in this plan.

### Task O2 — Broadcast tool (v2)

`mail.broadcast` wrapping `broadcast_detailed` — only if product asks; requires `group_id` / mailing list UX in chat.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Partner-only users vs mailbox members | Tools use `mail_access`, not `canUseMail` Flutter gate |
| Send spam / prompt injection | Inst: only send when user clearly requests; optional future confirmation block |
| Large HTML bodies in `mail.get` | Cap `body_html` length in JSON mapper for LLM (e.g. 8k) — document in mail.md |
| Outbound not configured in dev | `prompt_run` asserts tool hop + `failed` status, not delivery |
| Circular dep mod_mail ↔ mod_chat | One-way: mod_chat → mod_mail only |

---

## Definition of done

- [ ] All v1 tools registered and callable via `tool_exec` / Home turn
- [ ] `inst.sql` seeds for read/send/mailbox intents
- [ ] `mail.md` documents assistant tools
- [ ] `prompt_compose` fed tools on sample phrases
- [ ] `cargo build -p server_ai` + relevant tests green
- [ ] Live `inst_put` called out for operator if not auto-deployed
