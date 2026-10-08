# Site Info parity + editor save chrome — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Bring **Site → Info** to CSA-quality: handle edit, tagline + generator, location, open hours, avatar, computed SEO title (`name — tagline`), and **restore CSA save UX** (`Saving…` on app bar subtitle — not a centered green spinner / form progress bar).

**Architecture:** Flutter editor owns UX; persist through existing RPCs (`identity_put`, `site_handle_put`, `site_draft_put`). Site “business profile” fields live in **`site.draft.doc_json`** (`meta` + synced `hub_profile` / `hours` blocks) and **`ai.identity`** (`name`, `alien_id`, `pic`). Guest HTML + Flutter preview read the same block props (port CSA `schedule.rs` / hub chips into `mod_site` + `guest_site_blocks.dart`). Optional: mirror lat/lng in `site.config.presence_policy_json` for future presence — **not required for v1 guest hub**.

**Tech stack:** Flutter `clients/app`, Rust `mod_site` / `mod_chat` (`site_validate`), `clients/web/static/site-guest/`, geo HTTP (new thin route or reuse cluster geocode if present).

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/site.md`](../site.md) | [`_/specs/site-builder.md`](../site-builder.md) | [`_/specs/plans/2026-10-03-site-hub-blocks-design-system.md`](2026-10-03-site-hub-blocks-design-system.md)

**CSA reference (read-only):** `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_info_section.dart`, `widgets/io/in_geo_point.dart`, `widgets/io/in_site_schedule.dart`, `core/site/site_schedule.dart`, `pages/site/page_site_editor.dart` (`_SiteEditorSaveBus`), `crates/mod_site/src/render/hub.rs`, `render/schedule.rs`

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| SEO `<title>` | **Computed** at publish/render: `{name} — {tagline}`; drop manual **SEO title** field from Info UI |
| Meta description | `seo_desc` = tagline (or empty); stop writing redundant `seo_title` from client except legacy read fallback |
| Tagline storage | Canonical: `doc.meta.tagline` **and** `hub_profile.props.subtitle` (+ `hero.subtitle` if landing block exists) — **sync on every Info save** |
| Tagline suggest v1 | Reuse `siteTaglineSuggest` (templates), same as create dialog — **no LLM queue** (CSA setup LLM deferred) |
| Alien ID | Inline field + validation; save via `siteHandlePut`; refresh `SiteRow` in shell / store |
| Site name | Editable on Info (calls `identity_put` / store `renamePut`); stop “site list only” copy |
| Open hours | CSA slot model (`SiteScheduleSlot`) → `hours` block `schedule` JSON **or** `meta.open_hours` mirrored into block — pick **block as guest source of truth** |
| Location | `location_label` + `location_href` (+ optional `lat`/`lng` on `map` block or meta) on `hub_profile`; maps link from href |
| Capabilities | Stay on **Settings → Capabilities** — do **not** move feature checkboxes back into Info (CSA split) |
| Save UX | **App bar subtitle** `Saving…` (green `#22C55E` like CSA) via shared save bus; **no** full-screen loader for draft fetch; **no** `LinearProgressIndicator` at bottom of Info form |

---

## Current gaps (c35)

- `ui_site_info_editor.dart`: center `CircularProgressIndicator` on load; debounced save shows green `LinearProgressIndicator` in form body.
- `ui_site_editor_shell.dart`: chrome subtitle is section label only — no save/error state.
- Info: read-only name/handle; no tagline generator; `seo_title` field.
- No location / hours editors; guest `GuestSiteHubProfileBlock` does not render CSA chips; `mod_site` hub render lacks `show_hours` / location chip HTML.
- Meta inconsistency: `site.create` uses `seo_desc`; create dialog uses `tagline`; validate `META_KEYS` omits `tagline`.

---

## File map

| File | Action |
|------|--------|
| `clients/app/lib/c/site/site_editor_save_bus.dart` | **Create** — `SiteEditorSaveBus` (port CSA `_SiteEditorSaveBus`) |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` | **Modify** — provide save bus; subtitle Saving… / save failed |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_chrome.dart` | **Modify** — optional `subtitleColor` (already exists) |
| `clients/app/lib/widgets/sites/editor/ui_site_info_editor.dart` | **Modify** — full Info fields; use save bus; skeleton load |
| `clients/app/lib/c/site/site_draft_meta.dart` | **Modify** — meta merge: tagline, open_hours, location_*; doc patch helpers |
| `clients/app/lib/c/site/site_info_sync.dart` | **Create** — patch `hub_profile` / `hours` / `hero` from Info snapshot |
| `clients/app/lib/c/site/site_schedule.dart` | **Create** — port CSA slot types + formatters |
| `clients/app/lib/widgets/io/in_site_schedule.dart` | **Create** — port CSA `InSiteSchedule` / `InScheduleSlots` (trim deps) |
| `clients/app/lib/widgets/io/in_geo_point.dart` | **Create** — map picker; wire geocode API |
| `clients/app/lib/c/geo/site_geocode_api.dart` | **Create** — client for reverse geocode (or `wire_http` route) |
| `servers/crates/wire_http/src/site_geocode.rs` | **Create** (if no existing geocode) — proxy to Google/cluster geo |
| `servers/crates/mod_chat/src/site_validate.rs` | **Modify** — `META_KEYS` += `tagline`, `open_hours`, `location_label`, `lat`, `lng` (allowlist) |
| `servers/crates/mod_site/src/render.rs` | **Modify** — hub_profile location + hours chips; title from name+tagline |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | **Modify** — hub chips + hours summary in preview |
| `clients/app/lib/c/site/site_api.dart` | **Modify** — stop seeding `seo_title` in `siteCreateDraft`; computed desc |
| `clients/app/test/site_info_sync_test.dart` | **Create** |
| `clients/app/test/site_schedule_test.dart` | **Create** |
| `servers/crates/mod_site/tests/render_hub_profile_test.rs` | **Create** |
| `_/specs/site.md` | **Modify** — Info fields + meta contract |

