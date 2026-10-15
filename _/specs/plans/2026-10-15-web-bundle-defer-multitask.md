# Web bundle defer + CanvasKit trim -- Multitask Plan

> **For agentic workers:** Use `plan-execution.mdc` -- dispatch one `Task` subagent per track below; **model: inherit** only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Shrink **self-hosted** Flutter web artifacts and **initial JS** for `https://alienai.id/app/` by trimming CanvasKit deploy weight and **lazy-loading** mail, live call, and device control on **web only**, with clear loading UX.

**Architecture:** (1) Deploy: CDN CanvasKit + exclude `*.symbols` from S3 sync. (2) Runtime: `session_busy_registry` decouples shell from WebRTC; shared deferred `webrtc_module`; separate deferred loaders for mail / live / devices; `page_ai_home` and settings use loaders instead of eager page imports on web. Native platforms unchanged.

**Tech Stack:** Flutter web (`clients/app`), `deploy_app/build_web.dart`, `deploy_app/s3_upload.dart`, deferred imports, existing live/mail/remote code.

**Spec:** [`_/specs/web-app-bundle.md`](../web-app-bundle.md)

## Global Constraints

- Read `spec.md`, [`_/specs/web-app-bundle.md`](../web-app-bundle.md), [`_/specs/app-release.md`](../app-release.md) before coding.
- Verify: `.\_\scripts\dev\verify_flutter_app.ps1`; `flutter test` for touched tests under `clients/app/test/`.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Subagent model: **inherit** (not `*-fast`).
- Do not commit unless the user asks.
- Web publish after QA: `dart run deploy_app/push_web.dart` -- user-triggered only.
- No provider web grounding changes (`web-grounding-cluster-only.mdc`).

**Out of scope (this plan):**

- HTML renderer instead of CanvasKit.
- Full remote device viewer parity on web beyond current `remote_session` guards.
- Mail HTML widget migration (Track H optional).

---

## Multitask map

```
Track 0 (metrics)     --> all tracks
Track R (deploy trim) --> Track Q
Track B (busy shell)  --> Track W --> Track L + Track D
Track M (mail defer)  --> Track Q
Track L (live defer)  --> Track Q
Track D (devices defer)--> Track Q
Track H (mail HTML web)-- optional, after M
Track Q (QA + sizes)  --> Track F
Track F (docs lock)   --> done
```

| Track | Focus | Depends |
|-------|--------|---------|
| **0** | Baseline size script + before/after table | -- |
| **R** | CDN CanvasKit + symbols filter in build/upload | 0 |
| **B** | `session_busy_registry`; slim `app_update_busy`, `device_store` / auth | 0 |
| **W** | Shared deferred WebRTC module | B |
| **M** | Deferred mail + loader + settings/home wiring | B |
| **L** | Deferred live call + loading UI | W |
| **D** | Deferred devices + loading UI | W |
| **H** | (Optional) Web mail HTML widget | M |
| **Q** | Integration QA + size gate | R, M, L, D |
| **F** | Spec status + measured sizes in spec | Q |

**Parallel wave 1:** Track **0**  
**Parallel wave 2:** Track **R** + Track **B**  
**Parallel wave 3:** Track **W**  
**Parallel wave 4:** Track **M** + Track **L** + Track **D**  
**Parallel wave 5:** Track **Q**  
**Parallel wave 6:** Track **F** (+ **H** if desired)

---

## Track 0 -- Metrics baseline

**Deliverable:** `_/scripts/dev/web_bundle_size_report.ps1` printing MB per top-level path and `main.dart.js` size.

### Task 0.1: Size report script

**Files:**

- Create: `_/scripts/dev/web_bundle_size_report.ps1`

- [ ] Run `flutter build web --release --base-href /app/ --no-wasm-dry-run` from `clients/app` (or accept existing `build/web`).
- [ ] Print: total MB, `main.dart.js`, `canvaskit/` total, `canvaskit/**/*.symbols` sum, `assets/`, count of deferred part JS files (0 before defer).
- [ ] Write JSON to `.cache/web-bundle-size.json` for manual diff.

