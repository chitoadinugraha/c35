# Unified desktop + Chrome extension browser agent — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **Decision (2026-10-12):** One paired device per PC/VM — `type=windows` (or `linux`) — gains `browser.*` when daily Chrome + MV3 extension are connected. No second `type=browser` row for the same host for extension mode.
>
> **Related:** [_/specs/browser-extension.md](../browser-extension.md), [_/specs/remote.md](../remote.md), [2026-09-29-chrome-extension-automation-multitask.md](2026-09-29-chrome-extension-automation-multitask.md). **Supersedes** ad-hoc “route browser tools to another online browser device” once U2 ships (keep fallback only when `meta.browser_ready` is false and exactly one other browser online — optional narrow bridge).

**Goal:** `@VM1` can run `shell.run`, Remote desktop, **and** `browser.tabs` / `browser.sheets.*` on that machine’s Chrome without pairing `alienai_remote_browser.exe` separately.

**Architecture:**

```text
Flutter  ──►  alienai_remote_windows.exe  (one session_key, one device_iid)
                    │
                    ├─ desktop: shell, screenshot, input, drive (unchanged)
                    ├─ __c35_browser__  →  c_remote_browser_core::browser_command
                    └─ extension IPC :37538  ◄──  MV3 (NM host = desktop exe)
```

Extract shared browser/extension logic into **`c_remote_browser_core`** (no `c_remote_windows` dependency). `c_remote_windows` and `c_remote_browser` binaries both depend on core. Playwright `type=browser` devices remain for headless automation; extension on desktop uses **daily Chrome** only.

**Tech stack:** Rust `remotes/` workspace, `servers/crates/mod_device`, `mod_chat` browser tools, `ai.inst` seeds, MV3 under `clients/chrome_extension/alienai_remote/`.

## Global constraints

- `identity.kind = remote`; desktop `type = windows | linux`; browser capability is **not** a separate identity for extension mode on that host.
- `meta.browser_engine = extension` when extension IPC is healthy; `meta.browser_ready = true` on agent heartbeat when NM + extension connected.
- Wire `__c35_browser__:` JSON unchanged ([remote.proto](../../schemas/proto/c35/remote.proto)).
- UTF-8 sources; no PowerShell `Set-Content` on `.rs`/`.md`/`.ps1` without UTF-8.
- Verify: `cd remotes && cargo build -p alienai_remote_windows && cargo build -p alienai_remote_browser`; `cd servers && cargo build -p server_ai`; `.\_\scripts\dev\check_utf8_sources.ps1 -Changed`.
- Remote agent publish: `.\_\scripts\deploy\publish_remote_agent.ps1` when pairing/NM changes ship to users.
- Do not commit unless user asks.

---

## Problem statement (regression)

User message `103087205583998976`: `@VM1` + “open google sheet…” → `browser.tabs` sent to **Windows agent** → PowerShell parsed `__c35_browser__:{...}` → tool error → model replied with markdown table only.

Root cause: `browser_command::register_command_handler()` exists only in `c_remote_browser`; `c_remote_windows` has no handler (and rejects `--chrome-native-host`).

---

## Identity & server rules (U2)

| Field | Meaning |
|-------|---------|
| `type` | `windows` / `linux` (unchanged) |
| `meta.browser_engine` | `extension` when unified extension path active; absent on pure desktop |
| `meta.browser_ready` | `true` when agent reports extension IPC OK (heartbeat) |
| `meta.browser_install_version` | From install dir manifest (optional telemetry) |

**Server:**

- `remote_device_browser_invoke` / `remote_browser_device_iid_for_invoke`: allow `type != browser` when `meta.browser_ready == true` on that `device_iid`.
- Narrow or remove cross-device fallback when target desktop row is `browser_ready` false but user @mentioned that device (prefer clear `browser.ensure` error).
- `tool_exclude_browser_devices`: do **not** exclude `browser.*` on windows rows with `browser_ready`.

**Mention block:** `[MENTION TARGETS]` includes `browser_ready=true` for desktop devices when set.

---

## Agent behavior (U1 + U2)

### Windows startup (`c_remote_windows::run`)

1. After WebRTC handlers, call `c_remote_browser_core::unified::start_extension_backend()` when session paired:
   - `browser_state::init`, `browser_command::register_command_handler()`, `extension_ipc::spawn_extension_ipc_server` (extension engine only).
   - Skip second WS connection; skip Playwright sidecar.
2. Enable `chrome_native::should_run_native_host()` on **desktop exe** (remove exit(2) on `--chrome-native-host`; delegate to core NM loop).
3. On heartbeat, set local status → server `agent_presence` meta: `browser_ready`, `browser_engine`, `extension_install_version`.

### Chrome / extension ensure (U3)

