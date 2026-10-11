# Billing store compliance (Play + App Store) — multitask plan

> **For agentic workers:** Use subagent-driven-development or execute tracks in parallel. Checkboxes track progress.

**Goal:** Align in-app billing with Google Play and Apple App Store policies: native store checkout on mobile release builds, accurate store prices in UI, subscription management UX, IDR in Indonesia / USD elsewhere, iOS-ready IAP path, no off-store purchase steering.

**Architecture:** `billing_platform.dart` gates Midtrans/Stripe to non-mobile (and Android debug only). Mobile uses `in_app_purchase` + server verify (`billing_play_verify` for Android; `billing_apple` for iOS). Product catalog RPC returns per-currency store prices (web catalog × `PLAY_MARKUP`). Docs in `_/specs/billing-store-compliance.md`.

**Tech Stack:** Flutter `in_app_purchase`, Rust `mod_billing`, protobuf `billing.proto`.

## Global Constraints

- UTF-8 sources; `check_utf8_sources.ps1 -Changed -Fix` after edits.
- Regenerate Dart pb: `_/scripts/protoc.ps1`.
- Verify: `cargo build -p server_ai` from `servers/`, `verify_flutter_app.ps1`.
- No in-app copy steering users to cheaper web checkout.

---

## Track A — Documentation

- [x] A1 `_/specs/billing-store-compliance.md` — policy checklist, flows, iOS prep, domain wallet note
- [x] A2 This plan file

## Track B — Proto + server catalog

- [x] B1 `ReqBillingPlayProductList.currency`, `BillingPlayProductDoc.currency/web_price/store_price/credit_usd`
- [x] B2 `ReqBillingPlayVerify.store_platform` (`android` | `ios`)
- [x] B3 `billing_play_product_list` — IDR + USD plans and credit packs
- [x] B4 `billing_apple.rs` — verify stub + env gate; route from `billing_play_verify` when `ios`

## Track C — Flutter platform + checkout

- [x] C1 `billing_platform.dart` — native store = Android + iOS release
- [x] C2 `billingCurrencyForDeviceLocale()` — ID / `id` → IDR, else USD
- [x] C3 `billing_store_catalog.dart` — store price lookup for plan cards
- [x] C4 `billing_store_checkout.dart` — iOS messages, strict SKU match (no wrong-product fallback)
- [x] C5 Wire currency into product list + verify `store_platform`

## Track D — Billing UI

- [x] D1 Plan sheet — show `store_price`, native checkout for IDR and USD
- [x] D2 Cancel/downgrade + `plan_auto_renew` — banner + manage subscriptions link
- [x] D3 Top-up dialog titles for iOS
- [x] D4 Domain buy dialog — wallet + store credit note on mobile

## Track E — Tests + verify

- [x] E1 `billing_platform_test.dart`
- [ ] E2 `cargo test -p c35_mod_billing` (store price / apple gate)
- [ ] E3 `verify_flutter_app.ps1`
