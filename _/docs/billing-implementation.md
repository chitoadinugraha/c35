# Billing — multi-wallet implementation plan

Status: **active** 2026-09-21

Companion to [billing.md](billing.md) and [billing-plans.md](billing-plans.md).

---

## Goals

1. Native wallet balances per currency — stable UI, no FX-derived balance display
2. Native catalog prices (Rp 49.000, not converted USD)
3. Direct plan purchase without wallet credit
4. Metered LLM deduct in wallet currency via **published** FX rates
5. Multinational users: multiple wallets, one default

---

## Phase 0 — Docs + schema (this PR)

| Task | Output |
|------|--------|
| Revise billing.md | Multi-wallet model locked |
| Revise billing-plans.md | Per-currency price tables |
| Update billing.sql | New tables + legacy `billing_account` retained |
| Proto sketch | `billing.proto` target messages (comments / parallel types) |
| Migration notes | SQL script outline below |

**Exit:** schema applies idempotently on fresh DB; legacy code still runs against `billing_account`.

---

## Phase 1 — Schema migration + dual-read

| Task | Owner | Notes |
|------|-------|-------|
| Add `billing_profile`, `billing_wallet`, `billing_plan_price`, `billing_fx_rate`, `billing_purchase` | SQL | See `billing.sql` |
| Migration script `billing_migrate_v2.sql` | SQL | One-time: split `billing_account` → profile + wallets |
| `identity.billing_profile_iid` column | SQL | Nullable; backfill from existing users |
| Seed `billing_plan_price` IDR rows | SQL | Plus Rp 49k, bot.small Rp 60k, etc. from billing-plans.md |
| Seed `billing_fx_rate` | SQL | IDR micro_per_usd = 17630000000 (adjustable) |

**Migration logic (`billing_account` → v2):**

```text
FOR each billing_account row:
  INSERT billing_profile (owner_iid, plan_tier, alien_allow_*, windows, default_wallet_currency = billing_currency)
  INSERT billing_wallet (owner_iid, 'IDR', balance_idr, is_default = billing_currency = 'IDR')
  INSERT billing_wallet (owner_iid, 'USD', balance_usd, is_default = billing_currency = 'USD')
  IF only one balance > 0: set is_default on that currency
  UPDATE identity SET billing_profile_iid = profile.id
```

Keep `billing_account` read-only during dual-read; drop after Phase 3.

**Exit:** YB has v2 rows for all existing users; no user-visible change yet.

---

## Phase 2 — Protobuf + session init

| Task | Notes |
|------|-------|
| `BillingWallet` message | `id`, `owner_iid`, `currency`, `balance`, `is_default` |
| `BillingProfile` message | quota fields + `default_wallet_currency` |
| `BillingPlanPrice` | `plan_slug`, `currency`, `amount`, `period` |
| `ResSessionInit` | `profile` + `wallets[]` (replace single `BillingAccount`) |
| `BillingPushBalance` | `wallet_id`, `currency`, `balance` (drop dual usd/idr) |
| Regen Dart + Rust proto | `protoc.ps1` + `cargo build` |
| NATS payload | Match new `BillingPushBalance` |

**Exit:** wire types exist; server can still populate from legacy tables behind adapter.

---

## Phase 2b — Reservation + on-demand (2026-09-21)

| Task | Status |
|------|--------|
| `billing_on_demand.rs` — allowance, hold, FX math | ✅ + 11 unit tests |
| `billing_reservation.rs` — hold / settle / refund with `FOR UPDATE` | ✅ |
| `prompt_turn` / `channel_prompt_turn` — hold at start, refund on abort | ✅ |
| `billing_usage_report` — settle hold after deduct | ✅ |
| `billing_gate` — IDR-aware wallet + held totals | ✅ |

---

## Phase 3 — Server `mod_billing` refactor

