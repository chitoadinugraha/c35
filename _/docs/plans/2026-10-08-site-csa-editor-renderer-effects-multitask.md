# Site editor + guest renderer + effect engine — CSA parity

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks and does not implement every lane inline. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the c35 site editor and both guest renderers (Flutter widgets and published HTML) behave like `D:\csa_site_published`: same section layout, same hub/detail guest flows, and the CSA Rust effect sim on the public web page.

**Architecture:** Keep c35 identity, YSQL `site.*`, WebSocket `ReqSite*`, and `site.boot_get`. Do not paste CSA Dart that imports `SiteDraft` / `core/app.dart`. Port UX onto `SiteApi` and `site.draft.doc_json`. Web overlay effects load CSA `overlay_effects` WASM. Flutter keeps Dart `CustomPainter` runners (that is what CSA ships today; FFI is not in CSA). Guest interactivity stays vanilla `site-guest.v1.js`, not Alpine.

**Tech stack:** Rust `overlay_effects` (wasm32, not a `server_ai` dependency), `c35_mod_site`, static `clients/web/static/site-guest/`, Flutter `clients/app/lib/widgets/sites/editor/` and `guest_site/`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/docs/site.md`](../site.md) · [`_/docs/site-guest-components.md`](../site-guest-components.md) · [`_/docs/tx.md`](../tx.md) · CSA [`guest_ui.md`](file:///D:/csa_site_published/.agents/guest_ui.md) · CSA [`effects.md`](file:///D:/csa_site_published/.agents/effects.md) · CSA `crates/overlay_effects/README.md`

**Already shipped — do not rebuild:** hub blocks (`hub_profile`, `links`, `product_grid`, `social_feed`, `partners_display`, `clients_display`, `order_track`, `contact_form`, `hours`), `GuestDesign` tokens, reservation sheet, cart bar in `site-guest.v1.js`, effects editor UI, Flutter overlay painters, Info save-bus. Prior plans: [`2026-10-07-site-csa-parity-catalog-multitask.md`](2026-10-07-site-csa-parity-catalog-multitask.md) (done), [`2026-10-08-site-info-parity-multitask.md`](2026-10-08-site-info-parity-multitask.md), [`2026-10-08-site-blocks-effects-render-parity.md`](2026-10-08-site-blocks-effects-render-parity.md) (design chrome; its **X6.3 WASM** item is **this** plan’s Wave 2), [`2026-10-08-site-team-editor-csa-parity-multitask.md`](2026-10-08-site-team-editor-csa-parity-multitask.md) (Team + HR tables — dependency for Attendance), [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) (cart/checkout/order progress — finish open items there; this plan only adds the gaps listed below).

---

## Global constraints

- Guest URLs stay `https://alienai.id/{alien_id}/…`. Phone preview stays `GuestSiteView`, not a WebView of the published page.
- Editor saves stay `SiteApi.draftPut` / existing `ReqSite*` on the app WebSocket. No new HTTP invoke for staff edits.
- Staff ACL stays `ai.identity_grant` on `site_iid`. No `site_member` table.
- Do not add `overlay_effects` to `servers/Cargo.toml` `[workspace] members`. `wasm-bindgen` must not enter `cargo build -p server_ai`.
- Effect preset ids stay the hyphen ids in `clients/app/assets/effects/presets.json` (`rain-shower`, not new ids). Boot may store `presetId` + object `params`; the web host adapts to CSA `preset_id` + `params_json`.
- No Alpine.js. No provider web grounding. Do not split form or queue into extra script files. `site-guest.v1.js` stays the only guest interactivity script.
- Effects use a conditional script tag: `site-guest.effects.v1.js` plus `/static/site-guest/effects/overlay_effects.js` and wasm only when at least one effect has `active !== false` and a known preset id.
- UTF-8 sources. Verify per `verify-after-edit.mdc`.
- Prompt tools (`site.patch`, `site.publish`, `web.builder`) stay. The Sites page becomes the CSA-shaped editor; chat remains a parallel editor.

