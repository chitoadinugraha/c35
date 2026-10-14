# Site product editor CSA parity — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Bring Sites → **Products** detail + list UX to **CSA parity** (`D:\csa_site_published` `ui_site_products_section.dart` / `_ProductDetail`) — active toggle, hero stock/reservation controls, full inventory (unit, guest stock display, warning/critical reminders, stock-adjust dialog), list stock/duration hints, and field limits — while **keeping** c35-only catalog fields (SKU, barcodes, alt names, gallery, AI main pic, API-backed embeds).

**Architecture:** No new Yugabyte tables or RPCs for v1 — `site.product.stock_qty`, `track_stock`, `can_reserve`, and `product_json` extras already match CSA (`clients/app/lib/c/site/site_product_json.dart`). Port CSA **widgets and layout** into `ui_site_product_detail.dart` + `ui_site_products_section.dart`; reuse existing `UiSiteCatalogDetailHeader`, `showSiteObjectBatchDialog` (batch units **already shipped**). Guest render: Flutter preview already honors `stock_show_to_customer`; align Rust card HTML if editor starts writing flags consistently (see Wave 5).

**Tech stack:** Flutter `clients/app` only (v1); optional `mod_site` render test touch in Wave 5.

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/site.md`](../site.md) | [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc)

**CSA reference (read-only):**

| Area | Path |
|------|------|
| Products section + detail | `clients/app/lib/widgets/site/ui_site_products_section.dart` |
| Batch objects dialog | `clients/app/lib/widgets/site/ui_site_obj_batch_dialog.dart` |
| Duration control | `clients/app/lib/widgets/io/in_duration.dart` |
| Product draft fields | `clients/app/lib/core/site/site_draft.dart` (`SiteProductDraft`, `siteItemNameMax` / `siteItemDescMax`) |
| Catalog header | `clients/app/lib/widgets/site/ui_site_catalog_detail_header.dart` |

**c35 today:**

| Piece | Status |
|-------|--------|
| List, paste, import image, taxes, design panes | Parity |
| Batch reservation units | **Done** (`ui_site_object_batch_dialog.dart`) |
| `SiteProductExtras` stock JSON | **Done** — UI not wired |
| Active (`product_json.active` / `!isArchived`) | **Partial** — no editor toggle |
| Stock unit, show-to-customer, thresholds | **Missing** in UI |
| Stock adjust dialog | **Missing** (stepper only) |
| Hero track stock / can reserve checkboxes | **Missing** (switches in lower sections) |
| List stock / duration / inactive opacity / row active switch | **Missing** |
| Name/desc max length (40 / 200) | **Missing** |
| `InDuration` period picker | **Missing** (dropdown only) |
| SKU, barcodes, embeds, extra pics, AI pic | **c35 ahead** — keep |

**Related plans:** [`2026-10-08-site-csa-editor-renderer-effects-multitask.md`](2026-10-08-site-csa-editor-renderer-effects-multitask.md) (guest stock line R3) · [`2026-10-07-site-csa-parity-catalog-multitask.md`](2026-10-07-site-csa-parity-catalog-multitask.md)

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Scope | **Editor UI parity** with CSA for inventory + visibility + list hints — **not** removing c35-only fields |
| Persistence | Existing `SiteApi.productPut` + `siteProductApplyExtras` / `siteProductApplyCell` — no stock ledger RPC in v1 |
| Active vs archive | **Active** toggle sets `product_json.active` and `isArchived = !active` via `siteProductApplyExtras` (same as today’s JSON contract) |
| Track stock ↔ reserve | **Mutually exclusive** in UI like CSA: enabling track stock clears `can_reserve`; enabling reserve clears `track_stock` |
| Booking gate | Reservation UI only when `UiSiteProductsEditor.booking == true` (site capability), matching c35 today |
| Stock qty edit | Products are **persisted on create** — treat as CSA `localNew == false`: **read-only qty + tap → adjust dialog** (retire `_StockStepper` for on-hand) |
| Stock adjust note field | Port CSA dialog **with optional note**; note is **UI-only in v1** (CSA does not persist note either) |
| `localNew` | **No** draft flag in c35 — do not add server field; use adjust-dialog path for all saved products |
| Copy / i18n | English strings aligned with CSA meaning; use plain English (c35 site editors), not `easy_localization` keys unless trivial |
| Field limits | `siteItemNameMax = 40`, `siteItemDescMax = 200` — add to `site_catalog_limits.dart` (or `site_product_json.dart`) |
| List active switch | Show `UiSiteCatalogActiveSwitch` on list rows when `masterDetail == true` (CSA `showActive` default) |
| Batch objects | **Verify only** in Wave 6 — no re-port unless regression found |
| Materials / BOM | **Out of scope** — not in CSA `SiteProductDraft` |

---

## File map

| File | Action |
|------|--------|
| `clients/app/lib/c/site/site_catalog_limits.dart` | **Create** — `siteItemNameMax`, `siteItemDescMax` (CSA values) |
| `clients/app/lib/widgets/io/in_duration.dart` | **Create** — port CSA `InDuration` + periods; style with `siteEditorInputDecoration` |
| `clients/app/lib/widgets/sites/editor/ui_site_product_stock_adjust_dialog.dart` | **Create** — port `_StockAdjustDialog` |
| `clients/app/lib/widgets/sites/editor/ui_site_product_stock_fields.dart` | **Create** — stock unit row, show-to-customer block, threshold rows (shared widgets) |
| `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart` | **Modify** — header, hero, inventory sections, `InDuration`, limits |
| `clients/app/lib/widgets/sites/editor/ui_site_products_section.dart` | **Modify** — list tile stock/duration/active/opacity |
| `clients/app/lib/widgets/sites/editor/ui_site_products_editor.dart` | **Modify** — wire `onActiveChanged`, pass `booking` / capabilities, list `masterDetail` flags |
| `clients/app/lib/c/site/site_product_json.dart` | **Modify** (if needed) — helper `siteProductActiveRead` / single `setActive` path |
| `clients/app/lib/c/site/site_product_list_labels.dart` | **Create** — `productListStockLabel`, `productListDurationLabel` |
| `clients/app/test/site_product_extras_test.dart` | **Create** — round-trip extras including stock flags |
| `clients/app/test/site_product_list_labels_test.dart` | **Create** — label formatters |
| `clients/app/test/site_product_detail_stock_test.dart` | **Create** — widget smoke: toggles render thresholds |
| `servers/crates/mod_site/tests/guest_product_display_test.rs` | **Modify** (Wave 5, optional) — `stock_show_to_customer` + unit suffix on card HTML |
| `_/specs/site.md` | **Modify** — document product_json stock keys + active |

---

## Multitask waves

```
WAVE 0  D0   Locked decisions + site.md product_json inventory keys
WAVE 1  L1   site_catalog_limits + list label helpers + unit tests
        L2   Port InDuration (io/in_duration.dart)
