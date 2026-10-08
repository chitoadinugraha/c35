# Chrome extension native automation (Playwright-shaped tools) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** This plan continues [2026-09-29-chrome-extension-remote-multitask.md](2026-09-29-chrome-extension-remote-multitask.md) after **pairing + NM** are stable. Playwright remote browser stays on `meta.browser_engine=playwright`. Spec: [_/specs/browser-extension.md](../browser-extension.md), [_/specs/browser-remote.md](../browser-remote.md).

**Goal:** Make **Chrome extension** devices support the same **LLM `browser.*` tools** as Playwright (observe, act, tabs, extract, screenshot, task steps) by implementing automation **inside MV3** (tabs + scripting + capture), not Node/CDP — plus **Remote input** over WebRTC.

**Architecture:**

```text
server_ai  --browser_invoke-->  alienai_remote_browser (extension mode)
                                      |  __c35_browser__ RPC (unchanged wire)
                                      v
                               extension_ipc :37538  <-->  MV3 service worker
                                      ^
                               NM (pair/ping/frame + optional RPC fallback)
Google Chrome (daily profile)
```

- **Single tool surface:** reuse existing `browser.page.*`, `browser.tabs`, `browser.task.run` names; branch on `meta.browser_engine` in agent + server.
- **No Playwright process** for extension devices; `spawn_engine` stays blocked.
- **Correlation:** agent RPC must be **request/response** over IPC (request id), not fire-and-forget like early `tabs.list`.

**Tech stack:** `clients/chrome_extension/alienai_remote/` (dist JS or TS+esbuild), `remotes/c_remote_browser` (`chrome_native/`, `extension_ipc.rs`, `browser_command.rs`, `browser_input.rs`), `servers/crates/mod_chat/src/tools/builtin/browser.rs`, optional `_/specs/browser-extension.md` update.

## Global constraints

- `identity.type` = `browser`; `meta.browser_engine` = `extension` | `playwright`.
- No `session_key` in extension storage or NM payloads beyond pair status.
- UTF-8 for `.rs`, `.md`, `.dart`, `.js`, `.ps1` — use editor/Write, not PowerShell `Set-Content` default.
- Verify: `cd remotes && cargo build -p c_remote_browser`; `cd servers && cargo build -p server_ai`; `cd clients/app && flutter analyze` when app touched; `.\_/scripts/dev/check_utf8_sources.ps1 -Changed` before done.
- Do not commit unless user asks.

---

## Is this enough? What to improve

### Enough for the product bet (daily Chrome + LLM)

| Capability | In scope (this plan) | Defer |
|------------|----------------------|--------|
| See page structure | `browser.page.observe` | Full AX tree parity with Playwright |
| Click / fill / type | `browser.page.act` + Remote input | `debugger` Input.* (detectability) |
| Tabs | `browser.tabs` list/new/activate/close | Multi-window orchestration |
| Read selector text | `browser.page.extract` | Shadow DOM edge cases (best-effort v1) |
| Vision / debug shot | `browser.page.screenshot` on extension | CAS artifact same as Playwright tool |
| Multi-step flows | `browser.task.run` **extension step runner** (subset) | 100% Playwright step parity |
| Human remote | WebRTC video + input (CE-W3/W4) | Files tab, shell |

**Verdict:** Yes — **observe + act + tabs + screenshot + task subset + Remote input** is enough to justify the extension vs “Remote-only with no automation.” Playwright device remains for headless slots, heavy automation, and upload/network hooks.

### Improvements baked into this plan (not optional nice-to-haves)

1. **IPC request/response** with `req_id` and timeouts (fix tab list race).
2. **Long-lived `connectNative` port** for automation bursts; keep `sendNativeMessage` for pair/ping only.
3. **Same JSON shapes** as Playwright `browser_command` responses so Flutter/tools do not fork.
4. **Server gates:** remove extension hard-fail on observe/screenshot; fail only when agent returns unsupported.
5. **Docs:** parity matrix in `browser-extension.md` (what works on extension vs playwright).
6. **Safety:** optional `view_only` meta or per-session flag before full input on extension (document; implement minimal default = input allowed after W4).