---

## Locked decisions (Wave 0 writes these into `site.md`)

| Topic | Decision |
|-------|----------|
| Editor | Sites page is the CSA menu (Info first). Home prompt is a second editor, not the only one. |
| UITable | Stays available for power users. It is not the primary site editor. |
| Effects web | CSA `overlay_effects` WASM + canvas host. Conditional script tag for `site-guest.effects.v1.js` only when a preset is active. |
| Effects Flutter | Existing Dart painters + pointer hub. No FFI in this plan. |
| AI section | Knowledge rows on `doc_json.knowledge[]` (`id`, `title`, `content`). Not a new LLM product. |
| Accounts | Payment accounts on `doc_json.payment_accounts[]` (bank, account name, number, qris pic). Boot exposes them as `commerce_boot.payment_methods`. |
| Notifications | `doc_json.notify.order_ring` is `once` or `until_handled`. Playback uses the existing staff order push; this plan only stores the pref. |
| Attendance | UI over `site.work_shift*` and `site.presence_location` from the Team plan. Do not start Attendance until those tables exist. |
| Plan section | No CSA Alien-Coin site SKUs. Show the owner wallet / current billing summary and a link to the existing billing screen. |
| Capabilities | Keep the c35 Settings → Capabilities item. CSA has no equivalent menu row. |

---

## Gap table

| Surface | CSA | c35 now | This plan |
|---------|-----|---------|-----------|
| Web effects | `client/site/src/effects/host.ts` + `public/static/csa-effects/overlay_effects.wasm` | `site-guest.effects.v1.js` canvas stub, conditional script tag, `pointer-events: none` | Wave 2 |
| Flutter effects | Dart painters (README: FFI later) | Dart painters already ported | Wave 2 diff only |
| Flutter `map` `queue` `embed` `custom_html` | Hub/detail components | Missing; fall through to markdown | Wave 3 |
| Product / post detail in preview | `/products/{id}` `/posts/{id}` | HTML routes exist; Flutter preview has no detail | Wave 3 |
| Guest stock line | `stock_show_to_customer` | Field on product JSON; guest HTML ignores it | Wave 3 |
| Contact `data-guest` | `form` | `<form class="contact-form">` only | Wave 3 |
| Editor menu | info, links, design, effects, ai, products, objects, contacts, queue, team, attendance, accounts, notifications, plan, publish. Default **info** | Missing ai, attendance, accounts, notifications, plan. Default **products** | Wave 4–6 |

---

## Wave map

```
WAVE 0  S0   Revise site.md + site-guest-components.md (locked decisions above)

WAVE 1  (parallel, no server_ai dep)
  E1   Copy overlay_effects crate + wasm build script (not a workspace member)
  E2   Build wasm32 artifacts into clients/web/static/site-guest/effects/

WAVE 2  (after E2)
  E3   Replace site-guest.effects.v1.js with CSA host (WASM + pointer)
  E4   Diff Flutter painters vs CSA; copy only missing runners/physics
  E5   Boot still emits effects[]; host adapts presetId/params

WAVE 3  (parallel with Wave 2)
  R1   Flutter: map, queue, embed, custom_html
  R2   Flutter product detail + post detail
  R3   stock_show_to_customer on Rust HTML + Flutter
  R4   contact_form data-guest="form" both sides

WAVE 4  (after S0; parallel)
  M1   Editor menu order, default Info, new section ids wired to placeholders that compile
  M2   AI knowledge section → doc_json.knowledge
  M3   Notifications → doc_json.notify.order_ring

WAVE 5  (parallel; M3 independent, A1 needs Team-plan tables)
  A1   Accounts section → doc_json.payment_accounts + commerce_boot.payment_methods
  A2   Attendance section (shifts + presence areas) once Team plan schema is in
  P1   Plan section = billing summary link, no new SKU

WAVE 6
  V1   Tests listed below
  V2   publish_server only when HTML/JS/WASM changed; re-publish one guest site
```

