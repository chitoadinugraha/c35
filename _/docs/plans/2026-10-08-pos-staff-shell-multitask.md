# POS Staff Shell — Compact UI, Inline Pay, Product Thumbs

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Subagent model: **inherit** (not fast).

**Goal:** Staff POS (`posEntry` / Sites → POS) matches id.alienai register UX: **one surface** (catalog | cart), **no tabs**, **inline payments on cart**, **product thumbnails**, **slim toolbar**. Ledger (**Acc / Stock**) stays available only for **root** in **Orders → edit** (non–POS entry), not at the register.

**Non-goals:** Server/proto changes; guest storefront; redesign of receipt PDF; grid catalog (optional follow-up).

**Docs:** `_/docs/tx.md` (POS vs ledger), `_/docs/plans/2026-09-23-site-commerce-multitask.md` (original port map).

**Reference (visual):** id.alienai `transaksi/` — `E:\Project Archive\id.alienai\client_app\lib\page_project\bisnis\transaksi\` (when available on disk).

**Verify (each wave):**

```powershell
cd clients/app
flutter analyze lib/widgets/sites/tx
flutter test test/ui_sites_picker_dialog_test.dart test/site_commerce_cache_test.dart
# Add new tests from Track 6 before claiming done
.\_\scripts\dev\verify_flutter_app.ps1
```

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| **Staff POS** | `UiSiteTxEditor.posEntry == true` → **no TabBar**; body is catalog + cart only. |
| **Payments** | Moved into **cart footer** (list + add + “Uang pas” + Bayar); delete staff use of Payments tab. |
| **Acc / Stock** | Hidden when `posEntry`. When `!posEntry` (Orders editor): tabs **Acc** and **Stock** only if `Session.instance.isRoot`. |
| **Payments tab (admin)** | When `!posEntry` && not root: show **Items** + **Payments** only (2 tabs). Root: all 4 tabs. |
| **Header** | `posEntry`: single toolbar — close, site title, Hold, overflow (Save menu). Remove `_headerBar` duplicate totals/contact row. |
| **Contact** | Cart column header: compact customer chip / picker (reuse `_contactChanged` + contact list). |
| **Product image** | `SiteProduct.pic` → `UiImg` 40×40 in catalog list; optional 32×32 in cart lines. Empty pic → category/icon fallback. |
| **Data / save** | Same `Tx` / `tx_put` / payment dialogs; UI-only refactor. |

---

## Multitask map

```
Wave 1 (parallel)
  Track 0  Mode matrix + editor shell (tabs gating, drop posEntry header bar)
  Track 1  Slim POS toolbar (posEntry app bar)

Wave 2 (parallel, after Wave 1)
  Track 2  Product thumbs in catalog (+ cart optional)
  Track 3  Cart inline payments (new widget + wire editor callbacks)

Wave 3 (parallel, after Wave 2)
  Track 4  Contact chip in cart header
  Track 5  Ledger tabs root-only (Orders editor)

Wave 4
  Track 6  Widget tests + manual QA checklist + tx.md note
```

| Track | Focus | Key files | Depends |
|-------|--------|-----------|---------|
| **0** | Tab count / body layout by mode | `ui_site_tx_editor.dart` | — |
| **1** | Compact app bar | `ui_site_tx_editor.dart`, maybe `ui_tx_pos_toolbar.dart` | 0 |
| **2** | Product avatars | `section_tx_items.dart`, `ui_site_product_thumb.dart` (new, small) | — |
| **3** | Inline payments in cart | `section_tx_cart_pay.dart` (new), `section_tx_items.dart`, `ui_site_tx_editor.dart` | 0 |
| **4** | Customer on cart | `section_tx_items.dart` or cart header widget | 3 |
| **5** | Root-only Acc/Stock | `ui_site_tx_editor.dart` | 0 |
| **6** | Tests + docs | `test/section_tx_*`, `_/docs/tx.md` | all |

---

## Track 0 — Editor mode matrix (tabs + layout)

**Problem:** `TabController(length: 4)` + `TabBar` + `_headerBar` stack on top of `SectionTxItems`, which already has cart + Bayar.

- [ ] **0.1** Add computed `int _tabCount` / `List<Tab> _tabsForMode()`:
  - `posEntry` → **0 tabs** (no `TabBar`, no `TabBarView`).
  - `!posEntry && !isRoot` → **2 tabs**: Items, Payments.
  - `!posEntry && isRoot` → **4 tabs**: Items, Payments, Acc, Stock.
- [ ] **0.2** `initState` / `didUpdateWidget`: recreate `TabController` when tab count changes (dispose old).
- [ ] **0.3** `posEntry` body: `Column(offline banner?, SectionTxItems(...))` only — no `_headerBar`.
- [ ] **0.4** `!posEntry`: keep `_headerBar` for Orders editor (or slim in Track 5 if redundant with Payments tab).
- [ ] **0.5** Smoke: open POS from Sites picker → no tab strip; Orders → edit → staff sees 2 tabs.

---

## Track 1 — Slim POS toolbar

- [ ] **1.1** Extract optional `UiTxPosToolbar` (or inline): `leading: close`, `title: site name`, `actions: hold`, `UiTxSaveMenu` in overflow / `PopupMenuButton` if width tight.
- [ ] **1.2** `posEntry`: remove duplicate vertical space (no `bottom: TabBar` on AppBar).
- [ ] **1.3** Window title / semantics: keep site name in `AppBar.title`; subtitle optional (`alienai.id/slug`) only on wide layout (`LayoutBuilder`).

---

## Track 2 — Product thumbnails

- [ ] **2.1** New `ui_site_product_thumb.dart`: `UiSiteProductThumb({required SiteProduct product, double size})` → `UiImg(src: product.pic, ...)` + fallback `Icons.shopping_bag_outlined`.
- [ ] **2.2** Catalog `ListTile` → `leading: UiSiteProductThumb(size: 44)` in `section_tx_items.dart`.
- [ ] **2.3** (Optional) Cart line leading 32×32 thumb when `product.pic` non-empty.
- [ ] **2.4** Widget test: thumb renders fallback when `pic` empty.

---

## Track 3 — Inline cart payments

**Move** payment UX from `ui_site_tx_editor._paymentsTab` into cart column (id.alienai-style).

- [ ] **3.1** New `section_tx_cart_pay.dart`:
  - Props: `Tx tx`, `onAddPayment`, `onRemovePayment`, `onExactCash`, `onCheckout`, `nominal`, `paid`.
  - UI: compact payment rows (icon + method label + amount + remove); `+ Terima pembayaran`; chip `Uang pas`; **Sisa / Lunas** line; primary **Bayar** (delegate to existing `_checkoutTap`).
- [ ] **3.2** Extend `SectionTxItems` (or wrap cart column) to embed `SectionTxCartPay` **above** existing total block; merge duplicate “Total Pembayaran” / Bayar into one footer (single Bayar button).
- [ ] **3.3** `ui_site_tx_editor`: pass `payments`, `onAddPayment` → `_addPayment`, etc.; remove `onCheckout`-only footer duplication if cart handles full flow.
- [ ] **3.4** `posEntry`: `_checkoutTap` unchanged (method sheet → save when paid); partial payments visible in cart without Payments tab.
- [ ] **3.5** Delete or `#ifdef` dead `_paymentsTab` for `posEntry`; keep `_paymentsTab` implementation for **Payments** tab in admin mode (`!posEntry`).

