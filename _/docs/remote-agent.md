# Remote Agent Architecture & Multi-Platform Porting Guide

This document defines the architecture of the Alien AI Remote Agent platform (`remotes/`), specifying how core functionality is shared across operating systems and providing a blueprint for adding support for new platforms (macOS, Linux, Android, etc.).

---

## Architecture Overview

The remote agent is split into a **shared core** and **platform-specific executors**:

```
remotes/
├── c_remote_core/          # Shared library (Rust) — 100% cross-platform
│   ├── src/config.rs       # Local config path & session storage
│   ├── src/conn_ws.rs      # WebSocket connection & backoff reconnect
│   ├── src/update.rs       # Multi-platform OTA, idle state & staging
│   ├── src/webrtc/         # WebRTC signaling, remote-fs, media hooks
│   ├── src/skill_*.rs      # Autonomous skill replay & tape execution
│   └── src/task_run.rs     # Task dispatch & release frame handler
│
├── c_remote_windows/       # Windows executor (Win32, DXGI, WASAPI, UIA)
├── c_remote_macos/         # Planned macOS executor (ScreenCaptureKit, CoreAudio)
├── c_remote_linux/         # Planned Linux executor (Wayland PipeWire, uinput)
└── c_remote_android/       # Planned Android service (MediaProjection, Accessibility)
```

---

## Core vs. Platform Responsibilities

| Responsibility | Shared in `c_remote_core`? | Platform-Specific? | Details |
| :--- | :---: | :---: | :--- |
| **Activity Tracking & Idle Detection** | **YES** | No | `task_start()` RAII guard, `ACTIVE_TASKS`, `active_sessions_set()`, `is_idle()`. |
| **Auto-Update Polling & Download** | **YES** | No | `update_poll()` fetches `/version/remote-{platform}`, downloads signed CAS blob, verifies Blake3. |
| **Update Staging & Readiness** | **YES** | No | Writes to `%APPDATA%/updates` or `~/.local/share` with `.ready` marker; wakes up via `IDLE_NOTIFY`. |
| **Viewer Live Update Notification** | **YES** | No | Pushes `RemoteSessionPush { update_ready: true, update_version }` over active WebRTC sessions. |
| **Dev-Mode Protection** | **YES** | No | `is_dev_mode()` checks debug assertions, `C35_DEV=1`, or `--dev`/`--cli` args. |
| **Binary Process Replacement** | Partial | **YES** | Windows: `apply.ps1`. Linux/macOS: `apply.sh`. Android: APK installer intent. |
| **Crash Recovery Supervisor** | Core Pattern | **YES** | Main loop wraps execution in `catch_unwind` with exponential backoff rate limiter. |
| **Screen Capture** | No | **YES** | Windows: DXGI / GDI. macOS: ScreenCaptureKit. Linux: PipeWire / X11. Android: MediaProjection. |
| **Audio Capture** | No | **YES** | Windows: WASAPI Loopback. macOS: CoreAudio. Linux: Pulse/PipeWire. Android: AudioPlaybackCapture. |
| **Input Injection** | No | **YES** | Windows: `SendInput`. macOS: `CGEventPost`. Linux: `uinput`/`libei`. Android: AccessibilityService. |
| **Boot Auto-Start** | No | **YES** | Windows: Registry `Run`. macOS: LaunchAgent. Linux: Systemd. Android: BOOT_COMPLETED. |
| **Sleep / Standby Prevention** | No | **YES** | Windows: `SetThreadExecutionState`. macOS: `IOPMAssertion`. Linux: `systemd-inhibit`. |

---

## 1. Auto-Update Lifecycle

### A. Idle Definition
The agent is defined as **idle** if and only if:
```rust
is_idle() == (active_tasks() == 0 && active_sessions() == 0)
```
- **`active_tasks`**: Tracked via `c_remote_core::update::task_start()`, which returns an RAII `TaskGuard`. It increments on task/skill start and decrements on completion.
- **`active_sessions`**: Tracked via `WebrtcHub`, updating the number of connected human viewers in real time.

### B. Background Download & Verification
1. The agent checks for updates on startup (non-blocking background task) and every 5 minutes in `update_run_loop`.
2. When a higher build is found, the agent downloads the zip bundle directly into the platform staging directory.
3. The bundle is verified with **Blake3** against the server release hash.
4. Upon successful extraction, a `.ready` marker file is placed in the version staging folder.

### C. Decision Matrix: When to Apply
- **Case 1: Agent is Idle (`is_idle() == true`):**
  Auto-applies immediately. Relaunches into the new build within 2 seconds.
