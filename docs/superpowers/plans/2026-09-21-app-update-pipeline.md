# App Update Pipeline Implementation Plan

> **Goal:** Port cs_agent Windows/Android auto-update, version API, and deploy scripts into c35.

**Architecture:** Server exposes `GET /version/{platform}` reading `ai.config` keys `app.release.c35.{platform}`. Flutter `AppUpdateService` polls, downloads CAS artifacts (blake3 verify), stages Windows updates, uses Play Store + APK sideload on Android. Deploy scripts build, upload to CAS/OCI, and write `ai.config`.

**Tech Stack:** Rust/axum, Flutter, Dart deploy scripts, Yugabyte `ai.config`, blake3 CAS.

## Global Constraints

- Version compare uses **build number** (`234`), not full semver.
- Config keys: `app.release.c35.{platform}`.
- Windows zip contains `alienai.exe` only (no agent binary in c35).
- Same Play Store package: `id.alienai.agent`.

---

## Tasks

- [ ] 1. Add `ai.config` schema + register in store migrate
- [ ] 2. Add `GET /version` routes in `wire_http`
- [ ] 3. Fix `csai__version.dart` stamping (build int)
- [ ] 4. Port Flutter `c/update/*` + UI widgets
- [ ] 5. Add settings page + wire main/window bar
- [ ] 6. Port deploy scripts (`deploy_app/`)
- [ ] 7. Add tests + verify (`cargo build`, `flutter analyze`)
