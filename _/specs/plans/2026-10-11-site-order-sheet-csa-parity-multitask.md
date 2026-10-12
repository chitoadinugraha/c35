# Order & checkout bottom sheets — CSA visual parity

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks. Subagent model: **inherit** (`.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Guest **order** (per-product qty sheet), **checkout** (confirm → payment → pay detail), and **cart bar** match `D:\csa_site_published` on **both** Flutter site preview and published web (`site-guest.v1.*`), without Alpine.js.

**Architecture:** CSA is the **visual and interaction reference** for this plan (overrides the usual “app wins on cosmetic drift” only where this plan explicitly ports CSA). Keep c35 APIs (`POST /v1/site/guest-order/put`, `commerce_boot`, cart `localStorage` / `SharedPreferences` keys). Port CSA **DOM class names**, **sheet stack**, and **state machine** from `hub.rs` + `client/site/src/main.ts` into vanilla `site-guest.v1.js` and Flutter widgets. **Do not** add Alpine or provider grounding.

**Tech stack:** `D:\csa_site_published\crates\mod_site\src\render\{hub.rs,theme.rs}`, `client/site/src/main.ts`; c35 `clients/web/static/site-guest/`, `clients/app/lib/guest_site/guest_site_cart.dart` (+ new sheet widgets), `servers/crates/mod_site/src/render.rs`.

**Specs:** [`spec.md`](../../spec.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md) · [`_/specs/tx.md`](../tx.md) · [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc)

**Related (do not redo unrelated work):**

| Plan | Relationship |
|------|----------------|
| [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) | Wave 2B checkout steps — **partially done** (single-step modal today) |
| [`2026-10-08-site-reservation-objects-guest-sheet.md`](2026-10-08-site-reservation-objects-guest-sheet.md) | Reserve sheet — **functional**; CSA **visual** port is **Track 5** here |
| [`2026-10-11-site-guest-csa-identity-parity-multitask.md`](2026-10-11-site-guest-csa-identity-parity-multitask.md) | Parent identity program; update matrix row **Checkout / order sheet** when done |

---

## Global constraints

- **No Alpine.js** on c35 web — port behavior into `site-guest.v1.js` only.
- Guest money path stays **`POST /v1/site/guest-order/put`**; payment method id on payload the handler already accepts.
- Cart persistence keys stay **`c35.guest.cart.v1.{site_iid}`** (do not switch to CSA `csa.guest.cart.v4` without migration shim).
- **Iconify:** CSA templates use `<iconify-icon>`. c35 may use **inline SVG** or Material icons in Flutter — **same layout**, no new CDN dependency unless product approves loading Iconify on guest pages.
- UTF-8 sources; `check_utf8_sources.ps1 -Changed -Fix` after edits.
- Verify: `cargo test -p c35_mod_site`, `flutter test` `guest_site_cart_test.dart` + new sheet tests, `clients/web/static/site-guest/build.ps1`.
- **Done definition:** Side-by-side screenshot script (manual) — CSA published sample vs c35 preview vs c35 `localhost:10000/{slug}` for: order sheet, checkout steps (cash + transfer + QRIS), cart bar with items.

---

## CSA reference — what “exactly like” means

CSA commerce UI is **four layers** (see `hub.rs` body footer + `guestCart()` in `main.ts`):

| Layer | `sheet` / chrome | `data-guest` | c35 today |
|-------|------------------|--------------|-----------|
| **Cart bar** | `count > 0 && !sheet` | `cart` | Dark pill, **Lihat**, count avatar — CSA: `.guest-cart`, total + count labels, **Pesan** |
| **Per-product order** | `sheet === 'order'` | `order` | **Missing** — `c35GuestCart.add()` increments qty immediately |
| **Reservation** | `sheet === 'reserve'` | `reservation` | Separate JS sheet — markup differs (no handle, different slot cards) |
| **Checkout** | `sheet === 'checkout'` | `checkout` | Single **Pesanan** modal — all fields + **Kirim pesanan** in one step |

**Checkout steps (CSA):**

1. **`confirm`** — line list (`guest-checkout-line`, qty pill `N×`), subtotal/taxes/total, **Name**, **Order notes**, warn if no payment methods.
2. **`payment`** — list `guest-pay-option` rows (icon, title, chevron).
3. **`pay_detail`** — type-specific card (cash / WhatsApp / transfer pre-line / QRIS canvas + download-share).

**Order sheet (CSA):** product card (`guest-order-card`, pic, optional per-line note), stock hint, **numpad** (`guest-numpad-key`), primary CTA `Pesan N Item(s) · price` or **Batalkan** when qty 0.

**CSS source of truth:** `theme.rs` — `.guest-sheet-root`, `.guest-sheet-handle`, `.guest-sheet-header`, `.guest-checkout-*`, `.guest-numpad`, `.guest-cart`, `.guest-pay-*`, `.guest-qris-*` (lines ~476–602+).

---

## Gap summary (c35 vs CSA)

| Item | Resolution |
|------|------------|
| Cart bar layout + **Pesan** CTA | **port-csa** — `render.rs` + CSS + Flutter `GuestSiteCartChrome` |
| Per-product **order** bottom sheet + numpad | **port-csa** — new flow; wire `+ Pesan` / product tap → sheet, not `add(+1)` |
| Per-line **note** on cart lines | **port-csa** — extend cart line model (JS + Dart); map to `tx` item notes on put |
| Checkout **3-step** wizard + footer primary | **port-csa** — replace `renderModal()` single page |
| Payment detail (QRIS paint/download/share) | **port-csa** — port `paintQris`, `downloadQris`, `shareQris` from CSA or defer QRIS canvas to v1.1 with image-only |
| Theme tokens (`--surface`, `--primary`) on sheets | **port-csa** — align `guest_design` / hub CSS variables with CSA rhythm |
| Copy EN vs ID | **audit** — table in Track 0B; default **keep c35 ID** where equivalent (`Nama`, `Catatan`) unless user locks CSA English |

---

## Multitask map

```
WAVE 0  Audit + contract (screenshots, copy, cart line JSON shape)
WAVE 1  CSS — port CSA commerce sheet rules into site-guest.v1.css
WAVE 2  Web — cart state machine + order sheet + checkout wizard (site-guest.v1.js)
WAVE 3  Rust — shell HTML in render.rs (cart bar, optional static checkout root)
WAVE 4  Flutter — GuestSiteOrderSheet + GuestSiteCheckoutSheet (replace monolithic checkout)
WAVE 5  Reservation sheet visual parity (optional same release or follow-up)
WAVE 6  Tests + fixtures + site-guest-components.md + identity gap matrix
WAVE 7  Manual E2E + publish_server when shipping cluster
```

Dispatch **one subagent per track** within a wave when tracks do not share the same files.

---

## WAVE 0 — Audit & contract (parallel)

### Track 0A — Visual baseline

- [ ] **0A.1** Capture reference screenshots from CSA tree (local static serve or known deployed hub): cart bar, order sheet (qty 3), checkout confirm/payment/transfer/QRIS.
- [ ] **0A.2** Capture same states on c35 (natepaperie or any commerce site) — preview **Play** + `localhost:10000/{slug}`.
- [ ] **0A.3** Save pairs under `_/specs/plans/artifacts/2026-10-11-order-sheet-csa/` with `csa-*.png` / `c35-*.png` naming.

### Track 0B — Copy & behavior matrix

- [ ] **0B.1** Document string mapping CSA → c35 (headers, buttons, errors, placeholders).
- [ ] **0B.2** Document interaction matrix: `openProduct` → order vs reserve; `pesan()` → `checkout` step `confirm`; back stack; scrim tap closes sheet.
- [ ] **0B.3** Add row to [`artifacts/2026-10-11-guest-csa-identity-gaps.md`](artifacts/2026-10-11-guest-csa-identity-gaps.md): **Order sheet + checkout wizard** — status **GAP** until Wave 6.

### Track 0C — Cart line schema

- [ ] **0C.1** Spec cart line JSON: `{ qty, note? }` per product id; reservation lines unchanged (`r:…` keys with `slots`).
- [ ] **0C.2** Migration: on load, coerce legacy `number` values to `{ qty: n, note: "" }` in JS and Dart (mirror CSA `load()` in `main.ts`).
- [ ] **0C.3** Map `note` → guest order put item fields (read `guest_order_put` / proto — use existing line note if present).

---

## WAVE 1 — CSA commerce CSS (parallel)

### Track 1A — Port sheet + checkout rules

- [ ] **1A.1** Extract CSA rules from `D:\csa_site_published\crates\mod_site\src\render\theme.rs` (`.guest-sheet-root` through `.guest-qris-*`, `.guest-cart`, `.guest-numpad`, `.guest-order-card`).
- [ ] **1A.2** Merge into `clients/web/static/site-guest/site-guest.v1.css` — use `var(--accent)` / guest design tokens where c35 already defines `--fg`, `--surface` on hub.
- [ ] **1A.3** Deprecate or alias conflicting c35-only classes (`.guest-modal-backdrop`, `.guest-modal-sheet`) — checkout should use **`.guest-sheet-root` + `.guest-sheet`** like CSA.
- [ ] **1A.4** Run `clients/web/static/site-guest/build.ps1`; commit built `site-guest.v1.js` if repo tracks bundle.

### Track 1B — Flutter theme tokens

- [ ] **1B.1** Add `GuestCommerceSheetTheme` (or extend `SiteDesignResolve`) with radii, sheet handle, numpad key sizes matching CSS px values.
- [ ] **1B.2** Document token table in [`site-guest-components.md`](../site-guest-components.md) § Chrome / checkout.

---

## WAVE 2 — Web runtime (sequential after 1A)

### Track 2A — State machine

- [ ] **2A.1** Refactor `c35GuestCart` to CSA-shaped state: `sheet: '' | 'order' | 'checkout'` (reserve stays `c35GuestReserve` but opens from same `openProduct` rules).
- [ ] **2A.2** Implement `openOrder(productId)`, `numpad(key)`, `confirmOrder()`, `pesan()` → `sheet = 'checkout'`, `checkoutStep`, `checkoutBack()`, `checkoutPrimary()`.
- [ ] **2A.3** Change `add()` on non-reserve products to call `openOrder` instead of `items[id]++` (match CSA `openProduct`).

### Track 2B — DOM templates

- [ ] **2B.1** Build order sheet HTML with CSA class names (`guest-order-card`, `guest-numpad`, `guest-sheet-primary`).
- [ ] **2B.2** Build checkout wizard HTML (`guest-checkout-lines`, steps `confirm` | `payment` | `pay_detail`); sticky footer `guest-sheet-footer` + primary button text from CSA getters.
- [ ] **2B.3** Replace `#c35-guest-modal` / `#c35-modal-content` pattern with body-appended `.guest-sheet-root` (keep ids only where tests depend on them).

### Track 2C — Payment & QRIS

- [ ] **2C.1** Port `selectPayment`, `selectedPayment`, pay_detail branches from CSA `main.ts`.
- [ ] **2C.2** QRIS: port canvas paint + download/share or **v1.1** stub with image `qris_data` only — document choice in 0B.
- [ ] **2C.3** No payment methods → `checkoutSubmit()` from confirm (CSA behavior).

### Track 2D — Put payload

- [ ] **2D.1** Ensure `checkoutLines` includes per-line notes and reservation badge logic.
- [ ] **2D.2** Taxes: subtotal + `commerce_boot.taxes` rows on confirm step (already partially implemented — align DOM with CSA).

---

## WAVE 3 — Rust shell (parallel with 2B)

### Track 3A — Cart bar HTML

- [ ] **3A.1** Update `guest_commerce_chrome_html` in `render.rs`: CSA structure — `guest-cart-meta` (total + count), button **Pesan** calling `c35GuestCart.pesan()` (not `openModal`).
- [ ] **3A.2** Remove **Lihat** CTA string from shell when parity complete; keep `data-guest="cart"` on wrapper.

### Track 3B — Boot fields for payment UI

- [ ] **3B.1** Verify `commerce_boot.payment_methods[]` includes `type`, `icon`, `subtitle`, `whatsapp`, QRIS fields CSA expects — extend `commerce_boot.rs` if gaps.
- [ ] **3B.2** Optional: prerender empty checkout root in HTML for SEO (not required — JS-only OK).

---

## WAVE 4 — Flutter preview (parallel with Wave 2 after 1B)

### Track 4A — Order sheet widget

- [ ] **4A.1** Add `guest_site_order_sheet.dart` — `showGuestSiteOrderSheet(context, product, initialLine)` mirroring CSA order UI.
- [ ] **4A.2** Wire `guest_site_blocks.dart` / product tile **+ Pesan** to open order sheet (not immediate qty bump).
- [ ] **4A.3** Numpad + stock max from `commerce_boot` product row.

### Track 4B — Checkout wizard widget

- [ ] **4B.1** Split `GuestSiteCheckoutSheet` into stepper: confirm → payment → pay detail (reuse `GuestOrderApi` put).
- [ ] **4B.2** Match CSA layout: `ListTile` → custom rows with qty pill, reservation chip styling.
- [ ] **4B.3** `GuestSiteCartChrome`: CSA cart bar (total, count label, **Pesan**).

### Track 4C — Controller

- [ ] **4C.1** Extend `GuestSiteCartController` with `sheet`, `checkoutStep`, line notes, same transitions as JS.
- [ ] **4C.2** Persist line notes in SharedPreferences JSON (Track 0C schema).

---

## WAVE 5 — Reservation sheet visual (optional parallel)

**Scope:** Only if “order bottom sheet” includes reserve flow in the same release. Otherwise separate follow-up.

- [ ] **5.1** Align `guest_site_reservation_sheet.dart` + `c35GuestReserve` markup with CSA `hub.rs` reserve template (handle, slot cards, steppers, seat grid).
- [ ] **5.2** Port remaining `theme.rs` reserve classes (`.guest-slot-card`, `.guest-seat`, unit pick dialog).
- [ ] **5.3** See [`2026-10-08-site-reservation-objects-guest-sheet.md`](2026-10-08-site-reservation-objects-guest-sheet.md) — behavior stays; this wave is **visual**.

---

## WAVE 6 — Tests & docs (parallel)

### Track 6A — Rust/JS fixtures

- [ ] **6A.1** `guest_parity_commerce_checkout.json` — minimal boot with 2 products, taxes, 3 payment methods.
- [ ] **6A.2** `guest_parity_test.rs` — assert cart bar HTML contains `guest-cart-btn` / **Pesan**; no `guest-cart-cta` **Lihat** (or explicit migration flag).

### Track 6B — Flutter tests

- [ ] **6B.1** `guest_site_order_sheet_test.dart` — numpad sets qty, confirm updates controller.
- [ ] **6B.2** Extend `guest_site_cart_test.dart` — checkout step transitions, tax line math unchanged.

### Track 6C — Catalog

- [ ] **6C.1** Update [`site-guest-components.md`](../site-guest-components.md): document `order` sheet, checkout steps, `data-guest="checkout"`.
- [ ] **6C.2** Mark **Cart chrome** / **Checkout** rows **PASS (CSA parity)** in identity gaps artifact.

---

## WAVE 7 — Verification & deploy

- [ ] **7.1** `cargo test -p c35_mod_site`; `flutter test` guest suite; `build.ps1`.
- [ ] **7.2** Manual script (add to artifact 0A folder as `MANUAL.md`):
  1. Add product → order sheet → qty via numpad → confirm → cart bar **Pesan**.
  2. Checkout confirm → payment → cash detail → submit → toast + **Pesanan saya**.
  3. Repeat on Flutter preview and published URL (publish site + restart `server_ai` locally).
- [ ] **7.3** Cluster: `publish_server.ps1` when user requests deploy; include Publish summary.

---

## Subagent dispatch cheat sheet

| Wave | Parallel tracks | Primary files |
|------|-----------------|---------------|
| 0 | 0A, 0B, 0C | artifacts only + spec notes |
| 1 | 1A, 1B | `site-guest.v1.css`, Dart theme |
| 2 | 2A→2B→2C→2D (one agent can own 2A–2D) | `src/site-guest.v1.js` |
| 3 | 3A, 3B | `render.rs`, `commerce_boot.rs` |
| 4 | 4A, 4B, 4C | `guest_site_*.dart` |
| 5 | 5.x | reservation sheet + JS reserve |
| 6 | 6A, 6B, 6C | tests + md |
| 7 | single | verify + manual |

**Suggested execution order:** 0 → 1 → (2 + 3 + 4 in parallel) → 6 → 7; **5** when reservation visuals are in scope.

---

## Out of scope (explicit)

- Alpine / `site.js` bundle in c35.
- CSA `/a/http` invoke — keep c35 REST guest routes.
- Staff POS, tx editor, NATS notify (see commerce parity Wave 4).
- Changing `guest-order/put` to published-only rules (document existing behavior only).
- Pixel-perfect Iconify vs SVG (layout parity required; icon glyph parity best-effort).

---

## File quick reference

| Concern | CSA | c35 |
|---------|-----|-----|
| Templates | `hub.rs` (cart + sheets) | `render.rs` `guest_commerce_chrome_html` |
| CSS | `theme.rs` | `site-guest.v1.css` |
| Logic | `main.ts` `guestCart()` | `site-guest.v1.js` `c35GuestCart` |
| Preview | N/A (web Alpine) | `guest_site_cart.dart`, new order sheet |
| Boot | `__SITE_BOOT__` | `commerce_boot` + `__SITE_GUEST__` |
