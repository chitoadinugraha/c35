# Billing - drop monthly-pool legacy, ship 5h/7d + bar meters

> **For agentic workers:** Use subagent-driven-development or executing-plans task-by-task. Steps use `- [ ]` checkboxes.

**Goal:** One quota model: caps **derived from the plan SKU**, **enforced** on **5h** and **7d** rolling windows, **shown** as **linear bars**. Remove monthly IDR pool deduct, dual-path fallbacks, and ring UI.

**Architecture:** `billing_plan` catalog drives computed limits on `billing_profile` (four meters: Alien 5h/7d, Frontier 5h/7d). Deduct, gate, and reservations use rings then wallet. `billing_account` keeps balance and commission until wallet v2.

**Decisions (2026-10-06, Alien AI UI modes):** 5h + 7d enforcement; bar meters; monthly fee sets cap sizes only; signup trial 7 **days** is separate from 7d rolling quota.

**Specs to update:** `billing-plans.md`, `billing-pricing.md`, `billing.md`, `billing-implementation.md`, `ui.md`, `live-call.md`.

## Global constraints

- `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_billing`.
- `.\_\scripts\dev\verify_flutter_app.ps1` after Flutter edits.
- `check_utf8_sources.ps1 -Changed -Fix` on touched sources.
- User quota UI: IDR only.

---

## Multitask map

| Wave | Track | Name | Depends | Delivers |
|------|-------|------|---------|----------|
| 0 | S | Spec lock | - | `billing-plans.md` quota section |
| 1 | A | Schema | S | `billing_rings_v4.sql`, proto |
| 1 | B | Plan apply | S | subscribe sets four limits |
| 2 | C | Deduct + gate | A,B | rings-only server path |
| 2 | D | Push + summary | A | NATS + RPC fields |
| 3 | E | Live + voice | C | frontier rings only |
| 3 | F | Bot/device | A,B,C | subscription rings |
| 4 | G | Flutter bars | D | drop `UiQuotaDualRing` |
| 4 | H | Settings + plans copy | G | copy + i18n |
| 5 | I | Dev SQL | A | 99000/33000 cleanup |
| 5 | J | Tests | C-H | green mod_billing |
| 6 | M | Docs | all | invert implementation notes |

Parallel: S alone first. Then A+B, C+D, E+F, G+H, I+J, M.

---

## Track S - Spec lock (before Rust)

- [ ] S.1 Rewrite included usage in `billing-plans.md`: template on `billing_plan` derives **5h and 7d caps** (Alien + Frontier), not monthly `*_pool_used_idr`.
- [ ] S.2 Lock derive formula (confirm with Chito): e.g. 7d from `alien_allow_weekly_usd` / frontier template; 5h from `alien_allow_5h_usd`; add `frontier_allow_*` on plan if needed. Yearly +20% on **Alien 5h and Alien 7d** only.
- [ ] S.3 `ui.md`: avatar menu **bars** (four meters).
- [ ] S.4 `live-call.md`: Frontier **rings**, not monthly pool used.

---

## Track A - Schema

- [ ] A.1 `billing_profile`: alien + frontier, 5h + 7d used/limit; window anchors.
- [ ] A.2 One-time backfill from old monthly limits to ring limits; stop writing monthly used.
- [ ] A.3 Extend `BillingPushQuota` in `billing.proto`; regen Dart pb.

---

## Track B - Plan apply

**Files:** `billing_plan_change.rs`, `billing_profile.rs`, `billing_promotion.rs`, `billing_package.rs`.

- [ ] B.1 Subscribe/upgrade: set four ring limits; reset used/windows.
- [ ] B.2 Zero or stop writing `alien_pool_limit_idr` / `frontier_pool_limit_idr`.
- [ ] B.3 Trial/promo: ring caps, not monthly pools.
- [ ] B.4 Test: Lite limits match S.2 table.

---

## Track C - Deduct + gate

**Files:** `billing_turn.rs`, `billing_profile.rs`, `billing_resolve.rs`, `billing_reservation.rs`.

- [ ] C.1 Replace `billing_profile_deduct_turn` with ring deduct by model (alien vs frontier).
- [ ] C.2 `billing_gate`: rings or wallet; remove `profile_has_pools`.
- [ ] C.3 Window roll on profile.
- [ ] C.4 Remove personal `billing_deduct_allowance` on account (profile only).

---

## Track D - Wire

- [ ] D.1 `billing_push.rs`: four ring pairs from profile.
- [ ] D.2 `billing_summary` / account get aligned.
- [ ] D.3 Dart: remove `billingApiAllow5hDefault` / weekly defaults.

---

## Track E - Live call + voice

- [ ] E.1 Settle on frontier rings only (`mod_live`, `mod_voice`).
- [ ] E.2 `page_live_call.dart` uses frontier remainders from store.

---

## Track F - Bot / device

- [ ] F.1 Ring columns on `billing_subscription` if missing.
- [ ] F.2 Remove subscription USD ring fallback in `billing_deduct_scoped`.
- [ ] F.3 Owner borrow rules per `billing-plans.md`.

---

## Track G - Flutter bars

**Files:** `ui_quota_ring.dart`, `ui_account_menu.dart`.

- [ ] G.1 `UiQuotaMeterBars`: Alien 5h, Alien 7d, API 5h, API 7d.
- [ ] G.2 Remove `_hasIdrPools` branch and `UiQuotaDualRing` from menu.
- [ ] G.3 Delete unused ring painters.

---

## Track H - Settings + plans sheet

- [ ] H.1 Settings billing: package, balance, no monthly pool / orphan 5h-only row.
- [ ] H.2 Plans sheet: show 5h/7d caps in IDR per tier.
- [ ] H.3 i18n for 5h / 7d labels.

---

## Track I - Dev data

- [ ] I.1 Fix `billing_operator_plans_99000_33000.sql` (profile templates, not inflated account rings).
- [ ] I.2 Backfill 99000/33000: zero monthly pool cols; re-derive rings.

---

## Track J - Tests

- [ ] J.1 `profile_ring_deduct_test` replaces monthly pool deduct tests.
- [ ] J.2 `plan_subscribe_test`, `promotion_test` assert rings.
- [ ] J.3 `cargo test -p c35_mod_billing` green.

---

## Track M - Docs

- [ ] M.1 `billing-implementation.md`: deprecate **monthly pools**, not 5h/7d.
- [ ] M.2 `sync.md` quota = four bars.

---

## Drop vs keep

**Drop:** monthly `*_pool_used_idr` meter; pools-then-rings dual path; `UiQuotaDualRing`; client API quota defaults; operator account ring inflation; monthly pool UI copy.

**Keep:** Lite-Ultra SKUs; wallet; freemium; 7-day trial **duration**; promotions; reservations; dedupe; FX; $1.50/$7 Alien **rates**; Frontier wholesale rule; `billing_account` balance.

---

## Acceptance

- [ ] Personal turns update profile rings (non-freemium).
- [ ] Client bars only; server drives all four meters.
- [ ] Live call never debits alien rings.
- [ ] Docs match 5h + 7d + bars.

---

## Subagent dispatch

| Agent | Tracks |
|-------|--------|
| 1 | S (user OK first) |
| 2 | A + B |
| 3 | C |
| 4 | D + E |
| 5 | F |
| 6 | G + H |
| 7 | I + J + M |

After wave 2 server: `.\_\scripts\deploy\publish_server.ps1` before app test on cluster.
