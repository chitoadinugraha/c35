# Skill Marketplace (+ OpenSkill) — Multitask Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the **Skill marketplace** dialog list installable catalog skills (fix broken seed), and add **OpenSkill routing** per [`_/specs/skill.md`](../../_/specs/skill.md): internal `ai.skill_catalog` first, then external registry when search/list would otherwise miss.

**Architecture:** **Server-led catalog.** Wave 1 fixes FK-safe seed + optional SQL seed so `skillCatalogList` returns rows and `skillCatalogInstall` copies `body_md` into `ai.skill`. Wave 2 adds `mod_skill::openskill` HTTP client (OpenAgentSkill-compatible `/api/agent/skills` + install handoff), merges results in `skill_catalog_list_rpc` / `skill_catalog_search_rpc`, and extends install RPC with `external_source` + `external_slug` for skills not stored in YB. Wave 3 exposes `source` / `source_url` on wire + Flutter badges/links. Agent dispatcher reuses existing `skill_catalog_search_rpc` (no new RPC).

**Tech Stack:** Rust `servers/crates/mod_skill`, YSQL [`_/schemas/skill.sql`](../../_/schemas/skill.sql), proto [`_/schemas/proto/c35/skill.proto`](../../_/schemas/proto/c35/skill.proto), Flutter `clients/app` (`io_skill_catalog_pick.dart`, `skill_api.dart`). Spec: [`_/specs/skill.md`](../../_/specs/skill.md).

## Global Constraints

- **OpenSkill** in UI = external agent-skills registry; v1 HTTP base **`https://www.openagentskill.com`** (env override `C35_OPENSKILL_BASE_URL`). No API key required for public search/install handoff endpoints per their docs.
- **Internal catalog IDs** stay positive snowflakes / fixed seed IDs (`1001`–`1003`); **external** entries use `id = 0` on wire and install via `external_slug`.
- **Catalog author FK:** `ai.skill_catalog.author_iid` must reference `ai.identity(id)` — never `0`.
- **Seed identity:** fixed platform row **`33001`** / `alien_id = skill-catalog` (new seed in `identity.sql`), not automated tester `33000`.
- **Do not** silently swallow seed errors — log with `tracing::warn` or `ca::L` pattern used in sibling crates.
- **Payments:** `charge_install` stays **no-op for free** skills only in this plan; paid catalog + wallet debit = **deferred** (columns exist).
- **Proto change** requires regenerate Dart (`clients/app` pb) — run existing proto gen script if repo has one; else document manual step in track.
- Verify server: `cd servers && cargo build -p server_ai`; add `cargo test -p mod_skill` when tests land.
- Verify client: `cd clients/app && flutter analyze` (+ `flutter test` for new tests).
- **No cluster publish** required for local dev; production seed can use one-off SQL or first `skillCatalogList` after deploy.
- Do not commit unless user asks.

## Out of Scope (defer)

| Item | Why |
|------|-----|
| Marketplace payments / Play billing | `skill.md` deferred; `charge_install` hardening later |
| `pending_review` moderator UI | Submit RPC exists; approval workflow later |
| Embedding phrase match in search | v2 per `skill.md` |
| Caching full OpenSkill corpus in YB | v1 = live merge + install fetch only |
| Remote agent auto-install from dispatcher | Search RPC ready; agent wiring separate plan |

## Current Bugs (locked root causes)

1. `seed.rs` inserts `author_iid = 0` → FK violation → **0 rows** in `ai.skill_catalog`.
2. UI subtitle promises OpenSkill; **no HTTP integration** exists.
3. `SkillCatalog` proto omits `source` / `source_url` (DB has them; UI infers OpenSkill from tags only).

---

## External API Contract (v1)

| Step | HTTP | Maps to |
|------|------|---------|
| Search | `GET {base}/api/agent/skills?q={q}&limit={n}` | `SkillCatalog` list (external) |
| Detail (optional) | `GET {base}/api/agent/skills/{slug}` | summary, trust fields → `summary` |
| Install body | `GET {base}/api/skills/{slug}/install?format=text` | `ai.skill.body_md` on install |

