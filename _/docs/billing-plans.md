# Billing plans (LOCKED)

Status: **locked** 2026-09-22 (IDR pools, Lite–Ultra, bot/device SKUs, promotions)

## Overview

Plans are **scoped SKUs** attached to an identity (user, bot, device). Each plan defines:

- **Included pools** — monthly **Alien AI** + **Frontier** quota in IDR (see [billing-pricing.md](billing-pricing.md))
- **Caps** — channels, outbound pace, concurrent bots
- **Prices** — native IDR in `billing_plan_price` (`monthly` | `yearly` billing period)

**No permanent free tier** — new users enter via **signup trial** promotion (1× per verified email).

---

## Plan scopes

| Scope | Attached to | Billing row |
|-------|-------------|-------------|
| `user` | `billing_profile` | Personal app usage |
| `bot` | `billing_subscription` → `bot_iid` | Per-bot package |
| `device` | `billing_subscription` → `remote_iid` | Per Windows / IoT device |

One active paid subscription per `(scope, scope_iid)` unless upgrade replaces it.

---

## User plans (personal)

Yearly prepay = lower monthly equivalent. Charge exact `billing_plan_price` amount — no live FX.

### Prices (IDR / month)

| slug | tier | Yearly (per mo) | Monthly | Quota vs Lite |
|------|------|-----------------|---------|---------------|
| `lite` | lite | **Rp 49.000** | **Rp 59.000** | 1× |
| `plus` | plus | **Rp 99.000** | **Rp 109.000** | **4×** |
| `pro` | pro | **Rp 309.000** | **Rp 349.000** | **10×** |
| `ultra` | ultra | **Rp 1.000.000** | **Rp 1.200.000** | **40×** (marketing) |

### Included pools (Lite = 1× reference)

Shown to user as **monthly included usage** (resets each billing period):

| Tier | Alien AI pool | Frontier pool | Total shown | ~× price |
|------|---------------|---------------|-------------|----------|
| **Lite** | Rp 100.000 | Rp 20.000 | Rp 120.000 | 2.4× (at Rp 50k ref) |
| **Plus** | Rp 400.000 | Rp 80.000 | Rp 480.000 | ~4.8× |
| **Pro** | Rp 1.000.000 | Rp 200.000 | Rp 1.200.000 | ~3.9× |
| **Ultra** | Rp 4.000.000 | Rp 800.000 | Rp 4.800.000 | ~4.8× |

Lite reference uses **~83% Alien / ~17% Frontier** split. Higher tiers multiply both pools by tier multiplier.

### Channels & pace (user scope)

