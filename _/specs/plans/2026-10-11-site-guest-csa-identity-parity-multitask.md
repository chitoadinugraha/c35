# Site guest identity parity — app, web, and CSA reference

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks and does not implement every lane inline. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Sites look and behave the same in **Flutter Preview** (`GuestSiteView`), **published web** (`http://localhost:10000/{alien_id}` and `https://alienai.id/{alien_id}`), and the **CSA guest reference** (`D:\csa_site_published`) — without replacing the dual renderer with a WebView or Alpine.js.

**Architecture:** Keep **one boot JSON** (`site.boot_get` / inlined `__SITE_GUEST__`) and **two renderers** (Flutter widgets + Rust HTML + `site-guest.v1.js/css`). **Canonical behavior and layout:** app preview wins when c35 Flutter and c35 web disagree. **Port source for missing polish:** CSA prerender + `client/site/src/main.ts` when both c35 renderers should match CSA UX (hub list rows, link placements, cart chrome, post carousel). Enforce parity with **shared fixtures**, **three-way audit rows**, and **golden sites** (include `natepaperie` once boot is exported).

**Tech stack:** Flutter `clients/app/lib/guest_site/` + `c/site/design/`; Rust `servers/crates/mod_site` (`render.rs`, `guest_design.rs`, `site_boot.rs`, `http.rs`); static `clients/web/static/site-guest/`; CSA read-only `D:\csa_site_published\crates\mod_site\src\render\`, `client/site/src/`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md) · [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc)

**Related plans (do not redo finished work):**

| Plan | Role |
|------|------|
| [`2026-10-11-site-preview-web-renderer-parity-multitask.md`](2026-10-11-site-preview-web-renderer-parity-multitask.md) | App-wins process, block matrix, Waves 2–7 |
| [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) | Cart, checkout, member area, NATS staff notify |
| [`2026-10-08-site-csa-editor-renderer-effects-multitask.md`](2026-10-08-site-csa-editor-renderer-effects-multitask.md) | Effects WASM, editor, detail routes |
| [`artifacts/2026-10-11-guest-parity-gaps.md`](artifacts/2026-10-11-guest-parity-gaps.md) | Last verification snapshot |

**CSA docs (read-only):** `D:\csa_site_published\.agents\guest_ui.md`, `D:\csa_site_published\crates\mod_site\src\render\hub.rs`, `theme.rs`, `post.rs`, `client/site/src/main.ts`, `invoke.ts`.

---

## Global constraints

- **No WebView preview** of published HTML to “fix” Flutter — port to Rust/JS or fix boot.
- **No Alpine.js** on c35 web — port CSA Alpine behavior into `site-guest.v1.js` only.
- Guest order money path stays **`POST /v1/site/guest-order/put`** ([`_/specs/tx.md`](../tx.md)); no CSA `/a/http` protobuf band on public guest.
- **Draft vs published:** browser `/{alien_id}` serves **`site.render`** (last publish). Editor preview defaults **draft** `boot_get`. Compare fairly before calling a renderer bug (see Wave 0).
- **Draft web preview:** `?draft=1&ptoken=…` → `site_draft_html_render` (same `page_html_render` as publish job).
- UTF-8 sources; verify per [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc).
- After Rust/JS/CSS ship: `cargo test -p c35_mod_site`, `flutter test` guest tests, `clients/web/static/site-guest/build.ps1`, **site Publish** in app, `publish_server.ps1` for cluster.

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| **Canonical UI** | **Flutter `GuestSiteView`** for c35 preview vs c35 web. |
| **CSA role** | **Reference implementation** for hub commerce UX and CSS class rhythm when c35 both sides should match CSA (not an override when app preview is already correct and CSA differs). |
| **Identity bar** | Same site must show the same blocks, order, typography scale, cart chrome, and detail routes from the **same boot** (draft or published mode explicitly chosen). |
| **Done definition** | Fixture tests pass; golden site manual script passes for **draft URL**, **published URL**, and **Preview (matching mode)**. |
| **Golden sites** | At least: one **hub + commerce** (`natepaperie` or owner 99000 commerce site), one **hub-only** (links + profile), one **effects** site. |

---

## Three-way parity matrix (audit driver)

For each row, status **PASS / GAP** in `artifacts/2026-10-11-guest-csa-identity-gaps.md` (create in Wave 1). Resolution column: **fix-web**, **fix-flutter**, **fix-boot**, **port-csa**.

| Concern | Flutter (c35) | Web (c35) | CSA reference | Fixture |
|---------|---------------|-----------|---------------|---------|
| **Data: draft boot** | `boot_get` draft | `?draft=1&ptoken` | N/A | export JSON |
| **Data: published boot** | `boot_get` published | `site.render` | published HTML | export JSON |
| Page shell (max width, pad, cart inset) | `guest_site_view.dart` | `guest_shell_html`, `.wrap` | `theme.rs` hub shell | `guest_design_min.json` |
| Backdrop | `site_backdrop.dart` | `data-backdrop`, CSS | backdrop in theme | design fixture |
| Card styles | `site_card_style.dart` | `guest_card_html` | hub card classes | card style ids |
| `hub_profile` | `GuestSiteHubProfileBlock` | `hub_profile` | `hub.rs` profile | `guest_parity_hub.json` |
| `links` placements | `GuestSiteLinksBlock` | `links` | `links_html` list/icon/icon_label | links fixture |
| `product_grid` | list + grid | `product_card_html` / list row | `catalog_html` | product grid fixture |
| Product detail | preview route | `html:/products/{id}` | product detail in hub | product id fixture |
| Post detail + carousel | preview route | `html:/posts/{id}` | `post.rs` | post id fixture |
| Cart chrome | `guest_site_cart.dart` | sticky bar + drawer | `main.ts` `guestCart` | commerce_boot fixture |
| Checkout copy (ID) | Flutter strings | `site-guest.v1.js` | CSA strings | parity_commerce |
| Reservation | `guest_site_reservation_sheet.dart` | `c35ReservationMath` | CSA reserve flow | booking fixture |
| `contact_form` | **stub today** | `c35GuestLead` | form + RPC | **fix-flutter** |
| `order_track` | poll UI | `c35GuestOrder.poll` | order poll | order_track fixture |
| Effects z-order | `GuestSiteEffectStack` | `site-guest.effects.v1.js` | effects host | effects fixture |
| Hero vs hub delegate | Dart hub rules | Rust `hero` arm | hub.rs | hub+hero fixture |

---

## Multitask map

```
WAVE 0  Same data — publish, preview URL, golden boot exports (unblock "completely different")
WAVE 1  Audit — three-way gap report + fixture library + natepaperie boot snapshot
WAVE 2  CSA visual tokens — theme.rs → guest_design.rs + site-guest.v1.css (shell, type scale, hub rhythm)
WAVE 3  Hub blocks — port CSA markup semantics to render.rs; mirror in Flutter if CSA-aligned
WAVE 4  Commerce chrome — main.ts cart/checkout vs site-guest.v1.js + guest_site_cart.dart
WAVE 5  Detail routes — product/post pages (CSA post carousel, reserve vs pesan rules)
WAVE 6  Flutter wire gaps — contact form, order track parity with web APIs
WAVE 7  Effects — CSA overlay stack vs c35 WASM/Dart (z-order, detail page)
WAVE 8  Verification — CI tests, build.ps1, manual E2E script, optional render snapshots
WAVE 9  (optional) Dev ergonomics — "Open web preview" always uses ptoken; publish reminder in editor
```

Dispatch parallel tracks per wave ([`plan-execution.mdc`](../../.cursor/rules/plan-execution.mdc)).

---

## WAVE 0 — Same data (parallel)

**Why:** `/natepaperie` vs widget preview often differs because **published HTML ≠ draft boot**, not because renderers are unrelated.

### Track 0A — Document operator workflow

- [x] **0A.1** Add **“Comparing preview and browser”** subsection to [`_/specs/site-guest-components.md`](../site-guest-components.md): draft preview vs `site.render`; use Published mode in preview; publish before comparing to bare URL; use Visit link (`draft=1&ptoken`) for draft HTML.
- [x] **0A.2** Add 5-step checklist to [`artifacts/2026-10-11-guest-parity-gaps.md`](artifacts/2026-10-11-guest-parity-gaps.md) § Operator workflow.

### Track 0B — Golden boot exports

- [ ] **0B.1** For `natepaperie` (and one hub-only site): save `boot_get` **draft** and **published** JSON under `servers/crates/mod_site/tests/fixtures/golden/{alien_id}_boot_draft.json` and `_boot_published.json` (redact secrets only).
- [ ] **0B.2** Rust test: `site_boot_json_assemble` + published doc loader produces stable keys required by matrix (no full snapshot of entire JSON unless small).

### Track 0C — Publish pipeline sanity

- [x] **0C.1** Confirm site publish job re-runs `page_html_render` for all `html:*` keys when design/blocks change ([`site_publish.rs`](../../servers/crates/mod_site/src/site_publish.rs)).
- [ ] **0C.2** Manual: edit block → Publish → `curl -s http://localhost:10000/natepaperie | findstr __SITE_GUEST__` etag/body changes.

