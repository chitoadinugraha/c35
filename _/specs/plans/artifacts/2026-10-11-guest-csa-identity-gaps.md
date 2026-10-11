# Guest CSA identity gaps — three-way audit (Wave 1A)

**Date:** 2026-10-11  
**Plan:** [`2026-10-11-site-guest-csa-identity-parity-multitask.md`](../2026-10-11-site-guest-csa-identity-parity-multitask.md) — Track **1A**  
**Prior snapshot:** [`2026-10-11-guest-parity-gaps.md`](2026-10-11-guest-parity-gaps.md) (Waves 0–8 verification; some rows below supersede open items there)

## Wave 8 verification (2026-10-11)

| Check | Pass | Fail |
|-------|-----:|-----:|
| `cargo test -p c35_mod_site --test guest_parity_test --test guest_design_test --test render_test` | 44 | 0 |
| `flutter test` (guest_site_view, guest_site_design, guest_contact_api, guest_site_cart, site_preview_external_url) | 22 | 0 |
| `clients/web/static/site-guest/build.ps1` | OK | — |
| `check_utf8_sources.ps1 -Changed -Fix` | OK (plan artifacts) | — |

Matrix row counts unchanged from Wave 1A audit (**PASS 22**, **GAP 8**, **GAP (ops/E2E) 1**). Live publish E2E still **GAP**.

## Method

Static audit (no new screenshots in this pass):

| Surface | Code / entry |
|---------|----------------|
| **Flutter (canonical)** | `clients/app/lib/guest_site/` — `GuestSiteView`, `guest_site_boot.dart`, `guest_site_blocks.dart`, `guest_site_cart.dart` |
| **c35 web** | `servers/crates/mod_site/src/render.rs`, `guest_design.rs`, `site_boot.rs`; `clients/web/static/site-guest/site-guest.v1.{js,css}` |
| **CSA reference (read-only)** | `D:\csa_site_published\crates\mod_site\src\render\{hub.rs,theme.rs,boot.rs,post.rs}`; `D:\csa_site_published\client\site\src\main.ts` (Alpine `guestCart`) |

**Status:** **PASS** = same boot-driven identity for c35 Flutter vs c35 web (or N/A by design). **GAP** = measurable mismatch; resolution is **fix-web**, **fix-flutter**, **fix-boot**, or **port-csa** (CSA rhythm/behavior to port when both c35 renderers should match CSA).

**CSA caveat:** CSA hub HTML uses a **fixed section order** (`profile_html` → strips → `links_html` → `catalog_html` in `hub.rs`). c35 uses **SiteDoc block order**. CSA rows judge **commerce hub UX and class rhythm**, not arbitrary block permutations.

---

## Three-way parity matrix

