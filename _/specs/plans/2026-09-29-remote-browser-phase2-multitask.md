# Remote browser - Phase 2 implementation plan (remaining work)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth for progress.
>
> **For Chito:** Review this file **before each wave**. Phase 1: [2026-09-29-remote-browser-multitask.md](2026-09-29-remote-browser-multitask.md).

**Goal:** Finish Remote browser for production: H.264 WebRTC (GPU then CPU fallback), multi-tab_id automation, slots, downloads/uploads, LLM browser tools + inst/topic, Flutter tab strip, OTA/NATS, origin allowlist, and verification (compose + manual).

**Architecture:** Rust `c_remote_browser` (pair, WS, WebRTC encode, tasks) + Node `browser_engine` (Playwright IPC only). Human plane = WebRTC RTP + input DC; control = ActDeviceTaskRun + browser.* cluster tools. Spec: [_/specs/browser-remote.md](../browser-remote.md), [_/specs/remote.md](../remote.md).

**Tech stack:** Rust (c_remote_browser, c_remote_core, reuse c_remote_windows video_stream patterns), Node 22 + Playwright, Flutter clients/app, server mod_chat + mod_device + inst, deploy publish_remote_browser.ps1.

## Global constraints

- Naming: UI "Remote browser"; type=browser; tab_id; slot_id for Chromium profile.
- Planes: Exclude desktop remote tools on browser-only scope; add device.fs.list and device.fs.read to exclude list.
- Encode: Node JPEG screencast only; Rust JPEG to NV12 to H.264 RTP (see remotes/c_remote_windows/src/video_stream.rs).
- Build: cd remotes && cargo build -p c_remote_browser; npm run build in browser_engine; cd servers && cargo build -p server_ai; flutter analyze.
- Verify tools/inst: prompt_compose and prompt_run per .cursor/rules/prompt-run-test.mdc.
- Publish: .\_\scripts\deploy\publish_remote_browser.ps1 - Publish summary target remote-browser.
- Do not commit unless user asks.

---

## Phase 1 done (reference)

Pair/WS, browser_engine IPC, ActDeviceTaskRun to task.run, SCTP MJPEG MVP, Flutter row/detail, tool gating (4 tools), publish script + ai.config, c35.browser.mode on WS (app does not send yet).

## Gap summary

| Area | Gap |
|------|-----|
| Video | H.264 RTP, GPU encode, idle screencast throttle |
| Tabs | tab_id on steps/tools; agent RPC; Flutter tab strip |
| Slots | slot_id profiles and per-slot downloads dir |
| Files | download events; upload from CAS/chat attachment |
| LLM | browser.task.run, observe, extract, act, tabs, file.upload |
| Inst | seeds + topic for @ browser |
| OTA | agent self-update, GET /version/remote-browser, NATS optional |
| Safety | origin allowlist enforced in engine |

---

## Master wave map

| Wave | Name | Tracks | Depends | Ship criterion |
|------|------|--------|---------|----------------|
| RB2-W1 | Spec + gating | A docs, B fs exclude | - | Docs + compose test |
| RB2-W2 | Tabs + slots | C tab_id, D slots, E agent RPC | W1 | Task on tab_2 |
| RB2-W3 | H.264 WebRTC | F video, G idle, H client | W2 | Direct dot smooth H.264 |
| RB2-W4 | Files | I download, J upload, K CAS | W2 | Form file upload + download |
| RB2-W5 | LLM tools | L defs, M enqueue, N observe | W2,W4 | prompt_run uses browser tools |
| RB2-W6 | Inst/topic | O inst, P topic | W5 | prompt_compose trace |
| RB2-W7 | App | Q tabs, R mode WS, S tray | W2,W3 | Settings + tab strip |
| RB2-W8 | Ship | T OTA, U version/NATS, V smoke | W3-W7 | Publish summary |

Parallel dispatch: W1(A+B); W2(C+D then E); W3(F+G then H); W4(I then J+K); W5(L+M then N); W6(O+P); W7(Q+R+S); W8(T then U then V).

Dependency graph:

    RB2-W1 -> RB2-W2 -> RB2-W3 (video)
                  |-> RB2-W4 (files)
                  |-> RB2-W5 -> RB2-W6 (tools/inst)
    W2+W3 -> RB2-W7 (app)
    W3-W7 -> RB2-W8 (ship)

---

# RB2-W1 - Spec + gating hygiene

## Track A - browser-remote.md

Files: _/specs/browser-remote.md, _/specs/remote.md

- [ ] A.1 Section LLM tools: browser.task.run, browser.page.observe, browser.page.extract, browser.page.act, browser.tabs, browser.file.upload; list exclusions.
- [ ] A.2 Document tab_id on steps/tools; slot_id; downloads/uploads.
- [ ] A.3 WebRTC: JPEG sidecar to Rust NV12 to H.264 RTP; optional SCTP fallback env C35_BROWSER_SCTP_SCREEN=1.
- [ ] A.4 Re-save UTF-8 if file is corrupted.