### Out of scope (explicit)

- Replacing Playwright entirely; macOS/Linux NM host.
- `browser.file.upload` on extension v1 (Track G defer — MV3 file input is painful).
- Undetectable automation / anti-bot guarantees.
- Chrome Web Store listing.

---

## Deliverables summary

| Deliverable | User-visible |
|-------------|----------------|
| Extension automation module | LLM can click/fill/read daily Chrome via existing tools |
| Agent extension RPC | `page.*`, `tabs`, `navigate` work when `browser_engine=extension` |
| Remote input | Mouse/keyboard in app Remote tab moves daily Chrome |
| `browser.task.run` | Queued steps run in extension (navigate, click, fill, extract, wait) |
| Docs + MCP | `prompt_run` / manual test on 33000 extension fixture device |

---

## Master wave map

| Wave | Name | Tracks | Depends | Ship criterion |
|------|------|--------|---------|----------------|
| CE-A0 | Spec parity matrix | A doc | — | Locked table extension vs playwright tools |
| CE-A1 | IPC RPC layer | B protocol, C Rust bridge | A0 | `tabs.list` round-trip &lt; 2s with correlation |
| CE-A2 | Extension automation JS | D observe/act/navigate, E extract/screenshot | A1 | Manual: NM/IPC test page click + read title |
| CE-A3 | Agent `browser_command` | F wire methods in extension mode | A2 | `tool_exec` browser.tabs + page.observe on test device |
| CE-A4 | WebRTC input | G DC 뿯↽ extension injection | A1, W3 video | Remote tab click types on example.com |
| CE-A5 | Server + task runner | H tool gates, I extension task.run | A3 | `browser.task.run` 3-step flow on extension |
| CE-A6 | Video idle + polish | J capture gating, K errors/telemetry | A4 | No capture when no viewer; clear tool errors |
| CE-A7 | Verify + inst | L tests, M prompt smoke | A5 | `prompt_compose` feeds browser tools on extension topic |

Parallel dispatch: **A0** alone; **A1(B+C)**; **A2(D+E)** after A1; **A3(F)** after A2; **A4(G)** parallel with A3 once A1 done; **A5(H+I)** after A3; **A6(J+K)** after A4; **A7(L+M)** last.

---

# CE-A0 — Spec parity matrix

## Track A — `browser-extension.md`

Files: `_/specs/browser-extension.md`, link from [2026-09-29-chrome-extension-remote-multitask.md](2026-09-29-chrome-extension-remote-multitask.md)

- [ ] A.1 Table: each `browser.*` tool 뿯½ extension support level (`yes` / `subset` / `no` / `planned`).
- [ ] A.2 NM + IPC message catalog (`type` / `method`, request/response examples).
- [ ] A.3 Security copy: daily profile + automation = same risk as user at keyboard; no stealth claims.
- [ ] A.4 Update CE-W4/W7 Track R in old plan 뿯↽ “superseded by CE-A*”.

**Review gate A0:** Chito signs parity table (scope lock).

---

# CE-A1 — IPC request/response

## Track B — Protocol

Files: `remotes/c_remote_browser/src/chrome_native/messages.rs`, `extension_ipc.rs`, `clients/chrome_extension/.../service_worker.js`

- [ ] B.1 Add `ExtRpcRequest` / `ExtRpcResponse` (or extend `AgentIpcMsg`): `req_id`, `op`, `params`, `ok`, `error`, `result`.
- [ ] B.2 Ops v1: `tabs.list`, `tabs.activate`, `tabs.new`, `tabs.close`, `page.observe`, `page.act`, `page.extract`, `page.screenshot`, `navigate`, `reload`.
- [ ] B.3 Extension SW: handle ops from IPC socket (agent 뿯↽ ext) and reply on same connection.
- [ ] B.4 Deprecate one-way `tabs.list` NM echo except for legacy; agent uses IPC only for RPC.