| Concern | Flutter (c35) | Web (c35) | CSA reference | Status | Resolution | Evidence / notes |
|---------|---------------|-----------|---------------|--------|------------|------------------|
| **Data: draft boot** | `site.boot_get` draft (`guest_site_boot.dart`) | `?draft=1&ptoken` → live `page_html_render` + same boot assembly path | N/A (draft HTML only) | **PASS** | — | Same `site_boot_json_assemble` / doc snapshot when token valid; preview **Draft** must use Visit link, not bare slug ([`site-guest-components.md`](../../site-guest-components.md)). |
| **Data: published boot** | `boot_get` published | Cached `site.render` HTML + inline `window.__SITE_GUEST__` subset | Published HTML + `boot_json` in `render/boot.rs` | **GAP** | **fix-boot** | Full boot on Flutter includes `pages`, `design`, `product_preload`, `links`, `featured_contacts`, etc. (`site_boot.rs`). Published page script only injects `site_iid`, `commerce_boot`, `order_progress_steps` (`render.rs` `guest_client_script_tags`). Intentional for JS, but preview **Published** vs browser must compare **rendered blocks**, not assume identical inline JSON. |
| **Page shell** (max width, pad, cart inset) | `guest_site_view.dart`, shell padding | `guest_shell_html`, `.wrap`, `site-guest.v1.css` (`max-width` ~480px hub) | `theme.rs` hub shell | **PASS** | — | `guest_design_test` / `guest_site_design_test.dart` cover tokens; CSA max width differs slightly (~320px cart chip in CSS) — cosmetic, not identity. |
| **Backdrop** | `site_backdrop` / design resolve | `data-backdrop`, `guest_root_css` | `backdrop.rs` + layered divs in `hub.rs` | **PASS** | — | `GuestDesign` ↔ `guest_design.rs`; both c35 sides share theme doc. |
| **Card styles** | `site_card_style.dart` / `siteCardWrap` | `guest_card_html`, `design.card_wrap` | `card_class_for` in `hub.rs` | **PASS** | — | Card/bare modes wired on links, grids, strips in `render.rs`. |
| **`hub_profile`** | `GuestSiteHubProfileBlock` | `hub_profile` arm, `data-guest="profile"` | `profile_html` | **PASS** | — | Fixture `guest_parity_hub.json`; avatar/title/bio/location/hours flags use `design.profile` on web (`render.rs` ~808–881). |
| **`links` placements** | `GuestSiteLinksBlock` — list + icon row, boot `links[]` fallback | `links` arm — flat `<ul class="links">` | `links_html` — `list` / `icon` / `icon_label` | **GAP** | **port-csa** | No `placement` prop in Dart or `render.rs` (see [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](../2026-10-08-site-guest-csa-commerce-parity-multitask.md) §1A). Icon-only and icon+label grids not reproduced. |
| **`product_grid`** | List + grid layouts, preload cursors | `product_card_html` / list row, `data-display` | `catalog_html` | **PASS** | — | `guest_parity_product_grid.json`; filter/category/page size aligned. |
| **Product grid in-cart badge** | No per-tile qty badge in `guest_site_blocks.dart` | No tile badge in `site-guest.v1.js` (cart bar only) | CSA catalog often shows cart state on tiles | **GAP** | **port-csa** | Neither c35 renderer shows in-grid in-cart chrome; CSA reference may differ on hub catalog — port when commerce parity plan requires it. |
| **Product detail** | Preview route / `GuestSiteProduct` | `html:/products/{id}`, `product_detail_article_html` | Product section in hub / detail flow | **PASS** | — | Publish pipeline renders storefront paths (`guest-parity-gaps.md` Wave 0C). Reserve vs `+ Pesan` rules in `render.rs` + Dart. |
| **Post detail + carousel** | Post body in preview; no carousel widget in `guest_site/` | `html:/posts/{id}` static article | `post.rs` patterns | **GAP** | **port-csa** | No `carousel` in c35 guest renderers; CSA post detail may multi-image — defer to Wave 5 / effects plan unless required for identity bar. |
| **Cart chrome** | Sticky bar, **Lihat**, IDR total (`guest_site_cart.dart`) | `#c35-guest-cart-bar`, same labels (`render.rs` shell) | Alpine `guestCart` in `main.ts` | **PASS** | — | Label **Lihat** on both c35 sides; CSA uses sheet UX (class names differ — expected). |
| **Checkout copy (ID)** | Drawer strings in Dart | `site-guest.v1.js` modal copy | CSA checkout templates in `hub.rs` / `main.ts` | **PASS** | — | Same RPC paths; wording largely aligned (Keranjang kosong, Pesanan, etc.). Fine-grained diff not screenshot-verified. |
| **Reservation** | `guest_site_reservation_sheet.dart` | `c35GuestCart` / reservation math in `site-guest.v1.js` | Alpine reserve templates embedded in `hub.rs` | **GAP** | **port-csa** | Feature parity largely shipped; CSA uses iconify + stepper markup vs c35 vanilla — visual/flow deltas remain on complex reserve SKUs (honest **GAP** vs CSA reference, not vs Flutter↔web). |
| **`contact_form`** | `GuestContactApi.contactPut` (`guest_site_blocks.dart` ~387–432) | `c35GuestLead.submit` → `/v1/site/guest-contact/put` | `form.rs` / `guestFormSubmit` in CSA client | **PASS** | — | Supersedes older “Flutter stub” note in `guest-parity-gaps.md`. `data-guest="form"` on web (`render.rs` ~740–764). |
| **`order_track`** | `GuestOrderApi.orderGet`, label from `progress_label` | `c35GuestOrder.poll`, same field (`site-guest.v1.js` ~398–422) | Order poll in CSA guest JS | **PASS** | — | Copy: **Lacak pesanan**, **No. pesanan**, **Cek status** on web; Dart matches. |
| **`order_progress_steps` boot key** | Not parsed in `GuestSiteBoot` | Present in `__SITE_GUEST__` and used in JS step UI | CSA boot shape | **GAP** | **fix-flutter** | Rust emits key (`site_boot.rs`, `render.rs`); catalog documents `orderProgressSteps` ([`site-guest-components.md`](../../site-guest-components.md)); Flutter poll is label-only today. |
| **Effects z-order** | `GuestSiteEffectStack` | `site-guest.effects.v1.js` | `effects/host` in CSA client | **PASS** | — | Wave 7 notes: z-order + detail effects shipped; WASM vs Dart painters differ by stack. |
| **Hero vs hub delegate** | `hero` and `hub_profile` both render independently; hero CTA is non-link `Text` in gradient (`guest_site_blocks.dart` ~253–260) | `hero` arm emits `<a class="hero-cta">` (`render.rs` ~548–580) | CSA: `profile_html` only (no separate hero block type) | **GAP** | **fix-web** | When doc has **both** blocks, duplicate chrome vs CSA single profile. CTA: web link vs Flutter decorative chip — preview ≠ web. Align web hero to Flutter (canonical) or collapse hero into hub rules. |
| **Hub-only meta chips** | `shouldShowMetaLocation` / `shouldShowMetaHours` (`guest_site_boot.dart` ~248–251) | Implicit in `hub_profile` + block list (no duplicate meta row) | Profile-embedded hours/location | **PASS** | — | Flutter suppresses free-floating hours when `hub_profile.show_hours`; web embeds hours in hub section. |
| **`map` / `queue` blocks** | `GuestSiteMapBlock`, `GuestSiteQueueBlock` | `map` / `queue` arms in `render.rs` | No dedicated map hub block in CSA | **PASS** | — | c35-only blocks; CSA N/A. Queue uses `c35GuestQueue` on web. |
| **Featured strips** (`partners_display`, `clients_display`) | `GuestSiteFeaturedStripBlock` + design modes | `featured_strip_html`, `item_mode` | `strip_html` in `hub.rs` | **PASS** | — | Modes `card` / `icon` / `icon_label` in `guest_design.rs` + Dart. |
| **`social_feed`** | Block + `postsPreload` | `social_feed` arm, post cards | CSA social in catalog | **PASS** | — | Empty feed hidden on web. |
| **`hours` / `embed` / `custom_html` / `gallery` / `markdown` / `spacer` / `image`** | Arms in `guestSiteBlock` | Matching `block_html_render` arms | Partial (hub-focused) | **PASS** | — | `guest_parity_test` + component catalog; `custom_html` web-first (Flutter stub/skip acceptable). |
| **Commerce boot shape** | `GuestCommerceBoot.fromJson` | `commerce_boot` in boot + `__SITE_GUEST__` | CSA `SiteBoot` in `main.ts` | **PASS** | — | Payment methods, products, objects populated from `commerce_boot_build`. |
| **Preview cart persistence** | `SharedPreferences` `c35.guest.cart.v1.{siteIid}` (`guest_site_cart.dart`) | `localStorage` same key pattern in `site-guest.v1.js` | CSA localStorage | **PASS** | — | Wave 6C intent met on Flutter; web already persisted. |
| **HTTP serve / draft URL** | N/A | `http.rs` `serve_render_site`, draft bypass | CSA site router | **PASS** | — | Draft vs published rules documented in `site-guest-components.md`. |
| **Automated fixtures** | `test/guest_site_*.dart` | `guest_parity_test.rs`, `guest_design_test.rs` | — | **PASS** | — | Wave 8: **22** Flutter + **44** Rust guest/render/design tests green (see Wave 8 table above). |
| **Live E2E published URL** | Preview **Published** vs `localhost:10000/{id}` | Same | CSA deployed sample | **GAP** | **—** (ops) | Not re-run in 1A; requires `publish_server.ps1` + per-site **Publish**. Track in Wave 8. |

