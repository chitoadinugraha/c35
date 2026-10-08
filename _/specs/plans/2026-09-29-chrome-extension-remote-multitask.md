# Chrome extension remote (daily Chrome profile) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review before each wave. Playwright remote browser: [_/specs/browser-remote.md](../browser-remote.md). This plan adds **extension + native host** for strict sites (CF, e-Puskesmas) on the **user’s default Chrome profile**.

**Goal:** Ship **Alien AI Remote (Chrome extension)** + **native messaging host** (same `alienai_remote_browser.exe`) so users browse in **daily Chrome** (saved logins), pair via **web page + app code**, stream/control through **existing WebRTC Rust path**, and **OTA** like `remote-browser` / `remote-windows`. Public **download + install** on alienai.id (no Web Store required).

**Architecture (locked for this plan):**

```text
Flutter app  <--WebRTC (unchanged)-->  alienai_remote_browser.exe
                                              ^ Native Messaging (stdio)
Google Chrome (default profile)  +  MV3 extension
```

- **Playwright `browser_engine`:** keep for `meta.engine=playwright` devices; extension mode does not spawn Node for human Remote.
- **JPEG → `BrowserState::set_frame` → `browser_video.rs` → `c_remote_core::webrtc`:** reuse; frames from extension capture, not IPC screencast.
- **Pairing:** same HTTP `pair/register` + `pair/poll` + app claim; UX = extension opens **`https://alienai.id/device/pair/chrome-extension?code=…`** (secret stays in native host).

**Tech stack:** MV3 extension (`clients/chrome_extension/alienai_remote/`), Rust (`c_remote_browser` native host + frame ingress), `wire_http` static + version routes, Dart publish (`deploy_remote/`), Flutter Devices (`meta.browser_engine`).

**Global constraints**

- UI label: **Chrome extension** or **Chrome Remote**; `identity.type` stays `browser`; distinguish with `meta.browser_engine`: `playwright` | `extension`.
- No Web Store v1; ship **unpacked folder + optional `.crx` + `update_url`** for silent extension updates after OTA.
- Native host registry: `com.alienai.c35.remote` (name TBD in manifest).
- IPC/native messaging: no cloud credentials in extension; `session_key` only in Rust config on disk.
- Verify: `cargo build -p c_remote_browser`; extension `npm run build` (if TS); `cargo build -p server_ai` for routes; `flutter analyze` when app touched.
- Do not commit unless user asks.

---

## Deliverables summary

| Deliverable | User-visible |
|-------------|----------------|
| MV3 extension | Icon in Chrome; Pair; “Remote this tab” / auto when app connects |
| Native host + installer | Registers NM; bundles with remote-browser OTA or extension zip |
| Pair web page | `/device/pair/chrome-extension` — large code, link to app |
| Download web | `/download/chrome-extension` page + zip/crx links; hero link on `index.html` |
| OTA | `app.release.c35.chrome-extension`, `GET /version/chrome-extension`, NATS `c35.release.chrome-extension` |
| App | Devices row shows engine; Update when version &lt; release; Remote tab unchanged |

---

## Master wave map

| Wave | Name | Tracks | Depends | Ship criterion |
|------|------|--------|---------|----------------|
| CE-W1 | Spec + scaffold | A doc, B extension skeleton, C NM host stub | — | Load unpacked; ping native host |
| CE-W2 | Pairing | D pair web page, E extension+host pair loop | W1 | Claim in app; `session_key` on disk |
| CE-W3 | Video path | F capture, G Rust frame ingress, H idle throttle | W2 | WebRTC video in app (extension device) |
| CE-W4 | Input + tabs | I tab list/activate, J input DC → extension | W3 | Switch tabs; click/type on non-CF test page |
| CE-W5 | Web download | K download page, L wire routes + index link | W1 | User downloads zip from alienai.id |
| CE-W6 | OTA publish | M version file, N publish script, O agent update apply | W1,W5 | `publish_*` + smoke; extension files updated |
| CE-W7 | App + server | P device meta, Q needs_update, R optional tools route | W3 | device_list shows extension + update |
| CE-W8 | Polish | S self-hosted `update_url`, T Chito auto-install script | W6 | Policy/crx update on your PC |