## Track B - Tool exclude completeness

Files: servers/crates/mod_chat/src/device_context.rs, servers/crates/mod_chat/tests/compose_test.rs

- [ ] B.1 Add device.fs.list and device.fs.read to BROWSER_DEVICE_TOOL_EXCLUDE.
- [ ] B.2 Compose test: browser-only devices exclude desktop + fs tools.
- [ ] B.3 cargo test -p mod_chat (targeted compose tests).

Review gate RB2-W1: Chito signs tool list and tab_id/slot_id naming.

---

# RB2-W2 - Multi-tab + slots

## Track C - tab_id in automation

Files: remotes/browser_engine/steps.ts, browser.ts, remotes/c_remote_browser/src/browser_task.rs

- [ ] C.1 Optional tab_id per BrowserStep; default active tab.
- [ ] C.2 Steps: tab_activate, tab_new, tab_close.
- [ ] C.3 task.run default tab_id for batch.
- [ ] C.4 Dev test: two tabs, navigate second via tab_id.

## Track D - Slots

Files: remotes/browser_engine/slots.ts (new), remotes/c_remote_browser/src/engine/process.rs

- [ ] D.1 Paths: {config}/slots/{slot_id}/ userDataDir + downloads/.
- [ ] D.2 launch IPC slot_id; Rust passes downloadsPath.
- [ ] D.3 slot_id honored in browser_task JSON (stop ignoring slot_id).
- [ ] D.4 v1: one slot per agent process; restart engine on slot change.

## Track E - Agent tab RPC

Files: _/schemas/proto/c35/wire.proto, servers/crates/mod_device, remotes/c_remote_browser/src/browser_tabs.rs (new)

- [ ] E.1 Add ReqDeviceBrowserTab* or agent notify JSON schema; server forwards to agent WS.
- [ ] E.2 Rust bridge: tab.list, tab.activate, tab.new, tab.close.
- [ ] E.3 Flutter BrowserTabStore on RemoteSession (Track Q).

Review gate RB2-W2: Task opens URL on tab_2 while headed window shows tab_1.

---

# RB2-W3 - H.264 WebRTC (GPU)

## Track F - browser_video.rs

Files: remotes/c_remote_browser/src/webrtc/browser_video.rs (new), webrtc/mod.rs, Cargo.toml

- [ ] F.1 Share or extract encode from c_remote_windows/src/video_stream.rs (cfg dep or c_remote_core helper).
- [ ] F.2 JPEG frame from browser_state to decode to NV12 to H.264 MFT (hw then sw) to RTP track.
- [ ] F.3 set_track_handler + set_webrtc_rtp_media_enabled(true); disable SCTP screen when RTP on.
- [ ] F.4 Log encoder=hw|sw; env C35_BROWSER_JPEG_MAX_FPS default 15.
- [ ] F.5 cargo build -p c_remote_browser on Windows.

## Track G - Idle CPU

- [ ] G.1 When active_sessions==0: screencast.stop or everyNthFrame throttle (C35_BROWSER_IDLE_MS).
- [ ] G.2 Resume on WebRTC viewer connect.

## Track H - Client verify

- [ ] H.1 Manual Remote tab on browser device uses video track.
- [ ] H.2 flutter analyze if UI changes.

Review gate RB2-W3: Both dots green; acceptable CPU at 720p/15fps.

---

# RB2-W4 - Downloads + uploads

## Track I - Downloads

Files: browser_engine/browser.ts, protocol.ts, c_remote_browser/src/browser_download.rs (new)

- [ ] I.1 Playwright download handler; acceptDownloads.
- [ ] I.2 IPC download.wait returns path, filename, url under slot downloads/.
- [ ] I.3 Step download_wait; task result includes paths (CAS upload optional v1.1).

## Track J - Upload to page

- [ ] J.1 IPC file.upload: setInputFiles + file chooser.
- [ ] J.2 Rust size cap before IPC (e.g. 32 MiB).

## Track K - Server CAS bridge

Files: mod_device or tool helper, mod_chat/tools/builtin/browser.rs

- [ ] K.1 browser.file.upload: attachment_id to agent bytes/path.
- [ ] K.2 Promote completed downloads to CAS in task_done metadata.

Review gate RB2-W4: Upload PDF to file input; download file referenced in task result.

---

# RB2-W5 - LLM cluster tools

## Track L - Tool definitions

File: servers/crates/mod_chat/src/tools/builtin/browser.rs (new)

