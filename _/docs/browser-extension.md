# Chrome extension remote (LOCKED)

Status: **locked** 2026-09-29

**Chrome extension remote** is a paired `kind=remote`, `type=browser` endpoint that uses the user's **default Google Chrome profile** (saved logins, cookies) instead of the isolated Playwright Chromium profile. User-facing labels: **Chrome extension** or **Chrome Remote**. Distinguish from Playwright remote browser via `meta.browser_engine`: `extension` | `playwright` (default `playwright` when absent).

Sibling specs: [browser-remote.md](browser-remote.md) (Playwright engine), [remote.md](remote.md) (desktop OS remote).

---

## Two planes (unchanged)

| Plane | Transport | Chrome extension |
|-------|-----------|------------------|
| **Control** | Agent WebSocket | Pairing, presence, tab/slot commands, OTA |
| **Data** (human) | **WebRTC** + data channels | Viewport video + remote input — same stack as desktop / Playwright browser |

Server stores **signaling + ICE only** on the data plane. The MV3 extension does **not** talk to the cluster over HTTPS for session secrets.

---

## Process architecture

```text
Flutter app  <-- WebRTC (unchanged) -->  alienai_remote_browser.exe (Rust)
                                              ^ Native Messaging (stdio JSON)
Google Chrome (default profile)  +  MV3 extension (tab capture, tabs, input)
```

| Component | Responsibility |
|-----------|----------------|
| **MV3 extension** | Pair UX, active-tab capture → JPEG, tab list/activate, input scripting; **no** `session_key`, **no** direct cluster API |
| **Native messaging host** | Chrome ↔ Rust bridge; name **`com.alienai.c35.remote`** (Windows registry manifest) |
| **`c_remote_browser` (Rust)** | Same binary as Playwright mode: pair loop, `session_key`, agent WS, WebRTC encode, OTA; **skips** Node `browser_engine` when `browser_engine=extension` |
| **Playwright `browser_engine`** | **Not used** for extension devices — coexistence: one user may have both a Playwright browser device and an extension browser device |

### Video path (locked)

1. Extension: `captureVisibleTab` / `tabCapture` → JPEG (~quality 65, max ~15 fps via `C35_BROWSER_JPEG_MAX_FPS`).
2. Native host: NM message `{ "type": "frame", "width", "height", "jpeg_b64" }`.
3. Rust: decode JPEG → `BrowserState::set_frame` → `browser_video.rs` → **H.264** → existing `c_remote_core::webrtc` hub.

Playwright CDP screencast and Node IPC are **not** on this path.

### Coexistence with Playwright remote browser

| | Playwright (`browser_engine=playwright`) | Extension (`browser_engine=extension`) |
|---|------------------------------------------|----------------------------------------|
| Chrome profile | `%LOCALAPPDATA%\AlienAI\browser\profile\` | User's **daily** Chrome profile |
| Engine process | Node + Playwright sidecar | None (extension + NM only) |
| `browser.task.run` | Supported (automation steps) | **Not supported** — use Remote tab; clear error from tools |
| Strict sites (CF, e-Puskesmas) | Often blocked / separate session | Human login in real Chrome |

---

## Pairing (locked)

Same HTTP contract as [remote.md § Pairing](remote.md#pairing):

| Step | Actor | Action |
|------|-------|--------|
| 1 | Native host | `POST /v1/device/pair/register` with `device_type: "browser"` and `meta_json` containing `"browser_engine":"extension"` |
| 2 | Host | Opens `https://alienai.id/device/pair/chrome-extension?code=XXXXX-XXXXX` (public code only) |
| 3 | User | Alien AI app → Devices → enter code (claim) |
| 4 | Host | `GET /v1/device/pair/poll` until `claimed`; persist `config.json` + `session_key` |
| 5 | Host | Agent WS (`conn_ws`) — same as Playwright `c_remote_browser` |

**Never** put `device_secret` or `session_key` in the pair page URL or extension storage synced to cloud.

---

## Identity & config

| Field | Value |
|-------|--------|
| `kind` | `remote` |
| `type` | `browser` |
| `meta.browser_engine` | `extension` \| `playwright` |
| Host config (extension mode) | `%LOCALAPPDATA%\AlienAI\chrome_extension\config.json` (path may match browser agent dir until OTA split) |
| Extension install dir (OTA) | `%LOCALAPPDATA%\AlienAI\chrome_extension\` |

Register body example:

```json
{
  "device_name": "Chito-PC-Chrome",
  "device_type": "browser",
  "meta_json": "{\"browser_engine\":\"extension\"}"
}
```

---

## OTA (locked keys)

| Piece | Value |
|-------|--------|
| Config key | `app.release.c35.chrome-extension` |
| HTTP | `GET /version/chrome-extension` (mirror `remote-browser` JSON shape) |
| NATS | `c35.release.chrome-extension` |
| Playwright browser OTA | `app.release.c35.remote-browser` — unchanged; extension devices compare **chrome-extension** release only |

Host binary may ship shared with `remote-browser` zip when bundled; extension zip adds `dist/`, NM manifest, and `update_url` (self-hosted updates — see CE-W8 plan).

---

## Security warnings (locked)

1. **Daily profile risk** — Extension mode controls the same Chrome profile the user uses for banking, health portals, and work SSO. Treat Remote input as **full user capability** on the active tab; prefer view-only on sensitive flows until input policy is explicit.
2. **Active tab only** — Capture and scripting apply to the **focused** tab the user (or Remote) selected; extension must not exfiltrate background tabs without tab APIs visible in UX.
3. **Owner pair only** — Devices claim to one `owner_iid`; no multi-tenant extension install.
4. **No cluster credentials in extension** — `session_key` and poll secrets live in Rust on disk; extension ↔ host only via native messaging.
5. **No anti-bot guarantees** — Daily Chrome helps **human** logins; Remote input may still be detectable on some sites (document in troubleshooting; do not promise undetectable automation).
6. **Supply chain** — Ship extension + host from alienai.id CAS/OTA only; unpacked load from documented path.

---

## App & MCP

- Devices list: badge **Chrome** vs **Automated** from `meta.browser_engine`.
- `device_list` / `device_list_http`: `release.needs_update` vs `app.release.c35.chrome-extension` when `browser_engine=extension`, else `remote-browser` for Playwright browser agents.

---

## Verification

- `cd remotes && cargo build -p c_remote_browser`
- `cd servers && cargo build -p server_ai` (pair meta + release keys)
- `flutter analyze` when app device UI touched
- Manual: pair via web page + app; Remote tab video from extension device (CE-W3+)

---

## Related plans

- [2026-09-29-chrome-extension-remote-multitask.md](plans/2026-09-29-chrome-extension-remote-multitask.md) — implementation waves
- [browser-remote.md](browser-remote.md) — Playwright engine (phase 1/2 plans)