---

## Track 4 — Contact on cart

- [ ] **4.1** Cart header row: `Keranjang` + customer `DropdownButton` / `InkWell` “Pelanggan” (same data as `_headerBar` contact dropdown).
- [ ] **4.2** Plumb `contacts`, `selectedContact`, `onContactChanged` from editor into `SectionTxItems`.
- [ ] **4.3** Remove contact UI from `_headerBar` when cart header owns it (admin Items tab can keep bar contact until Track 5 cleanup).

---

## Track 5 — Root-only ledger tabs

- [ ] **5.1** Import `Session.instance.isRoot` in `ui_site_tx_editor.dart`.
- [ ] **5.2** Acc / Stock `TabBarView` children only registered when root (dynamic tab list from Track 0).
- [ ] **5.3** Preview / acc / stock lines still from `_refreshPreview()` for root; staff admin without root does not need stock tab to sell.

---

## Track 6 — Tests, docs, QA

- [ ] **6.1** `test/pos_shell_mode_test.dart`: pump `UiSiteTxEditor(posEntry: true)` with mocked `SiteApi` / minimal products → expect **no** `Tab(text: 'Acc')`.
- [ ] **6.2** Test root vs staff tab labels with `Session` test hook or inject `isRoot` parameter (prefer optional `ledgerVisible` on editor for tests over global session if brittle).
- [ ] **6.3** Update `_/docs/tx.md` § POS UI: staff shell vs Orders ledger editor (1 paragraph + table).
- [ ] **6.4** Manual QA (Chito **99000**, site **test-site**):
  - POS: thumbs, cart pay, cash change, save, receipt menu.
  - Orders → edit: staff 2 tabs; root 4 tabs.
  - Offline banner + cached catalog still works (`site_commerce_cache`).

---

## File touch summary

| File | Action |
|------|--------|
| `clients/app/lib/widgets/sites/tx/ui_site_tx_editor.dart` | Mode matrix, toolbar, wire cart pay + contacts |
| `clients/app/lib/widgets/sites/tx/section_tx_items.dart` | Thumbs, cart header, embed cart pay footer |
| `clients/app/lib/widgets/sites/tx/section_tx_cart_pay.dart` | **New** — inline payments |
| `clients/app/lib/widgets/sites/tx/ui_site_product_thumb.dart` | **New** — shared thumb |
| `clients/app/lib/widgets/sites/tx/ui_tx_pos_toolbar.dart` | **New** (optional) — slim bar |
| `clients/app/test/pos_shell_mode_test.dart` | **New** |
| `_/docs/tx.md` | Short POS shell section |

---

## Execution notes for dispatch

1. **Wave 1** tracks 0 + 1 can run in parallel (same file — prefer **one agent** for 0+1 to avoid merge conflicts).
2. **Wave 2** tracks 2 + 3 parallel (different files; 3 touches `section_tx_items` — sequence 2 before 3 if single agent).
3. Do **not** change `page_site_pos.dart` route behavior except imports if editor API grows.
4. Match existing colors in `section_tx_items.dart` (`_accent`, `_border`, etc.).

---

## Status

**Planned** 2026-10-08 — not started. Update this section when waves land.
