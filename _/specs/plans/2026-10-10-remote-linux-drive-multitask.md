# Remote Linux agent + cross-platform Alien AI Drive — master multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Checkbox tasks are source of truth.

**Goal:** Ubuntu/Debian **x86_64** remote agent (`type=linux`) with WebRTC/WS/Files/shell/OTA; **Alien AI Drive** on Linux (FUSE, label **Alien AI**, icon) and Android (DocumentsProvider + sync), reusing **`c_remote_core`** + **`c_remote_drive`**. Bytes on **HTTP/CAS**; **NATS** `c35.user.{owner}.drive-sync` wake only.

**Specs:** [`remote-linux.md`](../remote-linux.md), [`drive.md`](../drive.md), [`remote-android.md`](../remote-android.md), [`remote-agent.md`](../remote-agent.md)

## Global constraints

- Do not expose drive tree on WebRTC `remote-fs`.
- `drive_enabled` default **true** when paired.
- No `% used` in mount display name (Windows lock applies to Linux/Android labels).
- Verify: `cd remotes && cargo build -p c_remote_windows -p c_remote_drive -p c_remote_core`; add `c_remote_linux` when scaffolded.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`
- Do not commit unless user asks.

---

## Track 0 — Specs

- [x] `remote-linux.md` — targets, XDG paths, capture/input matrix
- [x] `drive.md` — v2 scope: Linux FUSE + Android provider; NATS vs HTTP table
- [x] `remote-android.md` — drive section (replace N/A)

## Track 1 — `c_remote_drive` multi-platform

- [x] `DriveMount` trait; `mount_windows.rs` (move WinFsp)
- [x] `mount_linux.rs` — FUSE over `backing_dir`, mount `$HOME/Alien AI`, `.directory` icon
- [x] `watch_linux.rs` (inotify); `runtime.rs` OS dispatch
- [x] Windows behavior unchanged — `cargo build -p c_remote_windows --lib` OK; full binary needs agent exe not running (link lock)

## Track 2 — `c_remote_linux` agent

- [x] Workspace member + `main.rs` (watchdog, handlers stub → real)
- [x] `c_remote_core::config` XDG on Linux
- [x] `pair_loop`, pair_ui/cli, systemd unit sample under `remotes/c_remote_linux/resources/`
- [x] `session_linux.rs` — Wayland vs X11 detect; `C35_LINUX_CAPTURE` / `C35_LINUX_INPUT` prefs
- [x] WebRTC screen: **xcap** + **portal/PipeWire** (`capture/portal_pipewire.rs`, `capture/mod.rs`) — **VM validate** on GNOME Wayland (build needs `libpipewire-0.3-dev`) — [`2026-10-10-linux-wayland-portal.md`](2026-10-10-linux-wayland-portal.md)
- [x] WebRTC input: **enigo** (X11) + **libei**/`reis` (`input/libei_backend.rs`) — VM validate on GNOME/KDE; **uinput** fallback optional / X11-only (not Wayland default)
- [x] Wayland packaging/docs — `apply.sh`, `remote-linux.md` §4–§6, `smoke_remote_linux_wayland.md`
- [x] `fs_linux.rs` + `linux_shell.rs` (register hooks)
- [x] `drive/` wired to `c_remote_drive::runtime` + `ws_drive` (post–Track 1; FUSE at runtime on Linux only)
- [x] `build_remote_linux.dart` skeleton — **upload/publish scripts** still TODO

## Track 3 — Android drive

- [x] `c_remote_drive` in android crate; sync via `mount_android.rs`
- [x] `register_ws_drive_sync_handler` on agent ready
- [x] Kotlin `AlienDriveDocumentsProvider` + manifest
- [x] Config toggle `drive_enabled` (shared with Windows)

## Track 4 — App / server

- [x] Flutter `linux` device type — icon + row subtitle (`ui_device_kind_icon`, `ui_device_row`)
- [x] WS relays `c35.user.{owner_iid}.drive-sync` per owner (not device-type gated) — no server change

## Wave order

```text
A: Track 0 + Track 1.1–1.3 (parallel)
B: Track 2.0–2.3 + Track 3.1–3.2 (parallel)
C: Track 2.4–2.8 + Track 3.3–3.5
D: E2E manual Ubuntu VM + publish scripts smoke
```
