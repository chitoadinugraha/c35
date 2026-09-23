# App & Remote Agent Auto-Update (c35)

## Overview

| Piece | Role |
|-------|------|
| `GET /version/{platform}` | Release source (`ai.config` → `app.release.c35.{platform}`) |
| CAS `/fs/{hash}` | Immutable release zip / APK (blake3), served from `https://alienai.id` through Cloudflare edge cache |
| NATS `c35.release.{platform}` | Real-time broadcast triggering instant background download on connected agents |
| Flutter `AppUpdateService` | Client app: poll, download, verify, stage, apply on restart |
| `c_remote_core::update` | Remote agents: background download, Blake3 verify, activity-aware idle restart |

**Compare versions using the build number** (`234`), not `20.234.0`.

---

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

- Android client adds `url` (Play Store) and optional `apkHash` / `apkSize` for direct APK download.
- Signed CAS URL: `https://alienai.id/fs/{hash}?exp={exp}&sig={sig}`. Cloudflare orange cloud caches the immutable blob at edge PoPs globally.

---

## Remote Agents (`remote-windows`, `remote-macos`, `remote-linux`, `remote-android`)

All remote agents share the exact same core lifecycle in `remotes/c_remote_core`:

```
c_remote_core/src/update.rs
├── Activity tracking: task_start() / TaskGuard (ACTIVE_TASKS)
├── Session tracking: active_sessions_set() (ACTIVE_SESSIONS)
├── Idle condition: is_idle() == (active_tasks == 0 && active_sessions == 0)
├── Platform detection: current_platform() -> "remote-{windows|macos|linux|android}"
├── Background download & Blake3 checksum verification
├── Staged marker: .ready in updates staging dir
└── Real-time wakeup: IDLE_NOTIFY triggers immediate apply when tasks/sessions reach 0
```

### Auto-Update Execution Rules

1. **Background Download:**
   - On startup (non-blocking) and every 5 minutes in `update_run_loop`.
   - On NATS `c35.release.{platform}` push via server WebSocket relay: wakes up immediately and downloads in the background.
2. **Idle Auto-Apply:**
   - If `is_idle() == true` (no running tasks and no active user remote sessions): applies immediately and restarts into the new binary.
3. **Active Tasks Running:**
   - If tasks or skills are running (`active_tasks > 0`): holds the update. Wakes up and applies the instant all tasks drop to 0.
4. **Active User Remote Session:**
   - If a human viewer is remoting into the machine (`active_sessions > 0`): the agent **never** reboots automatically.
   - Instead, `WebrtcHub` broadcasts `RemoteSessionPush { update_ready: true, update_version: N }`.
   - The Flutter client shows an emerald **`Update (vN)`** button on the remote display appbar.
   - When clicked, the client sends `apply_update` over the `remote-input` data channel, applying the update on demand.
5. **Development Mode Protection:**
   - If `is_dev_mode() == true` (`cfg!(debug_assertions)`, `C35_DEV=1`, `--dev`, or `--cli`), binary replacement is safely bypassed.

---

## Multi-Platform Porting Guide

When implementing new remote agent executors, wire the following platform hooks:

| Platform | Executable Target | Screen Capture | Audio Capture | Input Injection (`input_exec`) | Process Replacement (`update_apply`) | System Boot Auto-Start | Power Sleep Keep-Alive |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Windows** | `c_remote_windows` | DXGI Desktop Duplication / GDI | WASAPI Loopback | Win32 `SendInput` | `apply.ps1` (PID wait, copy, start) | `HKCU\...\CurrentVersion\Run` | `SetThreadExecutionState` |
| **macOS** | `c_remote_macos` | ScreenCaptureKit (`SCStream`) | CoreAudio tap | `CGEventPost` (Quartz) | `apply.sh` (copy, chmod, exec) | `~/Library/LaunchAgents/` plist | `IOPMAssertionCreateWithName` |
| **Linux** | `c_remote_linux` | PipeWire Portal / X11 SHM | PulseAudio / PipeWire | Kernel `uinput` or `libei` | `apply.sh` (copy, chmod, exec) | `~/.config/systemd/user/` | `systemd-inhibit` / D-Bus |
| **Android** | `c_remote_android` | `MediaProjection` | `AudioPlaybackCapture` | `AccessibilityService` | PackageInstaller intent | `BOOT_COMPLETED` Receiver | `WakeLock` / Foreground Service |

### Shared Input Channel `apply_update` Handler
In every platform's input executor:
```rust
if evt.event_type == "apply_update" {
    if let Some(v) = c_remote_core::update::update_staged_version() {
        let _ = c_remote_core::update::update_apply(v);
    }
}
```

### Shared Crash Watchdog Pattern
In every platform's `main.rs`:
- Dev mode: Direct run, prints panics and errors to terminal.
- Production mode: Watchdog supervisor loop with `futures_util::FutureExt::catch_unwind`, restarting after crash with rate-limited backoff (3s -> 30s if > 5 crashes in 60s).

---

## Deployment Commands

### Flutter App
```powershell
cd _\scripts\deploy
dart pub get
$env:DEPLOY_AUTH_TOKEN = '<jwt>'
$env:YB_PASSWORD = '<password>'
dart run deploy_app/windows_upload_prod.dart
dart run deploy_app/play_store_upload_prod.dart
```

### Remote Windows Agent
```powershell
cd _\scripts\deploy
dart pub get
$env:DEPLOY_AUTH_TOKEN = '<jwt>'
$env:YB_PASSWORD = '<password>'
dart run deploy_remote/remote_windows_upload_prod.dart
```

### Remote Linux / macOS Agent (Future)
Follow the same script pattern in `_\scripts\deploy\deploy_remote\`:
1. Build release binary: `cargo build --release -p c_remote_{platform}`
2. Zip binary, calculate Blake3 hash
3. Upload to CAS: `POST /v1/file/upload`
4. Update `ai.config`: `app.release.c35.remote-{platform}`
5. Broadcast over NATS: `c35.release.remote-{platform}`
6. Bump `remotes/VERSION`
