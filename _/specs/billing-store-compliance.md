# Billing — mobile store compliance (Play + App Store)

Status: **active** 2026-10-11  
Companion: [billing.md](billing.md), [billing-plans.md](billing-plans.md)

## Pre-submission checklist (Google Play)

| Check | Expected |
|-------|----------|
| Digital plans / wallet credit in release APK | **Google Play Billing** only (`billingUseNativeStoreCheckout`) |
| Midtrans / Stripe / manual top-up in release APK | **Hidden** (`billingShowInAppTopup` false on Android/iOS release) |
| In-app listed plan prices | Match **store SKU** prices (`store_price` from `billing_play_product_list`, or `ProductDetails.price` at checkout) |
| Subscriptions auto-renew | Disclosed; user can open **Play subscription center** from app when `plan_auto_renew` |
| Cancel at period end (wallet schedule) | Copy explains **also cancel recurring billing in Play** when subscription was bought via Play |
| Voucher / package redeem | Allowed for prepaid codes; **no** “buy cheaper on the website” or external checkout CTAs |
| Domain registration | Paid from **wallet** (real-world service); copy says credit comes from store top-up on mobile |
| Play AAB vs CAS APK | AAB: `C35_BILLING_DISTRIBUTION=play` — wallet top-up UI **not linked** (no Midtrans/transfer strings in binary). APK: `direct` — full wallet UI. Verify: `._/scripts/dev/verify_play_aab_wallet_strings.ps1` |
| Debug `flutter run` (no define) | Android debug → **direct** billing (Midtrans OK for local dev) |

## Pre-submission checklist (Apple App Store)

| Check | Expected |
|-------|----------|
| IAP for digital goods | Same client path as Android (`in_app_purchase` / StoreKit) |
| Server verify | `store_platform=ios` on `billing_play_verify` → `billing_apple` (configure `APPLE_IAP_SHARED_SECRET` or `C35_APPLE_IAP_STUB=1` for dev) |
| App Store Connect | Mirror product IDs (`id.alienai.plan.*`, `id.alienai.credit.*`) per currency |
| Manage subscriptions | Link to `https://apps.apple.com/account/subscriptions` when `plan_auto_renew` |

## Currency by region (UI + catalog)

| User context | Default checkout currency |
|--------------|---------------------------|
| Device locale Indonesia (`id` / `ID`) | **IDR** |
| Other locales | **USD** |

Account `billing_currency` from server still wins when set. Product list RPC passes `currency` so store SKUs match.

## Store price markup

Catalog web/native list price × **`PLAY_MARKUP` (1.15)** → in-app store price (covers store fees). UI must show **store** price on mobile, not raw web catalog.

## Flow trace — Lite monthly (Android, IDR)

1. User opens **Plans** → client loads `billing_play_product_list(currency=IDR)`.
2. Card shows `store_price` for Lite monthly.
3. Tap pay → Play purchase → `billing_play_verify(store_platform=android)`.
4. Server grants entitlement; `plan_auto_renew=true`; sync via `billing_play_sync_owner`.

## Flow trace — wallet top-up (iOS, USD)

1. **Top up** → `UiBillingPlayTopupPanel` (store credit SKUs in USD).
2. Consumable IAP → verify with `store_platform=ios`.

## Off-store steering

**Not present in app copy** (no “cheaper on website”, “pay on alienai.id to save”, etc.). Public voucher URLs are for **redeem only**, not checkout in the Play app.

## iOS preparation (server)

1. Set `APPLE_IAP_SHARED_SECRET` (App Store Connect → app-specific shared secret).
2. Optional dev: `C35_APPLE_IAP_STUB=1` (never production).
3. Implement full App Store Server API v2 when moving to production iOS billing.

## Related files

| Area | Path |
|------|------|
| Platform gates | `clients/app/lib/c/billing/billing_platform.dart` |
| Checkout | `clients/app/lib/c/billing/billing_store_checkout.dart` |
| Catalog helpers | `clients/app/lib/c/billing/billing_store_catalog.dart` |
| Manage subs | `clients/app/lib/c/billing/billing_store_manage.dart` |
| Play verify | `servers/crates/mod_billing/src/billing_play.rs` |
| Apple verify | `servers/crates/mod_billing/src/billing_apple.rs` |
