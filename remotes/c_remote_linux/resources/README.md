# c_remote_linux resources

## Runtime install (`apply.sh`)

On Ubuntu 22.04/24.04 or Debian 12 desktop, from this directory:

```bash
chmod +x apply.sh
./apply.sh
```

The script detects **Wayland vs X11** (same signals as the agent: `XDG_SESSION_TYPE`, then `WAYLAND_DISPLAY` / `DISPLAY`) and installs only what that session needs:

| Session | Packages (apt) |
|---------|----------------|
| **Wayland** | `dbus-user-session`, `fuse3`, `xdg-desktop-portal`, portal backend (`gnome` or `kde`), `pipewire`, `pipewire-pulse`, `wireplumber`, `libei1` |
| **X11** | `dbus-user-session`, `fuse3`, `libx11-6`, `libxcb1`, `libxtst6` (capture/input use **xcap** / **enigo**) |

**Overrides**

- `C35_LINUX_SESSION=wayland|x11|auto` — force or auto-detect (use when installing over SSH with no display).
- `DESKTOP_PORTAL_BACKEND=kde` — KDE portal backend (default `gnome`).
- `C35_LINUX_APPLY_BUILD_DEPS=1` — also install `libpipewire-0.3-dev` and `pkg-config` (compile portal capture on the host).

See [`_/specs/remote-linux.md`](../../../_/specs/remote-linux.md) §4–§6.

## Building the agent on Linux (portal capture)

```bash
C35_LINUX_APPLY_BUILD_DEPS=1 ./apply.sh
# or: sudo apt install -y libpipewire-0.3-dev pkg-config
cd remotes && cargo build -p c_remote_linux --release
```

## systemd

Sample user unit: [`alienai-agent.service`](alienai-agent.service). Set `Environment=XDG_RUNTIME_DIR=%t` when using portal capture from systemd.
