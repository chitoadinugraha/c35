# Publish server + APK + Windows + web (no Play promote)

Use when **Play production promote must be skipped** (e.g. internal review queue) but you still need cluster **server**, a **signed release APK** on `/version/android` (same upload keystore as Play), **Flutter Windows** zip on `/version/windows`, and **Flutter web**.

```powershell
.\_\scripts\deploy\publish_server_apk_web.ps1
```

If git should be left unchanged (already pushed):

```powershell
.\_\scripts\deploy\publish_server_apk_web.ps1 -SkipGit
```

Skip cluster server when only app artifacts changed:

```powershell
.\_\scripts\deploy\publish_server_apk_web.ps1 -SkipGit -SkipServer
```

Skip Windows zip when APK + web are enough:

```powershell
.\_\scripts\deploy\publish_server_apk_web.ps1 -SkipGit -SkipServer -SkipWindows
```

**Requirements**

- Uncommitted work is auto-committed (`git add -A`) unless `-SkipGit`.
- Repo-root `.env.local`: `YB_PASSWORD`, `S3_*`, `DEPLOY_AUTH_TOKEN` (or `-MintToken` on app script), cluster/OCIR for server.
- Android signing: `clients/app/android/key.properties` + `upload_keystore.jks` (same as Play uploads).
- Optional: Play service account JSON — used only to **read** latest production `versionCode` and align pubspec (no AAB upload).

**Does not** upload AAB or promote Play.

**Order:** server → **APK + Windows zip in parallel** (no pubspec bump) → web (single pubspec bump at end). Same pattern as `/publish-prod` without the Play steps (prod script still skips standalone Windows; this flow publishes Windows explicitly).

**Build speed (this PC):** deploy scripts default to **`auto` CPU parallelism** (see `DEPLOY_ANDROID_BUILD_CORES` in `_/specs/app-release.md`). Optional in `.env.local`: `DEPLOY_ANDROID_BUILD_CORES=12` to pin workers; `DEPLOY_ANDROID_GRADLE_STOP=1` only if you need a cold Gradle daemon.

**Windows:** Flutter desktop app zip (OTA via `/version/windows`), not the remote agent (`publish_remote_agent.ps1`).

On failure see `_/specs/app-release.md` (`--finish-cas-only` if APK built but CAS failed).

When finished, end with a **Publish summary** per `.cursor/rules/publish-perf-report.mdc` (`c35-server`, `android-apk-prod`, `windows-app-prod`, `web-release`).
