# Alien AI Chrome extension (Remote)

MV3 extension for **daily Chrome profile** remote control. Talks to `alienai_remote_browser.exe` via native messaging host `com.alienai.c35.remote`; WebRTC and pairing live in the Rust agent (see `_/specs/plans/2026-09-29-chrome-extension-remote-multitask.md`).

## One-click install (Windows, Chito profile)

From repo root:

```powershell
.\_\scripts\deploy\build_chrome_extension_local.ps1
.\.cache\chrome_extension\install\Install-AlienAI-Chrome-Remote.ps1
```

1. **Fully quit Chrome** (all windows).
2. Run the **Install** script — registers native host, policy-installs the packed extension, adds login agent shortcut.
3. Reopen Chrome → `chrome://extensions` should show **Alien AI Remote** (ID `nnijloaplkijpadhmifhleodobafjffi`).
4. Run `%LOCALAPPDATA%\AlienAI\chrome_extension\install\agent\Start-ChromeRemoteAgent.cmd`.
5. Extension popup → **Test native host** → **Pair device** → claim in the app.

**Daily use:** normal **Google Chrome** (pinned extension). Do **not** use the desktop shortcut **Chrome (Alien AI Remote)** for browsing — it opens a **separate** Chrome with `--load-extension` and is only for one-time install troubleshooting.

If policy install does not appear, load unpacked once (see below); avoid the shortcut unless you fully quit Chrome first.

## Dev sync (install folder)

If Chrome loads `%LOCALAPPDATA%\AlienAI\chrome_extension\install\alienai_remote`:

```powershell
.\_\scripts\dev\sync_chrome_extension_install.ps1
```

Then **Reload** on `chrome://extensions`. JS-only: `-SkipBuild`. Extension-only copy: `-SkipAgentRestart` after a prior full sync.

**Agent automation (Nuphus MCP):** enable `nuphus-mcp` in `.cursor/mcp.json` (same as your global Cursor config), reload MCP in Cursor, then use browser tools to open `chrome://extensions`, reload extension ID `nnijloaplkijpadhmifhleodobafjffi`, and click the Alien AI Remote toolbar icon to verify the popup diagnostics.

## Load unpacked (dev only)

1. `install_chrome_extension_chito.ps1` with `-ExtensionId` after first load.
2. Or load `clients/chrome_extension/alienai_remote` manually in Developer mode.

## Layout

| Path | Role |
|------|------|
| `manifest.json` | MV3 permissions, `externally_connectable`, `update_url` |
| `dist/service_worker.js` | Native messaging, capture/tabs stubs |
| `dist/popup.html` / `popup.js` | Pair + status UI |

## Version

`../VERSION` — `1.0.0+1` (semver+build). OTA publish scripts (track M/N) zip `dist/` + host manifests.

## Build

v1 uses **plain JS in `dist/`** — no npm build required. Edit `dist/*.js` directly (UTF-8, no BOM).

## Updates

Manifest `update_url`: `https://alienai.id/chrome-extension/updates.xml` (template in `clients/web/chrome-extension-updates.xml`).