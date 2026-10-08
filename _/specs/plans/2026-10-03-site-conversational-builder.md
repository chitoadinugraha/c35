# Conversational Site Builder — Multitask Implementation Plan

> **For agentic workers:** Subagent model: **inherit**. Follow `.cursor/rules/inst.mdc`, `plan-execution.mdc`, and `ui-page.mdc`.

**Goal:** Implement the Conversational Site Builder modeled after the Slide Deck pattern (`presentation.*`), enabling instant site creation, automatic Rust handle/slug generation, incremental block patching (`site.patch`), and an interactive chat preview card (`UiSitePreviewCard`) that preserves KV prefix caching.

**Docs (Source of Truth):**
- Spec: `_/specs/site-builder.md`
- Related Specs: `_/specs/site-ai.md`, `_/specs/site.md`, `spec.md`
- Schemas: `_/schemas/identity.sql`, `_/schemas/site.sql`, `_/schemas/inst.sql`

**Verify commands:**
- Rust: `cargo build -p server_ai`; `cargo test -p mod_chat`
- Flutter: `cd clients/app; flutter analyze`
- DB / SQL: `powershell -File ...` or psql syntax validation

---

## Multitask Waves

```
Wave 1 (Backend Core — Parallel)
  Track 0: Rust Slug & Handle Generator (`mod_site` / `mod_chat`)
  Track 1: Rust Tools: `site.create` & `site.handle.update`
  Track 2: Rust Tool: `site.patch` & SiteDoc mutation engine

Wave 2 (AI Steering & Context — After Wave 1)
  Track 3: `inst.site.builder` in `inst.sql` + topic & mention integration
  Track 4: Tool registration in dispatcher (`servers/crates/mod_chat/src/tools/mod.rs`)

Wave 3 (Flutter UI — Parallel with Wave 2)
  Track 5: `UiSitePreviewCard` widget (`clients/app/lib/widgets/ai/ui_site_preview_card.dart`)
  Track 6: `ui_msg_blocks.dart` wireup (`case 'site.preview'`)

Wave 4 (Verification & Polish)
  Track 7: Rust tests (`cargo test -p mod_chat`) + Flutter tests (`flutter test`)
  Track 8: End-to-end dry-run & documentation lock
```

---

## Detailed Track Breakdown

### Wave 1: Backend Core

#### Track 0: Rust Slug & Handle Generator
- **Files**: `servers/crates/mod_site/src/slug.rs` (or `servers/crates/mod_chat/src/site_slug.rs`)
- **Deliverables**:
  - `site_slug_generate(name: &str) -> String`: lowercase, remove accents/symbols, replace spaces/underscores with hyphens, truncate to 48 chars.
  - `site_slug_ensure_unique(pool: &PgPool, base_slug: &str) -> Result<String>`: queries `ai.identity WHERE kind = 'site' AND LOWER(alien_id) = LOWER($1) AND deleted_ts IS NULL`. If collision found, appends `-2`, `-3`, etc.
  - Unit tests for edge cases (empty strings, emoji, accented characters, numeric-only strings).

#### Track 1: Rust Tools — `site.create` & `site.handle.update`
- **Files**: `servers/crates/mod_chat/src/tools/builtin/site.rs`
- **Deliverables**:
  - `SiteCreateTool`:
    - Parameters: `name` (req), `alien_id` (opt), `tagline` (opt), `theme` (opt), `template` (opt).
    - Allocates snowflake `site_iid`.
    - Generates & verifies unique `alien_id`.
    - Inserts `ai.identity`, `ai.identity_grant` (role: owner), `site.config`.
    - Builds default `SiteDoc` (hero, features/products, contact, footer) and saves to `site.draft`.
    - Emits response with `block: { kind: "site.preview", body: { site_iid, alien_id, name, doc, theme } }`.
  - `SiteHandleUpdateTool`:
    - Parameters: `site_iid` (req), `new_alien_id` (req).
    - Validates format and checks uniqueness.
    - Updates `ai.identity.alien_id` and sets `site.config.alien_id_changed_ts = NOW()`.

#### Track 2: Rust Tool — `site.patch`
- **Files**: `servers/crates/mod_chat/src/tools/builtin/site.rs`, `servers/crates/mod_chat/src/site_validate.rs`
- **Deliverables**:
  - `SitePatchTool`:
    - Parameters: `site_iid` (opt, resolved via context), `action` (req: `update_block`, `insert_block`, `delete_block`, `patch_theme`, `patch_meta`), `block_id` (opt), `after_block_id` (opt), `block` (opt), `theme` (opt), `meta` (opt).
    - Loads existing `site.draft.doc_json`.
    - Applies targeted block/theme mutation in-memory.
    - Validates against `validate_sitedoc`.
    - Persists back to `site.draft`.
    - Returns `{ ok: true, action, block_id, block: { kind: "site.preview", body: { ... } } }`.

---

### Wave 2: AI Steering & Context

#### Track 3: `inst.site.builder` Instruction Macro
- **Files**: `_/schemas/inst.sql`
- **Deliverables**:
  - Seed macro `inst.site.builder`:
    - Priority: 150 (matching `inst.presentation`).
    - Triggers / Phrases: `bikin web`, `buat web`, `bikin website`, `landing page`, `create site`, `build website`.
    - Included Tools: `site.create`, `site.patch`, `site.publish`, `site.handle.update`, `img.generate`.
    - Directives:
      1. Always ask for business/site name if user didn't mention it.
      2. Call `site.create` as soon as name is known. Mention generated `@handle` and URL.
      3. For any subsequent edits, use `site.patch` (never regenerate full site).
      4. Suggest generating photos with `img.generate`.

#### Track 4: Tool Registration & Mention Gating
- **Files**: `servers/crates/mod_chat/src/tools/mod.rs`, `servers/crates/mod_chat/src/tools/definition.rs`
- **Deliverables**:
  - Register `SiteCreateTool`, `SitePatchTool`, `SiteHandleUpdateTool` in dispatcher.
  - Set `requires_kinds: []` on `site.create` (so it can run without an existing `@site` mention).
  - Allow `site.patch` to inherit `default_site_iid` from active mention or `site_iid` parameter.

---

### Wave 3: Flutter UI

#### Track 5: `UiSitePreviewCard` Widget
- **Files**: `clients/app/lib/widgets/ai/ui_site_preview_card.dart`
- **Deliverables**:
  - Parse `SitePreviewData` from block payload.
  - Header: Site Name, `@handle` pill, status badge (Draft / Published), Open Link button.
  - Preview Canvas: Responsive rendering of the blocks (Hero title/subtitle/CTA, gallery/product grid items, contact block).
  - Theme styling: Adheres to `accent` color from theme payload.
  - Action row: Quick links to "Visit", "Publish", "Copy Link".

#### Track 6: Chat Message Wireup
- **Files**: `clients/app/lib/widgets/ai/ui_msg_blocks.dart`
- **Deliverables**:
  - Add `case 'site.preview':` and `case 'site.builder':`.
  - Render `UiSitePreviewCard` with initially expanded state.

---

### Wave 4: Verification & Polish

#### Track 7: Automated Tests
- **Rust**:
  - Unit tests in `site.rs` for `site.create`, `site.patch`, and `site.handle.update`.
  - Unit tests for slug collision resolution.
  - Check `cargo test -p mod_chat`.
- **Flutter**:
  - Component tests for `UiSitePreviewCard`.
  - Check `flutter analyze`.

#### Track 8: Documentation Sync
- Update `_/specs/site-ai.md` and `spec.md` with links to `_/specs/site-builder.md`.
