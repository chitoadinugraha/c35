# Remote browser (LOCKED)

Status: **locked** 2026-09-29

**Remote browser** is a paired endpoint: `ai.identity(kind=remote, type=browser)`. User-facing name is always **Remote browser** -- never "automated browser".

Sibling: [remote.md](remote.md) (`type=windows|android|...` -- OS capture + `input_exec`). Remote browser uses **Playwright (Node sidecar)** for the page and **the same WebRTC human remote stack** as desktop (signaling via server; media P2P/TURN).

Playwright reference (automation only, not streaming transport): `D:\cs_bots\agents\agent_browser\`.

---

## Two planes (same rule as desktop)

| Plane | Transport | Remote browser |
|-------|-----------|----------------|
| **Control** | Agent WebSocket (+ NATS `ActDeviceTaskRun`) | Pairing, presence, tasks, tab/slot commands to engine |
| **Data** (human) | **WebRTC** (P2P/TURN) + data channels | Viewport video + remote input -- **not** agent WS bytes |

**Locked:** bulk automation and `task_run` steps **never** depend on an active WebRTC viewer. Server stores **signaling + ICE only** on the data plane -- no page screenshots on cluster unless user/tool explicitly uploads (CAS).

**Not in v1:** WebRTC **Files** tab (`remote-fs`) for `type=browser` -- Remote tab only.

---

## Process architecture

```text
Flutter app  <-- WebRTC (same as desktop Remote) -->  alienai_remote_browser.exe (Rust)
                                                           |
                     pair 뿯½ conn_ws 뿯½ webrtc 뿯½ H.264 encode |
                                                           | IPC (localhost only)
                                                           v
                                              browser_engine (Node + Playwright)
                                              Chromium persistent profile
