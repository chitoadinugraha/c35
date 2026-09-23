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

## Tables

See [`../schemas/tx.sql`](../schemas/tx.sql).

| Table | Notes |
|-------|-------|
| `site.tx_coa_category` | Platform seed → default account codes |
| `site.tx` | Header + denormalized totals + `tx_data_json` |
| `site.tx_item` | Lines; reservations + sources |
| `site.tx_payment` | Cash, card, QRIS, debt, wallet |
| `site.tx_installment` / `site.tx_debt_payment` | Hutang / piutang |
| `site.tx_acc` | GL lines |
| `site.tx_stock` | Inventory movement |
| `site.tx_tax` / `site.tx_discount` | Adjustments |

## Wire

Proto: [`../schemas/proto/c35/tx.proto`](../schemas/proto/c35/tx.proto)

- `ReqTxGet` / `ReqTxList` / `ReqTxPut` — staff POS
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
| AI tx input | `TxPrompt` in `tx_data` | Home prompt + `site.tx.put` tool |

Sites shell = Devices-like tabs ([`ui.md`](ui.md)) — not CSA 3-pane design editor.

Guest checkout UI stays on published SiteDoc blocks; staff POS is Flutter Sites detail only.

### AI / reports on transactions

- Staff chat: readonly **`site.query.run`** with catalog ids (`tx.sales_summary`, `tx.profit_summary`, …) — see [site-ai.md](site-ai.md).
- Multi-site compare: pass all `site_iids` from `MentionContext`; do not add multi-site variants per write tool.

## Why id.alienai, not CSA site_tx?

| | CSA `mod_site_tx` | id.alienai | c35 |
|--|-------------------|------------|-----|
| Scope | Guest orders + shop reports | Full POS / accounting | **id.alienai** |
| Migration target | — | Your existing POS | **Port id.alienai UI + logic** |
| Guest checkout | Good patterns | — | **Borrow CSA HTTP glue** on id.alienai schema |

We take **COA seed slugs + guest order flow** from CSA; **everything else** from id.alienai.

## Deferred

- Per-site COA chart table
- `ReqTxParse` (AI subject match)
- Stock delivery denorm table