## Track C — Rust bridge

Files: `extension_ipc.rs`, `extension_tabs.rs`, new `extension_page.rs`

- [ ] C.1 `ExtensionBridge::call(op, params, timeout)` 뿯↽ correlated response.
- [ ] C.2 `extension_tab_command` uses `call` for list/activate/new/close.
- [ ] C.3 Unit or integration test: mock TCP client sends `tabs.list`, receives JSON array.

**Review gate A1:** `cargo build -p c_remote_browser`; manual script pings IPC with Python/TCP.

---

# CE-A2 — Extension automation (MV3)

## Track D — observe / act / navigate

Files: `clients/chrome_extension/alienai_remote/dist/automation.js` (or `src/automation.ts`), wire in `service_worker.js`

- [ ] D.1 `page.observe`: url, title, `document.body.innerText` slice + optional simplified DOM tree (`max_chars`).
- [ ] D.2 `page.act`: `click` / `fill` / `press` via `chrome.scripting.executeScript` (active tab, host_permissions).
- [ ] D.3 `navigate` / `reload`: `chrome.tabs.update` / `reload` on target `tab_id` or active tab.
- [ ] D.4 Consistent errors: `ok: false`, `error` string (permission denied, no tab, selector not found).

## Track E — extract / screenshot

Files: same automation module, reuse `captureVisibleTab` for screenshot op

- [ ] E.1 `page.extract`: selector 뿯↽ `textContent` / `value` in injected script.
- [ ] E.2 `page.screenshot`: JPEG b64 + width/height (match Playwright tool response shape).
- [ ] E.3 Rebuild `dist/`; sync to `%LOCALAPPDATA%\AlienAI\chrome_extension\install\alienai_remote\` in publish script or doc step.

**Review gate A2:** Load unpacked; from devtools service worker, call automation helpers on `https://example.com`.

---

# CE-A3 — Agent browser_command (extension backend)

## Track F — `invoke_method` extension path

Files: `browser_command.rs`, `extension_page.rs`, `browser_task.rs` (stub only)

- [ ] F.1 Route `page.observe`, `page.extract`, `page.act`, `page.screenshot`, `navigate`, `reload`, `history.*` to `extension_page::*` when `is_extension_engine()`.
- [ ] F.2 `tabs` op matrix matches Playwright JSON (`list`, `new`, `activate`, `close`).
- [ ] F.3 `file.upload` 뿯↽ clear error “extension v1 not supported” (or defer Track G).
- [ ] F.4 Register handler unchanged; verify `__c35_browser__` from cluster reaches agent.

**Review gate A3:** MCP `tool_exec` with owner 33000 (fixture extension device) for `browser.tabs` + `browser.page.observe`.

---

# CE-A4 — WebRTC Remote input

## Track G — DC 뿯↽ extension

Files: `browser_input.rs`, extension `input.js`, `extension_ipc.rs`

- [ ] G.1 When extension engine: `browser_input::execute` forwards to IPC `input.inject` (mouse x/y normalized, keys, wheel).
- [ ] G.2 Extension maps to `executeScript` synthetic events OR trusted click at viewport coords (document v1 approach in plan CE-W4 J).
- [ ] G.3 Align coordinate system with capture frame size (1280뿯½800 logical vs actual tab).
- [ ] G.4 Manual: Flutter Remote tab 뿯↽ extension device 뿯↽ pointer moves focus on test page.

**Review gate A4:** Video + input on same session without Playwright process running.

---

# CE-A5 — Server tools + task runner

## Track H — Remove extension hard-blocks

Files: `servers/crates/mod_chat/src/tools/builtin/browser.rs`

