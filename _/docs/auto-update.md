# App auto-update (c35)

## Overview

| Piece | Role |
|-------|------|
| `GET /version/{platform}` | Release source (`ai.config` → `app.release.c35.{platform}`) |
| CAS `/fs/{hash}` | Immutable release zip / APK (blake3) |
| Flutter `AppUpdateService` | Poll, download, verify, stage, apply on restart |

**Compare versions using the build number** (`234`), not `20.234.0`.

## Release JSON (`ai.config`)

```json
{
  "version": 235,
  "versionName": "20.235.0",
  "min": 200,
  "hash": "<blake3 hex of zip>",
  "size": 89123456
}
```

Android adds `url` (Play Store) and optional `apkHash` / `apkSize` for direct APK download.

## Deploy

```powershell
cd _\scripts\deploy
dart pub get
$env:DEPLOY_AUTH_TOKEN = '<jwt>'
$env:YB_PASSWORD = '<password>'
dart run deploy_app/windows_upload_prod.dart
dart run deploy_app/play_store_upload_prod.dart
```

## Verify

```powershell
curl https://alienai.id/version/windows
```