**Rust types:** `OpenSkillSkillSummary { slug, title, summary, source_url, ... }` — parse minimal JSON fields only; ignore unknown.

**Timeouts:** 4s connect + 8s total per upstream call; on failure return **internal-only** results (never fail whole list RPC).

---

## File Map

| File | Action |
|------|--------|
| `_/schemas/identity.sql` | **Modify** — seed `33001` `skill-catalog` identity |
| `_/schemas/skill.sql` | **Modify** (optional) — comment + idempotent seed block mirroring `seed.rs` |
| `servers/crates/mod_skill/src/seed.rs` | **Modify** — `author_iid = 33001`, log errors, seed variant+release rows |
| `servers/crates/mod_skill/src/openskill.rs` | **Create** — HTTP client + JSON mapping |
| `servers/crates/mod_skill/src/rpc.rs` | **Modify** — merge external, install external branch |
| `servers/crates/mod_skill/src/lib.rs` | **Modify** — export module |
| `servers/crates/mod_skill/Cargo.toml` | **Modify** — `reqwest` (if not in workspace dep already) |
| `servers/crates/mod_skill/tests/catalog_seed_test.rs` | **Create** — optional `C35_TEST_DB=1` |
| `_/schemas/proto/c35/skill.proto` | **Modify** — `source`, `source_url`, install external fields |
| `clients/app/lib/widgets/skill/io_skill_catalog_pick.dart` | **Modify** — install external, source link |
| `clients/app/lib/c/skill/skill_api.dart` | **Modify** — `catalogInstall` params |
| `clients/app/lib/c/chat/chat_conn.dart` | **Modify** — wire new proto fields |
| `_/specs/skill.md` | **Modify** — move OpenSkill routing from Deferred → Implemented (after ship) |

**Env (server deployment):**

```text
C35_OPENSKILL_ENABLED=1
C35_OPENSKILL_BASE_URL=https://www.openagentskill.com
C35_OPENSKILL_LIST_LIMIT=15
```

---

## Multitask Map

```
WAVE 1 — Catalog works (parallel)
  I1  Platform identity 33001 in identity.sql
  S1  Fix seed.rs (author_iid, logging, variant+release for seeds)
  S2  skill_catalog_list returns ≥3 rows (manual or integration test)

WAVE 2 — Wire + install (after WAVE 1)
  P1  Proto: SkillCatalog.source/source_url; ReqSkillCatalogInstall external_*
  S3  openskill.rs client + unit test with mock/fixture JSON
  S4  rpc merge (list + search) + external install path

WAVE 3 — Client + docs (parallel after P1+S4)
  C1  Flutter catalog pick + skill_api + chat_conn
  C2  Widget test or manual E2E checklist
  D1  Update skill.md + roadmap one-liner

DEFERRED
  Pay  Paid install + billing
  Mod  Catalog moderation UI
```

### Suggested agent assignments

| Agent | Track | Deliverable |
|-------|-------|-------------|
| A | I1 | Identity seed `33001` |
| B | S1 | Fixed `seed.rs` + variants/releases |
| C | S2 | DB/integration verification |
| D | P1 | Proto + regenerate Dart pb |
| E | S3 | `openskill.rs` |
| F | S4 | RPC merge + external install |
| G | C1 | Flutter install + UI |
| H | C2 + D1 | Tests + docs |

---

# WAVE 1

## Track I1 — Platform catalog identity

**Files:**
- Modify: `_/schemas/identity.sql` (after automated tester block)

**Tasks:**

- [ ] **I1.1** Insert `ai.identity` id **`33001`**, `kind = 'bot'`, `alien_id = 'skill-catalog'`, `name = 'Alien Skill Catalog'`, `owner_iid = 33001`.
- [ ] **I1.2** Apply on cluster dev DB (migrate script or `yb_execute`) so FK exists before seed runs.

**Verify:** `SELECT id, alien_id FROM ai.identity WHERE id = 33001;` → one row.

