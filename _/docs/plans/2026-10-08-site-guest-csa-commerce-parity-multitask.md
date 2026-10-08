# Site guest CSA commerce parity — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Subagent **model: inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Migrate CSA (`D:\csa_site_published`) guest storefront behavior into c35 — cart, checkout, order progress, staff notify (broadcast), links/products/posts renderers, and a lightweight **guest member area** (visitor + “my orders”) — on **both** compiled guest HTML (`mod_site` + `site-guest.v1.*`) **and** Flutter preview (`GuestSiteView` / `UiSitePreview`).

**Architecture:** Keep c35’s **dual renderer** contract ([`_/docs/site-guest-components.md`](../site-guest-components.md), CSA [`.agents/guest_ui.md`](file:///D:/csa_site_published/.agents/guest_ui.md)): one enriched **`site.boot_get` / `__SITE_GUEST__` JSON**, two UIs (vanilla JS on web, native widgets in Flutter). **Do not** ship Alpine.js — port CSA logic from `client/site/src/main.ts` + `invoke.ts` into **`clients/web/static/site-guest/site-guest.v1.js`** (and shared Dart in `clients/app/lib/guest_site/`). Money stays **`ReqSiteGuestOrderPut`** / `Tx` proto only ([`_/docs/tx.md`](../tx.md)). Staff realtime uses **`c35.user.{owner_iid}.app.*`** ([`user-app-nats.mdc`](../../.cursor/rules/user-app-nats.mdc)), not CSA MQTT topics.

**Tech stack:** Rust `c35_mod_site`, `c35_mod_tx`, `wire_http`; static `clients/web/static/site-guest/`; Flutter `guest_site/*`, `widgets/sites/ui_site_preview.dart`; protos `site.proto`, `tx.proto`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/docs/site.md`](../site.md) · [`_/docs/tx.md`](../tx.md) · [`_/docs/sync.md`](../sync.md) · [`_/docs/site-ai.md`](../site-ai.md)

**Prior art (c35):** [`2026-10-07-site-csa-parity-catalog-multitask.md`](2026-10-07-site-csa-parity-catalog-multitask.md) (links, posts, queue, catalog HTTP — **done**). [`2026-09-29-site-guest-checkout-and-tools.md`](2026-09-29-site-guest-checkout-and-tools.md) (cart JS — **open**). [`2026-10-03-site-hub-blocks-design-system.md`](2026-10-03-site-hub-blocks-design-system.md) (hub CSS — **partial**).

---

## Global constraints

- Guest order **create** remains **`POST /v1/site/guest-order/put`** on `api.alienai.id` (JSON or proto); **published site only** for put today (`guest_order_put` → `site_published`) — draft preview may **browse + cart UI** but checkout E2E needs publish or an explicit **draft-checkout token** track (Wave 3b).
- No provider web grounding on LLM paths; no new steering in Rust for compose beyond mechanical/web-pipeline rules.
- RBAC: staff team = **`ai.identity_grant`** on `site_iid` — **not** CSA `site_member` table ([`_/docs/site.md`](../site.md) deferred HR).
- UTF-8 sources; verify per [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc).
- After server/static ship: `.\_\scripts\deploy\publish_server.ps1` + re-publish affected guest sites.

---

## Gap analysis (CSA → c35)

| Area | CSA reference | c35 today | Target |
|------|---------------|-----------|--------|
| **Cart + checkout** | `client/site/src/main.ts` `guestCart()`, `invoke.ts` `guestOrderCreate` | HTML shell + `+ Pesan` in `render.rs`; **`c35GuestCart` missing** in `site-guest.v1.js` | Full cart bar, sheets, taxes, payment pick, put → receipt |
| **Product UI** | `hub.rs` `catalog_html` — list rows, in-cart badge, tap → order sheet | Grid cards, no add, no detail UX in Flutter | Hub list + grid variants; detail route `html:/products/{id}` |
| **Links** | `links_html` — `list` / `icon` / `icon_label` placements | Flat `<ul class="links">` + basic Flutter list | Placement props + boot `links[]` from `site.link` |
| **Posts** | `post.rs` detail + carousel; hub post grid / see-all | `social_feed` list; post detail HTML exists but thin CSS/JS | Grid + detail carousel web + Flutter |
| **Order progress** | Staff updates `tx.state`; guest polls status | `c35GuestOrder.poll` text only; Flutter `order_track` non-functional | Stepper UI + auto-poll + optional live push |
| **Staff broadcast** | `mod_site_tx` `notify_staff_order_created` → MQTT fanout + FCM | **None** on `guest_order_put` | NATS `c35.user.{owner}.app.site_order` + Flutter handler |
| **Member area** | `csa_visitor_id` localStorage; deferred “guest login + my orders” in hub plan | No visitor id; no saved orders | Visitor id + “Pesanan saya” list (localStorage); optional Alien sign-in **deferred** |
| **Boot JSON** | Full products, taxes, `payment_methods`, `objects` in `__SITE_BOOT__` | `product_preload` per block, `links`, `posts_preload` | `commerce_boot` slice when `capabilities.commerce` |

---

## Locked design contract

1. **Single boot contract** — extend `site_boot.rs` output (and inlined `__SITE_GUEST__` on publish) with documented fields; Flutter and JS read the same keys.
2. **Interactive chrome is not a SiteDoc block** — cart bar, checkout modal, toast host injected by renderer when `commerce` + sellable products exist (CSA `data-guest-cart-root`).
3. **Preview parity** — `UiSitePreview` / `GuestSiteView` must expose the same flows as web (cart state in memory; persist cart to `SharedPreferences` keyed by `site_iid`).
4. **Progress tracking** — map `Tx.state` / `TxState` to a fixed guest step list (ID copy); server may add `guest_status_label` in `guest-order/get` JSON view model without leaking staff fields.
5. **Member area v1** — anonymous: `visitor_id` + `order_ids[]` in storage; no PII required to track. Logged-in cross-device orders = **Wave 8 (deferred)**.

---

## File map

| File / area | Responsibility |
|-------------|----------------|
| `servers/crates/mod_site/src/site_boot.rs` | `commerce_boot`: products (sell), taxes, payment methods, objects, link rows |
| `servers/crates/mod_site/src/render.rs` | Hub HTML/CSS; link placements; product list markup; cart chrome; post cards |
| `servers/crates/mod_site/src/render/post.rs` *(new split)* | Post detail HTML (port CSA `render/post.rs`) |
| `servers/crates/mod_site/src/render/product.rs` *(new split)* | Product detail HTML |
| `clients/web/static/site-guest/site-guest.v1.js` | `c35GuestCart`, checkout, lead, order poll, post carousel, link analytics |
| `clients/web/static/site-guest/site-guest.v1.css` | Port subset of CSA `theme.rs` hub commerce classes |
| `servers/crates/mod_tx/src/guest_order.rs` | After put: staff fanout hook |
| `servers/crates/system/nats/src/user_app.rs` | `user_app_subject_site_order` + decode |
| `servers/crates/wire_ws/src/session.rs` | Fanout decode → `WsRes` for Sites |
| `clients/app/lib/guest_site/guest_site_cart.dart` *(new)* | Cart + checkout state machine (mirror JS) |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | Interactive product rows, links placements, post grid, order track |
| `clients/app/lib/guest_site/guest_site_member.dart` *(new)* | Visitor id + my orders sheet |
| `clients/app/lib/widgets/sites/ui_site_preview.dart` | Wrap preview with `GuestSiteCartScope` |
| `clients/app/lib/c/site/guest_order_api.dart` *(new)* | HTTP guest-order put/get (reuse production api host) |
| `_/docs/site-guest-components.md` | Update component table + boot fields |
| Tests | `mod_site` render snapshots, `guest_order` fanout unit, `guest_site_*_test.dart` |

**CSA read-only sources (port, do not depend at runtime):**

- `D:\csa_site_published\client\site\src\main.ts` — cart/checkout/reserve
- `D:\csa_site_published\client\site\src\invoke.ts` — wire patterns (c35 uses JSON HTTP instead of `/a/http` protobuf for guest)
- `D:\csa_site_published\crates\mod_site\src\render\hub.rs`, `theme.rs`, `post.rs`, `boot.rs`
- `D:\csa_site_published\crates\mod_site_tx\src\service.rs` — `notify_staff_order_created` semantics

---

## Multitask map

```
WAVE 0  Contract + boot schema (docs + site_boot.rs shape)
WAVE 1  Static hub design system (CSS + render HTML parity: links, profile, posts, products)
WAVE 2  Guest runtime JS — cart, checkout, contact, catalog load-more (c35GuestCart)
WAVE 3  Order progress — stepper UI, poll, localStorage receipt, optional guest-order subscribe
WAVE 4  Staff broadcast — NATS app lane on guest_order_put + Flutter Sites notification
WAVE 5  Guest member area — visitor id, my orders list, profile chip entry (web + Flutter)
WAVE 6  Flutter dual renderer — cart scope, wire blocks to guest_order_api, preview E2E tests
WAVE 7  Verification, docs sync, publish_server, manual E2E checklist
```

Dispatch parallel tracks per wave (`plan-execution.mdc`). Parent does not implement all tracks inline.

---

## WAVE 0 — Boot contract & docs (parallel)

### Track 0A — Document boot extensions

- [ ] **0A.1** Extend [`_/docs/site-guest-components.md`](../site-guest-components.md) with `commerce_boot` fields: `products[]`, `taxes[]`, `payment_methods[]`, `objects[]`, `visitor` hints, `order_progress_steps[]`.
- [ ] **0A.2** Add “Guest commerce parity” section to [`_/docs/site.md`](../site.md) — dual renderer, vanilla JS, NATS staff notify (replace aspirational cart bullets with links to this plan).
- [ ] **0A.3** Note **draft vs published** checkout rules in [`_/docs/tx.md`](../tx.md) guest section.

### Track 0B — `site_boot.rs` commerce slice

- [ ] **0B.1** When `capabilities` includes `commerce`, load sellable `site.product` rows (same filter as `guest_product_sell_ids` + preload), active taxes from site config/draft meta, payment methods from `site.config` JSON (port shape from CSA `payment_boot`).
- [ ] **0B.2** Load reservable `site.object` rows for reservation UI (capability `booking`).
- [ ] **0B.3** Emit `commerce_boot` object in boot JSON; keep existing `product_preload` for block-scoped grids.
- [ ] **0B.4** Rust test: `site_boot_get` returns `commerce_boot` when commerce capability on.

---

## WAVE 1 — Hub renderers (Rust HTML) (parallel)

### Track 1A — Links renderer parity

- [ ] **1A.1** Add block prop `placement`: `list` | `icon` | `icon_label` (validate in `mod_site::doc`).
- [ ] **1A.2** Port CSA `links_html` structure into `render.rs` (or `render/links.rs`): icon row, chips, list rows; use `site.link` boot rows when block `links` empty.
- [ ] **1A.3** CSS in `site-guest.v1.css`: `.guest-link-icon`, `.guest-link-chip`, `.guest-link-list`.
- [ ] **1A.4** Snapshot test: links block renders three placements.

### Track 1B — Product renderer parity

- [ ] **1B.1** Hub **list mode** prop on `product_grid`: `layout: grid | list` (default grid for backward compat).
- [ ] **1B.2** List row HTML: pic, name, price, stock pill, `+ Pesan` (matches CSA `guest-product` classes).
- [ ] **1B.3** Enrich `html:/products/{id}` via `render/product.rs` — detail, reserve placeholder, add button.
- [ ] **1B.4** Prerender: include `data-product-id` attributes for JS pulse/highlight.

### Track 1C — Post renderer parity

- [ ] **1C.1** Hub `social_feed`: optional `layout: list | grid` (3-column grid like CSA).
- [ ] **1C.2** Split `render/post.rs`; port carousel markup + dots from CSA `post.rs`.
- [ ] **1C.3** Wire `html:/posts/{id}` in publish paths (verify existing route table in `mod_site`).
- [ ] **1C.4** JS: `c35GuestPost.carousel` for detail pages only.

### Track 1D — Hub profile + cart chrome shell

- [ ] **1D.1** Expand `hub_profile` HTML: avatar ring, location chip, hours summary hook (reuse `hours` block data).
- [ ] **1D.2** Inject cart bar + checkout modal templates from `render.rs` (already partial) — align class names with CSS track 2A.
- [ ] **1D.3** Set `data-site-iid` on `<body>` or root for guest JS.

---

## WAVE 2 — Guest runtime JS (cart & checkout)

### Track 2A — CSS design system

- [ ] **2A.1** Port CSA hub commerce CSS from `theme.rs` into `site-guest.v1.css` (cart bar, sheets, checkout lines, pay options, order cards) — trim unused CSA-only tokens.
- [ ] **2A.2** Version comment + `render_hash` / static path unchanged (`site-guest.v1.css`).

### Track 2B — `c35GuestCart` (vanilla port)

- [ ] **2B.1** Implement `window.c35GuestCart` API used by `render.rs`: `add`, `openModal`, `closeModal`, qty steppers, `localStorage` key `c35.guest.cart.v1.{site_iid}`.
- [ ] **2B.2** Checkout steps: confirm → payment → pay detail (cash/transfer/QRIS) — build `Tx` JSON matching `wire_http` guest_order JSON adapter.
- [ ] **2B.3** On success: show receipt (tx_id, total), append to `c35.guest.orders.v1.{site_iid}`, clear cart.
- [ ] **2B.4** Taxes: compute from boot `commerce_boot.taxes` (mirror CSA `taxLines` / `grandTotal`).
- [ ] **2B.5** Payment methods: read boot list; empty → WhatsApp / contact fallback copy (CSA warn box).
- [ ] **2B.6** Manual test on published site: add → checkout → order appears in Sites → Orders.

### Track 2C — Lead + catalog glue

- [ ] **2C.1** `c35GuestLead.submit` for `contact_form` (if not complete).
- [ ] **2C.2** Ensure `c35GuestCatalog.loadMore` stays compatible with new product card HTML.

### Track 2D — Reservation v1 (optional same wave)

- [ ] **2D.1** Port minimal reserve sheet from CSA (single product, date range) **or** keep placeholder + document defer full seat picker to v1.1 (per 2026-10-07 deferred).

---

## WAVE 3 — Order progress & tracking

### Track 3A — Guest progress UI

- [ ] **3A.1** Define `order_progress_steps` in boot (localized labels): e.g. `waiting_payment` → `preparing` → `ready` → `completed` mapped from `TxState`.
- [ ] **3A.2** Extend `guest-order/get` HTTP handler response (or client mapping) with `progress_index`, `progress_label`, `updated_ts_ms` for guest-safe fields only.
- [ ] **3A.3** JS: upgrade `c35GuestOrder.poll` to render stepper DOM in `order_track` block + receipt page.
- [ ] **3A.4** Auto-poll: after checkout, poll every N s until terminal state (cap 30 min).

### Track 3B — Draft preview checkout (optional)

- [ ] **3B.1** **Decision:** allow `guest-order/put` for draft when `ptoken` valid **or** keep publish-only and show snackbar in preview — document chosen behavior.
- [ ] **3B.2** If token path: `wire_http` validates preview token + site_iid (mirror draft HTML serve).

### Track 3C — Live guest subscribe (broadcast to browser)

- [ ] **3C.1** **v1:** long-poll only (3A) — no WS on public guest origin.
- [ ] **3C.2** **v1.1 (deferred):** `GET /v1/site/guest-order/subscribe?tx_id=` SSE for order updates when staff changes tx (requires tx_put fanout).

---

## WAVE 4 — Staff broadcast (NATS app lane)

### Track 4A — Server emit on guest order

- [ ] **4A.1** After successful `guest_order_put`, resolve `owner_iid` from `ai.identity`.
- [ ] **4A.2** Publish JSON (or small proto) on `c35.user.{owner_iid}.app.site_order` with `{ site_iid, tx_id, event: site_order_created }`.
- [ ] **4A.3** Grantees with `identity_grant` role `staff|manage|owner` on site — same audience as CSA `staff_notify_uids` (query grants, not `site_member`).
- [ ] **4A.4** On `tx_put` state change for guest-sourced tx (`TxInputSource::Web`), publish `site_order_updated`.

### Track 4B — Flutter app handler

- [ ] **4B.1** Extend `user_app_fanout_decode` + `WsRes` variant for site order push.
- [ ] **4B.2** Sites POS / Orders: toast + optional sound; refresh open tx editor if same `tx_id`.
- [ ] **4B.3** Unit test decode; manual test with guest order on Chito account site.

### Track 4C — Push notification (deferred)

- [ ] **4C.1** FCM hook like CSA `offline_push` — only if mobile push infra already wired for owner_iid (likely defer).

---

## WAVE 5 — Guest member area

### Track 5A — Visitor identity

- [ ] **5A.1** JS: `c35.guest.visitor_id` UUID in `localStorage` (CSA `csa_visitor_id` pattern).
- [ ] **5A.2** Optional analytics ping endpoint — **defer** unless `wire_http` analytics route exists; do not block commerce.

### Track 5B — “Pesanan saya” (my orders)

- [ ] **5B.1** Persist `{ tx_id, placed_ts_ms, total }[]` per site after checkout (cap 20).
- [ ] **5B.2** Hub chip / sheet: list orders → tap opens progress stepper (3A).
- [ ] **5B.3** Flutter: `GuestSiteMemberSheet` + `SharedPreferences` mirror.

### Track 5C — Alien account login on guest site (deferred)

- [ ] **5C.1** Document deferral: cross-device order history requires session on `api.alienai.id` + new `guest-order/list` RPC — out of v1 scope unless product insists.

---

## WAVE 6 — Flutter preview dual renderer

### Track 6A — Cart scope

- [ ] **6A.1** `GuestSiteCartController` — same state transitions as JS (items, sheet step, checkout).
- [ ] **6A.2** Wrap `GuestSiteView` in `GuestSiteCartScope`; show bottom cart bar in preview when commerce on.
- [ ] **6A.3** `guest_order_api.dart` — put/get using `C35Config` api host (same as production guest).

### Track 6B — Block parity

- [ ] **6B.1** `GuestSiteProductGridBlock`: `+ Pesan`, in-cart badge, list layout prop.
- [ ] **6B.2** `GuestSiteLinksBlock`: placements (icon/chip/list).
- [ ] **6B.3** `GuestSiteSocialFeedBlock`: grid layout + tap → post detail route (in-preview navigator or external URL).
- [ ] **6B.4** `GuestSiteOrderTrackBlock`: functional poll + stepper (not placeholder text).

### Track 6C — Preview entry points

- [ ] **6C.1** `UiSitePreview` embedded mode: cart + member sheet work without “open in browser”.
- [ ] **6C.2** `ui_site_preview_card.dart` expanded simulator — same `GuestSiteCartScope` if feasible (or link to full preview).

### Track 6D — Tests

- [ ] **6D.1** `guest_site_cart_test.dart` — add line, tax math, normalize tx payload.
- [ ] **6D.2** Extend `guest_site_view_test.dart` — links placement, product add button visible when commerce.

---

## WAVE 7 — Verification & ship

### Track 7A — Automated

```powershell
cd servers
cargo test -p c35_mod_site
cargo test -p c35_mod_tx
cargo test -p c35_wire_http
cargo build -p server_ai
.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed
cd ..\clients\app
.\_\scripts\dev\verify_flutter_app.ps1
flutter test test/guest_site_view_test.dart test/guest_site_cart_test.dart
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

### Track 7B — Manual E2E (published `@test-site` or staging)

- [ ] Guest: browse products (grid + list), add to cart, checkout cash, receive tx id.
- [ ] Guest: “Pesanan saya” shows order; progress updates when staff advances tx in POS.
- [ ] Staff: Flutter receives `site_order_created` push; order visible in Sites → Orders.
- [ ] Preview widget: same cart flow (or clear message if draft checkout disabled).
- [ ] Posts: grid + detail carousel; links: icon + chip rows.
- [ ] Re-publish site after server deploy so HTML/JS/CSS refresh.

### Track 7C — Ops

- [ ] `publish_server.ps1` — include static `site-guest` assets.
- [ ] Re-run `site.publish` for hub sites used in QA.

---

## Out of scope (explicit)

| Item | Reason |
|------|--------|
| CSA Alpine bundle / `site.js` as-is | c35 locked to vanilla `site-guest.v1.js` |
| Full HR (`site_member`, payroll, face enroll) | **Superseded for Team editor** by [`2026-10-08-site-team-editor-csa-parity-multitask.md`](2026-10-08-site-team-editor-csa-parity-multitask.md): ACL stays `identity_grant` (no `site_member`); Team ships shifts / face enroll storage / transfer. Attendance **clock-in**, payroll, POS face matching still deferred — see [`site.md`](../site.md) **Team** |
| CSA MQTT `site/{id}/notify` | Replace with NATS app lane |
| Guest SSE subscribe | v1.1 after poll ship |
| Pixel-perfect Flutter ≡ web | Dual renderer allows similar, not identical |

---

## Suggested execution order

1. **Wave 0 + 2B** — unblocks real ordering on published URLs (highest user pain).
2. **Wave 1 + 2A** — visual parity with CSA hub.
3. **Wave 3 + 4** — progress + staff notify.
4. **Wave 5 + 6** — member area + in-app preview parity.
5. **Wave 7** — ship.

---

## Acceptance criteria (summary)

- Published guest site: CSA-equivalent **order loop** (cart → pay → receipt → track).
- Staff owner sees **realtime** new guest order on app WS lane.
- Flutter **Live preview** supports cart/checkout/track (publish required for put unless 3B ships).
- Links, products, posts renderers match CSA hub **layouts** (placement + grid/list).
- Docs and boot contract updated; tests green per Wave 7.
