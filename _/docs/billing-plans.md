# Billing plans (LOCKED)

Status: **locked** 2026-09-22; **pools** 2026-03-25 = 2× monthly subscription (list IDR prices unchanged)

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

| slug | tier | Yearly (per mo) | Monthly | Tier features (channels, priority) |
|------|------|-----------------|---------|-------------------------------------|
| `lite` | lite | **Rp 49.000** | **Rp 59.000** | 2 channels |
| `plus` | plus | **Rp 99.000** | **Rp 105.000** | 2 channels, wallet overage |
| `pro` | pro | **Rp 309.000** | **Rp 340.000** | 3 channels, priority, overage |
| `ultra` | ultra | **Rp 1.000.000** | **Rp 1.200.000** | 5 channels, top priority, overage |

### Included pools (2× monthly subscription)

Shown to user as **monthly included usage** (resets each billing period). **Formula (all user tiers):**

```
total_pool_idr = 2 × monthly_subscription_idr   -- use monthly row; yearly prepay uses same pools per period
alien_pool     = round(total × 83.33%)          -- same ~5:1 as Lite (100k : 20k)
frontier_pool  = total − alien_pool
```

Seeded template on `ai.billing_plan` (`alien_pool_idr_monthly`, `frontier_pool_idr_monthly`) from **monthly** `billing_plan_price`:

| Tier | Monthly price | Alien AI pool | Frontier pool | Total | ≈ × subscription |
|------|---------------|---------------|---------------|-------|------------------|
| **Lite** | Rp 59.000 | Rp 100.000 | Rp 20.000 | Rp 120.000 | ~2.0× |
| **Plus** | Rp 105.000 | Rp 175.000 | Rp 35.000 | Rp 210.000 | ~2.0× |
| **Pro** | Rp 340.000 | Rp 565.000 | Rp 115.000 | Rp 680.000 | ~2.0× |
| **Ultra** | Rp 1.200.000 | Rp 2.000.000 | Rp 400.000 | Rp 2.400.000 | ~2.0× |

Lite rows are rounded to clean IDR but follow the same rule. Higher tiers buy **channels, priority, and overage** — not larger included pools vs Lite on a per-rupiah basis.

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
| Ultra | Wallet overage + **priority**; included pool is 2× monthly fee — balance is backstop |

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
| After expiry | **Freemium** (see below) or subscribe |

---

## Freemium (no paid plan)

When the user has **no active paid subscription** (`lite` / `plus` / `pro` / `ultra`) and **no active signup trial** (`trial_expires_ts` in the future):

| Rule | Value |
|------|-------|
| Model | **Alien AI only** (`alienai`) |
| Daily cap | **30 messages** or **30,000 tokens** (input+output) per UTC calendar day — **whichever exhausts first** |
| Paid tools | Blocked (`img.*`, `delegate.run`, `computer_use.delegate`, `device.*` remote control) |
| Billing | No pool / wallet deduct — platform COGS only |

Paid plan or active signup trial uses normal pool + billing paths instead of freemium counters.

Store: `billing_profile.freemium_day`, `freemium_msgs_used`, `freemium_tokens_used`.

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

Beyond higher monthly fee (same **2×** included-pool rule as other tiers):

- **Priority queue** (busy hours)
- **Early access** (models, features)
- **5 channels** (vs Pro 3)
- Faster outbound pace (8s vs 10s)
- Optional: included bot Lite discount, device discount, priority support

---

## Subscribe flows

Unchanged — see prior doc. Yearly vs monthly = separate `billing_plan_price` rows:

```sql
-- Current user plan prices (2026-03); pools on ai.billing_plan from 2× monthly fee
INSERT INTO ai.billing_plan_price (plan_slug, currency, amount, billing_period) VALUES
  ('lite', 'IDR', 49000, 'yearly'),
  ('lite', 'IDR', 59000, 'monthly'),
  ('plus', 'IDR', 99000, 'yearly'),
  ('plus', 'IDR', 105000, 'monthly'),
  ('pro', 'IDR', 309000, 'yearly'),
  ('pro', 'IDR', 340000, 'monthly'),
  ('ultra', 'IDR', 1000000, 'yearly'),
  ('ultra', 'IDR', 1200000, 'monthly');
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

- Plans sheet: yearly vs monthly toggle; list **Alien AI Quota** + **API Quota** (Frontier pool) per tier
- Account menu: tier name + dual pool rings + trial bar
- Never show USD pool rates or provider names on Alien AI
- Bot settings: indicate **"Using your quota"** when borrowing owner pools

---

## Related

- [billing-pricing.md](billing-pricing.md) — $1.50 / $7 Alien pool, Frontier ×1.5, debit order
- [billing.md](billing.md) — wallets, FX, tables
- [billing-implementation.md](billing-implementation.md) — phased rollout
