# Billing (LOCKED)

Status: **locked** 2026-09-21 (revised — multi-wallet)

## Overview

Wallet + quota + commission for platform AI usage. Adapted from `D:\cs_agent`, extended for **multi-currency wallets** and **native per-currency catalog prices**.

**Three layers:**

| Layer | Table(s) | Purpose |
|-------|----------|---------|
| **Profile** | `billing_profile` | Personal plan tier, Alien + Frontier IDR pools, default wallet currency |
| **Wallets** | `billing_wallet` | Spendable balance per `(owner_iid, currency)` |
| **Catalog** | `billing_plan` + `billing_plan_price` | Plan SKUs + **fixed native prices** per currency |

**Scoped plans (device + chat bot):** separate SKUs — see [billing-plans.md](billing-plans.md).

**Single audit ledger:** `ai.log` — see [log.md](log.md). Billable LLM rows set `cost_usd > 0` (internal COGS). Client error rows stay `0`.

`ResSessionInit` returns billing snapshot in one round trip. Realtime pushes: `c35.user.{iid}.balance`, `.quota`, `.commission` over NATS.

Implementation plan: [billing-implementation.md](billing-implementation.md).

---

## Design principles

### Native balances, not converted display

- Each wallet stores balance in **its own currency** (e.g. `49000.00` IDR, `12.50` USD).
- UI shows **one amount** from the user's **default wallet** — balance does not move when FX rates change.
- **Never** show `$X · Rp Y` dual-currency strings in user-facing UI.

### Catalog vs metered FX

| Flow | Pricing | FX |
|------|---------|-----|
| **Plan subscribe / direct purchase** | Fixed row in `billing_plan_price` (e.g. Rp 49.000) | None — charge exact listed amount |
| **Wallet top-up** | User pays exact amount in chosen currency | None — credit wallet 1:1 |
| **Metered LLM usage** | Internal `cost_usd` on `ai.log` | Convert at **deduct time** using `billing_fx_rate` (published, periodic) |

Platform absorbs FX drift between rate updates on metered usage. Catalog and top-up have **zero FX risk**.

**Voice metered SKU (cloud STT/TTS):** When the client uses engine mode `cloud`, `mod_voice` reserves a small USD hold (`VOICE_STT_HOLD_USD` / `VOICE_TTS_HOLD_USD`), calls Google Cloud Speech or Text-to-Speech, then settles against the user's balance at retail rates (`VOICE_STT_USD_PER_MIN`, `VOICE_TTS_USD_PER_1K_CHARS` in `billing_cost.rs`) with the same FX-at-deduct-time policy as LLM metered usage. Rows land in `ai.log` with `kind` `voice_stt` or `voice_tts`. Web and local engines never touch billing. See [voice.md](voice.md).

### Direct purchase (no wallet credit)

User may buy a plan or add-on **without** prefunding a wallet:

```
User selects plan + currency → payment provider → billing_purchase settled → activate subscription
```

Wallet top-up remains optional float for metered overage.

---

## Tables

| Table | Purpose |
|-------|---------|
| `billing_profile` | One per user: plan tier, allowance rings, default wallet currency |
| `billing_wallet` | Balance per `(owner_iid, currency)` |
| `billing_plan` | Plan SKU catalog (scope, allowances, caps) |
| `billing_plan_price` | Native list price per `(plan_slug, currency)` |
| `billing_fx_rate` | Published USD→currency rate for **metered deduct only** |
| `billing_purchase` | Direct plan purchase (provider checkout, no wallet credit) |
| `billing_topup_request` | Manual / provider top-up → credit `billing_wallet` |
| `billing_reservation` | Escrow hold during in-flight LLM turn (`req_id`) |
| `billing_usage_dedupe` | Idempotent deduct per `(owner_iid, req_id)` |
| `billing_subscription` | Scoped plan attachment (bot / device / user) |
| `log` | Audit + billing trace (`cost_usd`) |

Legacy (migrate away): `billing_account` — see [billing-implementation.md](billing-implementation.md) § Migration.

Canonical DDL: [`../schemas/billing.sql`](../schemas/billing.sql)

---

## `billing_profile`

One row per **user** (`owner_iid` unique). Holds quota meters and preferences — **not** spendable balance.

