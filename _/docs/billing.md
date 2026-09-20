# Billing (LOCKED)

Status: **locked** 2026-09-20

## Overview

Wallet + quota + commission for platform AI usage. Ported from `D:\cs_agent` billing model, adapted to c35 identity (`owner_iid`, `_ts` fields).

**Single meter:** `ai.billing_account` — balance, Alien allowance rings (5h / weekly), commission.

**Single audit ledger:** `ai.log` — see [log.md](log.md). Billable LLM rows set `cost_usd > 0`; client error rows stay `0`.

`ResSessionInit` returns billing snapshot in one round trip. Realtime pushes: `c35.user.{iid}.balance`, `.quota`, `.commission` over NATS.

---

## Tables

| Table | Purpose |
|-------|---------|
| `billing_account` | Wallet + quota windows + commission balances |
| `billing_topup_request` | Manual / provider top-up requests (admin approve) |
| `billing_reservation` | Escrow hold during in-flight LLM turn (`req_id`) |
| `billing_usage_dedupe` | Idempotent deduct per `(owner_iid, req_id)` |
| `log` | Audit + billing trace (cost on row) |

Canonical DDL: [`../schemas/billing.sql`](../schemas/billing.sql), [`../schemas/log.sql`](../schemas/log.sql)

---

## `billing_account`

One primary wallet per user (linked via `identity.billing_iid`).

| Field | Purpose |
|-------|---------|
| `balance_usd`, `balance_idr` | Spendable balance |
| `plan_tier` | `free` \| `plus` \| `pro` \| … |
| `alien_allow_5h_used/limit` | 5-hour ring (UI quota circle) |
| `alien_allow_weekly_used/limit` | Weekly ring |
| `window_5h_start`, `window_weekly_start` | Rolling window anchors |
| `billing_currency` | Display default `IDR` \| `USD` |
| `fx_micro_per_usd` | FX for IDR display |
| `commission_*` | Referral commission available / earned |

Server-only writes to balances. Client reads via sync + NATS.

---

## Top-up flow

```
User submits billing_topup_request (proof, amount)
  → status: pending
Admin approves
  → credit billing_account + status: approved
```

Providers: `manual` (Phase 1), later `midtrans`, `stripe`, etc.

---

## Reservation + deduct (LLM turn)

```
1. Prompt starts → billing_reservation(req_id, held_usd)  status=held
2. Turn completes → log row with cost_usd
3. billing_usage_dedupe insert (owner_iid, req_id) — idempotent
4. Deduct billing_account; reservation status=settled
5. On failure/abort → reservation status=refunded
```

Never double-charge: dedupe PK on `(owner_iid, req_id)`.

---

## Quota rings (Alien allowance)

Separate from paid balance — free-tier / plan allowance consumed before balance.

- **`alien_allow_5h_*`** — short window meter (avatar menu 5h circle)
- **`alien_allow_weekly_*`** — weekly cap (avatar menu weekly circle)

Reset windows via `window_*_start` + server-side roll logic (port from cs_agent).

---

## Commission (referral)

| Column | Meaning |
|--------|---------|
| `commission_available_*` | Withdrawable / usable |
| `commission_earned_*` | Lifetime earned |

Tied to referral forest (`referral_share`). Payout flow deferred.

---

## Message renderer billing trace

Assistant `chat_msg` rows carry `tokens_in`, `tokens_out`, `duration_ms` for UI (cs_agent `msg_trace_view`).

Canonical cost lives on **`ai.log`** linked by `req_id` — same turn, same id.

---

## NATS subjects

```
c35.user.{iid}.balance
c35.user.{iid}.quota
c35.user.{iid}.commission
```

Push after any `billing_account` mutation.

---

## Rules

1. Client-origin `log` rows: **`cost_usd = 0`** always.
2. Server rejects client attempts to set balance or cost.
3. Parallel fetch billing + profile in **`ReqSessionInit`** — no separate balance HTTP call on app open.
4. Index sync: `(owner_iid, updated_ts)` on `billing_account`.