---

## Multitask waves

```
WAVE 0  S0   SiteEditorSaveBus + shell chrome (Saving… / error bar)
WAVE 1  I1   Info UX shell: skeleton load, remove inline progress bars (info + design editors)
WAVE 2  I2   Tagline + generator; remove SEO title; meta/tagline/seo_desc alignment
        I3   site_info_sync → hub_profile (+ hero) on draft put
WAVE 3  I4   Alien ID + site name inline (handlePut + identity_put)
        I5   Avatar pick → identity.pic + hub_profile.pic
WAVE 4  G1   site_schedule.dart + in_site_schedule.dart (editor)
        G2   in_geo_point.dart + geocode API
        I6   Info wires location + hours → doc blocks/meta
WAVE 5  R1   mod_site hub render: location chip, hours summary (port schedule.rs)
        R2   guest_site_blocks hub_profile chips + hours block preview
        R3   Publish <title> = name — tagline; deprecate meta.seo_title write path
WAVE 6  T1   Unit/widget tests + flutter analyze
        T2   Manual E2E checklist (Chito site @test-site)
WAVE 7  P1   publish_server.ps1 + re-publish test site (if render changed)
```

### Parallel assignment (suggested)

| Wave | Agent A | Agent B | Agent C |
|------|---------|---------|---------|
| 0 | S0 save bus + shell | — | — |
| 1 | I1 skeleton Info load | I1 remove design editor bottom bar (optional same PR) | — |
| 2 | I2 tagline/SEO meta | I3 sync helper + tests | — |
| 3 | I4 handle + name | I5 avatar | — |
| 4 | G1 schedule UI | G2 geo picker + API | I6 Info compose |
| 5 | R1 Rust render | R2 Flutter guest blocks | R3 title computation |
| 6 | T1 tests | T2 manual notes | P1 deploy |

---

## Track details

### S0 — Save bus + app bar (CSA parity)

**Reference:** CSA `page_site_editor.dart` lines 48–82, 424–467.

- [ ] **S0.1** Add `SiteEditorSaveBus` with `beginSave`, `endSaveSuccess`, `endSaveError`, `saving`, `error`.
- [ ] **S0.2** Hold bus in `UiSiteEditorShell` (or `InheritedWidget` / callback `SiteEditorSaveScope`) so sections report saves.
- [ ] **S0.3** Chrome `subtitle` priority: save error (red) → `Saving…` (green `#22C55E`) → existing section subtitle.
- [ ] **S0.4** Error strip under chrome when `saveBus.error` non-empty (CSA pattern).
- [ ] **S0.5** API for children: `Future<T> siteEditorSaveRun(Future<T> fn())` wraps begin/end.

**Acceptance:** Typing in tagline shows **Saving…** under site title in top bar; no green bar in form center.

---

### I1 — Loading UX

- [ ] **I1.1** Replace Info full-screen `CircularProgressIndicator` with inline skeleton (fields disabled, grey placeholders) or keep prior frame — **never block vertical center of pane**.
- [ ] **I1.2** Remove `_saving` `LinearProgressIndicator` from `ui_site_info_editor.dart`; use save bus only.
- [ ] **I1.3** (Optional same wave) Audit `ui_site_design_editor.dart` / `ui_site_product_design_editor.dart` — route busy state to save bus or chrome where autosave applies.

---

### I2 — Tagline + SEO field removal

- [ ] **I2.1** Remove SEO title `TextField`; helper text: title is automatic (`Name — tagline`).
- [ ] **I2.2** Port tagline suffix `Icons.auto_awesome` from `in_site_create.dart` (`pick` counter for rotate suggestions).
- [ ] **I2.3** Align `siteMetaMergeFields` / validate: `tagline` allowed in `meta`; migrate read: `tagline` ?? `seo_desc` ?? hub subtitle.
- [ ] **I2.4** Update `siteCreateDraft` / `site.create` seed meta: `{ tagline, seo_desc: tagline }` without `seo_title` (server tool optional follow-up).

