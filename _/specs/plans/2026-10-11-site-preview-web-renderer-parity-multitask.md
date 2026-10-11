# Site guest preview → web renderer parity (app canonical)

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks and does not implement every lane inline. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Published guest HTML/CSS/JS on `alienai.id/{alien_id}` matches what the app shows in **Sites → Preview** (`GuestSiteView`), block order, chrome, typography, commerce UX, and effects — using **Flutter as the visual and behavior reference**, not CSA HTML and not “close enough.”

**Architecture:** Keep the **dual renderer** (native widgets + Rust prerender + `site-guest.v1.js`). Do not replace preview with a WebView. **Single boot contract** (`site.boot_get` / inlined `__SITE_GUEST__`) is unchanged. Parity is enforced by a **block matrix**, shared fixtures, and tests that assert web output against semantics taken from `clients/app/lib/guest_site/`. When Flutter and web disagree, **change web** (`mod_site` render + static guest bundle) unless the bug is clearly wrong data in boot assembly.

**Tech stack:** Flutter `clients/app/lib/guest_site/` + `c/site/design/`, Rust `servers/crates/mod_site` (`render.rs`, `guest_design.rs`, `site_boot.rs`), static `clients/web/static/site-guest/`, tests `guest_design_test.rs`, `guest_site_design_test.dart`, `guest_site_view_test.dart`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md) · [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc)

**Related plans (do not duplicate finished work):** [`2026-10-08-site-blocks-effects-render-parity.md`](2026-10-08-site-blocks-effects-render-parity.md) (design tokens + fixture), [`2026-10-08-site-csa-editor-renderer-effects-multitask.md`](2026-10-08-site-csa-editor-renderer-effects-multitask.md) (effects WASM, editor menu, detail routes), [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) (cart/checkout/order progress). **This plan** adds the **app-wins parity process**, a **full block/interaction audit**, and **CI-style gates** tying Flutter behavior to Rust/JS.

---

## Global constraints

- Preview stays `GuestSiteView` + `site.boot_get` (draft or published mode). No WebView of published HTML for parity “fixes.”
- Guest URLs stay `https://alienai.id/{alien_id}/…`. App staff edits stay WebSocket `ReqSite*`.
- No Alpine.js. One interactivity script: `site-guest.v1.js` (+ conditional `site-guest.effects.v1.js`).
- No provider web grounding. UTF-8 sources; verify per `verify-after-edit.mdc`.
- **App-first rule:** Any PR that changes `clients/app/lib/guest_site/**` or guest-relevant `c/site/design/**` must include matching web/renderer changes in the same PR (or an explicitly linked follow-up with a failing parity test in main — avoid).
- Republish + redeploy: Rust/HTML/CSS/JS fixes require `publish_server` and **site publish** to show on live URLs; remind in PR test plan.

---

## Locked decision (Wave 0 → `site.md` + `site-guest-components.md`)

| Topic | Decision |
|-------|----------|
| **Canonical UI** | **App preview** (`GuestSiteView`) is the reference for layout, visibility flags, spacing rhythm, and commerce UX. |
| **Web role** | Rust HTML + `site-guest.v1.css` + `site-guest.v1.js` **emulate** the Flutter widgets, same boot JSON. |
| **CSA** | `D:\csa_site_published` is a **port source** for missing behavior, not an override when app preview already looks correct. |
| **Done definition** | A block or chrome concern is done only when fixture tests pass **and** manual check: same site, draft boot mode = published boot mode, preview tab = browser (after publish). |

---

## Parity matrix (block types)

Use this table as the audit checklist. **Reference implementation:** Dart switch in `guest_site_blocks.dart` (`guestSiteBlock`). **Web implementation:** `block_html_render` in `render.rs` + styles in `guest_root_css` / inline page CSS / `site-guest.v1.css` + behavior in `site-guest.v1.js`.

| `type` | Flutter widget(s) | Web HTML | Web JS | Fixture test id |
|--------|-------------------|----------|--------|-----------------|
| `hero` | `GuestSiteHeroBlock` | `render.rs` `hero` | — | `parity_hero` |
| `hub_profile` | `GuestSiteHubProfileBlock` | `hub_profile` | — | `guest_design` (existing) |
| `links` | `GuestSiteLinksBlock` | `links` | — | `guest_design` |
| `product_grid` | `GuestSiteProductGridBlock` | `product_grid` | cart, load-more | `parity_product_grid` |
| `partners_display` / `clients_display` | `GuestSiteFeaturedStripBlock` | `featured_strip_html` | — | `guest_design` |
| `social_feed` | `GuestSiteSocialFeedBlock` | `social_feed` | — | `parity_social_feed` |
| `contact_form` | `GuestSiteContactFormBlock` | `contact_form` | `c35GuestLead` | `parity_form` |
| `hours` | `GuestSiteHours*` | `hours` | — | `parity_hours` |
| `gallery` / `image` / `markdown` / `spacer` | respective `GuestSite*` | match arms | — | `parity_media` |
| `map` / `queue` / `embed` / `custom_html` | respective `GuestSite*` | match arms | queue RPC | `parity_misc` |
| `order_track` | `GuestSiteOrderTrackBlock` | `order_track` | poll | `parity_order_track` |
| **Chrome** | `GuestSiteView` + `siteDesignResolve` | `guest_shell_html`, `guest_root_css` | effects host | `guest_design` |
| **Cart / checkout** | `guest_site_cart.dart`, reservation sheet | sticky bar HTML | `site-guest.v1.js` | `parity_commerce` |
| **Product/post detail** | preview routes (if shipped) | detail render fns | same JS | `parity_detail` |