- **Case 2: Tasks are Running (`active_tasks > 0`):**
  Staged update is held. The moment tasks finish and drop to 0, `IDLE_NOTIFY` triggers and applies the update.
- **Case 3: Active User Remote Session (`active_sessions > 0`):**
  The agent will **never** reboot automatically while a user is connected.
  Instead, `WebrtcHub` broadcasts `RemoteSessionPush { update_ready: true, update_version: N }` to the client.
  The Flutter app displays an emerald **`Update (vN)`** button on the remote display appbar. The user can click it to trigger `apply_update` on demand.
- **Case 4: Development Mode (`is_dev_mode() == true`):**
  Applying updates is completely bypassed to prevent overwriting target debug builds.

---

## 2. NATS Instant Release Push

Instead of waiting for the 5-minute poll interval, the deployment script broadcasts releases instantly:

1. **Deploy Script:**
   `dart run deploy_remote/remote_windows_upload_prod.dart` publishes release metadata to NATS subject:
   ```text
   c35.release.{platform}   # e.g. c35.release.remote-windows, c35.release.remote-linux
   ```
2. **Server WebSocket Relay:**
   `servers/crates/wire_ws/src/agent_session.rs` subscribes to `c35.release.*` and forwards a release notification frame to connected agent WebSockets.
3. **Agent Immediate Wake-Up:**
   `task_run.rs` receives `c35.release:*` and immediately calls `c_remote_core::update::trigger_background_update()`, starting the background download instantly.

---

## 3. Crash Recovery Watchdog (Production vs. Dev)

Unattended machines must self-heal from unhandled panics or driver crashes, while developer workstations must preserve error output:

```rust
if is_dev_mode() {
    // Development: Direct execution. Crashes print stack trace and exit.
    tokio::select! {
        r = run() => if let Err(e) = r { eprintln!("{e}"); std::process::exit(1); },
        _ = tokio::signal::ctrl_c() => {}
    }
} else {
    // Production: Watchdog supervisor loop.
    let mut crash_count = 0usize;
    let mut last_crash = std::time::Instant::now();
    loop {
        let run_future = std::panic::AssertUnwindSafe(run());
        let res = futures_util::FutureExt::catch_unwind(run_future).await;
        
        match res {
            Ok(Ok(())) => break, // Clean exit
            Err(panic_err) | Ok(Err(_)) => {
                // Rate-limited exponential backoff (3s -> 30s if > 5 crashes / min)
                let delay = if crash_count >= 5 { 30 } else { 3 };
                tokio::time::sleep(Duration::from_secs(delay)).await;
            }
        }
    }
}
```

---

## 4. Platform Implementation Checklist (For New Agents)

When building `c_remote_macos`, `c_remote_linux`, or `c_remote_android`, implement the following platform hooks:

### 1. Process Replacement (`update_apply`)
- **Windows:** Write `apply.ps1` (waits for PID, copies `.exe`, launches new process).
- **macOS / Linux:** Write `apply.sh`:
  ```sh
  #!/bin/sh
  sleep 1
  cp -f "$staging_bin" "$dest_bin"
  chmod +x "$dest_bin"
  nohup "$dest_bin" > /dev/null 2>&1 &
  exit 0
  ```
- **Android:** Launch `ACTION_VIEW` or `PackageInstaller` intent for the staged APK.

### 2. Autostart on Boot
- **Windows:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
- **macOS:** Create LaunchAgent plist in `~/Library/LaunchAgents/id.alienai.agent.plist`:
  ```xml
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  ```
- **Linux:** Create systemd user service in `~/.config/systemd/user/alienai-agent.service`:
  ```ini
  [Service]
  ExecStart=%h/.local/bin/c_remote_linux
  Restart=always
  [Install]
  WantedBy=default.target
  ```
- **Android:** Register a `BroadcastReceiver` listening for `android.intent.action.BOOT_COMPLETED` to start a Foreground Service.

### 3. Screen, Audio & Input Handlers
Bind them to `c_remote_core::webrtc` in `main.rs`:
```rust
c_remote_core::webrtc::set_input_handler(Arc::new(execute_input));
c_remote_core::webrtc::set_screen_handler(Arc::new(start_screen_stream));
c_remote_core::webrtc::set_screenshot_handler(Arc::new(capture_screen_jpeg));
```

### 4. Input Channel `apply_update` Handler
In your platform's `execute_input` function:
```rust
if evt.event_type == "apply_update" {
    if let Some(v) = c_remote_core::update::update_staged_version() {
        let _ = c_remote_core::update::update_apply(v);
    }
}
```
This ensures the on-screen **Update Agent** button in the Flutter appbar works identically across all operating systems.