**Exit criteria:** Script runs on Windows; referenced from [`web-app-bundle.md`](../web-app-bundle.md).

---

## Track R -- Deploy trim (CanvasKit / symbols)

### Task R.1: CanvasKit CDN flag

**Files:**

- Modify: `_/scripts/deploy/deploy_app/build_web.dart`

- [ ] Add `--web-resources-cdn` to the `flutter build web` argument list (keep `--no-wasm-dry-run`).
- [ ] Optional env `C35_WEB_RESOURCES_CDN=0` for offline local builds.

### Task R.2: Exclude symbols from S3 sync

**Files:**

- Modify: `_/scripts/deploy/deploy_app/s3_upload.dart`

- [ ] Skip files matching `*.symbols` under `canvaskit/` (or entire path when CDN omits local canvaskit).
- [ ] Log skipped count.

### Task R.3: Local build sanity

- [ ] Build web; confirm app loads (network tab: gstatic CanvasKit when CDN on).
- [ ] Record `dirSizeLabel(webBuildDir)` in `.cache/web-bundle-size.json`.

**Exit criteria:** Self-hosted tree <= ~15 MB with CDN; symbols never uploaded.

---

## Track B -- Shell decoupling (no WebRTC on startup)

### Task B.1: Busy registry

**Files:**

- Create: `clients/app/lib/c/session/session_busy_registry.dart`

- [ ] `liveCallActive` and `remoteControlActive` flags (ValueNotifier or static with notify for tests).
- [ ] `anyHeavySessionActive` getter.

