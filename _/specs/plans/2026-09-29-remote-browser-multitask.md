# Remote browser — master multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth for progress.
>
> **For Chito:** Review this file **before each wave**. Do not start the next wave until the prior **Review gate** is checked off.

**Goal:** Ship **Remote browser** (`kind=remote`, `type=browser`) on the user PC: **Rust** agent (pair, WS, WebRTC, H.264 encode) + **Node** Playwright sidecar (IPC only), **headed by default**, **background = headless + app Remote**, **slots** for long-lived tabs, **same two green dots** as desktop remote.

**Architecture:** Reuse `c_remote_core` (`pair`, `conn_ws`, `webrtc`). `c_remote_browser` registers browser handlers (IPC input, screencast→`video_stream`). `browser_engine/` has no server network. Human plane = **WebRTC** (not ARF1). Spec: [`_/specs/browser-remote.md`](../browser-remote.md).

**Tech stack:** Rust (`remotes/c_remote_browser`, `c_remote_core`), Node 22 + Playwright (`remotes/browser_engine`), Flutter reuses `UIRemoteDevice` / `RemoteSession`, server minimal (`device_type=browser`).

| Reference | Use |
|-----------|-----|
| [`browser-remote.md`](../browser-remote.md) | Locked product + safety |
| [`remote.md`](../remote.md) | Planes, pairing, WebRTC signaling |
| [`2026-09-21-remote-agent-pairing.md`](2026-09-21-remote-agent-pairing.md) | Pair HTTP |
| `D:\cs_bots\agents\agent_browser\src\browser.ts` | Playwright port (not ARF1) |
| `remotes/c_remote_windows/src/video_stream.rs` | H.264 encode |

**Out of scope:** cloud browser farm, ARF1 gateway, Files tab on browser, Chrome extension.

---

## Global constraints (every wave)

- **Naming:** **Remote browser** in UI; crates `c_remote_browser`, `browser_engine`; OTA `app.release.c35.remote-browser`.
- **Identity:** `type=browser` only; mentions `[@iid:…]`; slots via `slot_id`.
- **Planes:** Tasks on WS; pixels on WebRTC — server signaling only.
- **Encode:** Rust GPU→CPU fallback; Node sends JPEG screencast only.
- **IPC:** localhost bridge; engine never holds `session_key` on wire.
- **Safety:** `browser-remote.md` § Safety — allowlist, unpair wipe policy, no shell on browser agent.
- **Build:** `cd remotes && cargo build -p c_remote_browser`; `cd remotes/browser_engine && npm run build`; `cargo build -p server_ai` if server touched; `flutter analyze` if app touched.
- **Publish:** `.\_\scripts\deploy\publish_remote_browser.ps1` in RB-W4.
- **Do not commit** unless user asks.

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **RB-W0** | Spec + scaffold | — | — | Docs locked; crates build empty |
| **RB-W1** | Pair + WS + UI row | A=Rust pair+WS, B=server browser type, C=Flutter row/dots | W0 | Cloud dot green after pair |
| **RB-W2** | Engine bridge + tasks | D=IPC+Playwright, E=Rust task handler, F=slots | W1 | Headed navigate via task |
| **RB-W3** | WebRTC remote | G=screencast→encode, H=Flutter Remote reuse, I=input DC | W2 | Both dots green; stream smooth |
| **RB-W4** | Modes + ship | J=background toggle, K=tab strip, L=OTA+tray | W3 | Publish smoke |
| **RB-W5** | Tools (optional) | M=tool gate, N=inst | W4 | No desktop tools on browser |

**Parallel dispatch:**

- RB-W1: **A + B + C**
- RB-W2: **D** then **E**; **F** with D
- RB-W3: **G + H** (H after G sends frames); **I** with G
- RB-W4: **J + K + L**
- RB-W5: **M + N**

```text
RB-W0
  → RB-W1 (Rust agent online)
      → RB-W2 (Playwright + tasks)
          → RB-W3 (WebRTC)
              → RB-W4 (product + OTA)
                  → RB-W5 (optional LLM)
```

---

## Progress snapshot

| Area | Status |
|------|--------|
| `browser-remote.md` | **Locked** 2026-09-29 |
| `c_remote_browser` (Rust) | **W2–W3** pair, WS, engine IPC, SCTP screen, input, tasks |
| `browser_engine` (Node) | **W2** IPC worker + Playwright |
| WebRTC browser handlers | **MVP** SCTP MJPEG (`set_screen_handler`, RTP off) |
| Flutter `type=browser` row | **Done** (Remote banner + Settings copy) |
| Server `device_type=browser` | **Done** (allowlist + tool exclude when browser-only) |
| `publish_remote_browser.ps1` | **Done** (build zip + CAS + `app.release.c35.remote-browser`) |

---

# RB-W0 — Spec + scaffold

- [x] Lock [`browser-remote.md`](../browser-remote.md)
- [x] Plan aligned to Rust + Node + WebRTC
- [x] **structure.md** — remotes tree
- [x] **remote.md** — sibling section
- [x] **spec.md** — index link
- [x] **ui.md** — `type=browser` row (no Files tab v1)

## Track 0b — Repo scaffold

**Create:**

```text
remotes/
  Cargo.toml                    # member: c_remote_browser
  c_remote_browser/
    Cargo.toml
    src/main.rs                 # stub: version + exit 0 after pair placeholder
    src/pair_loop.rs
    src/engine/ipc.rs           # stub
    src/engine/process.rs
  browser_engine/
    package.json
    tsconfig.json
    src/worker.ts               # echo IPC protocol
```

- [x] `cargo build -p c_remote_browser` from `remotes/`
- [x] `npm run build` in `browser_engine/`
- [x] `dev_browser.ps1` at repo root