---

### I3 — Doc sync (preview matches Info)

- [ ] **I3.1** `siteInfoApplyToDoc(SiteDoc doc, SiteInfoSnapshot snap)`:
  - merge `meta`
  - find first `hub_profile` block → update `title` (name), `subtitle` (tagline), `location_*`, `show_hours`
  - find or insert `hours` block when `open_hours` non-empty
  - optional: `hero` subtitle on landing templates
- [ ] **I3.2** Call from Info `_save()` before `draftPut`.
- [ ] **I3.3** Tests: doc with hub template gets subtitle + hours block updated.

---

### I4 — Alien ID + site name

- [ ] **I4.1** Editable name field → `SiteStore.renamePut` / `identity_put`; update local `SiteRow` passed to shell (callback `onRowChanged`).
- [ ] **I4.2** Alien ID field with `siteHandleFormatError`, prefix `alienai.id/`; save → `handlePut`; handle collision errors in snackbar.
- [ ] **I4.3** Remove misleading copy “managed from the site list” (or narrow to “pin/archive on list” only).

---

### I5 — Avatar

- [ ] **I5.1** Circle avatar tap → existing file upload path (`fileStoragePath` / identity pic pattern from products).
- [ ] **I5.2** `identity_put` with new `pic`; sync `hub_profile.props.pic` via I3.
- [ ] **I5.3** Preview pane reload nonce on identity pic change.

---

### G1 — Open hours editor

- [ ] **G1.1** Port `site_schedule.dart` + `InScheduleSlots` from CSA (minimize line count; single-file slots UI if needed).
- [ ] **G1.2** Serialize slots to JSON array matching CSA / `hours` block `schedule` shape (document in `site.md`).
- [ ] **G1.3** Default slot Mon–Fri 09:00–17:00 when user taps “Add hours”.

---

### G2 — Location editor

- [ ] **G2.1** Port `InGeoPoint` (flutter_map + geolocator) or phase 1: text label + “Pick on map” deferred.
- [ ] **G2.2** Server geocode reverse endpoint (auth’d, owner-scoped) — proxy CSA `geo` crate pattern; **no keys in client**.
- [ ] **G2.3** Persist `location_label`, `location_href` (Google Maps URL), optional lat/lng in meta; sync hub_profile.

---

### I6 — Info screen composition

- [ ] **I6.1** Layout: avatar + name row; alien id; tagline; location; open hours (CSA order).
- [ ] **I6.2** Autosave debounce 500ms (keep); coalesce rapid field changes into one `draftPut`.
- [ ] **I6.3** Max lengths: tagline 120 (match create); location label reasonable cap (200).

---

### R1–R3 — Guest render + title

- [ ] **R1.1** Port `guest_hours_summary_html` / open-now chip from CSA `render/schedule.rs` (Rust unit tests).
- [ ] **R1.2** Hub profile HTML: location chip + hours when `show_hours` true.
- [ ] **R2.1** `GuestSiteHubProfileBlock`: location row + expandable hours (match published HTML).
- [ ] **R3.1** `render.rs` `<title>`: use identity name + meta tagline (fallback seo_desc / subtitle).
- [ ] **R3.2** Stop requiring `meta.seo_title` in tests; update `boot_get_test` if needed.

---

## Verification

```powershell
cd servers
cargo test -p c35_mod_site
cargo test -p c35_mod_chat --test site_tools_test
cargo build -p server_ai
cd ..\clients\app
flutter test test/site_info_sync_test.dart test/site_schedule_test.dart
.\_\scripts\dev\verify_flutter_app.ps1
```

**Manual (owner_iid 99000):**

1. Open site editor → Info: no centered loader; initial fields appear quickly.
2. Edit tagline → app bar shows **Saving…** then section subtitle returns.
3. Change handle → public URL updates; publish still works.
4. Set location + hours → draft phone preview shows chips; published guest matches after publish.
5. View page source: `<title>testing — {tagline}</title>` (no separate SEO field).

---

## Out of scope (this plan)

| Item | Why |
|------|-----|
| CSA LLM tagline queue | Templates only v1 |
| Feature checkboxes on Info | Capabilities editor exists |
| Full `SiteDraft` monolith port | Block doc + targeted fields only |
| HR / presence_policy modules | Only store geo if needed later |
| Alpine.js guest runtime | vanilla `site-guest` only |

---

## Publish

After **R1–R3** server/render changes:

```powershell
.\_\scripts\deploy\publish_server.ps1
```

Re-publish affected guest sites. End agent reply with **Publish summary** from `.cache/publish-perf/latest.json` when publish runs.

---

## Risk notes

- **Geocode dependency:** If no API key in cluster, ship **text-only location** in wave 4B and map picker in follow-up.
- **Meta validation:** Adding keys requires `site_validate.rs` + any strict `validate_sitedoc` paths before draft put succeeds.
- **Multi-block templates:** Sites with multiple `hub_profile` blocks — sync **first** on `/` page only (document behavior).