---

## WAVE 1 — Audit and fixtures (parallel)

### Track 1A — Three-way gap report

| Item | Detail |
|------|--------|
| **Output** | [`artifacts/2026-10-11-guest-csa-identity-gaps.md`](artifacts/2026-10-11-guest-csa-identity-gaps.md) |
| **Method** | Per matrix row: screenshot or DOM notes for Preview (published mode), `localhost:10000/{id}`, CSA published sample if available; file:line in Dart, `render.rs`, CSA `hub.rs` / `main.ts` |
| **Deliverable** | PASS/GAP + resolution (**fix-web** / **fix-flutter** / **fix-boot** / **port-csa**) |

### Track 1B — Fixture library

- [x] **1B.1** Extend `servers/crates/mod_site/tests/fixtures/guest_parity_*.json` — one page per block family + `golden/natepaperie_hub.json` slice (pages[0] blocks only).
- [x] **1B.2** `guest_parity_test.rs`: load each fixture; assert `data-guest`, critical classes, CSS vars, commerce flags match Flutter semantics documented in test names.

### Track 1C — Boot key parity

- [ ] **1C.1** Complete [`site-guest-components.md`](../site-guest-components.md) boot table: every `GuestSiteBoot` field ↔ `__SITE_GUEST__` ↔ JS consumer.
- [ ] **1C.2** Test: draft and published `load_doc_json` paths produce same boot shape (only `mode` and doc content differ).

