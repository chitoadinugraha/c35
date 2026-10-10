# Smoke: Linux remote agent on Wayland (manual E2E)

Run on **Ubuntu 22.04/24.04 amd64** with a normal graphical login (not SSH-only).

## Prerequisites

From the agent OTA bundle or repo `remotes/c_remote_linux/resources/`:

```bash
chmod +x apply.sh
./apply.sh
```

(`apply.sh` detects Wayland and installs portal + PipeWire + libei. For KDE: `DESKTOP_PORTAL_BACKEND=kde ./apply.sh`.)

```bash
systemctl --user enable --now pipewire pipewire-pulse  # if not already active
loginctl enable-linger "$USER"                        # headless / logout survival
```

Install agent to `~/.local/bin/c_remote_linux` and enable `alienai-agent.service` (see [`remote-linux.md`](../../specs/remote-linux.md)).

## Checklist

1. **Session** — `echo $XDG_SESSION_TYPE` → `wayland`.
2. **Pair** — claim device from Alien AI app; agent shows paired in logs.
3. **Screen** — open Remote tab; on Linux desktop approve **Screen Share** when prompted.
4. **Stream** — live image is not black; mouse move updates cursor.
5. **Input** — click/type in a test window (libei: `LIBEI_SOCKET` after portal consent; X11 session uses enigo via `./apply.sh` on X11).
6. **Files** — Files tab lists `/` and `$HOME` but **not** `~/Alien AI` mount path.
7. **Drive** — `~/Alien AI` mount visible in file manager; file sync to another device.
8. **OTA** — staged update applies via `apply.sh` and service restarts.

## Debug env

```bash
export C35_LINUX_CAPTURE=portal   # or xcap, auto
export C35_LINUX_INPUT=libei      # or enigo, auto
journalctl --user -u alienai-agent.service -f
```