Parallel dispatch: **W1(A+B+C)**; **W2(D+E)**; **W3(F+G then H)**; **W4(I+J)**; **W5(K+L)** can start after W1; **W6(M+N+O)** after W5; **W7(P+Q)** after W3; **W8(S+T)** last.

---

# CE-W1 — Spec + scaffold

## Track A — `browser-extension.md`

Files: `_/specs/browser-extension.md`, `spec.md` (index row), `_/specs/browser-remote.md` (defer → link)

- [x] A.1 Locked: planes, pairing, NM host name, daily profile warning, OTA keys, no anti-bot claims.
- [x] A.2 Diagram: extension ↔ native host ↔ Rust WebRTC; coexistence with Playwright engine.
- [x] A.3 Security: active tab only; owner pair; no extension network to cluster.

## Track B — Extension package

Files: `clients/chrome_extension/alienai_remote/manifest.json`, `src/service_worker.ts`, `src/popup.html`, `README.md`, `package.json` + esbuild

- [ ] B.1 MV3: `nativeMessaging`, `tabs`, `tabCapture` or `activeTab`, `scripting`, `storage`.
- [ ] B.2 `externally_connectable`: `https://alienai.id/*` for pair page ↔ extension messages.
- [ ] B.3 Popup: Pair, connection status, link to install help.
- [ ] B.4 Build outputs to `dist/`; gitignore `dist/` if needed; UTF-8 only (no Cursor Write on `.ts` without verify).

## Track C — Native messaging host (Rust)

Files: `remotes/c_remote_browser/src/chrome_native/` (new), `main.rs` subcommand `chrome-native-host`

- [ ] C.1 Chrome NM framing: 4-byte LE length + JSON (match Chrome docs).
- [ ] C.2 Commands: `ping`, `pair.start`, `pair.status`, `frame` (ingress later), `tabs.list` (later).
- [ ] C.3 Windows: install manifest template under `_/deployments/remote_browser/native_host/`.
- [ ] C.4 `cargo build -p c_remote_browser`.

**Review gate CE-W1:** Chito loads unpacked extension; `ping` returns OK from popup.

---

# CE-W2 — Pairing

## Track D — Pair web page (hosted)

Files: `clients/web/device-pair-chrome-extension.html`, `servers/crates/wire_http/src/web.rs`, `sitemap.xml`

- [ ] D.1 Route `/device/pair/chrome-extension` (+ optional `.html`).
- [ ] D.2 Query `?code=XXXXX-XXXXX`; large typography; i18n optional later.
- [ ] D.3 Copy: “Open Alien AI → Devices → Pair with code”; optional live status via `postMessage` from extension (`pairing` / `paired` / `error`).
- [ ] D.4 No `secret` in URL or page — host polls only.

## Track E — Pair loop (host + extension)

Files: `chrome_native/pair.rs`, extension `pair.ts`, reuse `c_remote_core::pair::*`

- [ ] E.1 `pair.start`: `pair_register` with `device_type: "browser"`, `meta.browser_engine: "extension"`.
- [ ] E.2 Open tab to pair page with public `code`.
- [ ] E.3 Background poll `pair_poll`; on claim persist `config.json` + `device_iid`; notify extension.
- [ ] E.4 Start agent WS (`conn_ws`) same as `pair_loop.rs` after claim.
- [ ] E.5 Manual test: app claim 99000 device; row appears as browser + extension.

**Review gate CE-W2:** End-to-end pair without Rust pair window.

---

# CE-W3 — WebRTC video (reuse Rust)

## Track F — Extension capture

Files: extension `capture.ts`, offscreen doc if required by MV3

