# Billing pools + promotions implementation plan

Status: **server shipped** 2026-09-22 — client quota UI pending

Specs: `_/docs/billing-plans.md`, `_/docs/billing-pricing.md`, `_/docs/billing-implementation.md` Phase 4b–4c.

---

## Wave 1 (parallel) — done

### Track A — Schema + seed + proto

- `_/schemas/migrations/billing_pools_v3.sql`
- `_/schemas/billing.sql` (idempotent CREATE/ALTER + reseed plans/prices)
- `_/schemas/proto/c35/billing.proto` (IDR pools, BillingPromotion, claim RPCs)

### Track B — Server: pools + promotions

- `billing_pool.rs`, `billing_promotion.rs` (`created_by_iid`, transactional limits)
- `wire_http/invoke.rs` handlers 18–20
- `billing_package_redeem` transactional fixes

### Track C — Integration tests

- `promotion_test.rs`, `package_redeem_test.rs`

---

## Wave 2 — server done

- [x] `billing_plan_subscribe` applies IDR pools from plan template + `billing_period` price row
- [x] Signup trial auto-claim on `billing_account_ensure`
- [x] `billing_turn` / `billing_usage_report` deduct IDR pools (personal; dual-read legacy)
- [ ] Client quota UI (separate PR)

See `_/docs/billing-implementation.md` § Phase 4c for module map and test commands.

---

## Acceptance

- [x] Plans seeded: lite, plus, pro, ultra, bot.lite, bot.small, device.light, device.medium
- [x] `billing_promotion.created_by_iid` set on create
- [x] Custom package: single + multi audience limits enforced in tx
- [x] Demo/signup trial types in schema + claim path
- [x] Tests cover limit exhaustion and email 1× rule
- [x] All redeem/claim paths use `pool.begin()` + row locks