---

## WAVE 2 — CSA visual tokens (parallel)

**Reference:** CSA `theme.rs`, `guest_root_css` in c35 `render.rs`, Flutter `site_design_resolve.dart`.

### Track 2A — Typography and spacing scale

- [ ] **2A.1** Extract CSA hub font sizes / weights for profile title, product name, price, link rows.
- [ ] **2A.2** Align `GuestDesign` defaults in `guest_design.rs` with Dart `siteDesignResolve` (single source of numeric defaults in Rust comments pointing to Dart).
- [ ] **2A.3** Port matching rules to `site-guest.v1.css` (product grid, hub profile, links).

### Track 2B — Shell and cart inset

- [ ] **2B.1** Match max content width and horizontal padding (Flutter logical px → CSS).
- [ ] **2B.2** `padding-bottom` on `.guest-page-main` when commerce cart visible — same as `GuestSiteCartChrome` inset.
- [ ] **2B.3** Tests: `guest_design_test.rs` + `guest_site_design_test.dart` same fixture.

### Track 2C — Card chrome

- [ ] **2C.1** CSA hub card classes → `guest_card_html` helpers for links, products, featured strips.
- [ ] **2C.2** Flutter: verify `siteCardDecorationResolve` uses same ids as web `data-card-style`.

---

## WAVE 3 — Hub blocks (parallel)

**Rule:** Read **Flutter widget first**, then CSA `hub.rs`, then change **web**; change **Flutter** only when row says **fix-flutter** or CSA port requires widget update.

| Track | Blocks | CSA port |
|-------|--------|----------|
| **3A** | `hub_profile`, `hero` (hub delegate) | profile section, hero CTA |
| **3B** | `links` | `links_html` placements |
| **3C** | `product_grid` | `catalog_html` list vs grid, in-cart badge |
| **3D** | `partners_display`, `clients_display`, `social_feed`, `hours` | strip + feed patterns |
| **3E** | `gallery`, `image`, `markdown`, `spacer`, `map`, `embed`, `custom_html`, `queue` | per catalog |

- [x] **3F** After 3A–3E: widget tests + `guest_parity_test` per fixture.

---

## WAVE 4 — Commerce chrome (parallel)

**Reference:** CSA `main.ts` (cart drawer steps), c35 `site-guest.v1.js`, `guest_site_cart.dart`.

| Track | Work |
|-------|------|
| **4A** | Sticky cart bar: labels (**Lihat**, item count, total format IDR) match Flutter |
| **4B** | Drawer steps: line items, notes, fulfillment modes, payment methods from `commerce_boot` |
| **4C** | Empty cart, single payment method, commerce off — same disabled/hidden behavior |
| **4D** | `build.ps1` + commit built artifacts per repo convention |

Open items from [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) (staff NATS, member area) stay in that plan unless merged here explicitly.

---

## WAVE 5 — Detail routes (sequential D1→D3)