- [ ] F.1 `captureVisibleTab` or `tabCapture` → JPEG (quality ~65); max 15 fps (env `C35_BROWSER_JPEG_MAX_FPS`).
- [ ] F.2 Send `{ type: "frame", width, height, jpeg_b64 }` to native host only when WebRTC viewer active (message from host).
- [ ] F.3 Pause capture when host says `screencast.stop` (idle).

## Track G — Rust frame ingress

Files: `browser_state.rs`, `chrome_native/mod.rs`, `webrtc/browser_video.rs` (minimal or no change)

- [ ] G.1 On NM `frame`, decode JPEG → `BrowserState::set_frame(w, h, bytes)`.
- [ ] G.2 Engine mode flag: `ExtensionEngine` vs `PlaywrightEngine`; skip `spawn_engine` when extension mode.
- [ ] G.3 `browser_video` loop unchanged (latest_frame → H.264).

## Track H — Idle / sessions

Files: `browser_idle.rs` or extension-specific idle

- [ ] H.1 When `active_sessions == 0`, NM `capture.stop` to extension (save CPU).
- [ ] H.2 On WebRTC connect, `capture.start` with active tab id.

**Review gate CE-W3:** Remote tab shows live video for extension-paired device.

---

# CE-W4 — Tabs + input

## Track I — Tab strip source

Files: extension `tabs.ts`, `browser_tabs.rs` or WS handler routing

- [ ] I.1 `tabs.list` / `tabs.activate` / `tabs.new` / `tabs.close` over NM → same JSON shape as Playwright `tab.list` IPC.
- [ ] I.2 Flutter `browserInvoke` unchanged if server routes `c35.browser.tab` to extension agent.

## Track J — Remote input

Files: extension `input.ts`, existing `remote-input` DC in Rust

- [ ] J.1 v1: map DC events to NM → `chrome.scripting` click/fill at coordinates OR `debugger` Input.* (document detectability in `browser-extension.md`).
- [ ] J.2 Prefer **view-only** flag for CF login flows first; enable full input on allowlist sites if needed.

**Review gate CE-W4:** Tab switch does not kill IPC; input works on simple test page.

---

# CE-W5 — Web download (user-facing)

## Track K — Download landing page

Files: `clients/web/download-chrome-extension.html`, copy blocks

- [ ] K.1 Sections: Install native host (link `agent.exe` or dedicated `chrome-remote-setup.exe` if split), Load extension (unpacked path), Pair, Troubleshooting.
- [ ] K.2 Link to `/device/pair/chrome-extension` after pair.
- [ ] K.3 Requirements: Chrome desktop, Windows (v1), Alien AI app for pair.

## Track L — Routes + index

Files: `wire_http/src/web.rs`, `clients/web/index.html`, `sitemap.xml`

- [ ] L.1 `GET /download/chrome-extension` → landing page.
- [ ] L.2 `GET /download/chrome-extension.zip` → CAS blob or staged static from publish (same pattern as `alienai.zip`).
- [ ] L.3 Optional `GET /download/chrome-extension.crx` for policy/update_url users.
- [ ] L.4 Hero card on `index.html` next to Remote Control: “Chrome extension (daily profile)”.
- [ ] L.5 `cargo test -p c35_wire_http` static file exists test.

**Review gate CE-W5:** Public URL downloadable without login.

---

# CE-W6 — OTA publish

## Track M — Version product

Files: `clients/chrome_extension/VERSION`, `deploy_remote/agent_version.dart` (`RemoteAgentProduct.chromeExtension`), `agent_version.dart` config key

- [ ] M.1 `app.release.c35.chrome-extension` JSON: `version`, `versionName`, `hash`, `size`, `url`, `min`.
- [ ] M.2 `GET /version/chrome-extension` mirror `remote-browser` handler.

## Track N — Publish script

Files: `deploy_remote/build_chrome_extension.dart`, `upload_chrome_extension_release.dart`, `publish_chrome_extension_version.dart`, `publish_chrome_extension.ps1`, `nats_broadcast_chrome_extension_release.ps1`

