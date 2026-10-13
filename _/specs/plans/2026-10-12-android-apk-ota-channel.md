# Android APK OTA channel (independent of Play)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review before each wave. Do not start the next wave until the prior **Review gate** is checked.

**Goal:** Sideload / website APK users get **background download + staged install** from `GET /version/android` (`apkUrl` / `apkHash`), **without calling Google Play In-App Update**, while Play-installed users keep the existing Play path unless they opt into APK updates.

**Architecture:** Persist `update_channel` (`play` | `apk`) in `SharedPreferences`. When `apk`, poll `/version/android` on resume (and optional in-app interval), download to app-private storage with Blake3 verify, mark staged `.ready`, show in-app **Install** banner (and force path when `min` > local build). Apply via Kotlin `PackageInstaller` session (API 31+ `USER_ACTION_NOT_REQUIRED` for same-package update when allowed) with `ACTION_VIEW` + `FileProvider` fallback. Mirror Windows idle behavior where practical (download in background; prompt when ready).

**Tech stack:** Flutter (`clients/app/lib/c/update/*`), Kotlin (`MainActivity` + `ApkUpdateInstaller`), existing CAS release pipeline ([`_/specs/app-release.md`](../app-release.md), [`_/specs/auto-update.md`](../auto-update.md)).

| Reference | Use |
|-----------|-----|
| [`app_update_android.dart`](../../clients/app/lib/c/update/app_update_android.dart) | Play vs sideload branch today |
| [`app_update_apk_sideload.dart`](../../clients/app/lib/c/update/app_update_apk_sideload.dart) | Download + Blake3 + `OpenFilex` (replace install path) |
| [`app_update_host.dart`](../../clients/app/lib/c/update/app_update_host.dart) | Resume checks, dialogs |
| [`app_update_service.dart`](../../clients/app/lib/c/update/app_update_service.dart) | Windows idle / ready pattern |
| [`UpdateInstaller.kt`](../../remotes/c_remote_android/android/app/src/main/kotlin/id/alienai/remote/bridge/UpdateInstaller.kt) | Intent fallback pattern (upgrade to PackageInstaller in main app) |

**Out of scope (v1):** NATS push for main Flutter Android app; separate package name; changing Play listing; removing `in_app_update` dependency (keep for Play channel).

---

## Locked decisions

1. **Channels:** `play` (default on first install) and `apk`. **Independent update sources** — same `id.alienai` binary and upload keystore.
2. **Auto-select `apk`:** When `InAppUpdate` fails with `ERROR_APP_NOT_OWNED` / `Install Error(-10)`, persist `apk` (existing `appUpdatePlayNotOwned` detection). Optional: set `apk` when user taps “Download APK” in Settings (already has `_apkUrl`).
3. **Play path:** Only when `update_channel == play` **and** Play check succeeds. Never fall through to Play after user is on `apk`.
4. **Version compare:** Build number (`csaiVersion` / `release.version`), not semver — same as [`auto-update.md`](../auto-update.md).
5. **Staging layout (Android):** `{appSupport}/alienai-updates/{version}/update.apk` + `{version}/.ready` (empty marker file after verify). Do not use `LOCALAPPDATA` paths on Android.
6. **Install:** Prefer `PackageInstaller` session initiated by hosting app; fallback `ACTION_VIEW` if session fails.
7. **UX:** Background download (no blocking modal). Non-force: snackbar or slim banner when ready + “Install”. Force (`min`): blocking dialog until install launched. Reuse dismiss prefs (`app_update_dismissed_version`) for **prompt only**, not for skipping forced `min`.
8. **Permissions:** `REQUEST_INSTALL_PACKAGES`; deep-link to per-app “Install unknown apps” when `canRequestPackageInstalls()` is false.

---

## Current gaps

| Area | Today |
|------|--------|
| Channel | None — Play tried first; APK only after not-owned |
| Download | Modal dialog; temp dir; no staging |
| Install | `OpenFilex` external handler |
| Ready state | `appUpdateStagedReady` is Windows `.exe` only |
| Idle / background | `AppUpdateService.start()` is Windows-only |
| Kotlin | No update `MethodChannel` on main app |
| Manifest | No `REQUEST_INSTALL_PACKAGES`; no dedicated `FileProvider` for updates |

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **APK-W0** | Spec + contract | — | — | `auto-update.md` § Android APK channel; plan linked in `spec.md` |
| **APK-W1** | Channel + paths | A=channel prefs, B=Android staging paths | W0 | Unit tests: channel read/write; apk path helpers |
| **APK-W2** | Native install | C=Kotlin installer + manifest | W0 | Debug APK: method channel installs a test apk path |
| **APK-W3** | OTA Dart core | D=apk OTA download/stage, E=android check routing | W1 | Staged `.ready` after mock download (widget test or unit) |
| **APK-W4** | UI + lifecycle | F=host banner/idle, G=deprecate modal sideload | W2, W3 | Manual: resume → background DL → Install tap |
| **APK-W5** | Settings + docs | H=settings channel toggle, I=app-release blurb | W4 | Settings shows channel; docs accurate |
| **APK-W6** | Verify | J=flutter analyze + manual matrix | W5 | `verify_flutter_app.ps1` green |