---

## Wave 0 — S0 spec

**Files:** `\_/docs/site.md`, `\_/docs/site-guest-components.md`

- [ ] **S0.1** In `site.md` replace the three bullets under the title:

```markdown
- **Primary editors** → Sites page (CSA section menu, Info first) and Home prompt (`@alien_id`, topic `web.builder`)
- **Admin UI** → Sites editor shell (rail + preview). `UITable` remains for power users
- **Guest effects** → Web runs `overlay_effects` WASM only when the theme has an active preset. Flutter runs Dart painters. Preset ids match `presets.json`
```

- [ ] **S0.2** Reference table: add a row that `D:\csa_site_published` is also the source for `crates/overlay_effects`, `client/site/src/effects/host.ts`, and `clients/app/lib/widgets/site/ui_site_*_section.dart` (UX only).
- [ ] **S0.3** In `site-guest-components.md`, set the effects row: web = WASM host (`site-guest.effects.v1.js`, conditional script tag), Flutter = `GuestSiteEffectStack`. Document boot fields `presetId`, `params` (object), `active`. Document `commerce_boot.payment_methods` from `doc_json.payment_accounts`. Document `data-guest="form"` on `contact_form`. No Alpine. Do not split form or queue into extra script files.

---

## Wave 1 — E1 / E2 effect crate

