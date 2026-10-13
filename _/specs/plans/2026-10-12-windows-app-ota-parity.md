# Windows Desktop App OTA Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the sideloaded Windows desktop app (`alienai.exe` ZIP) to reliable OTA parity with the remote agent: instant release wake, background download + Blake3 staging, title-bar **Restart to update** (user-initiated apply), busy-aware behavior, and publish/NATS/deploy hooks.

**Architecture:** Keep the existing client pipeline (`GET /version/windows` → CAS zip → `%LOCALAPPDATA%\AlienAI\updates\` → `apply.ps1`). Add **`c35.release.windows`** NATS (publish on app release) and a **per-app-WS** subscription in `wire_ws` (mirror `agent_session.rs`, not the `c35.user.*.app.*` lane). Server pushes a small **`AppReleaseNudge`** on `WsRes`; Flutter calls `AppUpdateService.checkNow()` (download only). Wave 1 improves UX and polling **without** server changes so partial rollout is safe.

**Tech Stack:** Flutter (`clients/app/lib/c/update/*`), Rust `wire_ws` + `c35_mod_device` release helpers, protobuf (`_/schemas/proto/c35/`), Dart deploy (`deploy_app/`), PowerShell dev E2E, Yugabyte `ai.config` key `app.release.c35.windows`.

## Global Constraints

- Read [`spec.md`](../../spec.md), [`_/specs/auto-update.md`](../auto-update.md), [`_/specs/app-release.md`](../app-release.md), [`_/specs/sync.md`](../sync.md) before behavior changes.
- **Version compare:** build number (`234`), not semver — same as [`auto-update.md`](../auto-update.md).
- **No provider grounding / unrelated changes** in this plan.
- **App realtime NATS:** do **not** use `c35.user.{iid}.ev.*` for OTA; global release subject `c35.release.windows` + WS fanout only (see [`user-app-nats.mdc`](../../.cursor/rules/user-app-nats.mdc)).
- **Verify Flutter:** `.\_\scripts\dev\verify_flutter_app.ps1` after Dart edits.
- **Verify Rust:** `cd servers && cargo build -p server_ai` after `wire_ws` / proto changes; regenerate protos per repo convention.
- **Verify PowerShell:** parse edited `*.ps1` with `[System.Management.Automation.Language.Parser]::ParseFile`.
- **UTF-8:** `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` on touched sources.
- **Multitask:** one subagent per track per wave; **`model: inherit`** only (`subagent-model.mdc`).

---

## Current baseline

| Piece | Status |
|-------|--------|
| `AppUpdateService` poll (startup + 6h), download, Blake3, stage, `apply.ps1` | Done |
| Title bar `UiUpdateChrome` (Downloading / Restart) | Done |
| Idle 5 min → 10s countdown auto-install | Done — **change to user-only Restart** (this plan) |
| `registerBusyCheck` | **Stub only — never wired** |
| NATS `c35.release.windows` + WS nudge | **Missing** |
| NATS broadcast on `windows_upload_prod` / orchestrator | **Missing** |
| Windows OTA E2E (mock `/version`) | **Missing** (agent has `test_remote_autoupdate.ps1`) |
| `auto-update.md` documents app NATS wake | **Gap** (table mentions agents only) |

---

## File map (by track)

| Track | Create | Modify |
|-------|--------|--------|
| **W0 — Spec** | — | `_/specs/auto-update.md`, `_/specs/sync.md` (WS push row only if needed) |
| **1 — Client UX & polling** | — | `app_update_service.dart`, `ui_update_banner.dart`, `main.dart` |
| **2 — Busy gating & install** | `app_update_busy.dart` (optional thin registrar) | `app_update_install.dart`, `page_live_call.dart`, `chat_conn.dart`, remote viewer entrypoints |
| **3 — Proto + server WS** | `wire.proto` field `AppReleaseNudge` | `session.rs`, `router.rs` (`WsQuery.platform`), `agent_session.rs` (extract shared release helper if DRY) |
| **4 — Deploy NATS** | `_/scripts/deploy/deploy_app/nats_broadcast_windows_app_release.ps1` | `publish_app_version.dart` or `upload_windows_release.dart`, `deploy_app_release.dart` |
| **5 — E2E & smoke** | `_/scripts/dev/test_windows_app_autoupdate.ps1`, `_/scripts/dev/windows_app_autoupdate_mock_server.py` | — |
| **6 — Flutter WS handler** | `app_update_nudge.dart` | `chat_conn.dart`, `app_update_service.dart` |

---

## Multitask execution map

```text
Wave 1 (parallel — no server deploy required)
├── W0: Spec + contract (can start first; unblocks review)
├── Track 1: UX — user Restart only, adaptive poll, WS reconnect check
├── Track 2: Busy gating + apply.ps1 hardening
└── Track 5: Mock E2E script (against local mock; tests staging paths)

Wave 2 (parallel — needs proto regen + server rollout)
├── Track 3: AppReleaseNudge proto + wire_ws release fanout
├── Track 4: NATS broadcast on Windows app publish
└── Track 6: ChatConn handles nudge → checkNow()

Wave 3 (integration)
└── Track 7: Manual + prod smoke checklist, spec.md index link, optional publish dry-run doc
```

**Dependency notes**

- Track 6 depends on Track 3 (proto + server deployed or local stack).
- Track 4 can merge before Track 3 but NATS is useless until Track 3 ships.
- Track 5 can land in Wave 1 without NATS.

---

## W0 — Spec & contract

**Deliverable:** Locked behavior for operators and implementers.

### Requirements

- Add **§ Windows desktop app OTA** to [`_/specs/auto-update.md`](../auto-update.md):
  - Poll: startup + 6h up-to-date; **45s while staged or downloading**; immediate on WS `AppReleaseNudge` and WS reconnect.
  - NATS: `c35.release.windows` on publish; payload `{ platform, version, versionName, hash, size }` (same as remote-windows).
  - Apply: **user** title-bar **Restart to update**; no silent restart except `min` force gate.
  - Staging paths unchanged (`%LOCALAPPDATA%\AlienAI\updates\`).
- Document `AppReleaseNudge` in proto comment + optional one row in `sync.md` under **server-initiated WS pushes** (not app NATS lane).

### Tasks

- [ ] **W0.1** Patch `auto-update.md` (app vs agent comparison table).
- [ ] **W0.2** Add plan link row to [`spec.md`](../../spec.md) plans table.

### Verify

- Peer review only.

---

## Track 1 — Client UX & adaptive polling

**Deliverable:** Background download stays automatic; **install is always explicit** (title bar / Settings / force gate).

### Requirements

- **Disable idle countdown** for `AppUpdatePhase.ready` — remove or gate `_checkIdleAutoUpdate` auto `installNow()` / dialog for normal updates.
- Keep `UiUpdateForceGate` for `forceRequired` (blocks until user taps **Update now**).
- **Title bar copy:** `Restart to update` when `ready`; show version label consistently.
- **Adaptive poll** in `AppUpdateService.start()`:
  - `ready` or `downloading` → `Timer.periodic(45s, checkNow)` (mirror agent `POLL_PENDING_SECS`).
  - `upToDate` / `idle` → 6h (keep) or 1h if product prefers faster offline catch-up (pick **6h** unless spec revised).
- **`checkNow()` on WS reconnect:** from `ChatConn` when status → `connected` (Windows only, release build).
- Optional: show low-key `checking` in bar (short phase).

### Tasks

- [ ] **1.1** Change `_checkIdleAutoUpdate` to no-op for `ready` (or delete idle timer on Windows; keep Android path in `app_update_host.dart` untouched).
- [ ] **1.2** Update `UiUpdateChrome` strings and visibility rules.
- [ ] **1.3** Implement adaptive poll timers (cancel/reschedule on phase change via `state` listener).
- [ ] **1.4** Hook `ChatConn` `connected` → `AppUpdateService.instance.checkNow()` (Windows, `!kDebugMode`).

### Verify

```powershell
.\_\scripts\dev\verify_flutter_app.ps1
```

Manual: run release build, point `/version/windows` at mock (Track 5), confirm download shows in bar and **no** countdown dialog after idle.

---

## Track 2 — Busy gating & install hardening

**Deliverable:** No restart prompt while user is in sensitive flows; safer apply script.

### Requirements

- Wire `AppUpdateService.registerBusyCheck` with OR of:
  - `ChatConn` prompt in flight (existing prompt flight / streaming flag).
  - `LiveCallSession.ready` or equivalent active live call.
  - Active **outbound** remote control session (viewer controlling a device) — grep `remote` session state used by display appbar.
- While busy: still **download** in background; only suppress any future auto-apply (already removed in Track 1); bar **Restart** may stay enabled (user override) — **product choice: allow manual Restart while busy** (document in spec); do not block `installNow()` unless we add explicit confirm dialog later.
- **`app_update_install.dart`:** spawn PowerShell with `CREATE_NO_WINDOW` equivalent (match agent `spawn_apply_script` flags via `ProcessStartMode` + `windows` package or `cmd /c start` pattern used elsewhere in repo).
- Extend graceful shutdown wait to **~8s** (align agent).

### Tasks

- [ ] **2.1** Add `app_update_busy.dart` with `bool appUpdateUserBusy()` aggregating signals.
- [ ] **2.2** Register from `main.dart` after boot (`registerBusyCheck`).
- [ ] **2.3** Harden `app_update_install.dart` apply script + process spawn.
- [ ] **2.4** Unit test for busy aggregator if pure-Dart (optional).

### Verify

```powershell
.\_\scripts\dev\verify_flutter_app.ps1
```

---

## Track 3 — Proto + server WebSocket release fanout

**Deliverable:** Connected Windows app receives instant nudge when operators publish.

### Requirements

- Add to `_/schemas/proto/c35/wire.proto` (or `session.proto`):

```protobuf
message AppReleaseNudge {
  string platform = 1;  // "windows"
  int64 version = 2;    // optional hint; client still calls /version
}
```

- Add `app_release_nudge = NN` to `WsRes` oneof (next free field id).
- Regenerate Rust + Dart protos (repo script / `build_runner` as documented).
- Extend `WsQuery` with optional `platform` (int32) **or** reuse `build` only and subscribe all desktop clients — **prefer explicit `platform=3`** on query string from Flutter `ChatConn.wirePlatform()` for Windows.
- New module or functions in `wire_ws` (extract from `agent_session.rs` if useful):
  - `spawn_app_release_nudge_loop(pool, app_build, out_tx)` — platform key `"windows"`, config `app.release.c35.windows`.
  - NATS subscribe `c35.release.windows` → send `WsRes { app_release_nudge: { platform: "windows", version } }`.
  - Constant nudge payload fallback: `b"c35.release:windows"` (parallel to agent).
- Only spawn when `app_build > 0` and `platform == 3` (Windows).

### Tasks

- [x] **3.1** Proto + regenerate.
- [x] **3.2** `router.rs` — add `platform` to `WsQuery`.
- [x] **3.3** `session.rs` — spawn nudge loop + NATS sub after auth (use `q.build`, `q.platform`).
- [x] **3.4** `cargo build -p server_ai` from `servers/`.

### Verify

```powershell
cd servers
cargo build -p server_ai
```

Local: connect WS with `build=1&platform=3`, publish NATS message (cluster or `nats` CLI), observe binary frame (log at debug).

---

## Track 4 — Deploy NATS broadcast (Windows app)

**Deliverable:** Every prod Windows app publish fires `c35.release.windows` from cluster (same pattern as remote).

### Requirements

- Copy pattern from [`_/scripts/deploy/deploy_remote/nats_broadcast_remote_release.ps1`](../../_/scripts/deploy/deploy_remote/nats_broadcast_remote_release.ps1):
  - Subject: `c35.release.windows`
  - `platform`: `windows`
- Invoke after `publishWindowsAppVersion` in `upload_windows_release.dart` / `deploy_app_release.dart` (flag `-SkipNats` for dry runs).
- Document env / kubectl prerequisites in `app-release.md`.

### Tasks

- [x] **4.1** Add `nats_broadcast_windows_app_release.ps1`.
- [x] **4.2** Wire Dart `Process.run` or PowerShell call from publish path (mirror remote agent publish).
- [x] **4.3** Update `app-release.md` script matrix.

### Verify

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('D:\c35\_\scripts\deploy\deploy_app\nats_broadcast_windows_app_release.ps1', [ref]$null, [ref]$errors)
```

After prod publish (operator): `curl -sS https://api.alienai.id/version/windows` then confirm connected client logs download (Track 6).

---

## Track 5 — Dev E2E (mock version server)

**Deliverable:** Repeatable Windows app OTA test without production.

### Requirements

- Python mock (or reuse pattern from `remote_autoupdate_mock_server.py`) serving:
  - `GET /version/windows` → JSON with `version`, `hash`, `size`, `url` (local file).
- Zip fixture: minimal `alienai.exe` stub + optional DLL, Blake3 known hash.
- PowerShell `test_windows_app_autoupdate.ps1`:
  - Set `C35_SERVER` / override API base env used by `serverHostActiveBase` **only for test process** (document limitation if hardcoded to prod).
  - Launch built `alienai.exe` with test flags if needed, or unit-test Dart `appUpdateDownloadVerify` + staging paths.
  - Assert staging dir contains exe; **optional** apply in CI sandbox.
- Prefer **Dart tests** for hash/extract + **PS1** for full loop if launching exe is heavy.

### Tasks

- [ ] **5.1** Mock server script.
- [ ] **5.2** `test_windows_app_autoupdate.ps1` + fixture zip builder note in header comment.
- [ ] **5.3** Add `clients/app/test/app_update_windows_staging_test.dart` (paths + blake3) if no exe launch.

### Verify

```powershell
.\_\scripts\dev\test_windows_app_autoupdate.ps1
```

---

## Track 6 — Flutter WS nudge handler

**Deliverable:** NATS → server → client → background download.

### Requirements

- `app_update_nudge.dart`: `void appUpdateOnReleaseNudge(AppReleaseNudge n)` → `unawaited(AppUpdateService.instance.checkNow())`.
- `ChatConn` decode `WsRes` branch for `appReleaseNudge` (or generated name).
- Debounce: ignore nudge if `_busy` check already running; coalesce within 2s.
- Windows + release only.

### Tasks

- [x] **6.1** Handler module + service hook.
- [x] **6.2** Wire in `chat_conn.dart` message dispatch.
- [x] **6.3** Pass `platform` query param on WS URL (`wirePlatform()` when Windows).

### Verify

```powershell
.\_\scripts\dev\verify_flutter_app.ps1
```

With local server + Track 3: publish NATS → client bar shows **Downloading** then **Restart to update**.

---

## Track 7 — Integration checklist (Wave 3)

**Deliverable:** Operator confidence before calling “done”.

### Tasks

- [ ] **7.1** Manual matrix:

| Step | Action | Expected |
|------|--------|----------|
| A | Old build running, publish new Windows app + NATS | Connected client starts download &lt; 1 min |
| B | Download completes | Title bar **Restart to update** |
| C | User clicks Restart | App exits, files mirrored, new build starts |
| D | `min` raised above local build | Force gate; download then **Update now** |
| E | Live call active | Download OK; user can still choose Restart (per Track 2 doc) |
| F | Logged out / no WS | Startup `checkNow` still works |

- [ ] **7.2** Run Track 5 PS1 on CI or dev machine; attach output to PR.
- [ ] **7.3** `check_utf8_sources.ps1 -Changed -Fix`.

---

## Subagent dispatch cheat sheet

| Wave | Track | Suggested subagent prompt focus |
|------|-------|----------------------------------|
| 1 | W0 | Spec edits only |
| 1 | 1 | `AppUpdateService` + `UiUpdateChrome` + reconnect check |
| 1 | 2 | Busy registrar + install.ps1 |
| 1 | 5 | Mock server + PS1 E2E |
| 2 | 3 | Proto + `wire_ws` |
| 2 | 4 | NATS broadcast script + Dart wire |
| 2 | 6 | `ChatConn` + nudge handler |
| 3 | 7 | Checklist + verify all scripts |

---

## Out of scope (follow-ups)

- macOS/Linux desktop (currently no `AppUpdateService.start` on those platforms).
- MSIX / Store update channel.
- Per-user `c35.user.{iid}.app.release` NATS (unnecessary vs global `c35.release.windows`).
- Tray notifications (optional polish).

---

## Reference commands

```powershell
# Flutter
.\_\scripts\dev\verify_flutter_app.ps1

# Server
cd servers
cargo build -p server_ai

# Windows app publish (existing)
cd _\scripts\deploy
dart run deploy_app/windows_upload_prod.dart

# After Track 4
.\deploy_app\nats_broadcast_windows_app_release.ps1 -Version <N> -VersionName <name> -Hash <blake3> -Size <bytes>
```