---

## Track S1 — Seed fix + variant/release

**Files:**
- Modify: `servers/crates/mod_skill/src/seed.rs`
- Modify: `servers/crates/mod_skill/src/rpc.rs` (only if seed helper extracted)

**Tasks:**

- [ ] **S1.1** Constant `CATALOG_AUTHOR_IID: i64 = 33001` used in all seed inserts.
- [ ] **S1.2** Replace `let _ = sqlx::query(...)` with `.await` + on error `tracing::warn!("skill_catalog seed: {e}")`.
- [ ] **S1.3** For each seed catalog id `1001..1003`, upsert:
  - `skill_catalog_variant` id `11001..11003`, `variant_key = 'default'`, `platform = 'any'`
  - `skill_catalog_release` id `12001..12003`, `is_current = TRUE`, `body_md` = catalog body, `hash_blake3` = blake3 of body (use existing `hash_body` from `rpc.rs` or duplicate minimal hasher in seed module)
- [ ] **S1.4** Keep `ON CONFLICT (id) DO UPDATE` on catalog rows.

**Verify:** Call `skill_catalog_list_rpc` locally or via MCP after deploy; expect titles *Web Scraper & Digest*, *Competitor Intelligence*, *Daily Standup Logger*.

---

## Track S2 — Verification

**Files:**
- Create: `servers/crates/mod_skill/tests/catalog_seed_test.rs` (optional)

**Tasks:**

- [ ] **S2.1** If `C35_TEST_DB=1`: test calls `skill_catalog_ensure_seed` then `SELECT count(*) FROM ai.skill_catalog WHERE status='published'` ≥ 3.
- [ ] **S2.2** Manual: open Skill tab → marketplace → three skills; install one → appears in skill list with `source = catalog`.

**Verify:** `cargo test -p mod_skill` (when test added); `flutter analyze` unchanged.

---

# WAVE 2

## Track P1 — Proto + Dart

**Files:**
- Modify: `_/schemas/proto/c35/skill.proto`

**Tasks:**

- [ ] **P1.1** Add to `SkillCatalog`:

```protobuf
  string source = 16;       // community | openskill | alien
  string source_url = 17;
  bool is_external = 18;    // true when id==0, install uses slug
  string external_slug = 19;
```

- [ ] **P1.2** Add to `ReqSkillCatalogInstall`:

```protobuf
  string external_source = 5;  // "openskill" when installing external
  string external_slug = 6;
```

- [ ] **P1.3** Regenerate protobuf Dart + Rust; update `catalog_from_row` to set `source` / `source_url` from SQL (`SELECT` add columns).

**Interfaces:**
- Produces: extended `SkillCatalog`, `ReqSkillCatalogInstall` on wire.

---

## Track S3 — OpenSkill HTTP client

**Files:**
- Create: `servers/crates/mod_skill/src/openskill.rs`
- Modify: `servers/crates/mod_skill/Cargo.toml`, `lib.rs`

**Tasks:**

- [ ] **S3.1** `openskill_enabled() -> bool` from env `C35_OPENSKILL_ENABLED` (default true in dev).
- [ ] **S3.2** `openskill_search(q: &str, limit: i32) -> Vec<ExternalCatalogItem>` — HTTP GET, parse `skills[]` or top-level array (handle both in fixture).
- [ ] **S3.3** `openskill_install_body(slug: &str) -> Result<String, String>` — GET install `format=text`.
- [ ] **S3.4** Map to wire: `id = 0`, `is_external = true`, `source = "openskill"`, `external_slug = slug`, `author_name` from API or `"OpenSkill"`.

- [ ] **S3.5** Unit test with `serde_json` fixture file `openskill_search_sample.json` (checked into `mod_skill/tests/fixtures/`).

**Verify:** `cargo test -p mod_skill openskill`

---

## Track S4 — RPC merge + external install

**Files:**
- Modify: `servers/crates/mod_skill/src/rpc.rs`

**Tasks:**