| Field | Purpose |
|-------|---------|
| `plan_tier` | `free` \| `plus` \| `pro` \| … |
| `default_wallet_currency` | ISO 4217 (`IDR`, `USD`, …) — from locale at signup, user-changeable |
| `alien_allow_5h_used/limit` | 5-hour ring (pool accounting USD internally) |
| `alien_allow_weekly_used/limit` | Weekly ring |
| `window_5h_start`, `window_weekly_start` | Rolling window anchors |
| `commission_*` | Referral balances (per-currency columns deferred → wallet or ledger) |

Linked from `identity` via `billing_profile_iid` (replaces legacy `billing_iid` wallet pointer).

---

## `billing_wallet`

Spendable balance. **Multiple wallets per user** — one per currency in use.

| Field | Purpose |
|-------|---------|
| `owner_iid` | User |
| `currency` | ISO 4217 (`IDR`, `USD`, `EUR`, …) |
| `balance` | Native currency amount (NUMERIC) |
| `is_default` | One `true` per owner — UI default; metered deduct targets this unless overridden |
| `name` | Optional label (`Personal IDR`, `Business USD`) |

**Unique:** `(owner_iid, currency)` where `deleted_ts IS NULL`.

**Signup:** create wallet for locale currency (e.g. `IDR` for `id_ID`) with `is_default = true`. Additional wallets created on first top-up or explicit user action.

**Multinational use:** user may hold IDR + USD wallets; switch default in settings.

---

## `billing_plan_price`

Marketing-friendly native prices — **not** converted from USD at checkout.

```sql
-- Examples
('plus',  'IDR', 49000,  'monthly')
('plus',  'USD', 4.99,   'monthly')
('bot.small', 'IDR', 60000, 'monthly')
```

Subscribe / direct purchase charges **exactly** `amount` in `currency`. No live FX.

`billing_plan.price_usd` remains reference / fallback for admin; **checkout uses `billing_plan_price`**.

---

## `billing_fx_rate`

Published rates for **metered usage deduct** and top-up amount pairing (display/record only — wallet credit stays in paid currency).

| Field | Purpose |
|-------|---------|
| `currency` | Target currency |
| `micro_per_usd` | Integer: local micro-units per 1 USD (same convention as legacy `fx_micro_per_usd`) |
| `effective_from` | Rate valid from this timestamp |

### How rates are updated

`c35-fetcher` (singleton Deployment) fetches USD→IDR hourly from **Open Exchange Rates**, applies configurable markup (`FX_MARKUP_BPS`, default 10%), inserts a row when change exceeds threshold, and publishes `c35.fetch.fx` on NATS.

`c35-server` pods keep the latest rate **in memory** (no per-deduct DB read). On boot: load latest `billing_fx_rate` row until first NATS push.

See [fetcher.md](fetcher.md). **Not sourced from Midtrans.**

**Deduct formula:**

```
deduct_native = cost_usd * (micro_per_usd / 1_000_000)
```

Store `cost_usd`, `deducted_amount`, `currency`, `fx_rate_id` on `billing_usage_dedupe` for audit.

---

## Top-up flow

```
User submits billing_topup_request (currency, amount, proof)
  → status: pending
Admin / provider approves
  → credit billing_wallet(owner, currency) + status: approved
```

Single `amount` + `currency` — no dual USD/IDR columns.

Providers: `manual` (Phase 1), later `midtrans`, `stripe`, etc.

---

## Direct purchase flow

```
User selects plan_slug + currency
  → billing_purchase created (pending)
  → Payment provider (Midtrans / Stripe / manual)
  → On success: activate billing_subscription, purchase status = settled
  → Optional: skip wallet credit entirely
```

`billing_purchase` records amount, currency, plan_slug, provider refs for reconciliation.

---

## Reservation + deduct (LLM turn)

```
1. Prompt starts → billing_reservation(req_id, wallet_id, held_native)  status=held
2. Turn completes → log row with cost_usd
3. billing_usage_dedupe insert (owner_iid, req_id) — idempotent
4. Personal scope: deduct billing_profile Alien/Frontier pools (IDR) when limits set
5. Pool overflow or no profile pools → legacy allowance on billing_account, then wallet (native currency via billing_fx_rate)
6. reservation status=settled | refunded on abort
```

Never double-charge: dedupe PK on `(owner_iid, req_id)`.

**Wallet selection:** default wallet currency unless turn context specifies another funded wallet.

---

## Included quota pools (Alien + Frontier)

On **`billing_profile`** (user) or **`billing_subscription`** (bot / device) — separate from wallet balance.

Users see **two monthly pools in IDR**:

| Pool | Models | Deduct rate |
|------|--------|-------------|
| **Alien AI** | `alienai` slug | **$1.50 / $7 per 1M** tokens (pool accounting) |
| **Frontier** | Pinned Gemini, GPT, Claude, … | Catalog wholesale × **1.50** |

See [billing-pricing.md](billing-pricing.md) for rates, margin, and debit order.  
See [billing-plans.md](billing-plans.md) for per-tier pool amounts and caps (**included total ≈ 2× monthly subscription**, 83/17 Alien/Frontier split).

**Server (shipped):** `billing_profile` pool columns are written on subscribe and signup-trial claim; `billing_usage_report` deducts pools first for personal turns. Legacy `billing_account` `alien_allow_*` columns still exist as fallback when profile pools are zero.

**Wallet deduct** uses native currency via `billing_fx_rate` when pools are exhausted (overflow) and `overage_enabled` on the plan.

---

## Commission (referral)

Phase 1: keep on `billing_profile` (legacy dual columns) or `commission_ledger`.

Target: commission credit per `(owner_iid, currency)` wallet or ledger entry — same multi-wallet rules.

---

## Context compaction billing (LOCKED)

Context compaction and memory-extraction LLM calls are **metered** like any other LLM usage. Token packing and screenshot prune are **free** (no LLM).

See [context-compaction.md](context-compaction.md) for full behavior.

### Deduct rules

| Event | `req_id` | Hold gate | Deduct path |
|-------|----------|-----------|-------------|
| User prompt turn | turn `req_id` | `billing_gate_with_hold` | `billing_usage_report` |
| Compact on threshold (same turn) | **parent** turn `req_id` | Already held | `extra_cost_usd` on parent `billing_usage_report` |
| Per-turn memory extract | **parent** turn `req_id` | Already held | `extra_cost_usd` on parent report |
| Idle compact / extract | `compact-{chat_id}-{snowflake}` | **None** | `billing_usage_report` if affordable; **skip** job if not |
| Memory retrieve (embed) | — | — | **Not billed** (platform COGS) |

### Allowance → on-demand

Same order as a normal turn: **quota pools / allowance first**, then wallet at `billing_fx_rate` deduct time.

Compaction must **never block** a reply the user already passed the gate for. If compact LLM fails or wallet is empty on idle job, **fail open** (truncation only; no user-visible error).

### Audit (`ai.log.meta`)

Parent turn log row may include:

```json
{
  "compaction_cost_usd": 0.002,
  "compaction_tokens_in": 1200,
  "compaction_tokens_out": 400,
  "memory_extract_writes": 1,
  "llm_cost_usd": 0.045
}
```

`ai.chat_compact_log` stores per-compaction detail for support and margin analysis.

### Model

Compaction and extraction use **`gemini-2.0-flash`** (or current `CONTEXT_COMPACT_MODEL` in [context-compaction.md](context-compaction.md)) — cheap housekeeping, not the user's selected chat model.

---

## Message renderer billing trace

Assistant `chat_msg` rows carry `tokens_in`, `tokens_out`, `duration_ms` for UI.

User-facing cost label: format `cost_usd` in **default wallet currency** using latest `billing_fx_rate` (display only; canonical `cost_usd` on `ai.log`).

Compaction cost is included in the turn total when rolled into `extra_cost_usd`; optional UI line "includes ~X compaction" for tester/root usage stats.

---

## NATS subjects

```
c35.user.{iid}.balance      -- payload includes wallet_id, currency, balance
c35.user.{iid}.quota        -- billing_profile allowance
c35.user.{iid}.commission
```

Push after any `billing_wallet` or `billing_profile` mutation.

---

## Rules

1. Client-origin `log` rows: **`cost_usd = 0`** always.
2. Server rejects client attempts to set balance or cost.
3. Parallel fetch billing + profile in **`ReqSessionInit`** — no separate balance HTTP on app open.
4. Index sync: `(owner_iid, updated_ts)` on `billing_wallet` and `billing_profile`.
5. UI displays **one currency** per context (default wallet); never dual-currency balance strings.
6. Catalog checkout uses **`billing_plan_price`** — never live FX conversion.

---

## Locale → default currency (signup)

| Locale prefix | Default wallet |
|---------------|----------------|
| `id` | `IDR` |
| `en_US`, default | `USD` |

Override in settings; creating a wallet in a new currency does not change default unless user selects it.
