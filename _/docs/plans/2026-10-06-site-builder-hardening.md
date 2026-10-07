# Site builder & catalog follow-up hardening

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Home chat site creation/editing and catalog-add confirmation reliable: forced builder tools reach the model, hop-1 `site.create` when appropriate, and a bare *ya* after catalog confirm still gets `site.product_put`.

**Architecture:** Fix compose to inject inst-forced tools from the **full tool catalog** (not mention-filtered). Add `compose_force_site_builder` like presentation. Add `catalog_add_followup` in `prompt_turn` using last assistant turn + affirmation text. Update docs; verify with `cargo test` and MCP `prompt_compose` / `prompt_run`.

**Tech Stack:** Rust `c35_mod_chat`, `ai.inst` seeds, `_/docs/site-ai.md`, cluster `publish_server.ps1`.

## Global Constraints

- Inst steers when/how; do not duplicate long steering in Rust except mechanical follow-up detection.
- `site.create` stays `requires_kinds: []`; patch/publish/handle may stay `requires_kinds: ["site"]` but must be **fed** when `inst.site.builder` matches.
- Catalog follow-up: only short affirmations after a prior assistant catalog-confirm question (no global *ya* inst).
- Verify: `cargo test -p c35_mod_chat`, `cargo build -p server_ai`, UTF-8 check on edited sources, `prompt_run` on cluster after publish.

---

### Task 1: Compose force-inject from full catalog

**Files:** `servers/crates/mod_chat/src/compose/mod.rs`, `servers/crates/mod_chat/tests/compose_test.rs`

- [ ] Keep `tool_catalog` clone before `tool_mention_eligible` filter.
- [ ] Pass `tool_catalog` to `compose_inject_force_tools` (and bot web inject if needed).
- [ ] Test: `inst.site.builder` + no @site → `site.patch` and `site.create` both in `out.tools`.

### Task 2: Force hop-1 `site.create` for builder inst

**Files:** `servers/crates/mod_chat/src/compose/mod.rs`, `servers/crates/mod_chat/src/prompt_turn.rs` (already uses `compose_force_tool_call`)

- [ ] Add `compose_force_site_builder_tool_call` when `inst.site.builder` and `site.create` fed.
- [ ] Wire into `compose_force_tool_call`.
- [ ] Compose test optional; rely on `prompt_run` for E2E.

### Task 3: Catalog add *ya* follow-up

**Files:** `servers/crates/mod_chat/src/catalog_add_followup.rs` (new), `lib.rs`, `prompt_turn.rs`

- [ ] `catalog_add_followup_boost(last_assistant, user_text) -> Option<CatalogAddFollowup>` with inst snippet + force `site.product_put`.
- [ ] `prompt_turn`: load last assistant msg in `chat_id`; apply boost via `ComposeTurnOpts.extra_tool_include` + append inst block.
- [ ] Unit tests: affirm after confirm question → boost; random *ya* → none.

### Task 4: Docs

**Files:** `_/docs/site-builder.md`, `_/docs/site-ai.md`, `_/docs/inst.md`

- [ ] Mark site-builder spec **Shipped**; note compose inject + catalog follow-up.
- [ ] Document catalog *ya* behavior in site-ai.md (replace “not implemented” note).

### Task 5: Verify & deploy

- [ ] `cargo test -p c35_mod_chat`
- [ ] `cargo build -p server_ai`
- [ ] `publish_server.ps1`
- [ ] `prompt_compose` / `prompt_run` for `buat website "Kopi Senja"` and catalog confirm path if feasible
