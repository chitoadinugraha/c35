# Chrome extension remote (LOCKED)

Status: **locked** 2026-09-29

**Chrome extension remote** is a paired `kind=remote`, `type=browser` endpoint that uses the user's **default Google Chrome profile** (saved logins, cookies) instead of the isolated Playwright Chromium profile. User-facing labels: **Chrome extension** or **Chrome Remote**. Distinguish from Playwright remote browser via `meta.browser_engine`: `extension` | `playwright` (default `playwright` when absent).

Sibling specs: [browser-remote.md](browser-remote.md) (Playwright engine), [remote.md](remote.md) (desktop OS remote).

Implementation plan for LLM automation on extension devices: [2026-09-29-chrome-extension-automation-multitask.md](plans/2026-09-29-chrome-extension-automation-multitask.md) (CE-A0 parity lock, CE-A1+ IPC RPC and MV3 observe/act).

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
| LLM `browser.*` tools | Full Playwright IPC surface | See **parity matrix** below (Remote-only today; automation in CE-A*) |

---

## LLM `browser.*` parity matrix (CE-A0)

Single cluster tool surface for `type=browser` devices. Branch on `meta.browser_engine` in server + agent (`servers/crates/mod_chat/src/tools/builtin/browser.rs`, `remotes/c_remote_browser/src/browser_command.rs`).

**Extension column values:** `yes` (parity or acceptable substitute), `subset` (partial / different semantics), `no` (blocked or not wired), `planned` (locked target in automation plan, not shipped).

| Cluster tool | Agent method | Playwright | Extension (shipped) | Extension (target CE-A*) | Notes |
|--------------|--------------|------------|------------------------|---------------------------|-------|
| `browser.tabs` | `tabs` | yes | **subset** | **yes** (subset) | Shipped: `list`, `activate` via extension IPC; `new` / `close` fail on agent. MV3 SW already has tab create/remove for IPC push — wired in CE-A3. Multi-window orchestration stays subset vs Playwright. |
| `browser.page.observe` | `page.observe` | yes | **no** | **subset** | Target: url/title + simplified DOM text slice (not full Playwright AX tree). CE-A2. |
| `browser.page.act` | `page.act` | yes | **no** | **subset** | Target: `click` / `fill` / `press` via `chrome.scripting` on active tab (CE-A2). Complements WebRTC Remote input (CE-A4). |
| `browser.page.extract` | `page.extract` | yes | **no** | **subset** | Target: selector text in injected script; shadow DOM best-effort v1 (CE-A2). |
| `browser.page.screenshot` | `page.screenshot` | yes | **no** | **yes** | Server pre-check blocks extension today; target CAS artifact same shape as Playwright tool (CE-A2 + CE-A5 H.1). |
| `browser.task.run` | task queue / steps | yes | **no** | **subset** | Shipped: agent + server reject extension. Target: queued steps (navigate, click, fill, extract, wait, tab ops) inside MV3 — not 100% Playwright step parity (CE-A5 / Track I). |
| `browser.file.upload` | `file.upload` | yes | **no** | **no** | Deferred Track G (MV3 file input). Playwright-only until product needs extension upload. |
| `browser.extension` | `extension.version` / `extension.reload` | **no** | **yes** | **yes** | MV3 dev: confirm manifest version or reload service worker after `sync_chrome_extension_install.ps1`. |
| `input.inject` (via `device.input` on browser device) | `input.inject` | yes | **yes** | **yes** | Default **CDP** on all sites; `input_mode: dom` for synthetic DOM. |
| `browser.sheets.cell_set` | `sheets.cell_set` | **no** | **yes** | **yes** | Open Google Sheet tab only. Name-box goto + F2 + `insertText` + Tab commit. |
| `browser.sheets.row_read` | `sheets.row_read` | **no** | **yes** | **yes** | Read one cell (`cell=B7`) or a row slice (`row`, `start_col`, `columns`). Replaces separate `cell_read` tool. |
| `browser.sheets.append_row` | `sheets.append_row` | **no** | **yes** | **yes** | Product + stock on one row (default cols **B/C**). |

