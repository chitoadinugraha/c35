# Billing plans (LOCKED)

Status: **locked** 2026-09-21 (revised — per-currency catalog prices)

## Overview

Plans are **scoped SKUs** attached to an identity (user, bot, device). Each plan has:

- **Allowance** — quota rings on `billing_profile` (personal) or subscription row (scoped)
- **Caps** — max tokens, models, etc.
- **Prices** — **native amounts per currency** in `billing_plan_price` (not live FX)

See [billing.md](billing.md) for wallets, FX policy, and direct purchase.

---

## Plan scopes

| Scope | Attached to | Example |
|-------|-------------|---------|
| `user` | Personal `billing_profile` | Plus, Pro |
| `bot` | `billing_subscription` → bot iid | bot.small, bot.pro |
| `device` | `billing_subscription` → remote/iot iid | device.basic |

One active subscription per `(scope, target_iid)` unless upgrade path replaces it.

---

## Catalog (`billing_plan`)

| slug | scope | tier | Notes |
|------|-------|------|-------|
| `free` | user | free | Default; allowance rings only |
| `plus` | user | plus | Higher allowance + wallet top-up |
| `pro` | user | pro | Highest personal tier |
| `bot.small` | bot | plus | Small chat bot |
| `bot.pro` | bot | pro | High-volume bot |
| `device.basic` | device | plus | Remote/IoT basic |

`price_usd` on `billing_plan` is **admin reference only**. Checkout reads `billing_plan_price`.

---

## Per-currency prices (`billing_plan_price`)

Marketing-friendly native amounts. Charge **exactly** this at subscribe / direct purchase.

### User plans (monthly)

| plan_slug | IDR | USD | EUR (future) |
|-----------|-----|-----|--------------|
| `plus` | Rp 49.000 | $4.99 | €4.49 |
| `pro` | Rp 149.000 | $14.99 | €13.99 |

### Bot plans (monthly)

| plan_slug | IDR | USD |
|-----------|-----|-----|
| `bot.small` | Rp 60.000 | $5.99 |
| `bot.pro` | Rp 199.000 | $19.99 |

### Device plans (monthly)

| plan_slug | IDR | USD |
|-----------|-----|-----|
| `device.basic` | Rp 39.000 | $3.99 |

**Rounding:** store as NUMERIC in DB; display with locale grouping (Rp 49.000, not 49000).

---

## Subscribe flows

### A — Pay from wallet (prefunded)

```
1. User has billing_wallet(currency) with balance >= billing_plan_price.amount
2. billing_plan_subscribe(plan_slug, currency, wallet_id)
3. Debit wallet exact native amount
4. Upsert billing_subscription + upgrade billing_profile.plan_tier (if user scope)
```

### B — Direct purchase (no wallet credit)

```
1. billing_purchase_create(plan_slug, currency)
2. Redirect to payment provider (Midtrans / Stripe / manual)
3. On webhook / admin approve → billing_purchase settled
4. Activate billing_subscription (no wallet credit step)
```

User chooses A or B in UI. Same `billing_plan_price` row for both.

---

## Allowance vs wallet

| Consumption | Source |
|-------------|--------|
| Within plan allowance (5h / weekly rings) | `billing_profile` counters — no wallet debit |
| Over allowance (metered LLM) | `billing_wallet` in default currency; `cost_usd` on log × `billing_fx_rate` |

Allowance pool accounting remains USD-internal for caps; **user sees wallet in native currency only**.

---

## Upgrade / downgrade

- **Upgrade:** prorate or charge full next period per product policy (Phase 5)
- **Downgrade:** effective end of current `billing_subscription.period_end`
- **Scoped cancel:** subscription `status = cancelled`; target reverts to free caps

---

## Admin seed SQL (reference)

```sql
INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
  ('plus', 'IDR', 49000, 'monthly'),
  ('plus', 'USD', 4.99, 'monthly'),
  ('pro', 'IDR', 149000, 'monthly'),
  ('pro', 'USD', 14.99, 'monthly'),
  ('bot.small', 'IDR', 60000, 'monthly'),
  ('bot.small', 'USD', 5.99, 'monthly');
```

---

## Client display

- Plans sheet: list prices for **default wallet currency**; toggle currency if user has multiple wallets
- Account menu: plan name from `billing_profile.plan_tier` — not from price table
- Never show converted USD alongside IDR for catalog prices