| Module | Change |
|--------|--------|
| `billing_wallet_get` | List wallets + default for owner |
| `billing_profile_get` | Quota + plan tier |
| `billing_plan_price_list` | Catalog for UI by currency |
| `billing_fx_rate_current` | Latest rate per currency |
| `billing_topup_put` | Single `amount` + `currency` → credit wallet |
| `billing_plan_subscribe` | Charge `billing_plan_price`; debit wallet OR direct purchase path |
| `billing_purchase_*` | Create / settle direct checkout |
| `billing_turn` / `billing_usage_report` | Deduct allowance → wallet native via fx rate |
| `billing_push` | Push wallet + profile separately |
| `session_init` | Parallel fetch profile + wallets |
| Adapter | `billing_account_get` wraps v2 for backward compat (temporary) |

**Crate touch order:**

```text
mod_billing → mod_identity/session_init → wire_ws → wire_http/invoke
```

**Tests:**

- Subscribe plus IDR debits exactly Rp 49.000 from IDR wallet
- Metered turn deducts IDR using published rate; `cost_usd` on log unchanged
- Idempotent dedupe unchanged

**Exit:** server writes only v2 tables; `billing_account` deprecated.

---

## Phase 4 — Flutter client

| Area | Change |
|------|--------|
| `AppStore` | `BillingProfile` + `List<BillingWallet>`; default wallet getter |
| `money_format.dart` | `walletBalanceLabel(wallet)` — single currency |
| Account menu | Balance row from default wallet only |
| History sheet | Transactions in wallet currency |
| Plans sheet | Prices from `billing_plan_price` for user's default currency |
| Settings | Default wallet picker when multiple wallets |
| Session init merge | Profile + wallets; remove `billingSummaryGet` on menu open |
| NATS handlers | Apply `BillingPushBalance` per wallet |

**Exit:** no dual-currency UI; balance stable day-to-day.

---

## Phase 5 — Direct purchase + providers

| Task | Notes |
|------|-------|
| `billing_purchase` API | Start checkout in chosen currency |
| Midtrans (IDR) | Webhook → settle purchase → activate subscription |
| Manual approve | Admin UI for purchase + top-up (existing pattern) |
| UI: "Pay with balance" vs "Pay now" | Wallet debit vs direct purchase |

**Exit:** user can buy plan without prefunding wallet.

---

## Phase 6 — Commission + cleanup

| Task | Notes |
|------|-------|
| Commission per currency wallet | Or unified ledger with currency column |
| Drop `billing_account` table | After metrics show zero reads |
| Drop legacy proto fields | `balance_usd` / `balance_idr` on wire |
| Admin FX rate UI | Update `billing_fx_rate` weekly |

---

## Risk register

| Risk | Mitigation |
|------|------------|
| IDR volatility on metered usage | Published weekly rate; small buffer in retail markup |
| Partial migration | Dual-read adapter; feature flag per user |
| Scoped bot/device subscribe in wrong currency | Require wallet in purchase currency or auto-create empty wallet |
| Allowance still USD-internal | Document in billing-plans; only wallet leg is native |

---

## File checklist

| Path | Action |
|------|--------|
| `_/docs/billing.md` | ✅ Revised |
| `_/docs/billing-plans.md` | ✅ Per-currency pricing |
| `_/docs/billing-implementation.md` | ✅ This file |
| `_/schemas/billing.sql` | ✅ New tables |
| `_/schemas/migrations/billing_migrate_v2.sql` | Create in Phase 1 |
| `_/schemas/proto/c35/billing.proto` | Target types (Phase 2) |
| `_/schemas/identity.sql` | `billing_profile_iid` (Phase 1) |
| `servers/crates/mod_billing/**` | Phase 3 |
| `clients/app/lib/c/billing/**` | Phase 4 |

---

## Acceptance criteria (full rollout)

- [ ] User sees one balance in default wallet currency everywhere
- [ ] Plus plan shows Rp 49.000 (not converted) for IDR users
- [ ] LLM usage deducts IDR from wallet; `ai.log.cost_usd` still accurate
- [ ] Direct purchase activates plan without wallet credit
- [ ] Second wallet (USD) usable for business purchases
- [ ] Session init returns profile + wallets; NATS updates balance in real time
- [ ] `billing_account` table dropped