- [ ] H.1 Drop pre-check that blocks `browser.page.screenshot` on extension (let agent error if capture fails).
- [ ] H.2 Keep `browser.task.run` block until Track I ships; then remove block for extension.
- [ ] H.3 Tool descriptions: one line “extension devices use daily Chrome (MV3); Playwright devices use isolated Chromium.”

## Track I — Extension `browser.task.run`

Files: `browser_task.rs`, extension `task_run.js`, `mod_chat` task enqueue unchanged

- [ ] I.1 Extension step ops v1: `navigate`, `click`, `fill`, `extract`, `wait` (ms), `tab_activate`.
- [ ] I.2 Agent `handle_act` extension path: parse `steps[]`, run sequentially via IPC with per-step timeout.
- [ ] I.3 `skill_api::task_done` with aggregated result JSON (same as Playwright task).
- [ ] I.4 Server: allow `browser.task.run` when `device_browser_engine == extension`.

**Review gate A5:** `browser.task.run` with 3 steps (navigate, extract, click) on 33000 test device.

---

# CE-A6 — Video idle + errors

## Track J — Capture gating

Files: `browser_idle.rs`, `service_worker.js`, `extension_ipc.rs`

- [ ] J.1 `active_sessions == 0` 뿯↽ IPC `capture.stop`; on WebRTC connect 뿯↽ `capture.start` + active tab id.
- [ ] J.2 Do not run 15 fps capture when no viewer (CPU).

## Track K — UX + ops

Files: extension popup (optional), `browser-extension.md` troubleshooting

- [ ] K.1 Tool errors surface `extension ipc not ready` 뿯↽ user message “Start Chrome Remote agent”.
- [ ] K.2 Log line on agent: extension RPC op + duration (no page content).

**Review gate A6:** 5 min Remote session 뿯↽ disconnect 뿯↽ CPU drops (capture stopped).

---

# CE-A7 — Verify + prompt steering

## Track L — Automated smoke

Files: `_/scripts/dev/smoke_chrome_extension_automation.ps1` (new), optional Rust test with mock IPC

- [ ] L.1 Script: assert agent listening 37538, NM `pair.status`, IPC `tabs.list` (if TCP test helper exists).
- [ ] L.2 Document Chito manual checklist: e-Puskesmas login human + `browser.page.observe` read-only tool.

## Track M — Inst (minimal)

Files: `_/schemas/inst.sql` only if model fails to pick browser tools on extension devices

- [ ] M.1 `prompt_compose` phrase: “use daily Chrome / extension browser” 뿯↽ `browser.page.observe` fed on device topic.
- [ ] M.2 Optional `prompt_run` on 33000 after seed extension device meta.

**Review gate A7:** `prompt_compose` shows `browser.page.observe` fed for extension mention.

---

## Optional Track G (defer) — `browser.file.upload`

- [ ] G-defer.1 Offscreen + `chrome.debugger` or user gesture file picker bridge.
- [ ] G-defer.2 Only if product needs extension upload before Playwright fallback.

---

## Verification checklist (final)

- [ ] Extension device: `browser.tabs`, `browser.page.observe`, `browser.page.act`, `browser.page.extract`, `browser.page.screenshot`.
- [ ] `browser.task.run` ≥3 steps on extension; Playwright device unchanged.
- [ ] Remote tab: live video + mouse/keyboard on test site.
- [ ] No Playwright `browser_engine` spawn when `C35_BROWSER_ENGINE=extension`.
- [ ] `cargo build -p c_remote_browser`; `cargo build -p server_ai`; `flutter analyze` if app strings touched.

---

## Execution notes (multitask)

| Wave | Suggested parallel tracks |
|------|---------------------------|
| 1 | A0 |
| 2 | A1 B + C |
| 3 | A2 D + E |
| 4 | A3 F + A4 G (start G after A1) |
| 5 | A5 H then I |
| 6 | A6 J + K |
| 7 | A7 L + M |

After server changes: `publish_server.ps1` when Chito wants cluster rollout; extension zip + host exe via existing chrome-extension publish when binaries change.
