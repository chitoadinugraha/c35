# Billing pools + promotions implementation plan

Status: **executing** 2026-09-22

Specs: `_/docs/billing-plans.md`, `_/docs/billing-pricing.md`, `_/docs/billing-implementation.md` Phase 4b.

---

## Wave 1 (parallel)

### Track A — Schema + seed + proto

- Create `_/schemas/migrations/billing_pools_v3.sql`
- Update `_/schemas/billing.sql` (idempotent CREATE/ALTER + reseed plans/prices)
- Extend `_/schemas/proto/c35/billing.proto` (IDR pools, BillingPromotion, claim RPCs)
- Run protoc if script exists; note if manual regen needed

**Exit:** migration applies; seeds match billing-plans.md Lite–Ultra.

### Track B — Server: pools + promotions

- `billing_pool.rs` — pure IDR pool deduct (Alien $1.50/$7, Frontier ×1.50), unit tests
- `billing_promotion.rs` — create (with `created_by_iid`), claim, limits (`max_claims_per_email`, `max_claims_total`, dates), all in **transactions** with `FOR UPDATE`
- Wire `lib.rs` + `wire_http/invoke.rs` handlers
- Fix `billing_package_redeem`: held totals inside tx, `FOR UPDATE` on `referral_code`

**Exit:** `cargo build -p server_ai`; `cargo test -p c35_mod_billing`

### Track C — Integration tests

- `servers/crates/mod_billing/tests/promotion_test.rs` — custom_package create/claim/limit/email
- `servers/crates/mod_billing/tests/package_redeem_test.rs` — max_uses, balance, concurrent (if DB available `#[ignore]`)

**Exit:** unit tests pass always; integration `#[ignore]` unless `C35_TEST_DB=1`

---

## Wave 2 (after Wave 1)

- `billing_plan_subscribe` applies IDR pools from plan template
- Signup trial auto-claim on account ensure
- `billing_turn` deduct IDR pools (dual-read legacy + profile)
- Client quota UI (separate PR)

---

## Acceptance

- [ ] Plans seeded: lite, plus, pro, ultra, bot.lite, bot.small, device.light, device.medium
- [ ] `billing_promotion.created_by_iid` set on create
- [ ] Custom package: single + multi audience limits enforced in tx
- [ ] Demo/signup trial types in schema + claim path
- [ ] Tests cover limit exhaustion and email 1× rule
- [ ] All redeem/claim paths use `pool.begin()` + row locks
