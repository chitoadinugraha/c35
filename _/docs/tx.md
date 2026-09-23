# Transaction / POS (LOCKED)

Status: **locked** 2026-09-21 (revised from 2026-09-20)

Business transactions for sites — sales, purchases, debt, GL, stock.

**Domain model follows `E:\Project Archive\id.alienai`**, not CSA `mod_site_tx` wholesale.

**Storage:** all tx tables live in YSQL schema **`site`** (`site.tx`, `site.tx_item`, …). Registry stays in `ai.identity`; ACL via `identity_grant`.

## Reference

| Project | Borrow |
|---------|--------|
| `E:\Project Archive\id.alienai` | **`tx.proto`**, transaksi editor UX, child tables, debt flows |
| `D:\csa_site_published` | Guest order HTTP/finalizer patterns; **`tx_coa_category` seed slugs**; report query ideas |
| c35 site | `site.product`, `site.contact`, `site.object` |

## Key mapping

| id.alienai | c35 |
|------------|-----|
| `aid` | `site_iid` |
| `uid` / `created_by_uid` | `*_iid` (identity snowflake) |
| `(aid, tx_id)` PK | `(site_iid, tx_id)` PK |
| `p_product` | `site.product` |

Money: **BIGINT minor units** (same as id.alienai int64 amounts).

## Tx types

`sale` | `purchase` | `transfer` | `adjustment` | `return_sale` | `return_purchase` | `reservation` | `ship` | `payment` | `receipt` | `debt_payable` | `debt_receivable` | `inventory`

States: `ok` | `draft` | `pending` | `waiting_payment` | `cancelled`

Input modes: `normal` | `accounting` | `sell` | `purchase`

## Scope: Site Commerce POS & Personal Expense Tracking

Transactions support both commercial and personal ledgers through identity polymorphic `iid`:

| Mode | `site_iid` | `owner_iid` | Meaning |
|------|------------|-------------|---------|
| **Personal Expense** | User's `iid` | User's `iid` | Personal transaction (`site_iid == owner_iid`). User acts as their own ledger. |
| **Site Commerce POS** | Site's `iid` | Owner/Staff's `iid` | Commercial transaction belonging to a specific `@site` store. |

Both modes share the exact same underlying `site.tx` and `site.tx_item` child tables, payment splits, and reporting engine.

## Tables

See [`../schemas/tx.sql`](../schemas/tx.sql) and [`../schemas/object_normalizer.sql`](../schemas/object_normalizer.sql).

| Table | Notes |
|-------|-------|
| `site.tx_coa_category` | Platform seed → default account codes |
| `site.tx` | Header + denormalized totals + `tx_data_json`. Indexed on `(owner_iid, time_ts)` |
| `site.tx_item` | Lines with `owner_iid` and `obj_id` (links to `ai.object_normalizer`) |
| `site.tx_payment` | Cash, card, QRIS, debt, wallet |
| `site.tx_installment` / `site.tx_debt_payment` | Hutang / piutang |
| `site.tx_acc` | GL lines |
| `site.tx_stock` | Inventory movement |
| `site.tx_tax` / `site.tx_discount` | Adjustments |
| `ai.object_normalizer` | Language-neutral product/service taxonomy DAG (`path`, `l1_category_id`, `l2_category_id`) |
| `ai.object_alias` | Multilingual names (`lang`, `name_norm`), OCR tokens, embeddings, `verified` flag |

## Product Normalization & Taxonomy (`ai.object_*`)

To allow instant natural language analytics (e.g. *"How much milk did I buy this month?"*, *"How much did I spend on Internet last year?"*), line items link to a language-neutral taxonomy:

```text
consumable.drink (L1 Category)
   └── consumable.drink.milk (L2 Subcategory)
          ├── consumable.drink.milk.indomilk (Brand Node)
          │      └── consumable.drink.milk.indomilk.uht_1l (SKU)
          └── consumable.drink.milk.ultramilk (Brand Node)

service.utility (L1 Category)
   └── service.utility.internet (L2 Subcategory)
          └── service.utility.internet.biznet (Brand/Provider)
```

1. **Language-Neutral Knowledge Graph (`ai.object_normalizer`)**:
   - `id`: Numeric standard ID (e.g. Google Product Taxonomy ID) or snowflake.
   - `path`: Materialized path string (e.g. `consumable.drink.milk.indomilk`). Indexed via `text_pattern_ops` for $O(\log N)$ prefix scans.
   - `l1_category_id`, `l2_category_id`: Direct ancestor references for zero-overhead `GROUP BY` without string parsing.