| Tool | Purpose |
|------|---------|
| browser.task.run | device_iid, slot_id?, tab_id?, steps[] via ActDeviceTaskRun |
| browser.page.observe | a11y snapshot + url/title (trimmed) |
| browser.page.extract | selector to text |
| browser.page.act | single click/fill/press |
| browser.tabs | list/new/activate/close |
| browser.file.upload | attachment_id + selector |

- [ ] L.1 Register tools; topics device; rag_phrases.
- [ ] L.2 cargo build -p server_ai.

## Track M - Task enqueue

- [ ] M.1 browser.task.run builds ActDeviceTaskRun.prompt JSON.
- [ ] M.2 Progress via TaskRunPush.

## Track N - Observe IPC

- [ ] N.1 browser_engine page.observe IPC (accessibility snapshot cap).
- [ ] N.2 Wire to browser.page.observe tool.

Review gate RB2-W5: prompt_run with @ browser uses browser.task.run (fixture 33000).

---

# RB2-W6 - Inst + topic

## Track O - inst.sql

- [ ] O.1 Inst phrases for remote browser / @ browser: tool_include browser.*; tool_exclude shell.run, device.*, computer_use.delegate, device.fs.*.
- [ ] O.2 Inst steer 2FA to Remote tab (no device.input).

## Track P - topic.sql

- [ ] P.1 Topic browser or device persona: slots, tab_id, no shell.
- [ ] P.2 prompt_compose trace check.

Review gate RB2-W6: prompt_compose excludes desktop tools for browser iid.

---

# RB2-W7 - App product

## Track Q - Tab strip

Files: ui_device_detail.dart, ui_browser_tab_strip.dart (new), remote_session.dart

- [ ] Q.1 Tab list UI on Remote tab; activate/new/close via Track E RPC.
- [ ] Q.2 Screencast follows active tab.

## Track R - Background from app

- [ ] R.1 Settings sends c35.browser.mode:background|interactive on agent session.
- [ ] R.2 Prompt restart agent after mode change.

## Track S - Tray / autostart (v1.1)

- [ ] S.1 Tray icon + quit for alienai_remote_browser.
- [ ] S.2 Optional Windows login autostart flag.

Review gate RB2-W7: Tabs and background mode from phone.

---

# RB2-W8 - OTA + smoke

## Track T - Agent OTA

- [ ] T.1 Handle c35.release.remote-browser in task_run / update (mirror remote-windows).
- [ ] T.2 device_list needs_update for remote-browser release key.

## Track U - Version HTTP + NATS

- [ ] U.1 GET /version/remote-browser (mirror remote-windows JSON).
- [ ] U.2 Optional NATS broadcast in publish_remote_browser_version.dart.

## Track V - Smoke

File: _/scripts/deploy/deploy_remote/smoke_remote_browser_release.ps1 (new)

- [ ] V.1 Version endpoint + hash smoke.
- [ ] V.2 Manual checklist (pair, both dots, tab task, slot restart, allowlist).
- [ ] V.3 Link Phase 2 progress in Phase 1 plan snapshot.

Review gate RB2-W8: Publish summary; OTA zip applies on idle agent.

---

## LLM tool contract (lock in W1/W5)

**browser.task.run** args: device_iid (required), slot_id (default default), tab_id (optional default), steps (array). Steps support tab_id per step.

**browser.tabs** args: device_iid, op=list|new|activate|close, tab_id?, url? (new).

**browser.page.observe** args: device_iid, tab_id?, max_chars?.

**browser.page.act** args: device_iid, tab_id?, action=click|fill|press, selector, text?.

**browser.file.upload** args: device_iid, tab_id?, selector, attachment_id.

Excluded when browser-only: shell.run, device.screenshot, device.input, computer_use.delegate, device.fs.list, device.fs.read.

---

## File map (new or major)

    remotes/browser_engine/slots.ts
    remotes/c_remote_browser/src/webrtc/browser_video.rs
    remotes/c_remote_browser/src/browser_tabs.rs
    remotes/c_remote_browser/src/browser_download.rs
    servers/crates/mod_chat/src/tools/builtin/browser.rs
    clients/app/lib/widgets/devices/ui_browser_tab_strip.dart
    _/scripts/deploy/deploy_remote/smoke_remote_browser_release.ps1

---

## Risk register

| Risk | Mitigation |
|------|------------|
| JPEG decode CPU | Idle throttle, FPS cap, resolution cap |
| video_stream on non-Windows | cfg gate; SCTP fallback |
| Large a11y trees | max_chars in observe |
| Agent CAS upload | size limits, owner_iid check |

## Related

- Phase 1: 2026-09-29-remote-browser-multitask.md
- Playwright MCP tool naming reference (observe/act pattern)
- prompt-steering: _/specs/inst.md, .cursor/rules/prompt-steering.mdc