```text
APK-W0
  → APK-W1 (A + B)
  → APK-W2 (C)
  → APK-W3 (D + E)
  → APK-W4 (F + G)
  → APK-W5 (H + I)
  → APK-W6 (J)
```

**Parallel dispatch (subagents):**

- APK-W1: **A + B**
- APK-W3: **D + E** (E needs A; D needs B)
- APK-W4: **F + G**
- APK-W5: **H + I**

---

## APK-W0 — Spec + contract

- [ ] Add **§ Android APK update channel** to [`_/specs/auto-update.md`](../auto-update.md): channels, staging paths, Play vs APK, force `min`, one-time unknown-sources.
- [ ] Link this plan from [`spec.md`](../../spec.md) plans table (one row).
- [ ] Note in [`_/specs/app-release.md`](../app-release.md) that prod `/version/android` + `apkUrl` is the OTA source for `apk` channel (no change to publish scripts required for v1).

**Review gate:** Spec matches locked decisions above.

---

## APK-W1 — Channel + Android paths

### Track A — `app_update_channel.dart`

**Files:**

- Create: `clients/app/lib/c/update/app_update_channel.dart`
- Modify: `clients/app/lib/c/update/app_update_prefs.dart` (or keep channel keys in channel file)

**Interfaces:**

- Produces: `Future<AppUpdateChannel> appUpdateChannelGet()`, `Future<void> appUpdateChannelPut(AppUpdateChannel)`, `enum AppUpdateChannel { play, apk }`

- [ ] Add pref key `app_update_channel` (`play` | `apk` string).
- [ ] Default `play` when unset.
- [ ] `appUpdateChannelPreferApk()` — set `apk` (call from not-owned path + Settings).
- [ ] Unit test: `clients/app/test/app_update_channel_test.dart` — default, round-trip, prefer apk.

### Track B — Android staging paths

**Files:**

- Modify: `clients/app/lib/c/update/app_update_paths.dart`
- Create: `clients/app/lib/c/update/app_update_paths_android.dart` (if paths file should stay Windows-centric)

**Interfaces:**

- Produces: `Future<String> appUpdateApkPath(int version)`, `Future<String> appUpdateAndroidRoot()`, `bool appUpdateApkStagedReady(int version)` (true when apk file exists + `.ready` marker)

- [ ] Use `path_provider` `getApplicationSupportDirectory()` on Android only.
- [ ] Keep existing Windows helpers unchanged.
- [ ] Split `appUpdateStagedReady` — Windows: existing exe check; Android: delegate to `appUpdateApkStagedReady`.
- [ ] Unit test paths with `Platform.isAndroid` mocked or test only pure path join helpers.

**Review gate:** `flutter test` for new tests pass.

---

## APK-W2 — Kotlin installer + manifest

### Track C — Native install bridge

**Files:**

- Create: `clients/app/android/app/src/main/kotlin/id/alienai/ApkUpdateInstaller.kt`
- Create: `clients/app/android/app/src/main/res/xml/apk_update_file_paths.xml`
- Modify: `clients/app/android/app/src/main/kotlin/id/alienai/MainActivity.kt`
- Modify: `clients/app/android/app/src/main/AndroidManifest.xml`

**Interfaces:**

- Produces MethodChannel `id.alienai/app_update`:
  - `canInstallApk` → `bool` (`packageManager.canRequestPackageInstalls()`)
  - `openInstallPermissionSettings` → `void`
  - `installApk` → `bool` (arg `path: String`) — PackageInstaller session; fallback intent
  - Optional: `installApkResult` via `BroadcastReceiver` + `IntentSender` for logging only (v1)

- [ ] `REQUEST_INSTALL_PACKAGES` in manifest.
- [ ] `FileProvider` authority `${applicationId}.apkupdate` for files under app support updates dir.
- [ ] `ApkUpdateInstaller`: API 31+ set `SessionParams.USER_ACTION_NOT_REQUIRED` when installing same package; else require user action.
- [ ] Dart: `clients/app/lib/c/update/app_update_install_android.dart` wrapping channel.

**Review gate:** Local release build; `adb install` base APK; call install with a second signed APK at higher `versionCode` (manual).

---

## APK-W3 — OTA Dart core

### Track D — Background download + stage

**Files:**

- Create: `clients/app/lib/c/update/app_update_apk_ota.dart`
- Modify: `clients/app/lib/c/update/app_update_apk_sideload.dart` (thin wrapper or delegate to OTA)

**Interfaces:**

- Consumes: `appUpdateDownloadFile`, `appUpdateBlake3Match`, path helpers, `AppRelease`
- Produces: `Future<bool> appUpdateApkDownloadStage(AppRelease release, {void Function(double)? onProgress})`, `Future<void> appUpdateApkInstallStaged(int version)`

- [ ] Download to `appUpdateApkPath(version)` with resume (`appUpdateDownloadFile` range).
- [ ] Verify `apkHash` when non-empty; delete corrupt file.
- [ ] Write `.ready` marker only after verify.
- [ ] `appUpdateApkInstallStaged`: check install permission → settings if needed → `installApk` channel.
- [ ] Do **not** use blocking `showDialog` for download in OTA path (progress via `ValueNotifier` / service state).

