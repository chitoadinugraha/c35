# Linux Remote Agent Architecture (`type=linux`)

Status: **Locked architectural specification** (2026-10-10)  
Platform targets: **Ubuntu 22.04 LTS / 24.04 LTS** and **Debian 12 (bookworm)** on **amd64 (x86_64)** only for v1.  
Binary: `c_remote_linux` in `remotes/c_remote_linux` — shares **`c_remote_core`** with Windows/Android.

Related: [`remote-agent.md`](remote-agent.md), [`remote.md`](remote.md), [`drive.md`](drive.md), [`auto-update.md`](auto-update.md).

---

## 1. Goals

| Goal | Approach |
|------|----------|
| Same control + data planes as Windows | Agent WebSocket + WebRTC (`remote-input`, `remote-screen`, `remote-fs`) |
| Owner cloud files on desktop | **Alien AI Drive** — FUSE mount at **`$HOME/Alien AI`** (label **Alien AI**), HTTP/CAS sync via `c_remote_drive` |
| Device file browse in app | WebRTC **`remote-fs`** over **real disk paths** — **never** the drive mount or backing cache |
| Unattended pairing | systemd **user** unit, OTA via `c35.release.remote-linux` |

---

## 2. XDG layout (locked)

All paths follow [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html). Config and secrets live under **config**; caches, drive backing, and OTA staging under **data**.

| Path | XDG / convention | Role |
|------|------------------|------|
| `$XDG_CONFIG_HOME/AlienAI/config.json` | Default `~/.config/AlienAI/config.json` | Pairing, `session_key` (encrypted when platform supports it), `drive_enabled`, `device_iid` |
| `$XDG_DATA_HOME/AlienAI/` | Default `~/.local/share/AlienAI/` | Agent state root |
| `.../drive_a/` | Under data home | **Backing cache** for Alien AI Drive (FUSE source tree) — not user-facing mount point |
| `.../sync_manifest.json` | Sibling of `drive_a/` | Agent-only sync manifest ([`drive.md`](drive.md)) |
| `.../system/` | Sibling of `drive_a/` | Reserved agent subtree (not on FUSE mount) |
| `.../updates/` | Under data home | OTA staging (`.ready` marker) — same pattern as other platforms |
| `$HOME/Alien AI` | User-visible | **FUSE mount point** — volume display name **Alien AI** only (no `· N% used` suffix; same lock as Windows in [`drive.md`](drive.md)) |
| `$HOME/.local/bin/c_remote_linux` | Install target | Released binary location (publish script may use `/opt` wrapper; user service points here) |

**Config keys** (same semantics as Windows):

| Key | Default | Behavior |
|-----|---------|----------|
| `drive_enabled` | **`true`** | On paired start: layout, quota fetch, FUSE mount when true |
| `session_key` | (paired) | Device session for drive HTTP + agent WS |

`C35_AGENT_STORAGE` optional subdir under config/data roots matches `c_remote_core::config` (browser sidecar pattern).

---

## 3. systemd user service

Autostart and crash restart use a **user** unit (no root). Sample ships under `remotes/c_remote_linux/resources/alienai-agent.service`:

```ini
[Unit]
Description=Alien AI Remote Agent (Linux)
After=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/c_remote_linux
Restart=always
RestartSec=3
Environment=XDG_RUNTIME_DIR=%t

[Install]
WantedBy=default.target
```

Enable after pair:

```bash
systemctl --user daemon-reload
systemctl --user enable --now alienai-agent.service
```

Loginctl **linger** may be required so the user service survives logout on headless boxes (`loginctl enable-linger "$USER"`). Sleep inhibition during active remote sessions uses **`systemd-inhibit`** or D-Bus (see [`remote-agent.md`](remote-agent.md)).

---

## 4. Screen capture matrix

Prefer **Wayland** portals; fall back to **X11** when no compositor portal is available.

| Environment | Capture backend | Rust (linux target) | Notes |
|-------------|-----------------|---------------------|-------|
| Wayland (GNOME, KDE, ...) | **PipeWire** via `xdg-desktop-portal` **ScreenCast** | **`ashpd`** + **`pipewire`** (`capture/portal_pipewire.rs`) | User consent dialog; PipeWire FD from portal |
| X11 | Shared memory / X11 root window | **`xcap`** (`screen_capture.rs`, shipped) | No portal; legacy sessions |
| Headless / no seat | Stub or error surfaced to viewer | — | Remote screen requires a graphical session |

**Debian/Ubuntu packages (Wayland):** `xdg-desktop-portal`, **`xdg-desktop-portal-gnome`** or `xdg-desktop-portal-kde`, **`pipewire`**, `pipewire-pulse`, `wireplumber`, `dbus-user-session`. Install script (session-aware): [`remotes/c_remote_linux/resources/apply.sh`](../../remotes/c_remote_linux/resources/apply.sh).

**Build (Linux host):** `libpipewire-0.3-dev`, `pkg-config` — required to compile `capture/portal_pipewire.rs`. Windows dev builds skip Linux-only capture (`cfg(target_os = "linux")`).

**Override:** `C35_LINUX_CAPTURE=portal|xcap|auto` (default **auto** — portal first; xcap fallback only on non-Wayland). See [`session_linux.rs`](../../remotes/c_remote_linux/src/session_linux.rs).

WebRTC ships **JPEG** over `remote-screen` and optional **H.264** RTP when encoder + portal pipeline support it (parity goal with Windows; v1 may JPEG-only until encode path lands).