**Agent-local checks:**

| Check | Action |
|-------|--------|
| Chrome installed | Registry / `Program Files` / `where chrome` |
| Install dir | `%LOCALAPPDATA%\AlienAI\chrome_extension\install\alienai_remote\` synced from agent bundle |
| NM registry | `com.alienai.c35.remote` → path to **desktop** exe with NM args |
| IPC | `extension_ipc` port listening; SW connected |

**Cluster tool `browser.ensure`** (new):

- Params: `device_iid` (required).
- Returns JSON: `chrome_installed`, `nm_ok`, `extension_connected`, `install_version`, `running_version`, `repair_actions[]`, `ok` (all green).
- Repairs (agent RPC): `sync_install`, `register_nm`, `open_extensions_page` (shell `start chrome chrome://extensions`).

### User-facing offer (Chrome + extension)

| Surface | Behavior |
|---------|----------|
| **`browser.ensure` tool** | Returns `user_offer` (pitch, steps, `chrome_download_url`, `install_path`) + runs `install_chrome` repair (opens Chrome download) |
| **Devices UI** | Banner on online `windows`/`linux` when `meta.browser_ready` is not true — Get Chrome + “Set up in chat” |
| **`inst.browser.ensure` / `inst.mention.sheets`** | Proactive offer before web.search fallback |

### Prompt / inst (U4)

**`inst.browser.ensure`** (seed in `inst.sql` + live `inst_put`):

- Phrases: extension not connected, browser tools failed, install chrome extension, load unpacked.
- When `browser.ensure` fails: call `browser.ensure` then `computer_use.delegate` with checklist (Extensions → Load unpacked → install path → reload).
- `include_tools`: `browser.ensure`, `browser.extension`, `computer_use.delegate`; exclude rival web tools as needed.

Update **`inst.mention.sheets`**: @mention desktop device is OK when `browser_ready`; otherwise run `browser.ensure` first.

---

## Crate layout (U1)

New workspace member: **`remotes/c_remote_browser_core/`**

| Module (moved from `c_remote_browser/src`) | Notes |
|--------------------------------------------|-------|
| `browser_command`, `extension_*`, `chrome_native`, `mode`, `browser_state`, `browser_tabs`, `extension_sheets`, … | No `c_remote_windows` dep |
| `browser_video` / H.264 | Trait `VideoEncoder` or `cfg(windows)` optional dep injected from `c_remote_windows` **at bin level only** — core exposes callback registration |

`c_remote_browser` binary: `main` calls core + Playwright `engine` + existing pair UI.

`c_remote_windows` binary: `main` calls `core::unified::attach_to_desktop_agent()` after pairing.

**Circular dependency rule:** `c_remote_browser_core` MUST NOT depend on `c_remote_windows`. `pair_loop` UI for browser-only binary stays in `c_remote_browser` crate, not core.

---

## Master wave map

| Wave | Name | Tracks | Depends | Ship criterion |
|------|------|--------|---------|----------------|
| **U0** | Spec + plan | Doc | — | This file + remote/browser-extension deltas |
| **U1** | `c_remote_browser_core` + Windows wire | A core extract, B windows NM+handler | U0 | `cargo build` both agents; NM host runs on desktop exe |
| **U2** | Server + presence | C meta.browser_ready, D invoke gates | U1 | `browser.tabs` on windows row when extension connected |
| **U3** | `browser.ensure` | E agent probes, F tool | U1 | `tool_exec browser.ensure` returns structured status |
| **U4** | Inst + prompt | G inst rows | U3 | `prompt_compose` on “install extension” phrase |
| **U5** | Linux parity | H linux agent | U1 | Same RPC on `c_remote_linux` |
| **U6** | Verify + publish | I tests, J publish doc | U2–U4 | `prompt_run` sheets phrase on 99000 VM fixture |

Parallel dispatch: **U0**; **U1(A+B)**; **U2(C+D)** after U1; **U3(E+F)** parallel with U2 once U1 B lands; **U4(G)** after U3; **U5(H)** after U1; **U6** last.

---

# U0 — Documentation

Files: `_/specs/remote.md`, `_/specs/browser-extension.md`, this plan.

- [ ] U0.1 **remote.md** — subsection “Unified extension on desktop agent” (one identity, `browser_ready`, NM host on desktop exe).
- [ ] U0.2 **browser-extension.md** — process diagram: NM host may be `alienai_remote_windows.exe`; standalone `alienai_remote_browser.exe` remains for browser-only pairing until deprecated in app UI.
- [ ] U0.3 Link this plan from `browser-extension.md` implementation section.

---

# U1 — Core extract + Windows integration

## Track A — `c_remote_browser_core`