### Task B.2: Wire sessions

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart` -- set/clear `liveCallActive`.
- Modify: `clients/app/lib/c/remote/remote_session.dart` -- set/clear `remoteControlActive` when controlling.

### Task B.3: Slim `app_update_busy`

**Files:**

- Modify: `clients/app/lib/c/update/app_update_busy.dart`

- [ ] Remove imports of `live_call_session.dart` and `remote_session.dart`.
- [ ] Use `session_busy_registry.dart` only.
- [ ] Keep `@visibleForTesting appUpdateUserBusyFromSignals`.

### Task B.4: Decouple `device_store` from `remote_session`

**Files:**

- Modify: `clients/app/lib/c/device/device_store.dart`
- Modify: `clients/app/lib/c/auth/auth_service.dart` if needed

- [ ] Use `remoteSessionActive` from registry in `deviceClusterOnline` (already has param) instead of importing `RemoteSession` at library load.
- [ ] Register remote-session hooks when devices module loads (Track D).

### Task B.5: Tests

- [ ] Unit tests for registry + `app_update_busy`; `flutter test` green.

**Exit criteria:** Shell path has no `flutter_webrtc` import (grep `clients/app/lib/c/update`, `auth_service`).

---

## Track W -- Shared deferred WebRTC module

### Task W.1: Deferred library

**Files:**

- Create: `clients/app/lib/c/remote/webrtc_module.dart` -- export `remote_session.dart` (thin barrel).
- Create: `clients/app/lib/c/remote/webrtc_module_loader.dart` -- `import 'webrtc_module.dart' deferred as webrtc;` + idempotent `ensureWebRtcModule()`.

### Task W.2: Web-only loader facade

**Files:**

- Create: `clients/app/lib/c/nav/feature_module_loader.dart` (or split per feature)

- [ ] `ensureWebRtcModule()` no-op when `!kIsWeb`.

**Exit criteria:** No eager `remote_session` from `page_ai_home.dart`.

---

## Track M -- Deferred mail

### Task M.1: Mail module

**Files:**

- Create: `clients/app/lib/pages/mail/mail_module.dart` -- `export 'page_mail.dart';`
- Create: `clients/app/lib/pages/mail/mail_module_loader.dart` -- `deferred as mail`, `openPageMail(...)`.

### Task M.2: Wiring

**Files:**

- Modify: `clients/app/lib/pages/page_ai_home.dart`
- Modify: `clients/app/lib/pages/page_settings.dart`

- [ ] Remove direct `page_mail.dart` import; call loader.

### Task M.3: Loading UX

- [ ] On web: modal + `UiLoading` / translated string during `loadLibrary()`.

**Exit criteria:** Mail part file in `build/web`; Home works without downloading mail part until Mail opened.

---

## Track L -- Deferred live call

### Task L.1: Live module

**Files:**

- Create: `clients/app/lib/pages/live_call_module.dart`
- Create: `clients/app/lib/pages/live_call_module_loader.dart`

- [ ] `ensureWebRtcModule()` then `live_call.loadLibrary()` on web.
- [ ] Wire `_liveCallStart` in `page_ai_home.dart`.

### Task L.2: Loading UX

- [ ] "Loading call..." on same user gesture chain as Connect (autoplay).

### Task L.3: Tests

- [ ] `live_call_session_test.dart` still passes.

**Exit criteria:** Live call works on web after cold load; smaller `main.dart.js`.

---

## Track D -- Deferred devices

### Task D.1: Devices module

**Files:**

- Create: `clients/app/lib/pages/devices_module.dart`
- Create: `clients/app/lib/pages/devices_module_loader.dart`

- [ ] `ensureWebRtcModule()` + `devices.loadLibrary()` on web.
- [ ] Wire `_openDevices` in `page_ai_home.dart`.

### Task D.2: Register `device_store` hooks

- [ ] On first devices module load, register callbacks that required `RemoteSession` (Track B).

### Task D.3: Loading UX

- [ ] "Loading devices..." on web.

**Exit criteria:** Devices list opens; remote control still gated per `remote.md` on web.

---

## Track H -- (Optional) Mail HTML on web

### Task H.1: Dependency

- Modify: `clients/app/pubspec.yaml` -- add approved HTML widget package.

### Task H.2: `_MailHtmlBody`

- Modify: `clients/app/lib/pages/mail/page_mail.dart`

- [ ] `kIsWeb` -> widget HTML + link confirm; `!kIsWeb` -> WebView + CSP.
- [ ] Sanitize HTML (no script).

---

## Track Q -- Integration QA and size gate

### Task Q.1: Size gate (soft)

- [ ] Extend `web_bundle_size_report.ps1`: warn/fail if `main.dart.js` > 8 MB after defer; warn if web dir > 18 MB with CDN.

### Task Q.2: Manual matrix (Chrome desktop)

| Flow | Pass |
|------|------|
| Cold Home -> chat | |
| Mail (loader once) | |
| Live Call connect | |
| Devices | |
| Idle OTA blocked during live | |

### Task Q.3: Native smoke

- [ ] Android or Windows: Mail, Live, Devices eager -- no loader regression.

**Exit criteria:** Matrix green; before/after in `.cache/web-bundle-size.json`.

---

## Track F -- Docs

### Task F.1

- [ ] Update [`web-app-bundle.md`](../web-app-bundle.md) with measured after sizes.

### Task F.2

- [ ] Confirm [`app-release.md`](../app-release.md) and [`spec.md`](../../spec.md) links (done at plan authoring; verify after implementation).

---

## Risk register

| Risk | Mitigation |
|------|------------|
| CDN blocked | `C35_WEB_RESOURCES_CDN=0`; document self-hosted fallback |
| Slow deferred load | HTTP cache; short loader copy |
| `device_store` without remote import | Registry + register on module load; tests |
| Duplicate WebRTC in two parts | Mandatory Track W shared module |
| Mail/AppFlowy defer break | Export full `page_mail.dart`; test compose + read |

---

## Success metrics

| Metric | Before | Target |
|--------|--------|--------|
| S3 web folder | ~50 MB | **<= ~15 MB** (CDN + symbols filter) |
| `main.dart.js` | ~10.4 MB | **<= ~7.5 MB** |
| Deferred parts | 0 | **>= 2** (mail + shared webrtc/live/devices) |
| Cold Home raw download | ~18-22 MB | **~14-17 MB** |
