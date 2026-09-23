# App Release Pipeline (c35)

Coordinated Flutter app releases for **Android (Play + sideload APK)**, **Windows (ZIP sideload)**, and **Flutter web** (`https://alienai.id/app/`). Stack: CAS upload + OCI S3 (web) + Yugabyte `ai.config` — not csa OCI/Postgres.

**Compare versions using the build number** (`234`), not `20.234.0`. Config keys: `app.release.c35.{platform}`.

---

## Script matrix

Run from `_/scripts/deploy` after `dart pub get`. Set env vars (see below) or use repo-root `.env.local`.

| Script | Builds | Uploads | Publishes `/version` | Bumps pubspec |
|--------|--------|---------|----------------------|---------------|
| **`deploy_app_release.dart`** *(default prod)* | AAB + APK + Windows ZIP + **web** | Play production + CAS + **S3** | `android` + `windows` + **`web`** | **Once** at end |
| `deploy_app_release.dart --tester` | AAB only | Play internal | **No** | Once at end |
| `deploy_app_release.dart --android-only` | AAB + APK | Play prod + CAS | `android` | Once at end |
| `deploy_app_release.dart --windows-only` | Windows ZIP | CAS | `windows` | Once at end |
| `deploy_app_release.dart --web-only` | Flutter web | S3 | **`web`** | Once at end |
| `push_web.dart` | Flutter web | S3 | **`web`** | **No** |
| `play_store_upload_tester.dart` | AAB only | Play internal | **No** | Once |
| `play_store_upload_prod.dart` | AAB + APK | Play prod + CAS | `android` | Once |
| `play_store_upload_promote_prod.dart` | AAB (+ APK on full run) | internal → prod | `android` | Once |
| `windows_upload_prod.dart` | Windows ZIP | CAS | `windows` | Once |

**Primary command:** `dart run deploy_app/play_store_upload_tester.dart` for internal QA; `dart run deploy_app/deploy_app_release.dart` for coordinated production.

**Rules**

- Never publish `/version/android` for internal/tester builds — prod clients would sideload-update to an unreleased build.
- Running `play_store_upload_prod.dart` then `windows_upload_prod.dart` **double-bumps** pubspec. Prefer `deploy_app_release.dart` for coordinated releases.
- Orchestrator sets `DEPLOY_SKIP_VERSION_BUMP=1` on child steps and bumps **once** at the end.

Windows artifact: `alienai-windows-{N}.zip` (Blake3 hash in `ai.config`).

---

## Version bump

One build number **N** per release wave:

1. Align **N** to Play Store latest + 1 (`playStoreAlignVersionToNext`).
2. Build and upload all platforms at **N**.
3. Publish `ai.config` keys.
4. Bump `clients/app/pubspec.yaml` **once** (`deployAppBumpVersion`).

Standalone scripts bump once each. Set `DEPLOY_SKIP_VERSION_BUMP=1` to skip (orchestrator child steps).

---

## Environment variables

| Variable | Required | Default / notes |
|----------|----------|-----------------|
| `DEPLOY_AUTH_TOKEN` | CAS upload | JWT for `POST /v1/file/upload` (APK, Windows ZIP) |
| `YB_PASSWORD` | Version publish | Yugabyte password for `ai.config` writes |
| `YB_HOST` | No | `yb-tservers.yugabyte.svc.cluster.local` |
| `YB_PORT` | No | `5433` |
| `YB_DATABASE` | No | `c35` |
| `YB_USER` | No | `csa` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play upload | Inline JSON (alternative to file) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH` | Play upload | Path to service account JSON |
| `PLAY_STORE_PACKAGE_NAME` | No | `id.alienai` |
| `DEPLOY_SKIP_VERSION_BUMP` | No | `1` skips pubspec bump |
| `PLATFORM_APP_VERSION_PUBLISH` | No | `0` skips `/version` publish (debug) |
| `S3_ENDPOINT` | Web upload + server read | OCI S3 endpoint (same bucket as CAS via `mod_file`) |
| `S3_BUCKET` | Web upload + server read | Bucket name |
| `S3_ACCESS_KEY` | Web upload + server read | Access key |
| `S3_SECRET_KEY` | Web upload + server read | Secret key |
| `S3_REGION` | Web upload + server read | Region (e.g. `ap-singapore-1`) |
| `S3_SECURE` | No | `1` (default) for HTTPS |
| `C35_SERVER` | No | `--dart-define` for web build; default `https://api.alienai.id` |