Mark each row **PASS / GAP** in Wave 1; every **GAP** gets a wave task below.

---

## Wave map

```
WAVE 0  P0   Policy docs + cursor rule (shipped with this file)

WAVE 1  (parallel audit — read-only + tests)
  A1   Generate gap report: matrix above vs current HTML/JS (subagent explore)
  A2   Extend fixtures/README under mod_site/tests/fixtures/ (one JSON per block family)
  A3   Document boot key parity: Flutter GuestSiteBoot vs __SITE_GUEST__ fields

WAVE 2  (parallel — page chrome, app wins)
  C1   Diff GuestSiteView shell (padding, max width, bottom cart inset) → guest_shell_html + .wrap
  C2   Backdrop + page background: match site_backdrop.dart / resolved background → CSS + data-backdrop
  C3   Card chrome: siteCardDecorationResolve → guest_card_html helpers (link/product/strip)
  C4   Tests: extend guest_design_test + guest_site_design_test for C1–C3 tokens

WAVE 3  (parallel — hub blocks)
  B1   hub_profile: mirror profile flags, avatar size, chips, hours chip (read Flutter, port HTML)
  B2   links + product_grid: list vs grid, cardStyleId none, product typography from design.product
  B3   featured strips: item modes card / icon / icon_label, header align (match strip widgets)
  B4   social_feed, hours, hero, gallery, image, markdown, spacer: line-by-line Dart → HTML/CSS
  B5   Per-block Rust tests using A2 fixtures; widget tests with same JSON pages[]

WAVE 4  (parallel — interactive + commerce, app wins)
  I1   Cart drawer: match steps, labels (ID copy), payment methods from commerce_boot
  I2   Reservation sheet: same math as site_reservation_math / window.c35ReservationMath
  I3   contact_form, queue, order_track: same validation messages and disabled states as Flutter
  I4   stock_show_to_customer, can_reserve, guest_picks units — match product card actions
  I5   JS unit tests where feasible (reservation math); else golden boot + manual script in plan

WAVE 5  (detail routes + preview navigation)
  D1   Flutter preview navigates to product/post detail like public URLs
  D2   Rust detail HTML matches Flutter detail widgets (typography, carousel, reserve CTA rules)
  D3   Test: same product id → title + price string match in HTML fixture and widget test

WAVE 6  (effects)
  X1   Active effects: Flutter GuestSiteEffectStack vs site-guest.effects.v1.js (preset id + params)
  X2   Z-order: backdrop < effects < blocks < cart chrome (match IgnorePointer behavior)

WAVE 7  (ship + regression)
  V1   cargo test -p mod_site guest_design parity_
  V2   flutter test test/guest_site_design_test.dart test/guest_site_view_test.dart
  V3   Rebuild site-guest bundle: clients/web/static/site-guest/build.ps1
  V4   Manual E2E script (below) on one commerce + one hub-only site, owner 99000
  V5   Optional: render_test.rs snapshot guard — fail if block_html_render output changes without fixture update
```

---

## Wave 0 — Policy (docs)

- [ ] **P0.1** Add subsection **Guest renderer parity** to [`_/specs/site.md`](../site.md): app preview canonical; dual renderer; link this plan.
- [ ] **P0.2** Add row to [`_/specs/site-guest-components.md`](../site-guest-components.md): “Canonical behavior: Flutter `guest_site/`; web must match.”
- [ ] **P0.3** Rule live: [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc).

---

## Wave 1 — Audit and fixtures

### A1 — Gap report

| Item | Detail |
|------|--------|
| **Output** | `_/specs/plans/artifacts/2026-10-11-guest-parity-gaps.md` (create dir if needed) |
| **Method** | For each matrix row, compare Dart widget build structure vs rendered HTML snippet from `page_html_render` / `block_html_render` with `guest_design_min.json` + block-specific fixture |
| **Deliverable** | PASS/GAP table + file:line pointers for each GAP |

### A2 — Fixture library

| Item | Detail |
|------|--------|
| **Files** | `servers/crates/mod_site/tests/fixtures/guest_parity_*.json` — one page per block family, shared `theme` from `guest_design_min.json` |
| **Test** | `guest_design_test.rs` or new `guest_parity_test.rs` loads each fixture and asserts `data-guest`, key CSS vars, absence/presence rules (e.g. no avatar img when `showAvatar: false`) |

### A3 — Boot contract doc

