# App Release Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align c35 client release/versioning with the proven `csa_site_published` workflow while keeping c35's CAS + Yugabyte stack, ZIP Windows sideload, and separate Play package (`id.alienai.agent`).

**Architecture:** One build number `N` per release wave. Deploy scripts align `N` to Play Store latest + 1, build all requested artifacts at `N`, upload to CAS, publish `ai.config` keys `app.release.c35.{platform}`, then bump pubspec **once**. Tester track uploads AAB only (no APK, no `/version`). MSIX + Microsoft Store and Flutter web are separate later tracks — do not block ZIP sideload.

**Tech Stack:** Dart deploy scripts (`_/scripts/deploy/deploy_app/`), Flutter, Rust `wire_http` version routes, Yugabyte `ai.config`, CAS `/v1/file/upload`.

## Global Constraints

- Version compare uses **build number** (`234`), not `20.234.0` — per `_/docs/auto-update.md`.
- Config keys: `app.release.c35.{platform}` in `ai.config`.
- Play package: `id.alienai.agent` (not csa's `id.alienai`).
- Play credentials default path: `_/certs/google-play-upload-service-account.json`.
- Android signing: `clients/app/android/key.properties` + `upload_keystore.jks`, alias `alien`.
- Windows sideload artifact: `alienai-windows-{N}.zip` (not MSIX for auto-update).
- Upload auth: `DEPLOY_AUTH_TOKEN`; version publish: `YB_PASSWORD`.
- Do not migrate to csa OCI/Postgres — stay on CAS + Yugabyte.
- Verify after edit: `dart analyze` (deploy scripts), `cargo build -p server_ai` (server), `flutter analyze` (client).

---

## File map (target state)

| File | Responsibility |
|------|----------------|
| `_/scripts/deploy/deploy_app/update_version.dart` | `versionStampSync`, `versionSetPubspecBuild`, `versionStampBump`, `versionMsixManifest` |
| `_/scripts/deploy/deploy_app/deploy_app_lib.dart` | `deployAppBumpVersion`, `deployAppBumpVersionUnlessSkipped` |
| `_/scripts/deploy/deploy_app/deploy_app_release.dart` | **Orchestrator** — align N, build, upload, publish, single bump |
| `_/scripts/deploy/deploy_app/play_store_upload_tester.dart` | Internal track only; AAB only; no APK; no `/version` |
| `_/scripts/deploy/deploy_app/play_store_upload_promote_prod.dart` | Internal → production promote + APK + `/version` |
| `_/scripts/deploy/deploy_app/play_store_upload_prod.dart` | Android-only prod (thin wrapper; documents double-bump risk) |
| `_/scripts/deploy/deploy_app/windows_upload_prod.dart` | Windows-only prod (thin wrapper) |
| `_/scripts/deploy/deploy_app/publish_app_version.dart` | Batch publish helper for orchestrator |
| `servers/crates/wire_http/src/web.rs` | `/download/{app,agent}.{apk,exe,msi}` redirects to latest CAS |
| `_/deployments/c35-server/ingress.yaml` | Route `/version` on `api.alienai.id` |
| `_/docs/auto-update.md` | Release workflow + script matrix |

---

## Release policy (locked)

| Script | Builds | Uploads | Publishes `/version` | Bumps pubspec |
|--------|--------|---------|----------------------|---------------|
| `deploy_app_release.dart` (default prod) | AAB + APK + Windows ZIP | Play prod + CAS | `android` + `windows` | **Once** at end |
| `deploy_app_release.dart --tester` | AAB only | Play internal | **No** | Once at end |
| `play_store_upload_tester.dart` | AAB only | Play internal | **No** | Once |
| `play_store_upload_prod.dart` | AAB + APK | Play prod + CAS | `android` | Once |
| `play_store_upload_promote_prod.dart` | AAB (+ APK on full run) | internal → prod | `android` | Once |
| `windows_upload_prod.dart` | Windows ZIP | CAS | `windows` | Once |
| `push_windows_msix.dart` *(later)* | MSIX | CAS or Store API | optional `windows` store URL | **No** (orchestrator already bumped) |

**Rule:** Never publish `/version/android` for internal/tester builds — prod clients would sideload-update to an unreleased build.

**Rule:** Running `play_store_upload_prod.dart` then `windows_upload_prod.dart` double-bumps. Prefer `deploy_app_release.dart` for coordinated releases.

---

### Task 1: Fix version helpers (blocking)

**Files:**
- Modify: `_/scripts/deploy/deploy_app/update_version.dart`
- Test: `cd _/scripts/deploy && dart analyze deploy_app/`

**Interfaces:**
- Produces: `String versionSetPubspecBuild(String repoRoot, int build)`
- Produces: `String versionMsixManifest(String repoRoot)` → `"MAJOR.MINOR.PATCH.0"`

- [ ] **Step 1: Add `versionSetPubspecBuild`**

Port from `csa_site_published/_/scripts/deploy/deploy_app/update_version.dart`:

```dart
String versionSetPubspecBuild(String repoRoot, int build) {
  if (build <= 0) throw StateError('Invalid build number: $build');
  final (major, _) = versionReadPubspec(repoRoot);
  versionWritePubspec(repoRoot, major, build);
  final version = '$build';
  versionStampWrite(repoRoot, version);
  return version;
}
```

- [ ] **Step 2: Add `versionMsixManifest` (for later MSIX task)**

```dart
String versionMsixManifest(String repoRoot) {
  final match = _pubspecMatch(repoRoot);
  return '${match.group(1)}.${match.group(2)}.${match.group(3)}.0';
}
```

- [ ] **Step 3: Verify**

```powershell
cd D:\c35\_\scripts\deploy
dart analyze deploy_app/play_store.dart deploy_app/update_version.dart
```

Expected: no errors.

---

### Task 2: Skip-bump helper for orchestrator

**Files:**
- Modify: `_/scripts/deploy/deploy_app/deploy_app_lib.dart`

**Interfaces:**
- Produces: `void deployAppBumpVersionUnlessSkipped()`
- Reads env: `DEPLOY_SKIP_VERSION_BUMP=1`

- [ ] **Step 1: Add helper**

```dart
bool deployAppShouldBumpVersion() => deployEnv('DEPLOY_SKIP_VERSION_BUMP', '0') != '1';

void deployAppBumpVersionUnlessSkipped() {
  if (!deployAppShouldBumpVersion()) {
    stdout.writeln('[skip] DEPLOY_SKIP_VERSION_BUMP=1 — version not bumped');
    return;
  }
  deployAppBumpVersion();
}
```

- [ ] **Step 2: Update standalone scripts to use `deployAppBumpVersionUnlessSkipped`**

Modify: `play_store_upload_prod.dart`, `windows_upload_prod.dart` (replace `deployAppBumpVersion()` calls).

---

### Task 3: Android tester script

**Files:**
- Create: `_/scripts/deploy/deploy_app/play_store_upload_tester.dart`

**Interfaces:**
- Consumes: `playStoreBuildAndUpload(uploadAabToPlayStoreInternal)`
- Does **not** call: `buildAndroidApk`, `uploadAndroidApkRelease`, `publishAndroidAppVersion`

- [ ] **Step 1: Create script**

```dart
import 'dart:io';

import '../deploy_lib.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    await runStep('Load Play Store credentials', playStoreCredentialsJson);
    final versionCode = await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
    // Internal only — no APK, no GET /version/android (prod clients must not sideload-update).
    deployAppBumpVersionUnlessSkipped();
    stdout.writeln('Tester upload complete (internal track, versionCode $versionCode)');
    final version = await playStoreShowDeployedStatus();
    deployDone(version: version ?? 'v$versionCode', detail: 'AAB ${aabBundleSizeLabel()}');
  } catch (e) {
    phaseFail('Play Store tester upload failed', e.toString());
  }
}
```

- [ ] **Step 2: Verify**

```powershell
cd D:\c35\_\scripts\deploy
dart analyze deploy_app/play_store_upload_tester.dart
```

---

### Task 4: Android promote script

**Files:**
- Create: `_/scripts/deploy/deploy_app/play_store_upload_promote_prod.dart`
- Port logic from: `csa_site_published/_/scripts/deploy/deploy_app/play_store_upload_promote_prod.dart`

**Interfaces:**
- `--promote-only <versionCode>` → `promotePlayStoreReleaseToProduction` + `publishAndroidAppVersion` (no rebuild)
- Default → internal upload → promote → `buildAndroidApk` → CAS → publish android version with apkHash

- [ ] **Step 1: Port promote script** (adapt imports to c35 `deploy_lib.dart`, keep APK upload + `publishAndroidAppVersion` with hash)

- [ ] **Step 2: Verify**

```powershell
dart analyze deploy_app/play_store_upload_promote_prod.dart
```

---

### Task 5: Batch version publish helper

**Files:**
- Modify: `_/scripts/deploy/deploy_app/publish_app_version.dart`

**Interfaces:**
- Produces: `Future<void> publishAppReleaseAll({required int version, String? apkHash, int apkSize, String? windowsHash, int windowsSize})`

- [ ] **Step 1: Add orchestrator helper**

```dart
Future<void> publishAppReleaseProd({
  required int version,
  String apkHash = '',
  int apkSize = 0,
  String windowsHash = '',
  int windowsSize = 0,
}) async {
  await publishAndroidAppVersion(version, apkHash: apkHash, apkSize: apkSize);
  if (windowsHash.isNotEmpty && windowsSize > 0) {
    await publishWindowsAppVersion(version: version, hash: windowsHash, size: windowsSize);
  }
}
```

Orchestrator calls this once after all uploads succeed.

---

### Task 6: Coordinated release orchestrator

**Files:**
- Create: `_/scripts/deploy/deploy_app/deploy_app_release.dart`

**Interfaces:**
- Args: `--tester` (internal only, AAB, no APK, no version publish)
- Args: `--android-only`, `--windows-only` (skip other platform builds)
- Sets `DEPLOY_SKIP_VERSION_BUMP=1` on child steps; bumps once at end

- [ ] **Step 1: Implement prod flow**

```dart
// Pseudocode — implement fully in Dart
deployStart();
deployLoadEnvLocal();
await playStoreCredentialsJson(); // fail fast

final versionCode = await playStoreAlignVersionToNext();
stdout.writeln('Release build number: $versionCode');

if (tester) {
  await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
  deployAppBumpVersion();
  deployDone(version: 'v$versionCode', detail: 'internal AAB only');
  return;
}

// Prod coordinated
final aabDir = await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
await promotePlayStoreReleaseToProduction(versionCode);

Platform.environment['DEPLOY_SKIP_VERSION_BUMP'] = '1';
final apk = buildAndroidApk();
await uploadAndroidApkRelease(apk);

WindowsBuildResult? win;
if (!androidOnly) {
  win = buildWindowsRelease();
  await uploadWindowsZipToCas(zipPath: win.zipPath, version: win.version, localHash: win.hash);
}

await publishAppReleaseProd(
  version: versionCode,
  apkHash: apk.hash,
  apkSize: apk.size,
  windowsHash: win?.hash ?? '',
  windowsSize: win?.size ?? 0,
);

await maybePruneAppArtifactsAfterPublish();
deployAppBumpVersion();
deployDone(version: 'v$versionCode', detail: 'AAB+APK+ZIP');
```

- [ ] **Step 2: Extract shared upload without bump**

Ensure `windows_upload_prod.dart` calls `uploadAndPublishWindowsRelease` which already publishes version — orchestrator should call `uploadWindowsZipToCas` only (not `uploadAndPublishWindowsRelease`) then batch-publish.

Refactor `upload_windows_release.dart`:

```dart
Future<void> uploadWindowsReleaseOnly(WindowsBuildResult build) async {
  await uploadWindowsZipToCas(zipPath: build.zipPath, version: build.version, localHash: build.hash);
}
```

Keep `uploadAndPublishWindowsRelease` for standalone `windows_upload_prod.dart`.

- [ ] **Step 3: Verify**

```powershell
dart analyze deploy_app/deploy_app_release.dart
```

---

### Task 7: Fix `/version` on `api.alienai.id`

**Problem:** Flutter client calls `serverHostActiveBase()` → `https://api.alienai.id/version/windows`, but ingress only routes `/a`, `/v1`, `/ws`, `/fs` on that host.

**Files:**
- Modify: `_/deployments/c35-server/ingress.yaml`

- [ ] **Step 1: Add `/version` path on `api.alienai.id`**

```yaml
          - path: /version
            pathType: Prefix
            backend:
              service:
                name: c35-server
                port:
                  name: http
```

- [ ] **Step 2: Apply ingress** (manual cluster step — document in auto-update.md)

---

### Task 8: Landing-page download redirects

**Problem:** `clients/web/index.html` links `/download/app.apk`, `/download/app.exe`, `/download/app.msi` but server has no handlers.

**Files:**
- Modify: `servers/crates/wire_http/src/web.rs`
- Modify: `servers/crates/wire_http/src/version.rs` (optional helper to resolve latest platform URL)
- Test: `cargo test -p wire_http`

**Behavior:**
- `GET /download/app.apk` → 302 to latest `apkUrl` from `app.release.c35.android` (or 404)
- `GET /download/app.exe` → 302 to latest Windows CAS signed URL from hash
- `GET /download/app.msi` → 302 to MSIX URL when `storeUrl` contains `.msix`, else 404 with note "ZIP sideload via auto-update"
- `GET /download/web` → keep redirect; update target when web ships (Task 10)

- [ ] **Step 1: Add `download_redirect` handler** reading `ai.config` same as version endpoint

- [ ] **Step 2: Register routes in `web_router()`**

```rust
.route("/download/app.apk", get(|| download_latest("android", DownloadKind::Apk)))
.route("/download/app.exe", get(|| download_latest("windows", DownloadKind::Zip)))
```

- [ ] **Step 3: Test + build**

```powershell
cd D:\c35\servers
cargo test -p wire_http
cargo build -p server_ai
```

---

### Task 9: Credentials & signing checklist (docs only)

**Files:**
- Modify: `_/docs/auto-update.md`
- Create: `_/docs/app-release.md` (script matrix + env vars)
- Ensure: `clients/app/android/key.properties.example` documents c35 package `id.alienai.agent`

**Content to document:**

| Asset | Path / env |
|-------|------------|
| Play service account | `_/certs/google-play-upload-service-account.json` or `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |
| Android keystore | `clients/app/android/app/upload_keystore.jks` + `key.properties` |
| Deploy upload JWT | `DEPLOY_AUTH_TOKEN` |
| Yugabyte | `YB_PASSWORD`, `YB_HOST` (default cluster local) |
| Play package override | `PLAY_STORE_PACKAGE_NAME` (default `id.alienai.agent`) |
| Skip bump (orchestrator child) | `DEPLOY_SKIP_VERSION_BUMP=1` |

**Explicitly NOT shared with csa:**
- Play listing (`id.alienai` vs `id.alienai.agent`)
- Version DB (`platform_app_version` vs `ai.config`)
- Artifact storage (OCI vs CAS)

**Reused from csa when MSIX ships (Task 11):**
- Partner Center identity `AlienAI.AlienAI`
- Publisher `CN=1F67612E-4D56-4905-A4FC-204F5F20F6C2`
- Cert: copy `_/_certs/windows-msix-store.pfx` → `_/certs/windows-msix-store.pfx` (gitignored)

- [ ] **Step 1: Write `_/docs/app-release.md`**
- [ ] **Step 2: Update `_/docs/auto-update.md` deploy section to reference orchestrator**

---

### Task 10: Flutter web publish (deferred wave)

**Scope:** Only after Windows ZIP + Android prod pipeline is stable. Do not implement in wave 1.

**Target:**
- `flutter build web` → upload static tree to CAS or object prefix
- `ai.config` key `app.release.c35.web` with `url: https://app.alienai.id/`
- Ingress/DNS for `app.alienai.id` (separate from `alienai.id` marketing site)
- Update `/download/web` redirect in `web.rs`

**Reference:** `csa_site_published/_/scripts/deploy/deploy_app/build_clients.dart`, `push_web.dart`, `oci_upload.dart` — adapt to CAS upload pattern, not OCI copy-paste.

---

### Task 11: MSIX + Microsoft Store (deferred wave)

**Scope:** Store distribution only. ZIP sideload remains the Windows auto-update channel.

**Files to add later:**
- `clients/app/pubspec.yaml` — `msix` dev_dep + `msix_config` (identity from csa)
- `_/scripts/deploy/deploy_app/package_windows_msix.dart`
- `_/scripts/deploy/deploy_app/push_windows_msix.dart` — build MSIX, upload to Store or CAS, **does not replace** ZIP publish

**msix_config starter (from csa):**

```yaml
msix_config:
  display_name: AlienAI
  publisher_display_name: Alien AI
  identity_name: AlienAI.AlienAI
  publisher: CN=1F67612E-4D56-4905-A4FC-204F5F20F6C2
  store: true
  certificate_path: ../../_/certs/windows-msix-store.pfx
  certificate_password: alienai
```

**Do not change** `AppUpdateService` to MSIX until explicitly requested — Store users update via Store; ZIP users keep ZIP pipeline.

---

## Execution waves

| Wave | Tasks | Parallel? |
|------|-------|-----------|
| **1** | Task 1, Task 2 | Yes |
| **2** | Task 3, Task 4, Task 5 | Yes |
| **3** | Task 6 | After wave 2 |
| **4** | Task 7, Task 8 | Yes |
| **5** | Task 9 | After wave 3–4 |
| **6** | Task 10, Task 11 | Future — separate plans |

---

## Verification checklist (end of wave 5)

```powershell
# Deploy scripts
cd D:\c35\_\scripts\deploy
dart pub get
dart analyze deploy_app/

# Server
cd D:\c35\servers
cargo test -p wire_http
cargo build -p server_ai

# Client
cd D:\c35\clients\app
flutter analyze
```

**Manual smoke (staging credentials):**
1. `dart run deploy_app/play_store_upload_tester.dart` — internal AAB, no `/version` change
2. `dart run deploy_app/deploy_app_release.dart` — coordinated prod (or `--windows-only` / `--android-only` for partial)
3. `curl https://api.alienai.id/version/android` — returns new build + `apkUrl`
4. `curl -sI https://alienai.id/download/app.apk` — 302 to CAS

---

## Self-review (spec coverage)

| Requirement | Task |
|-------------|------|
| Build number versioning | 1, 6 |
| Tester: no APK, no `/version` | 3, 6 |
| Prod: AAB + APK + `/version` | 4, 6 |
| Windows ZIP sideload | 6 (unchanged build) |
| MSIX later only | 11 (deferred) |
| Single bump per coordinated release | 2, 6 |
| c35 credentials path `_/certs/` | 9 |
| Separate Play package `id.alienai.agent` | 9 (documented) |
| CAS + Yugabyte (not OCI) | 5, 6, 8 |
| `api.alienai.id` version endpoint | 7 |

No placeholders remain in task steps above.
