# Transaction / POS (LOCKED)

Status: **locked** 2026-09-20

Business transactions for sites — sales, purchases, debt, GL, stock. **Domain model follows id.alienai**, not csa `site_tx` wholesale.

## Reference

| Project | Borrow |
|---------|--------|
| `E:\Project Archive\id.alienai` | **`tx.proto`** — enums, header totals, child tables, debt/installments |
| `E:\Project Archive\csa_site_published` | Sites 3-pane shell; COA category seed slugs |
| c35 site | `site_product`, `site_contact`, `site_object` |

## Key mapping

| id.alienai | c35 |
|------------|-----|
| `aid` | `site_iid` |
| `uid` / `created_by_uid` | `*_iid` (identity snowflake) |
| `(aid, tx_id)` PK | `(site_iid, tx_id)` PK |
| `p_product` | `site_product` |

Money: **BIGINT minor units** (same as id.alienai int64 amounts).

## Tx types

`sale` | `purchase` | `transfer` | `adjustment` | `return_sale` | `return_purchase` | `reservation` | `ship` | `payment` | `receipt` | `debt_payable` | `debt_receivable` | `inventory`

States: `ok` | `draft` | `pending` | `waiting_payment` | `cancelled`

Input modes: `normal` | `accounting` | `sell` | `purchase`

## Tables

See [`../schemas/tx.sql`](../schemas/tx.sql).

| Table | Notes |
|-------|-------|
| `tx` | Header + denormalized totals + `tx_data_json` |
| `tx_item` | Lines; optional reservations + sources |
| `tx_payment` | Cash, card, QRIS, debt, wallet |
| `tx_installment` / `tx_debt_payment` | Hutang / piutang schedules |
| `tx_acc` | GL lines (debit/credit) |
| `tx_stock` | Inventory movement |
| `tx_tax` / `tx_discount` | Line adjustments |
| `tx_coa_category` | Platform seed → default account codes |

## Wire

Proto: [`../schemas/proto/c35/tx.proto`](../schemas/proto/c35/tx.proto)

- `ReqTxGet` / `ReqTxList` / `ReqTxPut` — staff POS
- `ReqTxPreview` — dry-run totals + COA names
- `ReqTxDebtPay` — installment payment
- `ReqSiteGuestOrderPut` / `ReqSiteGuestOrderGet` — guest checkout

Sync collection: `tx` (header + children on full get).

## UI (future)

**id.alienai staff transaksi editor** inside Sites detail pane:

- Ledger tabs (items | payments | acc | stock)
- AI input (`TxPrompt` in tx_data)
- Debt / installment UI
- Subject picker → `site_contact`

Shell navigation from **csa Sites 3-pane** — not id.alienai app shell.

## Why not csa site_tx?

csa `site_tx` is simpler and site-commerce focused. id.alienai has richer accounting modes, debt flows, and the editor UX you prefer. We took:

- **COA category slugs** from csa (seed table)
- **Everything else** from id.alienai tx model

## Deferred

- Per-site COA chart table (preview returns `coa_name` map; chart mod later)
- Tx parse / AI subject match (`ReqTxParse` from id.alienai — add in mod_tx)
- Stock delivery denorm table (`TxStockDelivery` — derived query OK for v1)