| Item | Detail |
|------|--------|
| **Files** | Short table in `site-guest-components.md` § Boot JSON: column **Flutter field** / **__SITE_GUEST__ key** / **Used by JS** |
| **Check** | `GuestSiteBoot.fromJson` vs `site_boot_json_assemble` vs `render.rs` guest script inline JSON |

---

## Wave 2 — Page chrome (app wins)

**Reference files:** `guest_site_view.dart`, `guest_site_shell.dart`, `site_design_resolve.dart`, `site_backdrop.dart`.

- [ ] **C1** Match max content width (~960 logical px), horizontal padding 16–24, `padding-bottom` for cart bar (80px web already; verify against Flutter `SafeArea` + cart).
- [ ] **C2** Background types `none` | `color` | `image` — same precedence as Dart; image blur/overlay if implemented in app.
- [ ] **C3** Global and per-block card styles: same ids as `site_card_style.dart` (`none`, `solid`, …).
- [ ] **C4** Tests updated; no new block types without matrix row.

---

## Wave 3 — Hub blocks (app wins)

For each task: **read Flutter widget first**, list visible nodes and styles, then change `render.rs` + CSS only.

- [ ] **B1** `hub_profile`
- [ ] **B2** `links`, `product_grid`
- [ ] **B3** `partners_display`, `clients_display`
- [ ] **B4** content blocks (`hero`, `social_feed`, `hours`, `gallery`, `image`, `markdown`, `spacer`, `map`, `embed`, `custom_html`, `queue`)
- [ ] **B5** Fixture + widget tests per B1–B4

**Avoid:** duplicating product typography logic only in Rust — extract shared numbers from `GuestDesign` / `product_design` already on boot; Flutter uses `guestSiteProductTextStyle`; web uses inline styles + CSS vars with **same numeric defaults** as Dart.

---

## Wave 4 — Commerce and JS (app wins)

**Reference:** `guest_site_cart.dart`, `guest_site_reservation_sheet.dart`, `guest_site_commerce_boot.dart`, `site-guest.v1.js`.

- [ ] **I1–I4** See wave map; align copy and edge cases (empty cart, single payment method, booking off).
- [ ] **I5** Document `node` test or rust-side port of reservation math if JS test harness is heavy.

After JS/CSS edits: run `clients/web/static/site-guest/build.ps1` and commit built `site-guest.v1.js` / `.css` if repo tracks built artifacts (match existing convention in tree).

---

## Wave 5 — Detail routes

Depends on Flutter detail navigation existing or being added in CSA editor plan Wave 3.

- [ ] **D1–D3** Product detail: reserve vs add-to-cart mutual exclusion per `site-guest-components.md`. Post detail: carousel behavior.

---

## Wave 6 — Effects

- [ ] **X1–X2** Same active preset list; web skips unknown ids without throwing; Flutter `IgnorePointer` on effect layer unless preset docs say otherwise.

---

## Wave 7 — Verification

```powershell
cd D:\c35\servers
cargo test -p mod_site guest_design
cargo test -p mod_site guest_parity   # after A2

cd D:\c35\clients\app
flutter test test/guest_site_design_test.dart test/guest_site_view_test.dart

cd D:\c35
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

### Manual E2E (V4)

1. Sites → pick site with Design + Products + Effects configured (99000).
2. Preview tab: note accent, profile avatar on/off, product price size, cart label, one effect.
3. Publish site.
4. Open `https://alienai.id/{alien_id}/` (hard refresh).
5. **Pass:** same visual checks; cart and one product action behave the same.

---

## Subagent dispatch map (parent session)

| Wave | Tracks | Parallel? |
|------|--------|-----------|
| 1 | A1, A2, A3 | Yes |
| 2 | C1–C4 | C1–C3 parallel; C4 after |
| 3 | B1–B5 | B1–B4 parallel; B5 after |
| 4 | I1–I5 | I1–I4 parallel |
| 5 | D1–D3 | Sequential D1→D2→D3 |
| 6 | X1, X2 | Parallel |
| 7 | V1–V5 | Sequential |

Each track prompt must include: **“App preview is canonical; port gaps to render.rs and site-guest static files.”** and link this plan.

---

## File map (quick reference)

| Concern | App (reference) | Web (follow) |
|---------|-----------------|--------------|
| Blocks | `clients/app/lib/guest_site/guest_site_blocks.dart` | `servers/crates/mod_site/src/render.rs` |
| Design tokens | `c/site/design/site_design_resolve.dart` | `guest_design.rs`, `guest_root_css` |
| Shell / backdrop | `guest_site_view.dart` | `guest_shell_html`, `site-guest.v1.css` |
| Boot parse | `guest_site_boot.dart` | `site_boot.rs`, `render.rs` script tags |
| Cart / reserve | `guest_site_cart.dart`, `guest_site_reservation_sheet.dart` | `site-guest.v1.js` |
| Effects | `guest_site_effect_stack.dart` | `site-guest.effects.v1.js` |
| Tests | `test/guest_site_*.dart` | `tests/guest_design_test.rs`, `guest_parity_test.rs` |

Do not commit unless the user asks.
