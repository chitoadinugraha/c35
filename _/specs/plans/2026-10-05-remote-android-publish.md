# Remote Android agent — publish + website download

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review before each wave. Do not start the next wave until the prior **Review gate** is checked.

**Goal:** Ship **`id.alienai.remote`** (`c_remote_android`) with the same release contract as other remote agents: CAS blob, `ai.config` `app.release.c35.remote-android`, `GET /version/remote-android`, friendly download on [alienai.id](https://alienai.id), in-app sideload from the main Flutter app, and NATS `c35.release.remote-android` for connected agents.

**Architecture:** Mirror **remote-browser** / **remote-windows** deploy scripts under `_/scripts/deploy/deploy_remote/`. OTA artifact is a **signed APK** (Blake3 in config as `apkHash` / `apkSize`; optional duplicate `hash`/`size` for agents that only read `url` today). Android **apply** = `PackageInstaller` via Kotlin (not zip + exe). Spec: [`_/specs/remote-android.md`](../remote-android.md), [`_/specs/auto-update.md`](../auto-update.md).

**Tech stack:** Rust (`c_remote_android`, `c_remote_core`), Gradle/Kotlin APK, Dart deploy, `wire_http` download routes, Flutter sideload (reuse `app_update_apk_sideload.dart` pattern).

| Reference | Use |
|-----------|-----|
| [`remote-android.md`](../remote-android.md) | Dual-app model, permissions |
| [`remote-agent.md`](../remote-agent.md) | OTA lifecycle |
| [`publish_remote_browser.ps1`](../../scripts/deploy/publish_remote_browser.ps1) | CAS + config + NATS template |
| [`app_update_apk_sideload.dart`](../../clients/app/lib/c/update/app_update_apk_sideload.dart) | Download + Blake3 + `OpenFilex` |
| [`device_release_platform_key`](../../servers/crates/mod_device/src/release_config.rs) | `needs_update` platform key |

**Out of scope (v1):** Play Store listing for `id.alienai.remote`, F-Droid, multi-ABI split APKs (ship **universal** or **arm64-v8a** only first), macOS/Linux remote publish.

---

## Current gaps (baseline)

| Area | Today |
|------|--------|
| Publish | Only `publish_remote_agent.ps1` (Windows), `publish_remote_browser.ps1`, chrome extension |
| `ai.config` | No `app.release.c35.remote-android` seed or prod row |
| Website | Remote card → Windows `.exe` + Chrome extension only |
| `device_release_platform_key` | `type=android` → wrongly uses **`remote-windows`** release |
| NATS | Android agents would get **`c35.release.remote-windows`** nudge |
| `c_remote_core::update` | `update_apply` **bails** on Android; download assumes **zip** extract |
| Agent version | No `VERSION.android` / `agent_version::register()` on Android → `build=0` on WS |
| Signing | `build.gradle.kts` has no `signingConfigs` / release keystore |

---

## Locked decisions

1. **Config key:** `app.release.c35.remote-android`
2. **Version platform string:** `remote-android` (`c_remote_core::current_platform()` already returns this on Android)
3. **OTA artifact:** Single **release APK** (not zip). Config stores **`apkHash`** + **`apkSize`** (same as main app). Also set **`hash`** + **`size`** to the same values on publish so `/version/remote-android` `url` works for agents that only deserialize `ReleaseRes { hash, url }`.
4. **Download URLs (website):**
   - Primary: `GET /download/remote.apk` → `remote-android` + `DownloadKind::Apk` → filename `alienai-remote.apk`
   - Alias: `GET /download/agent.apk` → same handler (document: remote agent, not `id.alienai.app`)
5. **Version file:** `remotes/VERSION.android` — format `X.Y.Z+BUILD` (same as `VERSION.windows`)
6. **Signing:** Dedicated `remotes/c_remote_android/android/key.properties` (gitignored) + `key.properties.example`; env override `REMOTE_ANDROID_KEYSTORE` for CI. **Do not** reuse `id.alienai.app` applicationId.
7. **Consumer app:** Devices → Android phone → **Install Remote Agent** opens sideload flow against `platform: 'remote-android'` (no Play policy conflict).

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **RA-W0** | Spec + config contract | — | — | Decisions locked; seed SQL + docs index |
| **RA-W1** | Build + version embed | A=Gradle signing + APK, B=Rust version register | W0 | Release APK locally; WS shows `build=N` |
| **RA-W2** | Android OTA apply | C=download APK path, D=PackageInstaller JNI | W1 | Staged APK installs on device (manual test) |
| **RA-W3** | Publish pipeline | E=Dart build/upload/publish, F=PS entrypoints | W1 | `ai.config` row; CAS hash matches APK |
| **RA-W4** | Server + NATS | G=download routes, H=release platform key + NATS | W3 | `/download/remote.apk` 200; `needs_update` correct |
| **RA-W5** | Website + Flutter | I=web hero card, J=Devices install CTA | W4 | User can install from site or app |
| **RA-W6** | Smoke + docs | K=smoke script, L=doc updates | W5 | `smoke_remote_android_release.ps1` green |

```text
RA-W0 → RA-W1 (signed APK + build number)
          ├→ RA-W2 (OTA on device)
          └→ RA-W3 (publish)
                → RA-W4 (server)
                      → RA-W5 (UX)
                            → RA-W6 (smoke)
```

**Parallel dispatch:**

- RA-W1: **A + B**
- RA-W2: **C** then **D**
- RA-W3: **E** (F is one small PS file, same track)
- RA-W4: **G + H**
- RA-W5: **I + J**

---

## RA-W0 — Spec + config contract

- [ ] Add this plan link to [`spec.md`](../../spec.md) docs index (one line)
- [ ] Extend [`_/schemas/config.sql`](../../schemas/config.sql):

```sql
INSERT INTO ai.config (key, value) VALUES (
    'app.release.c35.remote-android',
    '{"version":0,"versionName":"0.0.0","min":0,"apkHash":"","apkSize":0}'::jsonb
)
ON CONFLICT (key) DO NOTHING;
```

- [ ] Document config shape in [`_/specs/auto-update.md`](../auto-update.md) § Remote Agents (apk fields for Android)
- [ ] Add `remoteAgentMinBuild` floor constant for Android in deploy (start at **1**; raise only on breaking wire/pair contract)

**Review gate:** Config key name and download URL paths approved.

---

## RA-W1 — Build + version embed

### Track A — Gradle release APK

**Files:**

- `remotes/c_remote_android/android/key.properties.example`
- `remotes/c_remote_android/android/app/build.gradle.kts` — read `versionCode` / `versionName` from `VERSION.android` (or `local.properties` generated by build script)
- `remotes/c_remote_android/dev_build_android.ps1` — optional `-Release` runs `gradlew assembleRelease` after `cargo ndk`

**Tasks:**

- [ ] Wire `signingConfigs.release` from `key.properties`
- [ ] Output: `android/app/build/outputs/apk/release/app-release.apk`
- [ ] Blake3 helper in Dart build (reuse deploy_lib / same as app release)

### Track B — Agent version on wire

**Files:**

- `remotes/VERSION.android` (initial `1.0.0+1`)
- `remotes/c_remote_android/build.rs` + embed pattern from `c_remote_windows/build.rs` → `agent_version_build.rs`
- `remotes/c_remote_android/src/agent_version.rs` — `register()` at JNI init in `lib.rs`

**Tasks:**

- [ ] `c_remote_core::version::register(name, build)` before `conn_ws_run_reconnect`
- [ ] Confirm pair uses `device_type: "android"` (already in `daemon.rs`)

**Verify:**

```powershell
cd remotes
cargo build -p c_remote_android
# assembleRelease APK; install on device; pair; MCP device_list → agent_build matches VERSION.android BUILD
```

**Review gate:** Paired Android device shows correct `agent_build` in `ai.identity.meta`.

---

## RA-W2 — Android OTA (download + apply)

### Track C — `c_remote_core::update` APK download

**File:** `remotes/c_remote_core/src/update.rs`

- [ ] In `update_download_once`, when `current_platform() == "remote-android"`:
  - Download bytes from `rel.url`
  - Verify Blake3 against `rel.hash` (publish sets hash = apk hash)
  - Write `staging/{version}/update.apk` (no zip extract)
  - Write `.ready` marker
- [ ] Optional: extend `ReleaseRes` with `apkUrl` / `apkHash` and prefer those on Android (fallback to `url`/`hash`)

### Track D — PackageInstaller apply

**Files:**

- `remotes/c_remote_android/android/.../UpdateInstallReceiver.kt` (session result)
- `remotes/c_remote_android/src/lib.rs` — JNI `installApk(path)`
- `MainActivity` / `RemoteAgentService` — handle `MY_PACKAGE_REPLACED` (already in manifest)

- [ ] `update_apply` on `target_os = "android"`: call JNI install; do not run `apply.ps1`
- [ ] Respect `is_idle()` / `apply_update` from viewer (same as Windows)
- [ ] User-visible notification: “Update ready — tap to install” when not idle (Android cannot silent-upgrade without session)

**Verify:** Bump `VERSION.android`, publish to dev server config manually, tap **Check for Update** in remote app UI.

**Review gate:** OTA install works on a test device without uninstall.

---

## RA-W3 — Publish pipeline

### Track E — Dart (mirror remote-browser)

**New files (suggested names):**

| File | Role |
|------|------|
| `deploy_remote/build_remote_android.dart` | `gradlew assembleRelease`, Blake3, rename `alienai_remote_android-{N}.apk` |
| `deploy_remote/publish_remote_android_version.dart` | Upsert `app.release.c35.remote-android` (`apkHash`, `apkSize`, mirror `hash`/`size`) |
| `deploy_remote/upload_remote_android_release.dart` | CAS upload `application/vnd.android.package-archive` |
| `deploy_remote/remote_android_upload_prod.dart` | Orchestrator: build → upload → publish → bump `VERSION.android` |
| `deploy_remote/nats_broadcast_remote_android_release.ps1` | `c35.release.remote-android` |

**Extend:**

- [`agent_version.dart`](../../scripts/deploy/deploy_remote/agent_version.dart) — `RemoteAgentProduct.android`, `VERSION.android`, config key helper
- [`publish_app_release.ps1`](../../scripts/deploy/publish_app_release.ps1) — `-RemoteAndroid` → `remote-android-agent` perf target
- [`publish_remote_android.ps1`](../../scripts/deploy/publish_remote_android.ps1) — thin wrapper like `publish_remote_agent.ps1`

**Config JSON (published):**

```json
{
  "version": 2,
  "versionName": "1.2.0",
  "min": 1,
  "apkHash": "<blake3>",
  "apkSize": 12345678,
  "hash": "<blake3>",
  "size": 12345678
}
```

**Tasks:**

- [ ] `agentVersionBump` for android product after successful publish
- [ ] `C35_SKIP_NATS_BROADCAST=1` escape hatch (same as browser)

**Verify:**

```powershell
.\_\scripts\deploy\publish_remote_android.ps1
# GET https://alienai.id/version/remote-android
```

**Review gate:** Prod `ai.config` row exists; CAS hash matches local APK.

---

## RA-W4 — Server + NATS

### Track G — HTTP downloads

**File:** `servers/crates/wire_http/src/web.rs`

- [ ] `download_remote_apk` → `download_serve(st, "remote-android", DownloadKind::Apk, "alienai-remote.apk")`
- [ ] Routes: `/download/remote.apk`, `/download/agent.apk` (remote agent alias)
- [ ] Unit test in `web.rs` tests module if present

### Track H — Release platform + NATS

**Files:**

- `servers/crates/mod_device/src/release_config.rs` — `device_type == "android"` → `"remote-android"`
- `servers/crates/wire_ws/src/agent_session.rs` — `release_nats_subject("remote-android")` → `c35.release.remote-android`; nudge payload constant
- `task_run` / release frame handler — confirm `remote-android` platform string forwarded (read `c_remote_core::task_run.rs`)

**Tasks:**

- [ ] `device_list` / `device_list_http`: Android remote devices compare `app.release.c35.remote-android`
- [ ] Deploy `server_ai` after Rust changes (`publish_server.ps1`)

**Verify:**

```powershell
curl.exe -sI https://alienai.id/download/remote.apk
curl.exe -s https://alienai.id/version/remote-android
```

**Review gate:** 200 download; version JSON includes `apkUrl` / signed `url`.

---

## RA-W5 — Website + Flutter consumer app

### Track I — Website

**Files:** `clients/web/index.html`, `clients/web/id/index.html`, locale strings if needed

- [ ] Remote Control card: **Android APK** button → `/download/remote.apk`
- [ ] Short copy: separate app `id.alienai.remote`; accessibility / projection permissions
- [ ] Optional: `clients/web/download-remote-android.html` (mirror chrome-extension page) — only if hero card is too cramped

### Track J — Flutter `id.alienai.app`

**Files (suggested):**

- `clients/app/lib/c/update/remote_agent_apk_install.dart` — `appReleaseGet(base, platform: 'remote-android')` + reuse download dialog pattern
- `clients/app/lib/widgets/devices/...` — CTA when user has no Android remote device paired: **Install Remote Agent**

**Tasks:**

- [ ] Deep link or intent: after install, user opens remote app to pair (no auto-launch from main app required v1)
- [ ] Do **not** add accessibility APIs to main app package

**Verify:** `.\_\scripts\dev\verify_flutter_app.ps1`

**Review gate:** Chito can install from Devices on a physical phone and pair.

---

## RA-W6 — Smoke + docs

### Track K — Smoke

**New:** `_/scripts/deploy/deploy_remote/smoke_remote_android_release.ps1`

- [ ] `GET /version/remote-android` → 200, `version > 0`, `apkHash` non-empty
- [ ] `HEAD /download/remote.apk` → 200, content-type reasonable
- [ ] Optional: download APK, Blake3 match against version JSON

Wire into `smoke_remote_release.ps1` or document as separate step after first publish.

### Track L — Docs

- [ ] [`_/specs/remote-android.md`](../remote-android.md) — § Distribution (URLs, publish command)
- [ ] [`.cursor/rules/publish-remote-agent.mdc`](../../.cursor/rules/publish-remote-agent.mdc) — add Android section or new `publish-remote-android.mdc` (mirror Windows)
- [ ] [`_/specs/remote-agent.md`](../remote-agent.md) — publish table row for Android

**Review gate:** First production publish + smoke green; Play full description can still point to Windows until copy updated.

---

## Operator commands (after implementation)

```powershell
# One-shot publish (like Windows remote)
.\_\scripts\deploy\publish_remote_android.ps1

# Or via app release orchestrator
.\_\scripts\deploy\publish_app_release.ps1 -RemoteAndroid

# Server only (after RA-W4 Rust changes)
.\_\scripts\deploy\publish_server.ps1
```

**User install paths:**

| Channel | URL |
|---------|-----|
| Website | https://alienai.id/download/remote.apk |
| Main app | Devices → Install Remote Agent |
| Remote app OTA | `GET /version/remote-android` + NATS push |

---

## Risks / mitigations

| Risk | Mitigation |
|------|------------|
| Unknown sources / install blocked | In-app copy + `REQUEST_INSTALL_PACKAGES`; use same pattern as main app sideload |
| Splitting `hash` vs `apkHash` confusion | Publish script sets both identically; tests assert |
| Wrong OTA nudge (Windows subject) | RA-W4 H + integration test with `device_type=android` |
| ABI mismatch | Default **arm64-v8a** in v1; document emulator x86_64 for dev |
| Keystore loss | Store encrypted backup; `key.properties.example` documents aliases |

---

## Progress snapshot

| Area | Status |
|------|--------|
| `c_remote_android` codebase | **In tree** (pair, services, JNI) |
| Publish + download | **Not started** (this plan) |
| OTA apply on Android | **Not started** |
| Website / app install UX | **Not started** |