**CSA source (read-only):** `D:\csa_site_published\crates\overlay_effects\` (`Cargo.toml`, `src/`, `presets.json`, `scripts/build.ps1`).

**Files:**

- Create: `servers/crates/overlay_effects/` (copy of CSA crate: `Cargo.toml`, `src/`, `presets.json`, `scripts/build.ps1`)
- Do **not** edit `servers/Cargo.toml` members

**Interfaces:**

- WASM exports (from CSA README): `overlay_init(preset, params_json, w, h) -> bool`, `overlay_resize(w, h)`, `overlay_tick(dt) -> count`, `overlay_particles_ptr()`, `overlay_particle_stride()` (8 × f32: kind, x, y, a, b, rot, opacity, color_u32).
- Kinds used by `host.ts`: `0` line, `1` glyph, `2` ellipse, `3` filled ellipse, `4` sakura, `5` leaf, `6` moon.

- [ ] **E1.1** Copy the crate tree. Keep `crate-type = ["cdylib", "rlib"]` and `wasm-bindgen`.
- [ ] **E1.2** Confirm `servers/Cargo.toml` members list does not include `overlay_effects`.
- [ ] **E2.1** Run CSA `scripts/build.ps1` from the copied crate (wasm32-unknown-unknown). Output must include `overlay_effects.js` and `overlay_effects_bg.wasm` (names match whatever `wasm-bindgen` emits; record the real filenames in the script comment).
- [ ] **E2.2** Copy those artifacts to `clients/web/static/site-guest/effects/`. The guest page will load `/static/site-guest/effects/overlay_effects.js`.
- [ ] **E2.3** `cd servers/crates/overlay_effects; cargo test` (native rlib tests if CSA has any). wasm build is the web gate.

---

## Wave 2 — E3 / E4 / E5 web host + Flutter diff

**CSA source:** `D:\csa_site_published\client\site\src\effects\host.ts` (`startGuestEffects`).

**Files:**

- Modify: `clients/web/static/site-guest/site-guest.effects.v1.js` (replace the particle stub)
- Modify: `servers/crates/mod_site/src/render.rs` `guest_client_script_tags`. Emit `site-guest.v1.js` on every page. Emit a conditional script tag for `site-guest.effects.v1.js` plus `/static/site-guest/effects/overlay_effects.js` and wasm only when at least one effect has `active !== false` and a known preset id. Do not split form or queue into extra script files. No Alpine.js.
- Modify: Flutter runner files under `clients/app/lib/widgets/overlay_effect/` only where a diff against `D:\csa_site_published\clients\app\lib\widgets\overlay_effect\` shows missing behavior.

**Interfaces:**

- Boot row (c35, already written by `theme_effects` / `site_boot.rs`): `{ id, presetId, params, active }`.
- Host normalizes before `overlay_init`:

```javascript
function effectBootRow(row) {
  var preset = row.presetId || row.preset_id || "";
  var params = row.params_json || row.params || {};
  var paramsJson = typeof params === "string" ? params : JSON.stringify(params);
  return { preset_id: String(preset).replace(/_/g, "-"), params_json: paramsJson, active: row.active !== false };
}
```

- [ ] **E3.1** Delete the generic `fillRect` / `arc` loop in `site-guest.effects.v1.js`.
- [ ] **E3.2** Port `startGuestEffects`: load wasm from `/static/site-guest/effects/overlay_effects.js`, init one sim per active preset, `requestAnimationFrame` tick, draw the 8-float particle buffer with the same kind switch as `host.ts`.
- [ ] **E3.3** Forward pointer down / move / up into the sim the same way `host.ts` does. The canvas must not be `pointer-events: none` if the sim reads pointers; hit-testing must still leave page links clickable (CSA uses the page as the pointer source and a non-hit canvas for paint — copy that, do not invent a new model).
- [ ] **E3.4** Unknown `presetId` is skipped. `active: false` is skipped. Empty effects array leaves the page with no canvas.
- [ ] **E4.1** Diff `widgets/overlay_effect/` against CSA. Copy a runner only when CSA has a behavior c35 lacks (pointer physics, glyph kind). Do not add `DynamicLibrary` / FFI.
- [ ] **E5.1** Widget test: boot with `presetId: rain-shower`, `active: true` still finds `UiOverlayEffectStack`. Inactive preset does not.
- [ ] **E5.2** Rust render test: published HTML contains the conditional `site-guest.effects.v1.js` script tag and `"presetId"` (or the inlined effects array) for a theme that has one active known preset. A theme with no active preset does not include that script tag. Do not assert pixel output.

---

## Wave 3 — renderer gaps

**Files:**

- Modify: `clients/app/lib/guest_site/guest_site_blocks.dart` (`guestSiteBlock` switch)
- Modify: `servers/crates/mod_site/src/render.rs` `block_html_render` and `product_card_html`
- Test: `clients/app/test/guest_site_view_test.dart`, `servers/crates/mod_site/tests/render_test.rs`

### R1 — missing Flutter blocks

`guestSiteBlock` today handles hero, contact_form, product_grid, gallery, image, links, social_feed, hub_profile, partners_display, clients_display, order_track, hours, spacer. Add:

| `type` | Flutter | Web (already in `render.rs`) |
|--------|---------|------------------------------|
| `map` | OpenStreetMap link from `lat`/`lng` (same URL as Rust). No new map SDK. | Keep existing iframe/link |
| `queue` | Take-number button calling the same guest queue HTTP as `c35GuestQueue.take`. Hidden when capability `queue` is off. | Already rendered |
| `embed` | `Image.network` is wrong. Show title + `url_launcher` on the URL. Do not embed arbitrary HTML. | Keep iframe |
| `custom_html` | One line: custom HTML is on the published page only. Do not `HtmlWidget` unsanitized staff HTML inside the app. | Keep sandboxed Rust output |

- [ ] **R1.1** Widget tests: boot with `map` shows the label; `queue` shows "Ambil nomor"; `embed` shows the url; `custom_html` does not throw and does not render raw HTML tags as widgets.

### R2 — detail routes inside preview

Web already emits `html:/products/{id}` and `html:/posts/{id}`. Flutter preview has no matching screen.

- [ ] **R2.1** Product tap in `GuestSiteProductGridBlock` opens a detail route/sheet with name, desc, price, pic or icon, and the same Reservasi vs `+ Pesan` rule as the card (`can_reserve`).
- [ ] **R2.2** Social feed item tap opens post detail from `posts_preload` (title, caption, body). No extra RPC when the post is already in boot.

### R3 — stock line

Product JSON already has `stock_show_to_customer` (`clients/app/lib/c/site/site_product_json.dart`). Guest render ignores it.

- [ ] **R3.1** When the flag is true and a stock count is on the product row, Rust card HTML and Flutter row both show `Stock: n`. When the flag is false, neither shows a stock line.
- [ ] **R3.2** Test both sides with the flag on and off.

### R4 — form attribute

- [ ] **R4.1** `contact_form` HTML root includes `data-guest="form"`. Flutter `GuestSiteContactFormBlock` sets `Key('guest-form')` so tests can find it. Submit still uses the existing lead RPC (`c35GuestLead` / Flutter equivalent). Do not add `/forms/{id}`.

---

## Wave 4 — editor menu + AI + notifications

**CSA source:** `ui_site_editor_menu.dart`, `ui_site_ai_section.dart`, `ui_site_notifications_section.dart`.

**Files:**

- Modify: `clients/app/lib/widgets/sites/editor/ui_site_editor_menu.dart`
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` (section switch)
- Create: `clients/app/lib/widgets/sites/editor/ui_site_ai_editor.dart`
- Create: `clients/app/lib/widgets/sites/editor/ui_site_notifications_editor.dart`
- Modify: draft load/save helper used by Info (`site_draft_meta.dart` or a sibling `site_draft_knowledge.dart`)