WAVE 2  H1   Product detail: UiSiteCatalogDetailHeader + Active toggle
        H2   Hero row: price beside pic; track stock + can reserve checkboxes (booking-gated)
WAVE 3  S1   Stock section: unit, on-hand (read-only + adjust dialog), show-to-customer + max
        S2   Reminder section: warning + critical threshold rows
WAVE 4  R1   Reservation: replace duration dropdown with InDuration (CSA period set + pro divider behavior optional)
        R2   Name/description LengthLimitingTextInputFormatter
WAVE 5  P1   Product list: opacity inactive, stock line, duration line, active switch (masterDetail)
        P2   Guest Rust HTML stock line parity check (if gap vs Flutter)
WAVE 6  V1   Widget tests + verify_flutter_app.ps1
        V2   Manual E2E checklist (99000 commerce site)
```

### Parallel assignment (suggested)

| Wave | Agent A | Agent B |
|------|---------|---------|
| 0 | D0 site.md | — |
| 1 | L1 limits + labels | L2 InDuration |
| 2 | H1 header + active | H2 hero checkboxes |
| 3 | S1 stock core + adjust dialog | S2 thresholds |
| 4 | R1 InDuration wire-up | R2 field limits |
| 5 | P1 list tiles | P2 render test |
| 6 | V1 tests | V2 manual notes |

---

## Wave 0 — Docs

- [ ] **0.1** In `_/specs/site.md`, under product / `product_json`, document: `active`, `stock_unit`, `stock_show_to_customer`, `stock_show_max_qty`, `stock_warning_*`, `stock_critical_*`, `duration_*`, `reservation_unit_selection` — mirror CSA `SiteProductDraft` comments.
- [ ] **0.2** Add one line: **batch reservation objects** are edited per product (not a separate “materials” model).

---

## Wave 1 — Shared helpers

### L1 — Limits and list labels

- [ ] **1.1** Create `site_catalog_limits.dart` with `siteItemNameMax = 40`, `siteItemDescMax = 200`.
- [ ] **1.2** Create `site_product_list_labels.dart`:
  - `productListStockLabel(SiteProduct p, SiteProductExtras extras)` → `Stock: {qty}{unit}` (CSA `_productListStockLabel`).
  - `productListDurationLabel(SiteProductExtras extras)` → `Per: {n} {Unit}` using same period labels as `InDuration`.
- [ ] **1.3** Tests in `site_product_list_labels_test.dart`.

### L2 — InDuration

- [ ] **1.4** Port `in_duration.dart` from CSA; drop `easy_localization`; use c35 theme (`siteEditorInputDecoration`, dark editor colors).
- [ ] **1.5** Period list: `day`, `week`, `month`, `year`, `hour`, `minute`, `second` — match CSA ids (used in `site_product_json.dart` already).
- [ ] **1.6** Optional: hide minute/second behind same “pro” divider as CSA if product wants billing gate later; **v1 show all** to match CSA editor behavior on published CSA builds.

---

## Wave 2 — Product detail header + hero

### H1 — Active header

- [ ] **2.1** Wrap `ui_site_product_detail.dart` body in `ListView` with CSA padding (`fromLTRB(16, 20, 16, 16)` or keep `UiSiteEditorFormScroll` if equivalent).
- [ ] **2.2** Add `UiSiteCatalogDetailHeader`:
  - `title`: `Products`
  - `subtitle`: short hint (e.g. “Catalog item”)
  - `icon`: `Icons.shopping_bag_outlined`
  - `active`: `siteProductExtrasRead(product).active`
  - `onActiveChanged`: `_persistExtras(extras.copyWith(active: v))` then `productPut` via existing apply path
  - `onDelete`: reuse `_removeOrArchive` / confirm flow (map CSA delete copy)
- [ ] **2.3** Remove duplicate delete `TextButton` in ID row if header owns delete (keep ID as muted text below header).

### H2 — Hero checkboxes

- [ ] **2.4** Restructure hero `Row` to CSA shape: **pic** | **column(name, price, checkbox row)**.
- [ ] **2.5** Move **price** from “Pricing” section into hero (`InMoneyIdr` or existing price field); keep **unit** in Pricing section (CSA has no separate unit field in hero).
- [ ] **2.6** Add checkbox row:
  - Track stock — disabled when `product.canReserve`; calls `_setTrackStock`
  - Can reserve — only if `widget.booking`; disabled when `product.trackStock`; calls `_commitProductField` for `can_reserve`
- [ ] **2.7** Move description **below** hero row (CSA order), still debounced text save.

---

## Wave 3 — Inventory (CSA stock + reminder)

### S1 — Stock section

- [ ] **3.1** When `product.trackStock`, render section divider **Stock** (match CSA copy: “Stock”).
- [ ] **3.2** **Unit** field: max length 6, binds `extras.stockUnit`, persist via `_persistExtras`.
- [ ] **3.3** **On hand**: read-only `TextField` + suffix unit; `onTap` → `showSiteProductStockAdjustDialog` → `productPut` with new `stock_qty`.
- [ ] **3.4** Remove `_StockStepper` from inventory (or keep only inside adjust dialog as CSA uses free numeric field).
- [ ] **3.5** **Show stock to customer** checkbox + conditional **max** qty field + helper footnote (CSA Indonesian helper → English equivalent for c35).

### S2 — Reminder section

- [ ] **3.6** Section divider **Reminder** (CSA `sectionReminder`).
- [ ] **3.7** Port `_stockThresholdRow`: enable checkbox + qty field for **Warning** and **Critical**; bind `stockWarningEnabled/Qty`, `stockCriticalEnabled/Qty`.
- [ ] **3.8** Extract shared widgets to `ui_site_product_stock_fields.dart` if `ui_site_product_detail.dart` exceeds ~1000 lines.

### Stock adjust dialog

- [ ] **3.9** Create `ui_site_product_stock_adjust_dialog.dart` — title, current qty + unit, new qty, optional note, Cancel/Save.
- [ ] **3.10** On save: return `int` qty; caller updates product + refreshes controllers.

---

## Wave 4 — Reservation + validation

- [ ] **4.1** In `_reservationSection`, replace duration `TextField` + `DropdownButtonFormField` with `InDuration` (value + period callbacks → `_persistExtras`).
- [ ] **4.2** Keep **Guest picks a unit** switch and `_reservationUnitsSection` / batch dialog unchanged.
- [ ] **4.3** Apply `LengthLimitingTextInputFormatter(siteItemNameMax)` on name; `siteItemDescMax` on description.
- [ ] **4.4** Hide counter via decoration pattern used elsewhere in site editor (CSA `hideCounter`).

---

## Wave 5 — Product list + guest

### P1 — List tiles (`ui_site_products_section.dart`)

- [ ] **5.1** For each product, compute `extras = siteProductExtrasRead(p)`.
- [ ] **5.2** Wrap title/price column in `Opacity(opacity: extras.active ? 1 : 0.5)`.
- [ ] **5.3** Under price: if `p.trackStock` show `productListStockLabel`; if `p.canReserve && booking` show `productListDurationLabel`.
- [ ] **5.4** When `masterDetail` (new param from editor), show `UiSiteCatalogActiveSwitch` on row; `onActiveChanged` callback → editor persists via `siteProductApplyExtras`.
- [ ] **5.5** Pass `booking` into section for duration line gate.

### P2 — Guest render (optional same release)

- [ ] **5.6** Run `guest_product_display_test` / manual: enable **show stock to customer** in editor, republish, confirm Flutter preview + web card show `Stock: n` per [`2026-10-08-site-csa-editor-renderer-effects-multitask.md`](2026-10-08-site-csa-editor-renderer-effects-multitask.md) R3.
- [ ] **5.7** If Rust HTML ignores `stock_unit` suffix, patch `render.rs` / `guest_product_display` in same wave.

---

## Wave 6 — Verification

- [ ] **6.1** `site_product_extras_test.dart` — write/read all stock + active fields on `product_json`.
- [ ] **6.2** `site_product_detail_stock_test.dart` — pump detail with `trackStock: true`, expect unit + reminder controls (keys or text).
- [ ] **6.3** `.\_\scripts\dev\verify_flutter_app.ps1`
- [ ] **6.4** `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`
- [ ] **6.5** Manual E2E (owner **99000** or test site):
  1. Products → pick item → toggle **Active** off → list shows dimmed row.
  2. Enable **Track stock** → set unit `pcs` → adjust on-hand via dialog.
  3. Enable **Show stock to customer** + max → guest preview shows capped label.
  4. Enable **Can reserve** (booking on) → batch **Add units** still works.
  5. Warning threshold saves and reloads in editor.
- [ ] **6.6** Batch objects smoke: enable reserve → Add units → create 3 rooms — no code change expected.

---

## Out of scope (explicit)

- Product **materials / BOM / recipe** lines
- Tokopedia/Shopee import menu items (CSA disabled stubs)
- Removing SKU, barcodes, alternative names, gallery, or AI generate pic
- Stock movement history / audit table for adjust-dialog notes
- `site_product_suggest_run` (guest disambiguation — unrelated to editor)

---

## Success criteria

1. Side-by-side with CSA on the same product data: **same controls visible** for active, stock, reminders, reservation duration, list annotations.
2. All stock-related `product_json` keys round-trip through editor save/load.
3. `verify_flutter_app.ps1` clean.
4. No regression on batch object create for reservable products.
