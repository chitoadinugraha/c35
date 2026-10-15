# Flutter web bundle size and lazy loading

Status: **locked** 2026-10-15

Engineering contract for `https://alienai.id/app/` static assets: what we ship to S3, what the browser downloads on first paint, and how **mail**, **live call**, and **device control** load on demand.

Companion: [`app-release.md`](app-release.md) (build/publish commands), [`live-call.md`](live-call.md), [`remote.md`](remote.md), [`mail.md`](mail.md).

Implementation: [`plans/2026-10-15-web-bundle-defer-multitask.md`](plans/2026-10-15-web-bundle-defer-multitask.md).

---

## Goals

1. **Smaller self-hosted tree** on S3 (`app/web/current/`) without breaking `GET /app/*` SPA serving.
2. **Smaller initial JavaScript** for Home/chat (users who never open mail, call, or devices).
3. **Explicit loading UX** on web before heavy modules run (mail, live connect, devices).
4. **One WebRTC download** shared by live call and device remote control (no duplicate `flutter_webrtc` parts).

Non-goals:

- Replacing CanvasKit with the HTML renderer (separate product decision; different fidelity).
- Provider-native web grounding changes (`web-grounding-cluster-only.mdc`).
- Enabling full device WebRTC viewer on web beyond what the live-call web plan already allows for live call.

---

## Baseline (release build, 2026-10-15)

Measured from `clients/app/build/web` after `flutter build web --release --base-href /app/ --no-wasm-dry-run` (see `deploy_app/build_web.dart`).

| Artifact | Disk size | Loaded on first Home visit |
|----------|-----------|----------------------------|
| `main.dart.js` | ~10.4 MB | **All** (mail, AppFlowy, live, devices, WebRTC today) |
| `canvaskit/` | ~36.1 MB | **One** WASM path (~3.6-7 MB) per browser; rest unused on disk |
| `canvaskit/**/*.symbols` | ~8.2 MB | **Never** (dev-only) |
| `assets/` | ~3.4 MB | Most fonts/translations |
| **Total folder** | ~50.3 MB | ~14-22 MB raw network cold load (JS + one CanvasKit WASM + assets) |

Current renderer: **dart2js + CanvasKit** (`_flutter.buildConfig.builds[0].renderer == "canvaskit"`).

---

## Target architecture

### A. Deploy trim (renderer hosting)

| Measure | S3 impact | Runtime impact |
|---------|-----------|----------------|
| **Omit `*.symbols` from upload** | about -8 MB | None |
| **`--web-resources-cdn`** (CanvasKit from gstatic) | about -36 MB local `canvaskit/` | Browser still fetches ~5-7 MB WASM from Google CDN |
| Keep **`--no-wasm-dry-run`** | Avoid broken bootstrap (see `build_web.dart` comment) | -- |

Self-hosted target after A: **~12-14 MB** per version snapshot (bootstrap + `main.dart.js` + assets + splash), plus CDN CanvasKit at runtime.

### B. Deferred feature modules (web only)

Use Dart **`deferred as`** imports so the compiler emits `main.dart.js` + part files. **Native mobile/desktop builds keep eager imports** (conditional export or `kIsWeb` loaders).

| Module | Entry UI | Heavy dependencies | Load trigger |
|--------|----------|-------------------|--------------|
| **mail** | `PageMail` | `appflowy_editor`, large `page_mail.dart` | First open Mail from Home or Settings |
| **live** | `PageLiveCall` | `live_call_session`, shared WebRTC | User starts Call (after loading UI) |
| **devices** | `PageDevices` | `remote_session`, remote widgets, shared WebRTC | First open Devices |
| **webrtc_shared** | -- | `flutter_webrtc` | First live **or** devices open (single shared deferred lib) |

**Shell must not import** `live_call_session`, `remote_session`, or `flutter_webrtc` at startup.

Replace today's eager paths:

- `app_update_busy.dart` -> `LiveCallSession` / `RemoteSession` statics
- `auth_service.dart` -> `device_store.dart` -> `remote_session.dart` (if still eager after refactor)

Use a tiny **`session_busy_registry.dart`**: boolean flags updated when sessions start/stop; `app_update_busy` reads flags only.

### C. Mail HTML (Track H -- shipped)

| Platform | Renderer |
|----------|----------|
| **Web** | `flutter_widget_from_html` (`mail_html_body_web.dart`) + `sanitizeMailHtml` |
| **Native / desktop** | `webview_flutter` with CSP (`mail_html_body_io.dart`) |

External links: `confirmAndLaunchMailExternalUrl` in `mail_external_link.dart`.

---

## Expected sizes (order-of-magnitude)

After **B + A** (defer + CDN + no symbols):

| Chunk | When | Raw JS/WASM (approx.) | Gzip-ish wire |
|-------|------|------------------------|---------------|
| **First `main.dart.js`** | App open | ~5.5-7.5 MB | ~1.8-2.6 MB |
| **CanvasKit** | App open (CDN) | ~5-7 MB WASM | ~1.5-2.5 MB |
| **Assets** | App open | ~3-4 MB | varies |
| **mail part** | First Mail | ~3-5 MB | ~1-1.7 MB |
| **live + webrtc part** | First Call | ~3-5 MB if WebRTC first heavy use | ~1-2 MB |
| **devices part** | First Devices | ~1-2.5 MB extra if WebRTC already loaded | ~0.4-1 MB |

**Cold Home-only visit:** ~14-17 MB raw (~5-7 MB compressed) vs ~18-22 MB raw today.

Repeat visits: browser HTTP cache for part files and CDN WASM.

---

## Loading UX (web)

| Action | UI |
|--------|-----|
| Open Mail | Full-screen or dialog: "Loading mail..." until `mail.loadLibrary()` completes |
| Start Live Call | "Loading call..." on Connect path before mic/WebRTC |
| Open Devices | "Loading devices..." until devices (+ webrtc if needed) parts load |

Use existing loading patterns (`UiLoading`, modal barrier). Do not block Home render.

---

## Build and publish

| Step | Command / file |
|------|----------------|
| Local build | `flutter build web --release --base-href /app/` (+ CDN flag when Track R lands) |
| CI / release | `deploy_app/build_web.dart` |
| Upload | `deploy_app/s3_upload.dart` -- may filter `*.symbols` before `s3SyncDir` |
| Verify | `.\_\scripts\dev\verify_flutter_app.ps1`; optional `web_bundle_size_report.ps1` (plan Track 0) |

Record **`artifacts_bytes.web`** in publish perf JSON; compare before/after in PR notes.

---

## Verification checklist

- [ ] `main.dart.js` size drops; deferred `*.part.js` (or equivalent) appear in `build/web/`.
- [ ] Home chat works without loading mail/live/devices parts.
- [ ] Mail / Call / Devices work on Chrome desktop after cold load (each shows loader once).
- [ ] `appUpdateUserBusy()` still blocks idle OTA during live call or active remote control.
- [ ] S3 `app/web/current/` folder size <= ~15 MB (with CDN) or <= ~42 MB (symbols stripped, self-hosted CanvasKit).
- [ ] No regression on Android/iOS/Windows (no deferred loaders on non-web).

---

## References

- Eager import map (pre-change): `page_ai_home.dart` -> `page_mail`, `page_live_call`, `page_devices`; `app_update_busy.dart` -> live + remote sessions.
- WebView scope: mail HTML read-only only; sites use `GuestSiteView` (no WebView parity shortcut).