**Menu order (match CSA, plus c35 Capabilities):**

```text
Site:        info, links, design, effects, ai
Catalog:     products, objects, contacts, queue
Settings:    capabilities, team, attendance, accounts, notifications, plan, publish
```

`siteEditorMenuDefaultId = 'info'`.

**Knowledge JSON** (inside `doc_json`, not a new table):

```json
"knowledge": [{ "id": "k1", "title": "Hours", "content": "Open 9–5" }]
```

**Notify JSON:**

```json
"notify": { "order_ring": "until_handled" }
```

Allowed values: `once`, `until_handled`. Missing key reads as `until_handled`.

- [ ] **M1.1** Menu ids and default. Shell `switch` has a widget for every id. New ids may be a short “not ready” pane until M2/M3/Wave 5 land in the same wave; do not leave a red screen or a missing case.
- [ ] **M2.1** AI section: searchable list, add, edit title/content, delete. Save through the existing draft save bus (`draftPut`). Empty list copy matches CSA empty state in plain English (c35 editor strings are not `.tr()` today — follow `ui_site_info_editor.dart`, not CSA `easy_localization`).
- [ ] **M2.2** Test: `knowledgeAdd` equivalent round-trips through the draft JSON helper.
- [ ] **M3.1** Notifications: two radios, `once` and `until_handled`, saved on `doc_json.notify`.
- [ ] **M3.2** Test: parse missing notify → `until_handled`; parse `once` stays `once`.

Knowledge is editor data for the site. Wiring it into the Home prompt is **out of this plan** (no new `inst` rows, no `prompt_run`).

---

## Wave 5 — accounts, attendance, plan

### A1 Accounts

**CSA source:** `ui_site_accounts_section.dart`, `site_payment_account.dart`.

**JSON:**

```json
"payment_accounts": [{
  "id": "pa1",
  "bank": "BCA",
  "account_name": "Toko",
  "account_number": "123",
  "qris_pic": ""
}]
```

