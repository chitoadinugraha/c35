# Google Play store listing (canonical copy)

Text files under each locale folder are the **source of truth** for Play Console listing fields.

| File | Play field | Limit |
|------|------------|-------|
| `title.txt` | App name (listing) | 30 characters |
| `short_description.txt` | Short description | 80 characters |
| `full_description.txt` | Full description | 4000 characters |

## Locales

| Folder | Language |
|--------|----------|
| `en-US/` | English (United States) — default |

Add `id-ID/` (or others) with the same three files when you want localized listings.

## Sync to Play Console

From `_/scripts/deploy` (service account JSON same as AAB upload):

```powershell
dart run deploy_app/play_store_listing_sync.dart
dart run deploy_app/play_store_listing_sync.dart id-ID
```

Uses `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` / `_/certs/google-play-upload-service-account.json` and `PLAY_STORE_PACKAGE_NAME` (default `id.alienai`).

Edits commit immediately (Google sends listing changes for review when required).

## Sync billing SKUs (subscriptions + credit packs)

From `_/scripts/deploy` (same service account as AAB upload; needs `YB_PASSWORD` for catalog prices):

```powershell
dart run deploy_app/play_store_billing_sync.dart
dart run deploy_app/play_store_billing_sync.dart --apply
dart run deploy_app/play_store_billing_sync.dart --apply --create-missing
```

Prices follow server rules: `ai.billing_plan_price` x **1.15** (`PLAY_MARKUP`), product IDs `id.alienai.plan.*` and `id.alienai.credit.*`. Optional: `PLAY_REGIONS_VERSION`, `--currency=USD|all`.

## Manual paste

If you prefer Console: Play Console → Grow → Store presence → Main store listing → paste from the locale folder.