- [ ] **S4.1** `skill_catalog_list_rpc`: after internal query, if `openskill_enabled()` and (`q` non-empty OR internal count < limit): append external results (dedupe by slug vs internal `slug` / `source_url`).
- [ ] **S4.2** `skill_catalog_search_rpc`: if internal `total == 0` or ranked internal below threshold, **fallback** external search (per `skill.md` wording).
- [ ] **S4.3** `skill_catalog_install_rpc`: if `req.external_source == "openskill"` && `req.external_slug` non-empty:
  - fetch install text via `openskill_install_body`
  - `INSERT ai.skill` with `source = 'catalog'`, `catalog_id = 0`, `body_md` = fetched text, title from slug or optional prefetch
  - skip `install_count` bump on `skill_catalog` (no row)
- [ ] **S4.4** Else existing DB install path unchanged.

**Verify:**

```text
prompt_compose not required
```

- MCP / WS: `skillCatalogList` with `q=browser` returns mixed or external-only rows.
- Install external skill → `ai.skill` row with non-empty `body_md`.

**Server verify:** `cd servers && cargo build -p server_ai`

---

# WAVE 3

## Track C1 — Flutter marketplace

**Files:**
- Modify: `clients/app/lib/c/chat/chat_conn.dart`
- Modify: `clients/app/lib/c/skill/skill_api.dart`
- Modify: `clients/app/lib/widgets/skill/io_skill_catalog_pick.dart`
- Modify: `clients/app/lib/widgets/skill/ui_skill_master_detail.dart` (install call site)

**Tasks:**

- [x] **C1.1** `catalogInstall`: pass `externalSource` / `externalSlug` when `catalog.isExternal`.
- [x] **C1.2** Badge: prefer `catalog.source == 'openskill'` over tag heuristics.
- [ ] **C1.3** Optional: tap-hold or subtitle link opens `source_url` in browser when non-empty.
- [ ] **C1.4** Empty state copy: only when **both** internal and external failed/empty; if `_error != null` keep showing error.

**Verify:** `cd clients/app && flutter analyze`

---

## Track C2 — E2E checklist

- [ ] Marketplace opens with ≥3 Alien seed skills (no search).
- [ ] Search `automation` (or similar) returns OpenSkill rows when enabled.
- [ ] Install seed skill → listed locally; reinstall shows friendly “already installed”.
- [ ] Install external skill → markdown body present in skill detail.
- [ ] Web (`127.0.0.1:8080`) and Windows app smoke.

---

## Track D1 — Docs

**Files:**
- Modify: `_/specs/skill.md` (Deferred section)
- Modify: `_/specs/roadmap.md` (one line: marketplace browse + OpenSkill fallback shipped)

- [x] Document env vars and install semantics (`id=0` external).
- [x] Remove or narrow “OpenSkill API routing” under Deferred after implementation.

**Pending (other tracks):** Flutter `catalogInstall` + `chat_conn` still omit `external_source` / `external_slug`; Dart pb not regenerated from extended `skill.proto` — external install from UI blocked until **C1** / **P1.3** complete.

---

## Self-Review (spec coverage)

| Requirement | Task |
|-------------|------|
| Marketplace list/browse | S1, S4, C1 |
| Install from catalog | S1 releases optional, S4, C1 |
| OpenSkill fallback on miss | S3, S4 |
| UI “Alien catalog + OpenSkill” | C1 (truthful once S4 ships) |
| Dispatcher `catalogSearch` | S4.2 (same RPC) |
| Payments | Deferred |
| `pending_review` visibility rules | Deferred |

---

## Execution order (for parent agent)

1. Dispatch **I1 + S1** in parallel (wave 1).
2. When I1 merged, run **S2**; confirm DB rows.
3. Dispatch **P1** then **S3** (S3 can start with fixtures in parallel with P1).
4. **S4** after P1 + S3 interfaces stable.
5. **C1 + D1** after S4 deployed or local server built.
6. **C2** manual pass.

**Publish:** Only if user asks — `publish_server.ps1` after Rust changes; include Publish summary per `publish-perf-report.mdc`.
