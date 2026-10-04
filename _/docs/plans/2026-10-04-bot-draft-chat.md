# Bot draft from chat

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home chat can draft a chat bot from one purpose, attach Google Sheet / Doc / Slide URLs, and leave the bot off until the user says to turn it on.

**Architecture:** `bot.draft` is the capability. `inst.bot.draft` steers when to call it and tells the model to reply with the tool's `summary`. Pure planning in `bot_draft.rs` decides purpose, name, instruction, access mode, and which question is still missing. The tool writes `identity` (`kind=bot`, `type=chat`, `meta.active=false`) and `ai.data_source` rows. Channel connect stays on the Bots page.

**Tech Stack:** Rust `c35_mod_chat`, `identity_put`, `data_source_put`, `ai.inst` seed, Flutter `bot.draft` block.

## Global Constraints

- Bot row: `kind=bot`, `type=chat`. Channels stay in `meta.channels[]` and are not created from chat.
- Draft `meta.active` is false until `activate` is true.
- `strict_mode` and `auto_block_spammer` stay at identity defaults (true). `web_search` stays false unless the tool argument is true.
- Docs and Slides are always `read_only`.
- Access defaults to `read_only` unless the purpose describes a write. Read and write in one purpose is a split: two bindings, or one question.
- Ask only for a missing slot. Do not ask "want a channel?" or "want a sheet?" before the tool call.
- Reply text is the tool `summary` (id or en from `locale`).

---

### Task 1: Planner

**Files:**
- Create: `servers/crates/mod_chat/src/bot_draft.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`

**Interfaces:**
- Produces: `plan_bot_draft(BotDraftInput) -> DraftPlan`, `draft_summary(...) -> String`

- [x] Unit tests cover: purpose missing (no write), stock read only, reservation write, menu+booking split, doc forced read only, name "Stok Barang", sheet URL requested only when the purpose needs data.

### Task 2: Tool

**Files:**
- Create: `servers/crates/mod_chat/src/tools/builtin/bot_draft.rs`
- Modify: `servers/crates/mod_chat/Cargo.toml`, `tools/builtin/mod.rs`, `tools/mod.rs`

**Interfaces:**
- Consumes: `plan_bot_draft`, `c35_mod_identity::identity_put`, `data_source_put`
- Produces: tool `bot.draft` returning `{ ok, ask, bot_iid, summary, block }`

- [x] Create when purpose is clear, even with no sheet.
- [x] Update when `bot_iid` is set (same owner, `kind=bot`). Do not clear `pic` or `inst_base`.
- [x] Attach each planned sheet via `data_source_put` (`view_url` + `access_mode`).
- [x] Return `{ ok, ask, bot_iid, summary }` for the model to say as the reply.

### Task 3: Steering and UI

**Files:**
- Modify: `_/schemas/inst.sql`, `_/schemas/translation.sql`, `_/docs/identity.md`, `_/docs/inst.md`, `_/docs/ui.md`
- Modify: `servers/crates/mod_chat/tests/compose_test.rs`
- [x] `inst.bot.draft` phrases (id+en), `include_tools: bot.draft`, `exclude_tools: web.search, web.visit`.
- [x] Compose test: "buat bot jawab harga menu" feeds `bot.draft` and drops `web.search`.
- [x] The assistant reply is the tool `summary` (no second card).

### Task 4: Verify

- [x] `cd servers` then `cargo test -p c35_mod_chat bot_draft`
- [x] `cargo test -p c35_mod_chat compose_bot_draft`
- [x] `cargo build -p server_ai`
- [x] UTF-8 check on the edited files
- [x] No Flutter UI change (reply text is the summary)