### Track E — Android check routing

**Files:**

- Modify: `clients/app/lib/c/update/app_update_android.dart`

- [ ] At start of `appUpdateAndroidCheck`: if `appUpdateChannelGet() == apk` → `appUpdateApkOtaCheck(...)` and return.
- [ ] On `appUpdatePlayNotOwned`: call `appUpdateChannelPreferApk()` then APK OTA check.
- [ ] Play branch unchanged when channel is `play`.
- [ ] APK OTA check: fetch `/version/android`, compare build, respect dismiss unless force, start **background** stage when user accepts OR when already staged (ready → banner only).

**Review gate:** With channel forced to `apk` in prefs, Play In-App Update is never invoked (grep / log / breakpoint).

---

## APK-W4 — UI + lifecycle

### Track F — Host + service state

**Files:**

- Modify: `clients/app/lib/c/update/app_update_host.dart`
- Modify: `clients/app/lib/c/update/app_update_service.dart` (optional shared `ValueNotifier` for Android ready state)
- Create: `clients/app/lib/c/update/app_update_banner.dart` (slim Material banner or overlay)

- [ ] Expose `AppUpdatePhase.ready` equivalent for Android APK (reuse `AppUpdateService.state` or parallel notifier).
- [ ] On resume: run check; if staged ready without new download, show banner immediately.
- [ ] **Idle install prompt:** After 5 min no activity (mirror Windows `recordUserActivity` / `postponeAutoUpdate` hooks if already on Home shell), show “Install update” if phase `ready` and not force-pending install.
- [ ] Wire `AppUpdateHost` child to show banner when `ready` (non-blocking).

### Track G — Retire modal sideload flow

**Files:**

- Modify: `clients/app/lib/c/update/app_update_apk_sideload.dart`

- [ ] Replace `_ApkDownloadDialog` path with OTA staging + banner; keep dialog **only** for unrecoverable error summary if needed.
- [ ] Settings “download APK” link can call `appUpdateApkDownloadStage` + install for manual full APK fetch (same pipeline).

**Review gate:** Manual on device: APK channel → new version published on `/version/android` → background download → one-tap Install → system sheet → app restarts at new build.

---

## APK-W5 — Settings + operator docs

### Track H — Settings

**Files:**

- Modify: `clients/app/lib/pages/page_settings.dart`

- [ ] Android-only: “App updates” — radio or list tile: **Google Play** / **Website (APK)**.
- [ ] Changing to APK calls `appUpdateChannelPreferApk()` and triggers `checkNow` / host check.
- [ ] Changing to Play sets `play` (warn that sideload users should stay on APK).

### Track I — Docs

- [ ] User-facing one-liner in `_/docs/en/` + `_/docs/id/` only if there is an existing “install app” guide; otherwise spec-only (prompt-first: optional short FAQ later).

**Review gate:** Chito can flip channel in Settings without reinstalling.

---

## APK-W6 — Verify

### Track J — CI + manual matrix

- [ ] `.\_\scripts\dev\verify_flutter_app.ps1`
- [ ] `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`
- [ ] Manual matrix:

| Case | Expected |
|------|----------|
| Fresh install APK, channel auto `apk` after not-owned | No Play API |
| Channel `play`, owned | Flexible/immediate Play |
| Channel `apk`, newer `/version/android` | Background DL + banner |
| `min` > local | Force copy; no “Later” on prompt |
| No install permission | Settings deep link |
| Wrong `apkHash` | Download deleted; error state |
| Same version | No prompt |

**Review gate:** All rows checked once on a physical device (or emulator with staged `/version` mock).

---

## Subagent task briefs (copy-paste)

**APK-W1-A:** Implement `app_update_channel.dart` + tests per Track A.

**APK-W1-B:** Android staging paths + `appUpdateApkStagedReady` per Track B.

**APK-W2-C:** Kotlin `ApkUpdateInstaller` + MethodChannel + manifest per Track C.

**APK-W3-D:** `app_update_apk_ota.dart` background stage + install per Track D.

**APK-W3-E:** Refactor `app_update_android.dart` channel routing per Track E.

**APK-W4-F:** `app_update_host.dart` + banner + idle per Track F.

**APK-W4-G:** Remove blocking download dialog per Track G.

**APK-W5-H:** Settings channel toggle per Track H.

**APK-W5-I:** Spec/doc touch-ups per Track I.

**APK-W6-J:** Run verify script + fill manual matrix.

---

## Risks

| Risk | Mitigation |
|------|------------|
| OEM still shows install confirmation | Document; API 31+ reduces friction, not 100% |
| Play + APK signature mismatch | Same upload keystore for all release APKs; doc in app-release |
| Large APK on cellular | v1: download whenever user accepted; v2 optional Wi‑Fi-only flag |
| `open_filex` no longer needed for updates | Keep dep until remote agent install path audited |

---

## Server changes

**None for v1** — existing `GET /version/android` and `apkUrl` / `apkHash` from prod publish are sufficient.
