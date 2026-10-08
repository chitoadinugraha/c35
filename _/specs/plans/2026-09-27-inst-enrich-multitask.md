# Inst enrich (`inst_enrich`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When phrase-matched inst rows apply (e.g. `inst.consumption_coach` for “enaknya makan apa”), inject **factual DB context** into the system prompt at compose time so the model can answer without relying on a first-hop `consumption.today` tool call.

**Architecture:** Keep **Type B** inst bodies in `ai.inst` (steering text). Add a Rust **`inst_enrich`** registry (not a revived `inst!` macro with inline `txt`) — map `inst.id` → async enricher fn that returns a compact JSON/markdown block appended under `[ENRICH:<key>]\n…` inside `inst_block`. Run enrichers only for **matched** inst rows during `compose_tools_and_inst_async` (Home + MCP `prompt_compose`). Record enrich ids + timing on `ComposeTrace` for debugging.

**Tech Stack:** Rust `mod_chat`, `mod_consumption`, YugabyteDB, MCP `prompt_compose` / `prompt_run`.

## Global Constraints

- Read `spec.md`, [`_/specs/inst.md`](../../_/specs/inst.md) compose section, [`.cursor/rules/inst.mdc`](../../.cursor/rules/inst.mdc) before coding.
- **Type B steering stays in SQL** — enrichers inject **data**, not new hardcoded persona strings in Rust.
- Inst match remains **phrase / mention / topic / trigger** (no vector inst in this plan).
- Verify server: `cd servers && cargo build -p server_ai` and `cargo test -p c35_mod_chat`.
- Verify steering: MCP `prompt_compose` then `prompt_run` with `owner_iid=99000`, text `Enaknya aku makan apa?` — assert `trace` shows `inst.consumption_coach` and enriched block contains `calories_remaining` (or equivalent keys).
- Subagent model: **`inherit`** (never `*-fast`).
- Do not commit unless user asks.

---

## Multitask Map

```
Track 1 (consumption enrich API) ──► Track 2 (inst_enrich registry)
                                              │
Track 3 (compose wire + trace) ◄──────────────┘
         │
         ├──► Track 4 (inst.sql + docs)
         └──► Track 5 (tests + MCP verify)
```

| Track | Focus | Depends | Parallel wave |
|-------|--------|---------|---------------|
| **1** | Extract `consumption_coach_enrich` in `mod_consumption` (shared with tool compact shape) | — | **Wave 1** |
| **2** | `inst_enrich.rs` registry + `inst_block_with_enrich` | 1 | **Wave 2** |
| **3** | `compose_tools_and_inst_async` + `prompt_turn` ctx (`owner_iid`, `locale`) | 2 | **Wave 2** |
| **4** | Seed wording + [`_/specs/inst.md`](../../_/specs/inst.md) “Enrich layer” section | 2 | **Wave 3** |
| **5** | Unit/integration tests + `prompt_compose` / `prompt_run` checklist | 3, 4 | **Wave 3** |

**Wave 1:** Track 1  
**Wave 2:** Tracks 2 + 3 (same agent OK if small; prefer 2 subagents)  
**Wave 3:** Tracks 4 + 5  

---

## Locked design

### Enrich block format (system prompt)

After existing `inst_matched_prompt` output:

```text
[INST:inst.consumption_coach]
…seed body from ai.inst…

[ENRICH:consumption.nutrition]
{"day_id":"2026-09-27","calories_remaining":…,"protein_deficit_g":…,"current_meal_slot":"…","recent_frequent_foods":[…]}
```

- `[ENRICH:…]` keys are stable telemetry ids (`consumption.nutrition`), not inst ids.
- Serialize with `serde_json` compact (no pretty print) to save tokens.
- On DB error: omit enrich block for that enricher; log warn; do not fail the turn.

### Registry (Rust)

File: `servers/crates/mod_chat/src/inst_enrich.rs`

```rust
pub struct InstEnrichCtx<'a> {
    pub pool: &'a PgPool,
    pub owner_iid: i64,
    pub locale: &'a str,
    pub user_text: &'a str,
}

pub async fn inst_enrich_append(matched: &[InstRow], ctx: &InstEnrichCtx<'_>) -> (String, Vec<String>, i64);
// Returns (appendix, enrich_keys, duration_ms)
```

Static map (phase 1 — no SQL column yet):

| `inst.id` | Enricher key | Handler |
|-----------|--------------|---------|
| `inst.consumption_coach` | `consumption.nutrition` | `consumption_coach_enrich` |

Phase 2 (optional follow-up): `ai.inst.enrichers TEXT[]` for MCP visibility only; runtime still dispatches via Rust map validated against ids.