- [ ] **A1.1** Master/detail editor: list, add, edit, delete. Persist on draft save.
- [ ] **A1.2** `site_boot` copies these rows to `commerce_boot.payment_methods` when `commerce` is on (`id`, `bank`, `account_name`, `account_number`, `qris_pic` only).
- [ ] **A1.3** Guest checkout (existing cart modal in `site-guest.v1.js` and Flutter cart) lists those methods when the array is non-empty. Do not invent a new payment provider. Choosing a method stores its `id` on the guest order note or the existing payment field the commerce plan already uses — read `guest_order_put` before adding a column. If no field exists, put `payment_account_id` in the order JSON payload the put handler already accepts, and ignore unknown ids server-side with a clear error.

### A2 Attendance

**Depends on:** [`2026-10-08-site-team-editor-csa-parity-multitask.md`](2026-10-08-site-team-editor-csa-parity-multitask.md) tables `site.work_shift`, `site.work_shift_slot`, `site.presence_location`.

**CSA source:** `ui_site_attendance_section.dart`, `ui_site_attendance_area_section.dart`.

- [ ] **A2.1** If those tables are not migrated yet, the Attendance menu item stays disabled with the Team-plan name in the subtitle. Do not create a second schema.
- [ ] **A2.2** When the tables exist, port the CSA list: areas (presence locations) and shifts, master/detail, save via the RPCs the Team plan added (`ReqSite*` shift/location). Face enroll stays on Team, not a second uploader here.

### P1 Plan

**CSA source:** `ui_site_plan_section.dart` (subscribe with Alien Coin). **Do not port subscribe.**

- [ ] **P1.1** Section shows the owner billing summary already available to the app (wallet balance / plan name if `BillingApi` exposes it). Button opens the existing billing route. No new product ids, no `site_plans` table.

---

## Wave 6 — verify

| Track | Command |
|-------|---------|
| WASM crate | `cd servers/crates/overlay_effects; cargo test` and the wasm `build.ps1` |
| Guest HTML | `cd servers; cargo test -p c35_mod_site` |
| Flutter | `cd clients/app; flutter test test/guest_site_view_test.dart test/guest_site_design_test.dart` plus the new knowledge/notify tests |
| App analyze | `.\_\scripts\dev\verify_flutter_app.ps1` |
| UTF-8 | `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` |
| Server binary | `cd servers; cargo build -p server_ai` (must succeed **without** linking `overlay_effects`) |

- [ ] **V1.1** Manual: Effects → Rain on a published site. View source loads `overlay_effects` wasm. Rain is the CSA sim (strokes), not the old white dots. Phone preview still shows rain via Dart painters.
- [ ] **V1.2** Manual: editor opens on Info. AI knowledge survives reload. Notifications radio survives reload. A payment account shows in guest checkout after publish.
- [ ] **V2.1** If `render.rs` or `clients/web/static/site-guest/` changed: `.\_\scripts\deploy\publish_server.ps1` and re-publish one test site so `site.render` picks up the new script tags. End the reply with the publish summary from `.cache/publish-perf/latest.json`.

---

## Out of scope

- Alpine.js and CSA `SiteDraft` type in the c35 app.
- Flutter FFI to `overlay_effects`.
- CSA per-site subscription SKUs.
- `/forms/{id}`, `/contacts/{id}`, `/checkout` as separate SiteDoc pages (checkout stays the cart sheet).
- Feeding `knowledge[]` into the LLM system prompt.
- Replacing prompt-built `site.patch` / `site.publish`.

---

## Agent assignment

| Agent | Wave | Track |
|-------|------|-------|
| A | 0 | S0 docs |
| B | 1 | E1 + E2 |
| C | 2 | E3 + E5 (after E2) |
| D | 2 | E4 Flutter diff (parallel with E3) |
| E | 3 | R1 + R4 |
| F | 3 | R2 + R3 |
| G | 4 | M1 + M2 + M3 |
| H | 5 | A1 |
| I | 5 | A2 (only if Team schema exists) + P1 |
| J | 6 | V1 + V2 |

**Dependencies:** E3 needs E2 artifacts. A2 needs the Team plan tables. Wave 3 does not wait on effects. Wave 4 menu can land before Wave 5 bodies; placeholders must compile.
