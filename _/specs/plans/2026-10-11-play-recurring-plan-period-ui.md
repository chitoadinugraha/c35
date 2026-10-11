# Play recurring sync + plan period UI

> **For agentic workers:** Use subagent-driven-development or execute tasks in order. Checkboxes track progress.

**Goal:** Google Play plan purchases use subscription expiry and sync renewals; account menu shows **Renew at** (auto-renew / Play) vs **Expired at** (prepaid wallet/voucher) under Alien AI / Frontier meters.

**Architecture:** `billing_profile.plan_auto_renew` flags recurring Play billing. `billing_play_sync_owner` re-queries Google subscriptions API on account load and extends linked `billing_entitlement` expiry from Google. Wallet `billing_plan_change` clears auto-renew. Wire `plan_auto_renew` on `BillingAccount`, `BillingPushQuota`, `ResBillingSummary`.

**Tech Stack:** Rust `mod_billing`, protobuf, Flutter `ui_quota_ring.dart`, `in_app_purchase` (unchanged client purchase path).

## Global Constraints

- UTF-8 sources; run `check_utf8_sources.ps1 -Changed -Fix` after edits.
- Regenerate Dart pb: `_/scripts/protoc.ps1`; Rust via `cargo build -p c35_mod_billing`.
- Verify: `cargo build -p server_ai` from `servers/`, `verify_flutter_app.ps1`.

---

## Track A — Schema & proto

- [ ] A1 `billing_profile.plan_auto_renew BOOLEAN NOT NULL DEFAULT FALSE` in `_/schemas/billing.sql` + `_/schemas/migrations/billing_plan_auto_renew_v1.sql`
- [ ] A2 `plan_auto_renew` on `BillingAccount` (34), `BillingPushQuota` (23), `ResBillingSummary` (37) in `billing.proto`
- [ ] A3 Run `_/scripts/protoc.ps1`

## Track B — Play API (server)

- [ ] B1 Parse `expiryTimeMillis` / subscriptions v2 `lineItems[].expiryTime` from Google verify JSON
- [ ] B2 Use parsed expiry for new plan grants (fallback: `plan_expires_from_months`)
- [ ] B3 `billing_play_sync_owner` — latest plan `billing_play_purchase`, refresh Google state, update entitlement + profile `plan_auto_renew = true`
- [ ] B4 Call sync from `billing_account_get` and on idempotent `billing_play_verify`
- [ ] B5 Unit test `play_expiry_from_google_json`

## Track C — Wallet / push

- [ ] C1 `billing_plan_change` immediate apply: `plan_auto_renew = FALSE`
- [ ] C2 `billing_account_get`, `billing_push`, `billing_summary`: read and emit `plan_auto_renew`

## Track D — Flutter UI

- [ ] D1 Merge `plan_auto_renew` in `billingAccountMerge` / panel builders
- [ ] D2 Under quota rows: localized **Renew at** / **Expired at** + date (`plan_expires_ts_ms`)
- [ ] D3 `en.json` / `id.json` strings

## Track E — Verify

- [ ] E1 `cargo build -p server_ai`
- [ ] E2 `cargo test -p c35_mod_billing play_expiry`
- [ ] E3 `verify_flutter_app.ps1`