- [ ] N.1 Zip: `dist/` extension + `native_host/*.json` + README; Blake3; CAS upload.
- [ ] N.2 Optional: pack `.crx` with repo-held private key (document in `_/deployments/`).
- [ ] N.3 Bump `VERSION`; smoke script `smoke_chrome_extension_release.ps1`.

## Track O — Agent apply

Files: `c_remote_core/update.rs`, `apply.ps1` template in OTA zip

- [ ] O.1 Poll `/version/chrome-extension` when device `browser_engine=extension` (or always).
- [ ] O.2 Apply: extract to `%LOCALAPPDATA%\AlienAI\chrome_extension\`; update NM manifest if needed; `chrome.runtime.reload` via NM ping extension.
- [ ] O.3 NATS `c35.release.chrome-extension` → `trigger_background_update`.

**Review gate CE-W6:** Publish summary; version bump visible in app.

---

# CE-W7 — App + cluster

## Track P — Identity meta

Files: `_/schemas/identity.sql` (doc only), pair register body, Flutter device row

- [x] P.1 `meta.browser_engine`: `extension` | `playwright` (default playwright for old agents).
- [x] P.2 Icon/badge “Chrome” vs “Automated” in `ui_device_row.dart`.

## Track Q — needs_update

Files: `mod_device` / `client_list_http` pattern, extension version compare

- [x] Q.1 `device_list` / HTTP: `needs_update` vs `app.release.c35.chrome-extension`.
- [ ] Q.2 Toolbar Update triggers extension OTA + host restart if bundled.

## Track R — Tools (defer heavy)

Files: `mod_chat` device_context, `browser_tabs` WS

- [ ] R.1 Route `browser.tabs` / `browser.page.observe` to extension NM when engine=extension.
- [x] R.2 Defer `browser.task.run` Playwright steps on extension devices (return clear error or hide tools).

**Review gate CE-W7:** Two device types visible; update badge works.

---

# CE-W8 — Chito machine + update_url

## Track S — Self-hosted extension updates

Files: `clients/web/chrome-extension-updates.xml`, `wire_http` route, manifest `update_url`

- [ ] S.1 Manifest field: `"update_url": "https://alienai.id/chrome-extension/updates.xml"`.
- [ ] S.2 XML points to versioned `.crx` on CAS.
- [ ] S.3 Publish bumps XML + crx hash.

## Track T — Auto-install script (Chito)

Files: `_/scripts/deploy/install_chrome_extension_chito.ps1` (or documented in `browser-extension.md`)

- [ ] T.1 Register native host (current user).
- [ ] T.2 Copy extension to `%LOCALAPPDATA%\AlienAI\chrome_extension\`.
- [ ] T.3 Optional: `ExtensionInstallForcelist` + packed crx for **default profile** (document Chrome must be closed for policy first run).
- [ ] T.4 Open `chrome://extensions` with instruction once.

**Review gate CE-W8:** e-Puskesmas login in daily Chrome + Remote stream from app.

---

## Out of scope (this plan)

- Chrome Web Store listing.
- macOS/Linux native host (Windows first).
- WebRTC Files tab.
- Replacing Playwright entirely.
- `shell.run` on extension devices.

---

## Verification checklist (final)

- [ ] Pair via web page + app code (99000 test + Chito).
- [ ] `https://malang.epuskesmas.id/login` in **daily Chrome** with extension (human login).
- [ ] Remote video + tab strip in app.
- [ ] Download page works; OTA bump applies extension files.
- [ ] `flutter analyze`; `cargo build -p server_ai`; `cargo build -p c_remote_browser`.

---

## Publish commands (when shipping)

```powershell
.\_\scripts\deploy\publish_chrome_extension.ps1   # new; mirror publish_remote_browser.ps1
# Host binary still:
.\_\scripts\deploy\publish_app_release.ps1 -RemoteBrowser
```

**Publish summary targets:** `chrome-extension` (zip/crx), optionally bundled `remote-browser` if exe changed.