---

## 5. Audio

| Environment | Capture | Packages / tools |
|-------------|---------|------------------|
| PipeWire default | PulseAudio compatibility / native PipeWire loopback | **`pipewire`**, **`pipewire-pulse`**, **`wireplumber`** |
| PulseAudio-only | `parec` / PA monitor source | `pulseaudio-utils` |

Audio capture is **not** required for v1 remote view; ship when viewer needs desktop sound.

---

## 6. Input injection (`remote-input` + automation)

| Priority | Backend | Rust (linux target) | When |
|----------|---------|---------------------|------|
| 1 | **libei** (Emulated Input) | **`reis`** or libei FFI (`input/libei_backend.rs`, `input/shared.rs`) | Wayland — compositor EI portal |
| 2 | **`enigo`** | **`enigo`** (`input_exec.rs`, shipped) | X11 sessions |
| 3 | **`/dev/uinput`** | **`evdev`** / **`uinput`** (`input_uinput.rs`, planned) | libei denied; requires `input` group or udev rule |

**Debian/Ubuntu packages:** **`libei1`** (with portal stack above). Optional X11 tools are not used on Wayland. Wayland input needs LIBEI_SOCKET from xdg-desktop-portal Remote Desktop (no /dev/uinput fallback on Wayland).

**Override:** `C35_LINUX_INPUT=libei|enigo|auto` (default **auto** — libei on Wayland, enigo on X11).

Same **`RemoteInputEvent`** protobuf and `input_exec` entrypoint as Windows — human Remote tab and server-pushed automation converge on one executor ([`remote.md`](remote.md)).

`apply_update` on the input channel triggers `c_remote_core::update::update_apply` like other agents.

---
## 7. WebRTC `remote-fs` (Files tab)

Human file browse uses the shared **`remote-fs`** SCTP channel and `RemoteFs*` protobuf frames ([`remote.md`](remote.md#files-tab--browse-copy-stream)).

### Root listing (`path == ""`)

List **POSIX mount roots** the agent can read (e.g. `/`, `/home/{username}`) with `RemoteFsDriveKind` set from mount metadata (`Fixed`, `Removable`, etc.). Paths on the wire use **UTF-8** with `/` separators.

### Hard exclusions (locked)

| Path / tree | On `remote-fs`? |
|-------------|-----------------|
| `$HOME/Alien AI` (FUSE mount) | **No** — cloud drive is [`drive.md`](drive.md), not device Files |
| `$XDG_DATA_HOME/AlienAI/drive_a/` (backing cache) | **No** |
| `.../system/` agent subtree | **No** |

Drive bytes are **never** listed, read, or written through WebRTC. Users open cloud files via the desktop mount or the app drive browser (HTTP-backed), not the Files tab.

### Path rules

- Reject `..` above the resolved root; normalize `.` and `//`.
- Mutations follow the same chunk + session gate as [`ui.md`](ui.md#files-tab-remote).

Implementation: Linux-specific delegate behind `c_remote_core::webrtc::fs` (Track 2) — not the Windows `list_drives()` A–Z logic.

---

## 8. `shell.run` (control plane)

Task/skill **`shell.run`** uses the agent **control** WebSocket (`ReqRemoteCommand`) — **not** WebRTC.

| Platform | Executor | Policy |
|----------|----------|--------|
| Windows | PowerShell | [`remote.md`](remote.md) |
| Linux | `/bin/bash -c` or `/bin/sh -c` | **Allowlist only** — deny by default; stderr names rejected command |
| Android | `/system/bin/sh -c` | [`remote-android.md`](remote-android.md#9-shellrun-control-plane) |

Linux is **not** an arbitrary root shell. Approved categories (exact list ships with agent code) include read-only diagnostics such as `uname -a`, `df -h`, `systemctl --user status alienai-agent.service`, `journalctl --user -u alienai-agent.service -n 50`, and documented `ls`/`cat` under user home — expanded in `linux_shell.rs`, not duplicated in chat inst bodies.

---

## 9. Alien AI Drive on Linux

| Item | Detail |
|------|--------|
| Crate | Shared **`c_remote_drive`** (`mount_linux.rs` FUSE over `drive_a` backing) |
| Mount | **`$HOME/Alien AI`** — `.directory` / icon metadata for file managers |
| Sync | Same HTTP API as Windows ([`drive.md`](drive.md)); wake via NATS `c35.user.{owner_iid}.drive-sync` only |
| Watcher | `inotify` on backing dir (debounced) — [`plans/2026-10-05-drive-sync-efficient.md`](plans/2026-10-05-drive-sync-efficient.md) |
| Toggle | `drive_enabled: false` → stop sync, unmount FUSE; cache may remain |

---

## 10. OTA and release

| Item | Detail |
|------|--------|
| Version endpoint | `GET /version/remote-linux` → `app.release.c35.remote-linux` |
| NATS | `c35.release.remote-linux` → agent WS wake |
| Apply | `apply.sh` copy to `~/.local/bin`, chmod +x, restart user service |

---

## 11. Verification (when implemented)

- `cd remotes && cargo build -p c_remote_linux -p c_remote_drive -p c_remote_core`
- Paired VM: Files tab lists `/home/...` but **not** `Alien AI` mount path
- Drive: file round-trip via FUSE + second device pull; label **Alien AI** without quota percentage in display name
- Publish: `_/scripts/deploy/publish_remote_linux.ps1` when shipped (mirror `publish_remote_windows`)