---

## Boot JSON key parity (feeds Track 1C)

| Key | `boot_get` (Flutter) | `__SITE_GUEST__` (published HTML) | Status | Resolution |
|-----|----------------------|-----------------------------------|--------|------------|
| `commerce_boot` | Yes | Yes | PASS | — |
| `order_progress_steps` | Yes (Rust) | Yes | GAP | **fix-flutter** — parse/expose on `GuestSiteBoot` if step UI needed in preview |
| `design` / `theme` / `pages` | Yes | No (in HTML/CSS only) | PASS | By design |
| `product_preload` / `links` / `posts_preload` | Yes | Prerendered into HTML | PASS | Compare DOM, not inline JSON |
| `featured_contacts` / `effects` | Yes | Effects via `__SITE_BOOT__.effects` when active | PASS | — |

---

## Summary counts (matrix rows above)

| | Count |
|---|------:|
| **PASS** | 22 |
| **GAP** | 8 |
| **GAP (ops / E2E)** | 1 |

### GAP backlog by resolution

| Resolution | Items |
|------------|--------|
| **fix-web** | Hero vs hub + hero CTA link vs Flutter chip |
| **fix-flutter** | `order_progress_steps` on `GuestSiteBoot` |
| **fix-boot** | Document/compare strategy: full `boot_get` vs minimal `__SITE_GUEST__` (avoid false alarms in manual QA) |
| **port-csa** | Links `placement`; optional in-cart tile badge; post carousel; reservation sheet visual parity vs CSA Alpine |
| **—** | Live E2E after publish (Wave 8) |

---

## Recommended next tracks (from plan)

| Track | Action |
|-------|--------|
| **1B** | Extend `servers/crates/mod_site/tests/fixtures/guest_parity_*.json` for each **GAP** row that should become regression (hero+hub doc, links placement). |
| **1C** | Complete boot field table in [`site-guest-components.md`](../../site-guest-components.md) — fold `order_progress_steps` Flutter gap above. |
| **3A** | Hero / hub_profile — fix-web item |
| **3B** | Links placement — port-csa |
| **3C** | In-cart badge — port-csa (if product confirms) |
| **6A** | Close stale “contact stub” docs — contact is wired |

---

## File quick reference

| Concern | Flutter | Web | CSA |
|---------|---------|-----|-----|
| Blocks | `guest_site_blocks.dart` | `render.rs` `block_html_render` | `hub.rs` |
| Design | `site_design_resolve.dart` | `guest_design.rs`, CSS | `theme.rs` |
| Boot | `guest_site_boot.dart` | `site_boot.rs`, `__SITE_GUEST__` | `render/boot.rs` |
| Cart | `guest_site_cart.dart` | `site-guest.v1.js` | `client/site/src/main.ts` |