**Not an LLM tool:** Remote tab **WebRTC video + input** works on extension devices today (human plane). That is required for daily-profile control when `browser.page.act` is unavailable.

**Review gate CE-A0:** parity table above is scope lock for extension automation waves; do not expand Playwright-only paths onto extension without updating this table first.

---

## NM + IPC message catalog

Three hops: **MV3 extension** ↔ **native messaging host** (same `alienai_remote_browser.exe` NM loop) ↔ **extension IPC** (`127.0.0.1:37538`, default) ↔ **WebRTC agent** thread inside that binary.

Framing (NM stdin/stdout and IPC socket): **4-byte little-endian length** + UTF-8 JSON payload (`remotes/c_remote_browser/src/chrome_native/host.rs`, `extension_ipc.rs`).

### Native messaging — extension → Rust host (`type` / `command` → `ExtRequest.cmd`)

| `type` | Direction | Purpose |
|--------|-----------|---------|
| `ping` | ext → host → ext | Liveness; response includes `pong: true`. |
| `pair.start` | ext → host → ext | Register `browser_engine=extension` pair code. |
| `pair.status` | ext → host → ext | `idle` / `pending` / `claimed` + optional `code`, `device_iid`. |
| `frame` | ext → host | JPEG capture for WebRTC (`width`, `height`, `jpeg_b64`); host forwards to IPC. |
| `tabs.list` | ext → host | Extension pushes tab array in message body; host forwards `tabs_result` to agent. |
| `tabs.activate` | ext → host | Ack only today; tab switch done in SW before NM. |
| `capture.start` / `capture.stop` | host → ext (via port push) | Start/stop `captureVisibleTab` loop (also driven from agent IPC). |

Host → extension (long-lived `connectNative` port) uses the same JSON shapes as `ExtPush`: `type` values `capture.start`, `capture.stop`, `tabs.list`, `tabs.activate` (`extension_ipc::agent_ipc_to_ext_push`).

**Example — pair status (request/response on `sendNativeMessage`):**

```json
{ "type": "pair.status" }
```

```json
{
  "ok": true,
  "status": "pending",
  "code": "AB12CD",
  "expires_in_sec": 600
}
```

**Example — video frame (fire-and-forget on native port):**

```json
{
  "type": "frame",
  "width": 1280,
  "height": 720,
  "jpeg_b64": "/9j/4AAQSkZJRg..."
}
```

```json
{ "ok": true }
```

**Example — tab list (extension → host; tabs filled by MV3 before send):**

```json
{
  "type": "tabs.list",
  "tabs": [
    { "tab_id": "123", "url": "https://example.com/", "title": "Example", "active": true }
  ]
}
```

```json
{ "ok": true, "tabs": [ { "tab_id": "123", "url": "https://example.com/", "title": "Example", "active": true } ] }
```

### Localhost IPC — agent ↔ native host (`AgentIpcMsg`, field `op`)

Default listen: `127.0.0.1:37538` (`C35_BROWSER_EXTENSION_IPC_PORT` optional). Same length-prefix framing as NM.

| `op` | Direction | Purpose |
|------|-----------|---------|
| `capture_start` / `capture_stop` | agent → host → ext | Maps to NM `capture.start` / `capture.stop`. |
| `tabs_list` | agent → host → ext | Maps to NM `tabs.list`; host waits for ext tab payload. |
| `tabs_activate` | agent → host → ext | NM `tabs.activate` + `tab_id`. |
| `frame` | host → agent | Decoded into `BrowserState` for H.264 WebRTC. |
| `tabs_result` | host → agent | Tab list JSON stored for `browser.tabs` list RPC. |
| `ping` / `pong` | either | Diagnostics. |

**Example — agent asks for tabs (host forwards to extension; async result):**

Agent → host:

```json
{ "op": "tabs_list" }
```

Host → agent (after extension NM `tabs.list`):