```

| Component | Responsibility |
|-----------|----------------|
| **`c_remote_browser`** (Rust binary) | Pairing UI/loop, `session_key`, agent WS, presence, WebRTC session, **JPEG->NV12->H.264 encode** (GPU preferred, CPU fallback), task dispatch to engine, headed/background mode |
| **`browser_engine/`** (Node worker) | Playwright only: launch context, tabs, slots, steps, CDP screencast frames -> IPC; **no** WS, **no** WebRTC, **no** `session_key` on network |

### Encode path (locked)

1. Node: `Page.startScreencast` -> JPEG frames over IPC.
2. Rust: decode + scale -> NV12 -> **Media Foundation H.264** (hardware MFT first, software MFT fallback) -- reuse `c_remote_windows` `video_stream` logic.
3. Rust: RTP video track on existing `c_remote_core::webrtc` hub.

Node does **not** encode video for WebRTC.

### IPC bridge (locked)

- **Local only:** named pipe or `127.0.0.1` TCP; never exposed off-machine.
- **Framed messages** (length-prefixed JSON or proto), version field `bridge_version: 1`.
- Rust supervises worker lifecycle (restart on crash, shutdown on unpair).
- Worker runs with **no cloud credentials** except profile path and headless flag passed by Rust.

---

## Identity & pairing

| Field | Value |
|-------|--------|
| `kind` | `remote` |
| `type` | `browser` |
| Config | `%LOCALAPPDATA%\AlienAI\browser\config.json` |
| Profile | `%LOCALAPPDATA%\AlienAI\browser\profile\` (Chromium `userDataDir`) |

Pairing: identical steps to [remote.md section Pairing](remote.md#pairing) -- `device_type: "browser"` on register.

**Not supported:** per-tab identities; compound kinds like `remote-browser`.

---

## Devices UI -- two dots (locked)

Same as desktop `kind=remote` ([`ui_device_row.dart`](../clients/app/lib/widgets/devices/ui_device_row.dart)):

| Dot | Meaning |
|-----|---------|
| **Left** | **Alien AI Cloud** -- agent control WS / presence. Grey: subtitle **Device is offline** |
| **Right** | **Direct link (WebRTC)** -- app <-> runner video/input |

Optional: distinct icon for `type=browser` (e.g. globe); dots unchanged.

---

## Display modes

| Mode | Playwright `headless` | Local Chromium window | App Remote |
|------|----------------------|------------------------|------------|
| **Interactive (default)** | `false` | Visible | Optional |
| **Background** | `true` | None | Required to see/control |

Toggle: device Settings + runner tray (v1). **Autostart:** user-logon tray/helper -- **not** Windows Session 0 service (headed/WebRTC require interactive session).

When **no WebRTC viewer** and idle timeout elapses, runner may reduce screencast/encode work (policy TBD in agent; do not kill paired profile without user action).

---

## Tabs and slots (locked naming)

### `tab_id`

- Opaque string per open Playwright `Page` in the runner (engine-assigned; stable for the page lifetime).
- **Active tab** drives screencast, WebRTC input, and default target when a tool omits `tab_id`.
- App tab strip: list / activate / new / close via control path (`tab.activate`, agent RPC, or LLM `browser.tabs`).
- **Task steps** and **`browser.task.run`** may set `tab_id` per step; batch defaults to the active tab when omitted.
- **Mentions:** only `[@iid:<device_iid>]` -- see [mention.md](mention.md). No `[@tab:...]` identity kind.

### `slot_id`

- Named long-lived page profile (`default` when omitted).
- Persisted under `profile/slots.json` and/or `identity.meta.browser_slots` (label, seed URL).
- Cron and background tasks address **`device_iid` + `slot_id`**; downloads land under slot `userData` paths (see Downloads/uploads).

| Concept | Scope | Default |
|---------|--------|---------|
| `tab_id` | Ephemeral tab within a slot | Active tab |
| `slot_id` | Persistent browser context | `default` |

---

## LLM cluster tools (Phase 2)

Registered on topic **`device`** (RAG phrases). All browser tools require **`device_iid`** for a `type=browser` row.

| Tool | Purpose |
|------|---------|
| `browser.task.run` | Run step array via `ActDeviceTaskRun` (`slot_id?`, `tab_id?`, `steps[]`) |
| `browser.page.observe` | a11y snapshot + url/title (trimmed; `tab_id?`, `max_chars?`) |
| `browser.page.extract` | Selector -> text (`tab_id?`) |
| `browser.page.act` | Single click / fill / press (`tab_id?`, `action`, `selector`, `text?`) |
| `browser.tabs` | `op=list|new|activate|close`, `tab_id?`, `url?` (for `new`) |
| `browser.file.upload` | Chat `attachment_id` + file input `selector` (`tab_id?`) |

### Args summary

- **`browser.task.run`:** `device_iid` (required), `slot_id` (default `default`), `tab_id` (optional), `steps` (array). Each step may include its own `tab_id`.
- **`browser.tabs`:** `device_iid`, `op`, optional `tab_id`, optional `url` when `op=new`.
- **`browser.page.observe`:** `device_iid`, optional `tab_id`, optional `max_chars`.
- **`browser.page.act`:** `device_iid`, optional `tab_id`, `action`, `selector`, optional `text`.
- **`browser.file.upload`:** `device_iid`, optional `tab_id`, `selector`, `attachment_id`.

Compose: when every device in prompt scope is `type=browser`, server adds `BROWSER_DEVICE_TOOL_EXCLUDE` via `tool_exclude_browser_devices` (`mod_chat` / `device_context.rs`).

### Excluded on browser-only scope (desktop remote)

| Tool | Reason |
|------|--------|
| `shell.run` | OS shell -- not Chromium |
| `device.screenshot` | Desktop capture; use `browser.page.observe` |
| `device.input` | OS-level input |
| `computer_use.delegate` | Desktop vision loop |
| `device.fs.list` | Host filesystem -- not browser profile |
| `device.fs.read` | Host filesystem read |

Prefer **`browser.task.run`** step JSON and server `gsheet.*` for bulk sheet work -- not vision loops on desktop tools.

---

## Safety & trust (locked)

### Pairing & session

- Only **owner** (`owner_iid` + grant) may claim code; `session_key` rotatable on unpair.
- **Symmetric unpair** same as desktop ([remote.md section Unpair](remote.md#unpair-locked)).
- On unpair: clear `session_key` in config; **default: delete `profile/`** only when user chooses "Remove data" -- otherwise document "keep logins" vs "wipe" in Settings.

### Exposure

- Streaming shows **active tab only** -- tab list visible in app before takeover when possible.
- Any tab in the profile may contain logged-in sites; recommend **dedicated automation profile** copy in onboarding.
- Remote input goes to **active page only** -- not OS desktop.

### Automation policy (v1)

- **`origin_allowlist`** optional in device meta / local config -- block navigation and `goto` outside list when set.
- No arbitrary `page.evaluate` with user secrets in server-pushed prompts without explicit admin tools (task steps use fixed ops: `navigate`, `click`, `fill`, `extract`, `wait`).
- **No** `shell.run` on browser agent.
- Do not claim anti-bot bypass; captcha/2FA via **Remote** human completion.

### Network

- IPC bridge bound to localhost.
- WebRTC: same ICE/TURN policy as desktop ([remote.md section ICE/TURN](remote.md#ice--turn-cluster)).
- Engine must not open outbound WS to server (Rust only).

---

## Downloads and uploads

- Engine emits download events; Rust may mirror completed files under slot `downloads/` (CAS upload optional in task result metadata).
- **`browser.file.upload`:** server resolves `attachment_id` from chat attachments and streams bytes to the chosen file input on the page.

---

## Task payload (v1 JSON in `ActDeviceTaskRun`)

```json
{
  "slot_id": "default",
  "tab_id": null,
  "steps": [
    { "op": "navigate", "url": "https://example.com" },
    { "op": "fill", "selector": "#q", "text": "..." },
    { "op": "extract", "selector": ".balance", "as": "balance" }
  ]
}
```

Proto extension optional later; JSON is sufficient for v1.

---

## OTA & dev

| Piece | Value |
|-------|--------|
| Binary | `alienai_remote_browser.exe` + bundled `browser_engine/` (+ Node runtime or system Node documented) |
| Config key | `app.release.c35.remote-browser` |
| NATS | `c35.release.remote-browser` (when wired) |
| Local | `.\dev_browser.ps1` -- `C35_SERVER_URL`, builds Rust + engine |

**Verify:** `cd remotes && cargo build -p c_remote_browser`; `cd remotes/browser_engine && npm run build`; `flutter analyze` when app touched.

---

## Deferred (not v1)

- Cloud multi-session browser farm (cs_bots ARF1 density) -- separate plan.
- WebRTC Files tab for browser.

**Chrome extension (daily profile):** shipped as a sibling mode — see [browser-extension.md](browser-extension.md) (`meta.browser_engine=extension`, native host `com.alienai.c35.remote`). Playwright path in this doc remains `browser_engine=playwright`.