- [x] **5D1** Flutter preview navigates to product/post detail paths matching public URLs (`/products/{id}`, `/posts/{id}`).
- [x] **5D2** Rust detail HTML: CSA `post.rs` carousel + product detail layout; **Reservasi** vs **+ Pesan** mutual exclusion per [`site-guest-components.md`](../site-guest-components.md).
- [x] **5D3** Test: same product id → title + formatted price in HTML fixture and widget test.

---

## WAVE 6 — Flutter wire gaps (parallel)

| Track | Work |
|-------|------|
| **6A** | `GuestSiteContactFormBlock`: wire to guest-contact API (match web validation + success copy) |
| **6B** | `GuestSiteOrderTrackBlock`: match `c35GuestOrder.poll` step labels |
| **6C** | Preview cart: optional `SharedPreferences` persist keyed by `site_iid` (CSA localStorage parity) |

---

## WAVE 7 — Effects (parallel)

- [x] **7X1** Active preset list: same filtering as CSA (skip unknown ids).
- [x] **7X2** Z-order: backdrop < effects < blocks < cart (Flutter `IgnorePointer` ↔ CSS `pointer-events`).

---

## WAVE 8 — Verification (sequential)

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site --test guest_parity_test --test guest_design_test --test render_test
cargo build -p server_ai

cd D:\c35\clients\app
flutter test test/guest_site_view_test.dart test/guest_site_design_test.dart

cd D:\c35\clients\web\static\site-guest
.\build.ps1

cd D:\c35
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

### Manual E2E — golden site (e.g. natepaperie)

1. **Draft alignment:** Preview (Draft) ↔ browser `/{alien_id}?draft=1&ptoken=…` (Visit link).
2. **Published alignment:** Preview (Published) ↔ `http://localhost:10000/{alien_id}` after **Publish**.
3. **Checks:** profile avatar on/off, accent, first product grid card, cart bar, one link row, one effect (if enabled).
4. **Detail:** open one product — reserve/pesan rules, price, image.
5. **CSA spot-check:** same flows on CSA reference site if block mix matches (visual rhythm, not pixel-perfect font stack).

- [x] **8V1** Update [`artifacts/2026-10-11-guest-parity-gaps.md`](artifacts/2026-10-11-guest-parity-gaps.md) with PASS/GAP after E2E.
- [ ] **8V2** Optional: `render_test.rs` snapshot guard for `block_html_render` (fail on drift without fixture update).

---

## WAVE 9 — Editor ergonomics (optional)

- [ ] **9E1** Editor banner when draft doc ≠ last published render: “Publish to update public URL.”
- [ ] **9E2** Preview pane default external link = draft ptoken URL (not bare slug).

---

## Subagent dispatch map

| Wave | Tracks | Parallel? |
|------|--------|-----------|
| 0 | 0A, 0B, 0C | Yes |
| 1 | 1A, 1B, 1C | 1B/1C after 1A partial |
| 2 | 2A, 2B, 2C | Yes |
| 3 | 3A–3E | Yes; 3F after |
| 4 | 4A–4D | 4A–4C parallel |
| 5 | 5D1→5D3 | Sequential |
| 6 | 6A–6C | Yes |
| 7 | 7X1, 7X2 | Yes |
| 8 | 8V1–8V2 | Sequential |
| 9 | 9E1, 9E2 | Yes |

**Each track prompt must include:**

- “App preview is canonical for c35 web; CSA is port reference for hub/commerce UX.”
- Link this plan + [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc).
- Compare **same boot mode** before renderer changes.

---

## File map (quick reference)

| Concern | Flutter | Web | CSA (read-only) |
|---------|---------|-----|-----------------|
| Blocks | `guest_site_blocks.dart` | `render.rs` `block_html_render` | `hub.rs` |
| Design | `site_design_resolve.dart` | `guest_design.rs`, CSS | `theme.rs` |
| Boot | `guest_site_boot.dart` | `site_boot.rs`, `__SITE_GUEST__` | `boot.rs` |
| Cart | `guest_site_cart.dart` | `site-guest.v1.js` | `main.ts` |
| HTTP serve | N/A | `http.rs` `serve_render_site` | site router |
| Tests | `test/guest_site_*.dart` | `guest_parity_test.rs` | — |

---

## Success metrics

| Metric | Target |
|--------|--------|
| Golden site draft | Preview (Draft) = draft URL (ptoken) for block order and commerce chrome |
| Golden site published | Preview (Published) = `localhost:10000/{id}` after publish |
| Automated | `guest_parity_test` + Flutter guest tests green on CI |
| CSA | Hub/commerce flows recognizable as same product family as CSA (class rhythm, copy, cart steps) |