| Tier | Channels | Outbound pace |
|------|----------|---------------|
| Lite, Plus | **2** (1 WhatsApp + 1 Telegram) | 10s between outbound **per prompt turn** (split replies don't reset timer) |
| Pro | **3** | 10s / prompt turn |
| Ultra | **5** | 8s / prompt turn; **priority queue** on busy hours; **early access** features |

`channels_limit` + `caps_json.outbound_gap_ms` on `billing_plan`.

### Overage & wallet

| Tier | Pools empty |
|------|-------------|
| Lite | Stop or top-up wallet (no slow bleed) |
| Plus, Pro | Wallet metered overage (`overage_enabled`) |
| Ultra | Wallet overage + **priority**; 40× pool is promotional — balance is backstop |

---

## Bot plans (per bot)

**Default:** bot consumes **owner's user pools** unless bot has its own subscription.

| slug | Yearly (per mo) | Monthly | Channels | Msgs/mo cap |
|------|-----------------|---------|----------|-------------|
| `bot.lite` | **Rp 39.000** | **Rp 49.000** | **1** | **none** |
| `bot.small` | **Rp 89.000** | **Rp 99.000** | **3** | **none** |

### Bot rules (per bot instance)

| Rule | Behavior |
|------|----------|
| Quota source | **Own subscription pools first** → may borrow owner user pools |
| Message cap | **No monthly msg limit** — only channel count + rate limits |
| Normal pace | Plan `outbound_gap_ms` (default 10s per prompt turn) |
| Own pool empty | **Slow mode**: Alien AI model only, **15s global gap** between outbound replies (all chats) |
| Owner pool empty while borrowing | **Bot stops** |
| Instructions | System prompt / config is **per bot** (`scope_iid = bot_iid`) |

`msgs_limit = 0` means unlimited. Enforce `channels_limit` + `caps_json`.

---

## Device plans (per device)

Computer-use / Windows automation. Quota = same **Alien + Frontier IDR pools** model as user (token usage accounting).

| slug | Yearly (per mo) | Monthly | Positioning |
|------|-----------------|---------|-------------|
| `device.light` | **Rp 499.000** | **Rp 599.000** | Light UI automation, reports, data entry |
| `device.medium` | **Rp 999.000** | **Rp 1.109.000** | Heavier 24/7 workloads, more concurrent tasks |

### Device rules

| Rule | Behavior |
|------|----------|
| Quota | Dedicated subscription pools on `billing_subscription` |
| Pool empty | **Slow mode** — Alien AI model only, background throttle |
| Marketing | ~Rp 3M admin salary vs Rp 499k automation |

Pool amounts: scale from Lite reference (product to tune — e.g. Light ≈ 10× Lite pools, Medium ≈ 20×).

---

## Promotions (`billing_promotion`)

Separate from referral commission codes. Marketing / trials / custom packages.

### Promotion types

| type | Purpose |
|------|---------|
| `signup_trial` | New user: **0.25× Lite** pools, **7 calendar days**, **1× per email** |
| `demo_trial` | Sales demo: **15–30 min** (configurable) computer-use; **does not burn user pools** |
| `discount` | % or fixed off subscribe |
| `custom_package` | Bespoke pools / duration for sales |

### Audience

| audience | Fields | UI |
|----------|--------|-----|
| `single` | One redemption total | After use: **"Used by …"** |
| `multi` | `max_claims_total`, `valid_from` / `valid_to` | List of users who claimed |

### Common fields

| Field | Notes |
|-------|-------|
| `max_claims_per_email` | Default **1** (enforce on verified email) |
| `alien_pool_idr` / `frontier_pool_idr` | Fixed grant or use `pool_multiplier` × plan |
| `duration_days` | Signup trial (7) |
| `duration_minutes` | Demo trial (15–30) |
| `base_plan_slug` | e.g. `lite`, `plus` |
| `scope` | `user` \| `device` \| `bot` (demo computer-use → device-scoped ephemeral pool) |

Claims tracked in `billing_promotion_claim` — not overloaded into `referral_code` (keep `referral_code` for purchase / affiliate packages).

---

## Signup trial (default entry)

| Item | Value |
|------|-------|
| Duration | **7 calendar days** (`trial_expires_ts`) |
| Pools | **0.25× Lite** → Alien Rp 25.000, Frontier Rp 5.000 |
| Limit | **1× per verified email** |
| UI | Progress bar in avatar dropdown (days left + pool %) |
| After expiry | Subscribe or read-only / blocked per product policy |

---

## Demo trial (marketing)

| Item | Value |
|------|-------|
| Duration | **15–30 minutes** (configurable on promotion) |
| Scope | Computer-use demo session |
| Billing | Deduct from **promo ephemeral pool** only — **never user `billing_profile` pools** |
| Implementation | `billing_reservation.promotion_id` + session-scoped allowance |

---

## Ultra extras

Beyond 40× pools:

- **Priority queue** (busy hours)
- **Early access** (models, features)
- **5 channels** (vs Pro 3)
- Faster outbound pace (8s vs 10s)
- Optional: included bot Lite discount, device discount, priority support

---

## Subscribe flows

Unchanged — see prior doc. Yearly vs monthly = separate `billing_plan_price` rows:

```sql
-- Example shape (amounts illustrative)
INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
  ('lite', 'IDR', 49000, 'yearly'),
  ('lite', 'IDR', 59000, 'monthly'),
  ('plus', 'IDR', 99000, 'yearly'),
  ('plus', 'IDR', 109000, 'monthly');
```

### A — Pay from wallet

```
wallet balance >= price → billing_plan_subscribe → debit wallet → activate
```

### B — Direct purchase

```
billing_purchase → payment provider → settled → activate subscription
```

---

## Catalog slugs (`billing_plan`)

### User

| slug | Replaces |
|------|----------|
| `lite` | `free` (deprecated as default) |
| `plus` | `plus` |
| `pro` | `pro` |
| `ultra` | new |

### Bot

| slug | Replaces |
|------|----------|
| `bot.lite` | `bot.small` (old naming) |
| `bot.small` | `bot.medium` |

### Device

| slug | Replaces |
|------|----------|
| `device.light` | `device.office_light` |
| `device.medium` | `device.office_pro` |

---

## Client display

- Plans sheet: yearly vs monthly toggle; show **Alien + Frontier Rp pools** per tier
- Account menu: tier name + dual pool rings + trial bar
- Never show USD pool rates or provider names on Alien AI
- Bot settings: indicate **"Using your quota"** when borrowing owner pools

---

## Related

- [billing-pricing.md](billing-pricing.md) — $1.50 / $7 Alien pool, Frontier ×1.5, debit order
- [billing.md](billing.md) — wallets, FX, tables
- [billing-implementation.md](billing-implementation.md) — phased rollout