Files: `remotes/c_remote_browser_core/**`, `remotes/Cargo.toml`, slim `c_remote_browser/src/*`.

- [ ] A.1 Add crate `c_remote_browser_core`; move extension + `browser_command` + `chrome_native` + `mode` + state (no playwright `engine/`).
- [ ] A.2 `c_remote_browser` bin depends on core; keep Playwright path in bin crate only.
- [ ] A.3 Public API: `register_browser_command_handler()`, `start_extension_ipc(BrowserState)`, `run_chrome_native_host_if_argv()`, `unified::attach_to_desktop_agent()`.
- [ ] A.4 `cargo build -p alienai_remote_browser` (unchanged binary name).

## Track B — Windows desktop

Files: `remotes/c_remote_windows/src/main.rs`, `remotes/c_remote_windows/Cargo.toml`, NM install scripts under `_/scripts/dev/`.

- [ ] B.1 Depend on `c_remote_browser_core`; call `attach_to_desktop_agent()` in `run()` after WebRTC setup.
- [ ] B.2 Replace `--chrome-native-host` exit(2) with core NM entry.
- [ ] B.3 Update Chrome NM manifest template / `sync_chrome_extension_install.ps1` docs to prefer desktop exe path when unified.
- [ ] B.4 `cargo build -p alienai_remote_windows`.

**Review gate U1:** On a dev PC, one paired windows device; extension connects; `tool_exec browser.tabs` op=list does not hit PowerShell.

---

# U2 — Server

## Track C — Presence meta

Files: `remotes/c_remote_browser_core` or `c_remote_core` heartbeat, `servers/crates/mod_device/src/agent_presence.rs`.

- [ ] C.1 Agent version report includes `browser_ready`, `browser_engine`, `extension_install_version`.
- [ ] C.2 Persist into `ai.identity.meta` on heartbeat (merge, do not wipe).

## Track D — Invoke + compose

Files: `servers/crates/mod_device/src/remote_signaling.rs`, `mod_chat` device_context, `mention_registry.rs`, `browser.rs`.

- [ ] D.1 `remote_browser_device_iid_for_invoke`: if type is windows/linux and `meta.browser_ready`, use same iid (remove wrong-device redirect when ready).
- [ ] D.2 If type is windows/linux and not ready: return error pointing to `browser.ensure` (not PowerShell stderr).
- [ ] D.3 Mention targets line: `browser_ready=…`.
- [ ] D.4 `cargo build -p server_ai`.

---

# U3 — `browser.ensure`

## Track E — Agent RPC

Files: `c_remote_browser_core` new `browser_ensure.rs`, wire in `browser_command` method `ensure` or `browser.ensure` cluster mapping.

- [ ] E.1 Implement probes + repair actions (sync install dir, register NM, open chrome://extensions).
- [ ] E.2 Method `ensure` on `__c35_browser__` wire.

## Track F — Cluster tool

Files: `servers/crates/mod_chat/src/tools/builtin/browser.rs`, tool registry.

- [ ] F.1 `browser.ensure` tool definition + `browser_invoke(..., "ensure", ...)`.
- [ ] F.2 Tests: arg parsing / device_iid resolve (unit).

---

# U4 — Inst

## Track G — Seeds

Files: `_/schemas/inst.sql`.

- [ ] G.1 Insert `inst.browser.ensure` (phrases, include_tools, body checklist).
- [ ] G.2 Update `inst.mention.sheets` per plan header.
- [ ] G.3 Live `inst_put` on cluster (operator step; not git).

---

# U5 — Linux

## Track H

Files: `remotes/c_remote_linux/src/main.rs`, `linux_shell.rs` (remove duplicate handler if conflicts).

- [ ] H.1 Same `attach_to_desktop_agent()` as Windows when extension NM supported on Linux (if NM host exists; else document defer).

---

# U6 — Verification

## Track I

- [ ] I.1 `prompt_compose` owner 99000: “open new google sheet …” with @windows device — expect `browser.tabs` fed.
- [ ] I.2 `prompt_run` when VM extension connected — hop 1 tool, not markdown-only fallback.
- [ ] I.3 `check_utf8_sources.ps1 -Changed`.
- [ ] I.4 Publish remote agent when B/C ship to paired VMs.

---

## Migration / coexistence

- Existing separate `type=browser` extension devices: keep working; app may show “merge” later.
- Users with **only** windows paired: after OTA, install extension once; `browser.ensure` guides.
- Do **not** run `alienai_remote_browser.exe` and unified windows agent with both binding extension IPC port — core must detect port in use and log single-owner rule (already in browser `main`).

---

## Out of scope

- Merging Playwright `type=browser` into windows (still separate product).
- Chrome Web Store listing.
- Fully silent extension install without user gesture on locked-down OS images (delegate + inst only).
