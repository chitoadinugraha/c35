# Billing — model pricing & quota pools (LOCKED)

Status: **locked** 2026-09-22

Companion to [billing.md](billing.md) and [billing-plans.md](billing-plans.md).

---

## Overview

Users see **two monthly included pools in IDR** — not token math, not wholesale cost:

| Pool | Models | Purpose |
|------|--------|---------|
| **Alien AI** | `alienai` slug (default) | Everyday assistant, bots (slow mode), device throttle |
| **Frontier** | User-pinned models (Gemini, GPT, Claude, …) | Premium / explicit model choice |

Wallet balance is **separate** — on-demand top-up when included pools are empty (tier-dependent).

Three internal numbers — never mix in UI:

| Layer | Meaning |
|-------|---------|
| **Provider cost** | What we pay Google / OpenAI (wholesale catalog) |
| **Pool deduct rate** | What we subtract from user's included pool |
| **Wallet deduct** | Pool rate × `billing_fx_rate` when pools empty + overage enabled |

---

## Alien AI pool rate (LOCKED)

Bill `alienai` slug against the **Alien pool** at:

| | Per 1M tokens |
|--|---------------|
| **Input** | **$1.50** |
| **Output** | **$7.00** |

Display to user as **Rp** at published FX (`billing_fx_rate`) — e.g. at Rp 17.600 / USD:

| | Per 1M tokens |
|--|---------------|
| Input | ~Rp 26.400 |
| Output | ~Rp 123.200 |

### Backend routing

- Wire slug: `alienai` (aliases: `auto`, empty)
- UI label: **Alien AI** only — never provider name
- Routing: flash-lite chain (e.g. `gemini-3.1-flash-lite` → `gemini-3.5-flash-lite`) — **invisible** to user
- `model_used` in chat / log: `alienai`

### Margin (flash-lite backend)

Provider wholesale ~$0.075 / $0.30 per 1M → **~95% gross margin** at pool rates.

Even if backend upgrades to Gemini 3.5 Flash Lite ($0.30 / $2.50 Google API), margin stays **~64–80%**.

### Why high pool $/M?

Cursor-style psychology: high nominal $/M → small real token burn per Rp shown → we can display **large included quotas** while COGS stays low.

---

## Frontier pool rate

Pinned models bill against the **Frontier pool** at:

```
pool_deduct = catalog_wholesale_usd × RETAIL_MARKUP (1.50)
```

Example — Gemini 3.5 Flash Lite (catalog wholesale $0.30 / $2.50):

| | Per 1M tokens |
|--|---------------|
| Input | $0.45 |
| Output | $3.75 |

Display as Rp using same FX rate.

---

## Model comparison (retail / 1M tokens)

| Model | Pool | Input | Output |
|-------|------|-------|--------|
| **Alien AI** | Alien | **$1.50** | **$7.00** |
| Gemini 3.5 Flash Lite | Frontier | $0.45 | $3.75 |
| Gemini 2.5 Flash | Frontier | $0.23 | $0.90 |
| GPT-4o (catalog seed) | Frontier | ~$0.38 | ~$1.50 |

Alien AI is **more expensive per token** than pinned Gemini — by design. Users get a **larger Alien Rp bucket** in the plan.

### Example turn (10k in / 2k out)

| Model | Pool charge |
|-------|-------------|
| Alien AI | ~$0.029 |
| Gemini 3.5 FL (Frontier) | ~$0.012 |
| Google API direct (3.5 FL) | ~$0.008 |

---

## Included pool shape (Lite reference)

For a **Rp 50.000 / mo** user plan (Lite), show approximately:

| Pool | Included (shown) | ~% of visible value |
|------|------------------|---------------------|
| Alien AI | **Rp 100.000** | ~83% |
| Frontier | **Rp 20.000** | ~17% |
| **Total shown** | **Rp 120.000** | **2.4× subscription price** |

Higher tiers scale pools by **quota multiplier** (below), not by duplicating the 2.4× ratio blindly.

---

## Quota multipliers (internal)

Lite = **1×** reference. Plan subscription sets monthly pool caps:

| Tier | Multiplier | Alien : Frontier split |
|------|------------|------------------------|
| Trial | **0.25×** Lite, **7 calendar days** | same % split |
| Lite | 1× | ~83% / ~17% |
| Plus | **4×** Lite | same % split |
| Pro | **10×** Lite | same % split |
| Ultra | **40×** Lite (marketing) | same % split; **wallet + priority** are real limits |

Ultra's 40× is promotional face value — heavy usage hits **wallet top-up** or slow mode; bundle **priority queue + early access + 5 channels**.

---

## Debit order

Per LLM turn (`req_id`):

```
1. If model is alienai → deduct Alien pool (IDR accounting at $1.50 / $7 rates)
2. If pinned frontier model → deduct Frontier pool (catalog × 1.50)
3. If promo-scoped demo session → deduct promo ephemeral pool (not user profile)
4. Else if overage_enabled → deduct billing_wallet (native currency via FX)
5. Else reject / slow mode (tier-dependent)
```

Never double-charge: `billing_usage_dedupe (owner_iid, req_id)`.

---

## Bot slow mode

When bot uses **own depleted quota** (not user pool):

| Setting | Value |
|---------|-------|
| Model | Alien AI only (configurable cheap model) |
| Outbound pace | **15s gap between replies, global per bot** (all chats share one human-like pace) |
| Queue | No extra 15s wait before start — pace is between outbound messages |

When bot borrows **owner user quota** and user pools empty → **bot stops**.

Bot with **own subscription** consumes **bot subscription pools first**, then may borrow user pools per product policy.

---

## Device slow mode

When device subscription pool empty:

- Continue on **Alien AI model only**
- Background throttle (protect margin)
- No hard stop unless wallet also empty (tier policy)

---

## UI display

Avatar dropdown / quota panel:

```
Lite · 23 days left
━━━━━━━━━━━━━━━━━━━━
Alien AI    Rp 280k left  ████████░░  80%
Frontier    Rp  38k left  ██████░░░░  60%
━━━━━━━━━━━━━━━━━━━━
Balance     Rp  50k        [Top up]
```

- Show **% remaining** and **Rp left** — not $/M rates
- Trial: progress bar + days left
- Label pools "Included monthly usage" — not wallet balance
- Never show wholesale or provider slug on Alien AI

---

## Principles

**Do**

- Bill `alienai` at **$1.50 / $7** pool rates
- Bill pinned models at **catalog × 1.50** on Frontier pool
- Show large **Rp Alien** + smaller **Rp Frontier** buckets
- Store `cost_wholesale_usd` + `pool_deduct_idr` on log for audit

**Don't**

- Show Gemini slug as Alien AI
- Use provider cost for allowance display
- Merge wallet balance into included pool UI

---

*Adapted from `D:\cs_agent\_\docs\billing-pricing.md` — IDR pools + $1.50 / $7 Alien rate locked 2026-09-22.*