### DB queries (Track 1 — document for perf)

Per `consumption_coach_enrich` call (same order of magnitude as `consumption.today` tool with `days: 3`):

| Query / call | Purpose |
|--------------|---------|
| `nutrition_sum_day` | Today macros + meal count |
| `prefs_calorie_goal` | Calorie goal |
| `food_list_day` (today) | Meals list for names / slots |
| `food_list_day` (multi-day window) | `recent_frequent_foods` when `days > 1` |

**Total: ~3–4 SQL round-trips** per enriched turn (one compose, not per trace poll). Acceptable vs extra LLM tool hop (~3s).

### Compose trace

Extend `ComposeTrace` in `compose/mod.rs`:

```rust
pub inst_enrich_keys: Vec<String>,
pub inst_enrich_ms: i64,
```

Persist in turn tracer meta under `trace_prepare` / compose hop (follow existing `inst_ids` pattern).

### What we are **not** doing in this plan

- Vector search for inst rows (future; tools already use vector RAG).
- Purchase / product vector enrich (stub hook only — register no-op or skip).
- Flutter changes (trace loading UX already improved separately).
- Removing `consumption.today` tool or `tool_include` — enrich **complements** tools; optional later: drop forced tool loop for recommendation phrases once enrich is proven.

---

## Track 1 — Consumption enrich API

### Task 1.1: Shared coach context builder

**Files:**
- Create: `servers/crates/mod_consumption/src/coach_enrich.rs`
- Modify: `servers/crates/mod_consumption/src/lib.rs` (pub mod + re-export)
- Modify: `servers/crates/mod_chat/src/tools/builtin/consumption.rs` (call shared helper from `consumption_today_exec` — DRY)

**Interfaces:**
- Produces:

```rust
pub async fn consumption_coach_enrich(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    user_text: &str,
) -> Result<serde_json::Value, String>;
```

- Logic:
  - `days = 3` when user text matches meal **recommendation** phrases (`enaknya makan apa`, `what should i eat`, `rekomendasi makan`, … — reuse same list as `inst.consumption_coach` phrases or a single shared const in `mod_consumption`).
  - `days = 1` for recap-style queries (optional; can always use 3 for v1).
  - Fields aligned with tool compact: `day_id`, `glance`, `calories_remaining`, `protein_deficit_g`, `current_meal_slot`, `current_hour`, `recent_frequent_foods`, `days_inspected`.
  - **No** UI `block` in enrich payload (keep token-small).

**Tests:**
- Create: `servers/crates/mod_consumption/tests/coach_enrich_test.rs` (or inline `#[cfg(test)]` with `C35_TEST_DB=1` if repo pattern exists)
- Minimal: mock-free unit test on phrase → `days` selection if extracted as pure fn.

- [ ] **Step 1:** Add `coach_enrich.rs` with `consumption_coach_enrich` (copy multi-day logic from `consumption_today_exec` lines ~284–318).
- [ ] **Step 2:** Refactor `consumption_today_exec` to call shared builder for compact fields.
- [ ] **Step 3:** `cd servers && cargo test -p c35_mod_consumption && cargo build -p server_ai`

---

## Track 2 — `inst_enrich` registry

### Task 2.1: Module + registry

**Files:**
- Create: `servers/crates/mod_chat/src/inst_enrich.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` (`pub mod inst_enrich`)

**Interfaces:**
- Consumes: `consumption_coach_enrich` from `c35_mod_consumption`
- Produces: `inst_enrich_append` (see Locked design)

- [ ] **Step 1:** Implement registry with one entry: `inst.consumption_coach` → calls `consumption_coach_enrich`.
- [ ] **Step 2:** Format appendix: for each enrich result, `\n\n[ENRICH:{key}]\n{json}`.
- [ ] **Step 3:** Unit test in `servers/crates/mod_chat/tests/inst_enrich_test.rs` with empty pool mock — or test pure formatting with injected JSON.

---

## Track 3 — Compose integration

### Task 3.1: Async compose + prompt turn