- [ ] **Review gate RB-W0:** Chito signs safety + WebRTC (not ARF1) + profile wipe policy

---

# RB-W1 — Pairing + control session

## Track A — Rust pair + WS

**Files:** `c_remote_browser/src/pair_loop.rs` — call `c_remote_core::pair`, `device_type: "browser"`, config path `browser/config.json`

**Files:** `main.rs` — if unpaired → pair UI (v1: console large code; v1.1: port `pair_window.rs` with title “Remote browser”)

**Files:** wire `conn_ws_run_reconnect` from core after paired

- [ ] Register + poll E2E with app claim
- [ ] Presence → `meta.last_seen_ts_ms` → **right dot** green

## Track B — Server

- [ ] Allow `device_type=browser` in `device_pair_register`
- [ ] Comment in `device.proto`
- [ ] `cargo build -p server_ai`

## Track C — Flutter

- [ ] `type == 'browser'` → subtitle “Remote browser”, icon (globe or `Icons.public`)
- [ ] Same `UiDeviceRow` dots — no code fork
- [ ] `flutter analyze`

- [ ] **Review gate RB-W1:** Unpair → pairing code again; session invalid handled

---

# RB-W2 — IPC bridge + Playwright + tasks

## Track D — `browser_engine` worker

Port from cs_bots `browser.ts` (launch, anti-webdriver init script optional, tabs):

- [ ] `launch` / `shutdown` IPC
- [ ] `screencast` JPEG to Rust when streaming flag on
- [ ] `input` from Rust → Playwright mouse/keyboard
- [ ] `headless` flag from Rust

## Track E — Rust `engine/process.rs` + `ipc.rs`

- [ ] Spawn worker next to exe; framed protocol v1
- [ ] Health: restart worker if exit non-zero (rate limit)

## Track F — Slots + tasks

**Node:** `slots.ts`, `steps.ts`  
**Rust:** `task/browser_task.rs` — parse `ActDeviceTaskRun` JSON steps → IPC `task.run`  
**Rust:** `task_report` progress/done via core

- [ ] Slot `default` survives restart (`userDataDir`)
- [ ] Task navigate + extract without WebRTC viewer

- [ ] **Review gate RB-W2:** Origin allowlist enforced when meta set

---

# RB-W3 — WebRTC (reuse desktop path)

## Track G — Video + handlers

**Files:**

- `c_remote_browser/src/webrtc/browser_input.rs` — `RemoteInputEvent` → IPC input
- `c_remote_browser/src/webrtc/browser_video.rs` — IPC JPEG → NV12 → share/refactor `video_stream` encode → track

**Wire in `main.rs`:**

```rust
c_remote_core::webrtc::set_input_handler(... browser_input ...);
c_remote_core::webrtc::set_track_handler(... browser_video::start ...);
c_remote_core::webrtc::set_webrtc_rtp_media_enabled(true);
```

- [ ] Log `encoder=hw|sw` on start
- [ ] Disable or stub desktop `set_screen_handler` / screenshot for browser binary

## Track H — Flutter

- [ ] `type=browser` on Remote tab → same `UIRemoteDevice` / `RemoteSession` (no Files tab)
- [ ] **Left dot** green when PC connected

## Track I — Active tab

- [ ] IPC `tab.list` / `tab.activate` — Rust exposes via WS extension frame or task meta (document in browser-remote.md)
- [ ] Flutter tab strip above remote viewport

- [ ] **Review gate RB-W3:** Background mode (headless) + full control from app only

---

# RB-W4 — Background, autostart, OTA

## Track J — Modes

- [ ] Rust `mode` in config: `interactive` | `background`
- [ ] Flutter Settings: Show browser / Run in background / Run at login
- [ ] Restart engine with new headless flag

## Track K — Idle

- [ ] When `active_sessions == 0`, throttle or pause screencast (optional env `C35_BROWSER_IDLE_MS`)
- [ ] Align `update` idle with core if OTA bundled

## Track L — Publish

- [ ] `publish_remote_browser.ps1` — zip Rust exe + `browser_engine` + playwright chromium fetch
- [ ] `ai.config` release row; smoke pair + 30s Remote view
- [ ] Download page copy: **Remote browser**

- [ ] **Review gate RB-W4:** Publish summary (`target`: `remote-browser`)

---

# RB-W5 — LLM (optional)

## Track M — Tool gating

- [ ] Server/tool filter: `type=browser` excludes `device.screenshot`, `device.input`, `shell.run`, `computer_use.delegate`
- [ ] Optional `browser.task` tool → enqueue steps (no vision)

## Track N — Inst

- [ ] `inst` + topic for @ browser mention → task/tool only

- [ ] **Review gate RB-W5:** `prompt_compose` does not feed desktop device tools for browser iid

---

## Manual test checklist

1. Pair → both dots (cloud then WebRTC when Remote opened).
2. Headed: local Chromium visible; app Remote optional.
3. Background: no window; app-only Remote; 2FA manually.
4. Task on `slot_id` without LLM.
5. Unpair: config cleared; wipe profile optional.
6. Allowlist: blocked navigation logged and fails task.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Session 0 service | User-session tray only |
| Node on PATH | Bundle node in installer v1 |
| JPEG decode CPU | Cap FPS/resolution; GPU encode |
| Desktop/browser tool mix | `identity.type` gate |
| IPC trust | Localhost only; Rust validates message sizes |
| Profile secrets | Wipe on unpair option; safety copy |

---

## Related

- [`2026-09-21-webrtc-filesystem-e2e.md`](2026-09-21-webrtc-filesystem-e2e.md)
- [`data_source.md`](../data_source.md) — bulk sheets via `gsheet.*` + tasks