```json
{
  "op": "tabs_result",
  "value": {
    "tabs": [
      { "tab_id": "123", "url": "https://example.com/", "title": "Example", "active": true }
    ]
  }
}
```

**Example — capture gating (CE-A6 target; partial today):**

```json
{ "op": "capture_start" }
```

```json
{ "op": "capture_stop" }
```

### Planned — correlated agent RPC (CE-A1+)

Automation tools will use **request/response** over the IPC socket (and mirrored NM where needed), not fire-and-forget `tabs_list` alone. Locked shape from [automation multitask plan](plans/2026-09-29-chrome-extension-automation-multitask.md):

```json
{ "req_id": "01JABC...", "op": "page.observe", "params": { "tab_id": "123", "max_chars": 8000 } }
```

```json
{ "req_id": "01JABC...", "ok": true, "result": { "url": "https://example.com/", "title": "Example", "snapshot": "..." } }
```

```json
{ "req_id": "01JABC...", "ok": false, "error": "permission denied: scripting" }
```

Initial `op` set (CE-A1 B.2): `tabs.list`, `tabs.activate`, `tabs.new`, `tabs.close`, `page.observe`, `page.act`, `page.extract`, `page.screenshot`, `navigate`, `reload`, plus `input.inject` (CE-A4). Agent `browser_command` maps cluster methods to these ops when `browser_engine=extension`.

**Input (CE-A4):** `device.input` → `input.inject` defaults to **CDP** (`Input.dispatchKeyEvent` / `dispatchMouseEvent` / `insertText`) on all sites; pass `input_mode: dom` to force synthetic DOM events. Optional `focus: false` skips raising the window when the tab is already active.

## Extension automation — shipped (2026-09)

Paired device: `type=browser`, `meta.browser_engine=extension`. User’s **daily Chrome** profile (logins, cookies). Control plane: agent WS + native messaging; data plane: WebRTC Remote tab unchanged.

### Cluster tools (extension branch)

| Tool | Purpose |
|------|---------|
| **`browser.tabs`** | `list` / `activate` / `new` / `close` — resolve `tab_id` for other calls. |
| **`browser.extension`** | `version` \| `reload` — MV3 service worker after syncing install dir. |
| **`device.input`** → **`input.inject`** | Trusted **CDP** mouse/keyboard/text on any URL (`input_mode: dom` optional). |
| **`browser.page.observe`** | URL, title, simplified DOM text (accessibility-oriented slice). |
| **`browser.page.act`** | `click` / `fill` / `press` via injected script. |
| **`browser.page.extract`** | Selector text extraction. |
| **`browser.page.screenshot`** | JPEG capture (cluster artifact path). |
| **`browser.sheets.cell_set`** | Write one cell; extension verifies; **`llm.summary`** e.g. `B2 set to "text"` on success (no follow-up read). |
| **`browser.sheets.range_read`** | One call: product+stock rows + **`next_row`** for append (replaces many `row_read`). |
| **`browser.sheets.row_read`** | Single cell or one row slice — prefer `range_read` for inventory. |
| **`browser.sheets.append_row`** | Product + stock row (default **B/C**); verifies both cells; **`llm.summary`** e.g. `Row 11: B11="Es teler", C11="5"`. |

**Not on extension:** `browser.task.run` (use Playwright device or stepwise `page.*` + sheets tools). **`browser.file.upload`** deferred.

### Google Sheets CDP path (extension)

- **Goto:** name box (all frames DOM, else CDP click + type ref + Enter) — **no** `#range=` URL navigation (avoids full reload).
- **Write:** name-box goto → F2 → DOM replace → **Tab** (next col) or **Enter** (stay); one read-back on active cell — no extra name-box hop for verify.
- **`append_row`:** caches last row per tab/column so auto-row is usually **one** goto; pair write uses **one** goto (Tab B→C); verify reads stock cell only (already selected).
- **`cell_set` / `append_row`:** extension returns `ok` + `summary`; server exposes `llm.summary` — model should not `row_read` after `ok:true`.
- **Read:** formula bar across frames after goto each cell.
- **Guard:** RPC fails fast if `tab.url` is not a spreadsheet (wrong tab or missing `tab_id`).
- **Queue:** per-tab mutex so parallel tool calls do not interleave CDP.
- **Values only:** no cell formatting (bold, colors, number format, column width). Plain text/numbers via CDP; use **`gsheet.*`** or Sheets API if you need format metadata.

