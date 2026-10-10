# Linux Wayland — portal screen + libei input (locked plan)

**Specs:** [`remote-linux.md`](../remote-linux.md) §4–§6 · **Code:** `remotes/c_remote_linux/`

## Goal

On **Wayland** (GNOME, KDE, …), `c_remote_linux` captures through **xdg-desktop-portal ScreenCast** → **PipeWire** (`ashpd` + `pipewire`), and injects input through **libei** (`reis`). **X11** keeps **xcap** + **enigo**. No root, no compositor bypass.

## Architecture

| Layer | Wayland | Fallback |
|-------|---------|----------|
| Screen | `ashpd` ScreenCast + `pipewire` | `xcap` (X11) |
| Input | `libei` / `reis` (connect on VM) | `enigo` (X11) |
| Env | `C35_LINUX_CAPTURE=portal\|xcap\|auto` | `C35_LINUX_INPUT=libei\|enigo\|auto` |

User approves **Screen sharing** on the Linux desktop when the viewer connects.

## Rust modules

| Module | Role |
|--------|------|
| `session_linux.rs` | Session detect + backend choice |
| `capture/portal_pipewire.rs` | Portal + PipeWire |
| `capture/xcap.rs` | X11 capture |
| `input/libei_backend.rs` | libei via reis (shipped; VM validate) |
| `input/enigo_backend.rs` | X11 input |

## Debian/Ubuntu packages

Install via [`remotes/c_remote_linux/resources/apply.sh`](../../remotes/c_remote_linux/resources/apply.sh) or:

```bash
sudo apt install -y dbus-user-session xdg-desktop-portal xdg-desktop-portal-gnome \
  pipewire pipewire-pulse wireplumber libei1 fuse3
```

KDE: `DESKTOP_PORTAL_BACKEND=kde ./apply.sh` (uses `xdg-desktop-portal-kde`).

## Verification

- `cd remotes && cargo build -p c_remote_linux`
- Wayland VM: [`_/scripts/dev/smoke_remote_linux_wayland.md`](../../scripts/dev/smoke_remote_linux_wayland.md)

## Remaining (VM-gated)

1. Validate PipeWire stream link on Ubuntu 24.04 GNOME (portal FD).
2. VM-validate libei input (LIBEI_SOCKET, coords).
3. Optional: `uinput` fallback (X11 only, documented opt-in).