**Files:**
- Modify: `servers/crates/mod_chat/src/compose/mod.rs`
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs`
- Modify: `servers/crates/mod_chat/src/mcp_agent.rs` (pass `owner_iid`, `locale` into compose if not already)
- Modify: `servers/crates/mod_chat/src/channel_prompt_turn.rs` (only if channel uses consumption inst — likely skip enrich for `role:bot`)

**Flow:**

```rust
// compose_tools_and_inst_async — after compose_prepare_scoped Ok(prep):
let (enrich_suffix, enrich_keys, enrich_ms) = inst_enrich_append(&matched_rows, &InstEnrichCtx { ... }).await;
let inst_block = format!("{}{}", prep.inst_block, enrich_suffix);
// pass inst_block into compose_finish via ComposePrep or override in ComposeOutput
```

- Skip enrich when `owner_iid == 0` or test compose without pool (MCP compose uses real pool).
- Skip enrich for bot channel scopes unless an enricher is registered for bot inst ids.

**Sync path:** `compose_tools_and_inst` (tests) — leave **without** enrich (no pool); tests unchanged.

- [ ] **Step 1:** Extend `ComposeTrace` with `inst_enrich_keys`, `inst_enrich_ms`.
- [ ] **Step 2:** Wire async enrich in `compose_tools_and_inst_async`.
- [ ] **Step 3:** Ensure `prompt_turn` tracer records new fields in compose meta JSON.
- [ ] **Step 4:** `cd servers && cargo build -p server_ai && cargo test -p c35_mod_chat`

---

## Track 4 — Seeds + documentation

### Task 4.1: `inst.consumption_coach` seed tweak

**Files:**
- Modify: `_/schemas/inst.sql` (`UPDATE inst.consumption_coach` block ~299+)

Add one sentence to inst body:

```text
Use the [ENRICH:consumption.nutrition] JSON block when present for calories_remaining, protein_deficit_g, recent_frequent_foods, and current_meal_slot. You may still call consumption.today for UI blocks or multi-day detail not in enrich.
```

Add phrase variant if missing: `enaknya aku makan apa` (substring of existing `enaknya makan apa` already matches — verify only).

### Task 4.2: Docs

**Files:**
- Modify: [`_/specs/inst.md`](../../_/specs/inst.md) — new section **Inst enrich (data injection)** after compose pipeline:
  - Registry in Rust keyed by `inst.id`
  - Not Type A macro; not merged into topic inst
  - `[ENRICH:*]` format
- Modify: [`.cursor/rules/inst.mdc`](../../.cursor/rules/inst.mdc) — bullet: enrichers = factual context only; register in `inst_enrich.rs`

- [ ] **Step 1:** Update seed + docs.
- [ ] **Step 2:** Apply seed on dev YB if needed (`yb_execute` / deploy pipeline per team habit).

---

## Track 5 — Tests & MCP verification

### Task 5.1: Compose test

**Files:**
- Modify: `servers/crates/mod_chat/tests/compose_test.rs`

Add test with **mocked enrich** only if no DB — prefer integration test gated on `C35_TEST_DB`:

- Phrase: `Enaknya aku makan apa?`
- Assert `matched_ids` contains `inst.consumption_coach`
- With DB: assert `inst_block` contains `[ENRICH:consumption.nutrition]`

### Task 5.2: Prompt MCP (manual agent checklist)

```
prompt_compose { text: "Enaknya aku makan apa?", locale: "id-ID", owner_iid: 99000 }
```

Assert:
- `inst_ids` or compose trace includes `inst.consumption_coach`
- Response includes enrich keys or inst_block preview with `calories_remaining`

```
prompt_run { same text, owner_iid: 99000 }
```

Assert:
- Reply references personalized nutrition (not generic “what cuisine do you prefer” only)
- `trace` shows compose with enrich timing
- Tool hop optional — OK if no `consumption.today` when enrich sufficed

- [ ] **Step 1:** Rust tests green.
- [ ] **Step 2:** MCP checks recorded in PR / session notes.

---

## Optional follow-ups (separate plans)

| Item | Notes |
|------|--------|
| `ai.inst.enrichers TEXT[]` | MCP `inst_get` visibility |
| `inst_enrich` for commerce | Product vector top-k from user text |
| Vector inst pick | Embed `phrases[]` like tools |
| `compose_force_tool_call` for consumption | Only if enrich alone insufficient for UI blocks |

---

## Self-review (spec coverage)

| Requirement | Task |
|-------------|------|
| Meal recommendation without tool hop | Tracks 1–3 |
| Reuse consumption.today data shape | Track 1 DRY refactor |
| Phrase “enaknya makan apa” | Existing seed + Track 4 verify |
| Debuggability | ComposeTrace enrich fields, Track 3 |
| No revival of Type A `inst!` macro | Locked design + docs |
| MCP verify | Track 5 |

---

## Execution handoff

When user says **go** / **execute plan**:

1. Dispatch **Track 1** (subagent).
2. Wave 2: **Tracks 2 + 3** in parallel.
3. Wave 3: **Tracks 4 + 5** in parallel.
4. Report: compose trace sample + `prompt_run` one-liner result for Chito (99000).