Scripts call `deployLoadEnvLocal()` — values in repo-root `.env.local` apply when not set in the shell.

Web upload does **not** require `DEPLOY_AUTH_TOKEN` (S3 only). Version publish still requires `YB_PASSWORD`.

---

## Credentials & signing (local paths)

| Asset | Path |
|-------|------|
| Play service account | `_/certs/google-play-upload-service-account.json` *(gitignored)* |
| Android `key.properties` | `clients/app/android/key.properties` *(gitignored; copy from `key.properties.example`)* |
| Android upload keystore | `clients/app/android/app/upload_keystore.jks` *(gitignored)* |
| Keystore alias | `alien` |

Play credentials resolution order: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` → `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH` → default file above.

---

## Not shared with `csa_site_published`

| Concern | csa | c35 |
|---------|-----|-----|
| Play package | `id.alienai` | **`id.alienai`** (same listing; c35 continues version) |
| Version store | Postgres `platform_app_version` | Yugabyte **`ai.config`** |
| Release blobs | OCI object storage | **CAS** `/v1/file/upload` → `https://alienai.id/fs/{hash}`; **web** → S3 `app/web/current/` |
| Config key prefix | csa-specific | **`app.release.c35.{platform}`** |

Do not copy csa deploy env or DB credentials into c35 release scripts.

---

## Flutter web publish

Public URL: **`https://alienai.id/app/`** (not `app.alienai.id`).

Static assets live in **OCI S3** — they are **not** baked into the `c35-server` Docker image. The server reads from S3 at runtime via `GET /app/*`.

### S3 layout

| Prefix | Purpose |
|--------|---------|
| `app/web/{N}/` | Immutable snapshot for build **N** (rollback / QA) |
| `app/web/current/` | Live tree served at `https://alienai.id/app/` |

Same bucket and `S3_*` credentials as CAS (`mod_file`). Deploy syncs `clients/app/build/web/` after `flutter build web --base-href /app/`.

### Cluster requirement

The `c35-server-env` secret must include `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION`, and `S3_SECURE` so the server can **read** web assets (may already be present for CAS writes).

### Commands

```powershell
cd _\scripts\deploy
dart pub get
$env:S3_ENDPOINT = '<endpoint>'
$env:S3_BUCKET = '<bucket>'
$env:S3_ACCESS_KEY = '<key>'
$env:S3_SECRET_KEY = '<secret>'
$env:YB_PASSWORD = '<password>'

# Web only (no Play / Windows)
dart run deploy_app/push_web.dart

# Or via orchestrator flag
dart run deploy_app/deploy_app_release.dart --web-only

# Default prod includes web after Windows upload
dart run deploy_app/deploy_app_release.dart
```

Config key: `app.release.c35.web` → `url: https://alienai.id/app/`. Compare versions using build number **N**, not semver.

Landing page `/download/web` redirects to `https://alienai.id/app/`.

---

## Deferred tracks (do not block ZIP sideload)

**MSIX + Microsoft Store** — Store distribution only; ZIP remains the Windows auto-update channel. Reuse from csa when implemented:

- Identity: `AlienAI.AlienAI`
- Publisher: `CN=1F67612E-4D56-4905-A4FC-204F5F20F6C2`
- Cert: `_/certs/windows-msix-store.pfx` *(gitignored; copy from csa `_/_certs/`)*

`AppUpdateService` stays on ZIP until MSIX is explicitly requested.

---

## Smoke checks

```powershell
curl https://api.alienai.id/version/android
curl https://api.alienai.id/version/windows
curl https://api.alienai.id/version/web
curl -sI https://alienai.id/download/app.apk
curl -sI https://alienai.id/app/
curl -sI https://alienai.id/download/web
```

Ensure `_/deployments/c35-server/ingress.yaml` routes `/version` on `api.alienai.id` before relying on client auto-update.