2. **Multilingual Aliases & OCR Tokens (`ai.object_alias`)**:
   - `(obj_id, lang, name, name_norm, ehash, verified)`
   - Allows querying in any language: searching English `"milk"` or Indonesian `"susu"` resolves to the exact same `obj_id` (Milk).
   - Stores raw store receipt OCR tokens (e.g. `INDMILK UHT 250ML`) mapped to canonical objects.
3. **Auto-Learning Pipeline & Root Curation**:
   - If an item from a receipt or prompt does not exist, the LLM creates the taxonomy node and alias with `verified = false`.
   - Root admins can view and curate unverified aliases in the root admin UI (same pattern as `ai.inst` and `ai.translation`).
4. **Data Sources**:
   - Base seeds populated from the official **Google Product Taxonomy** (multilingual category feeds with matching numeric IDs), **Wikidata**, and local utility/telecom catalogs.

## Zero-Full-Table-Scan Query Architecture

Queries at any zoom level (category, subcategory, brand, specific SKU) use index range scans:

```sql
-- "How much milk did I purchase last year?"
SELECT 
    COUNT(ti.item_id)   AS total_items,
    SUM(ti.qty)         AS total_qty,
    SUM(ti.total_price) AS total_spent_minor
FROM site.tx t
JOIN site.tx_item ti 
    ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id
JOIN ai.object_normalizer o 
    ON o.id = ti.obj_id
WHERE t.owner_iid = :owner_iid
  AND t.deleted_ts IS NULL
  AND t.state = 'ok'
  AND t.time_ts >= date_trunc('year', NOW() - INTERVAL '1 year')
  AND t.time_ts <  date_trunc('year', NOW())
  AND o.path LIKE 'consumable.drink.milk%';
```

* `site.tx (owner_iid, time_ts)` index filters directly to the user's transactions in that date window.
* `site.tx_item (site_iid, tx_id, obj_id)` index performs point joins on items.
* `ai.object_normalizer (path text_pattern_ops)` index executes prefix matching as a B-tree range scan.

## Wire

Proto: [`../schemas/proto/c35/tx.proto`](../schemas/proto/c35/tx.proto)

- `ReqTxGet` / `ReqTxList` / `ReqTxPut` — staff POS & personal expense entry
- `ReqTxPreview` — dry-run totals + COA names
- `ReqTxDebtPay` — installment payment
- `ReqSiteGuestOrderPut` / `ReqSiteGuestOrderGet` — guest checkout (HTTP on api host)

Sync collection: `tx` (header + children on full get).

## UI

**Port id.alienai transaksi editor** inside Sites detail (Phase 9) — **not** CSA `ui_staff_tx_board`.

Reference tree: `E:\Project Archive\id.alienai\client_app\lib\page_project\bisnis\transaksi\`

| Surface | id.alienai source | c35 target |
|---------|-------------------|------------|
| Tx list browse | UITable / list patterns | Sites → **Orders** tab (`site.tx` collection) |
| Tx editor | `page_transaksi_edit.dart` + ledger sections | Ledger tabs: **Items \| Payments \| Acc \| Stock** |
| Receipt / print | `transaksi/receipt/` (`ui_receipt`, `receipt_pdf_generator`) | Same UX in Sites Orders flow |
| Debt / installment | `payment/ask_transaksi_payment_debt.dart`, etc. | Port with `site_iid` |
| AI tx input | `TxPrompt` in `tx_data` | Home prompt + `site.tx.put` tool / `hint.expense_add` |

Sites shell = Devices-like tabs ([`ui.md`](ui.md)) — not CSA 3-pane design editor.

Guest checkout UI stays on published SiteDoc blocks; staff POS is Flutter Sites detail only.

### AI / reports on transactions

- Staff chat: readonly **`site.query.run`** with catalog ids (`tx.sales_summary`, `tx.profit_summary`, …) — see [site-ai.md](site-ai.md).
- Multi-site compare: pass all `site_iids` from `MentionContext`; do not add multi-site variants per write tool.

## Why id.alienai, not CSA site_tx?

| | CSA `mod_site_tx` | id.alienai | c35 |
|---|-------------------|------------|-----|
| Scope | Guest orders + shop reports | Full POS / accounting | **id.alienai** |
| Migration target | — | Your existing POS | **Port id.alienai UI + logic** |
| Guest checkout | Good patterns | — | **Borrow CSA HTTP glue** on id.alienai schema |

We take **COA seed slugs + guest order flow** from CSA; **everything else** from id.alienai.

## Deferred

- Per-site COA chart table
- Stock delivery denorm table