**vs `gsheet.*`:** API tools on bot-attached spreadsheet IDs — bulk, no UI, no open tab. Use **`browser.sheets.*`** for the user’s visible Chrome sheet (e.g. Test Stock).

### Compose / eligibility (today)

- Topic **`sheets`** + **`inst.mention.sheets`** / phrases (“google sheet”, “tambah baris”, …) — tools are **not** `always`.
- **`@iid` device mention alone** does **not** disable web search; you need **sheet** steering (`inst.mention.sheets` / topic `sheets`) so compose skips forced **`web.search`** preflight and excludes `web.search` / `web.visit` via inst triggers.
- Inst body: **`browser.tabs` first** when `tab_id` unknown; **`append_row` without `row`** auto-fills the next empty product column.
- **Deferred:** hide `browser.sheets.*` unless the paired browser’s **active tab** is a spreadsheet URL.

### Dev loop (extension JS / MV3)

After editing `clients/chrome_extension/alienai_remote/dist/`:

1. `.\_\scripts\dev\sync_chrome_extension_install.ps1` → `%LOCALAPPDATA%\AlienAI\chrome_extension\install\alienai_remote\`
2. **`browser.extension`** `op: reload` on the paired Chrome device (`extension.reload` → `chrome.runtime.reload()`). MCP may **timeout** on reload; wait ~15s and `op: version` to confirm.
3. Rebuild **`c_remote_browser`** only when Rust IPC changes (`restart_chrome_remote_agent.ps1` or copy `.exe` when unlocked).

---

## Pairing (locked)

Same HTTP contract as [remote.md § Pairing](remote.md#pairing):

| Step | Actor | Action |
|------|-------|--------|
| 1 | Native host | `POST /v1/device/pair/register` with `device_type: "browser"` and `meta_json` containing `"browser_engine":"extension"` |
| 2 | Extension popup | Shows **Pair with Code** (same UX as desktop agent): code + expiry progress bar — no extra Chrome window |
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
2. **Daily profile + LLM automation (CE-A0)** — When CE-A* ships, every `browser.page.act`, `browser.task.run` step, and related MV3 script runs **as the logged-in user** in that daily profile: same cookies, vault, and site sessions as physical keyboard use. Automation is **not** an isolated sandbox like Playwright `%LOCALAPPDATA%\AlienAI\browser\profile\`. Do not market stealth, anti-bot evasion, or “undetectable” remote control; synthetic events and Remote input can be visible to sites.
3. **Active tab only** — Capture and scripting apply to the **focused** tab the user (or Remote) selected; extension must not exfiltrate background tabs without tab APIs visible in UX.
4. **Owner pair only** — Devices claim to one `owner_iid`; no multi-tenant extension install.
5. **No cluster credentials in extension** — `session_key` and poll secrets live in Rust on disk; extension ↔ host only via native messaging.
6. **No anti-bot guarantees** — Daily Chrome helps **human** logins; Remote input and agent-driven clicks may still be detectable on some sites (document in troubleshooting; do not promise undetectable automation).
7. **Supply chain** — Ship extension + host from alienai.id CAS/OTA only; unpacked load from documented path.

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

- [2026-09-29-chrome-extension-automation-multitask.md](plans/2026-09-29-chrome-extension-automation-multitask.md) — **LLM `browser.*` on extension** (CE-A0 parity, CE-A1 IPC RPC, MV3 observe/act/task runner)
- [2026-09-29-chrome-extension-remote-multitask.md](plans/2026-09-29-chrome-extension-remote-multitask.md) — pairing, NM, WebRTC video (CE-W*)
- [browser-remote.md](browser-remote.md) — Playwright engine (phase 1/2 plans)
