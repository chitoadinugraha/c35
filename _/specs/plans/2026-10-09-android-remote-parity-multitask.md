# Android remote parity — FS, shell, teach, drive (master multitask plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Implementation status** and each wave **Review gate** before starting the next wave.

**Goal:** Close the gap between **Windows** and **Android** remote agents for **device.fs** (Files tab + chat tools), **shell.run** (platform-appropriate), **skill teach** (Remote tab from main app), and **Alien mapped drive** (explicit N/A on Android with docs + steering).

**Architecture:** Keep one wire plane (`c_remote_core` WebRTC + agent WS). Android adds a **storage backend** behind existing `remote-fs` / `ReqRemoteFs*` (virtual roots + SAF/JNI), a **shell backend** behind existing `ReqRemoteCommand` (not PowerShell), and **teach hooks** on the Android input path (Accessibility metadata). **Alien AI Drive (`A:`)** stays **Windows-only**; Android uses **Files over `remote-fs`** only.

**Tech stack:** Rust (`c_remote_core`, `c_remote_android` NDK), Kotlin (SAF, `DocumentFile`, foreground services), Flutter (`clients/app` remote + files + teach), server (`mod_device`, `mod_chat` tools/inst).

**Specs:** [`_/specs/remote-android.md`](../remote-android.md), [`_/specs/remote.md`](../remote.md), [`_/specs/skill.md`](../skill.md), [`_/specs/ui.md`](../ui.md), [`_/specs/plans/2026-09-26-files-priority-ffmpeg-media-android.md`](2026-09-26-files-priority-ffmpeg-media-android.md), [`_/specs/plans/2026-09-29-remote-skill-teach-multitask.md`](2026-09-29-remote-skill-teach-multitask.md), [`_/specs/plans/2026-09-27-alien-ai-drive-multitask.md`](2026-09-27-alien-ai-drive-multitask.md)

## Global constraints

- Proto: `_/schemas/proto/c35/remote.proto` (+ regenerate Dart pb after wire changes).
- Android agent: `cargo ndk` / `dev_build_android.ps1`; ship APK via `publish_remote_android.ps1` when pairing with cluster.
- Windows agent: `publish_remote_agent.ps1` only when `c_remote_windows` / shared core changes affect Windows.
- App: `.\_\scripts\dev\verify_flutter_app.ps1` after Flutter edits.
- Server: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_device` / `c35_mod_chat` when touched.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after `.rs` / `.md` / `.dart` / `.kt` edits.
- Do not commit unless user asks.

---

## Implementation status (today)

Legend: **Done** = works end-to-end for intended platform · **Partial** = wire/UI exists, agent/backend missing or wrong semantics · **N/A** = not a product goal on that platform · **Not started** = no meaningful code.

### Shared core (`c_remote_core`)

| Capability | Windows agent | Android agent | Notes |
|------------|---------------|---------------|--------|
| Pairing + agent WS | Done | Done | `daemon.rs`, `conn_ws` |
| WebRTC `remote-input` | Done | Done | Win32 vs Accessibility JNI |
| WebRTC `remote-screen` + RTP H.264 | Done | Done | DXGI/MFT vs MediaCodec |
| WebRTC `remote-fs` channel wired | Done | Done | `session.rs` → `wire_fs_channel` |
| FS ops implementation (`fs.rs`) | Done | **Partial** | Same Windows-centric `std::fs` + `A:`–`Z:` roots; empty/wrong on Android |
| Agent WS `ReqRemoteFsList/Read` | Done | **Partial** | Same `fs_list` / `fs_read` |
| `ReqRemoteCommand` / `shell.run` | Done | **Not started** | `#[cfg(not(windows))]` returns unsupported |
| `remote-teach` channel + `teach.rs` | Done | **Partial** | DC works; no Android `register_platform` / input recorder |
| Skill tape playback (`skill_tape`) | Done | **Partial** | Input steps OK; `shell` steps need Android shell |
| Skill dispatch over WS (`skill_dispatch`) | Done | Done | Shared; playback quality depends on above |
| OTA (`update`, APK install) | Done | Done | `register_android_apk_installer` |
| FFmpeg sidecar | Done | N/A | Plan: agent-only Windows |
| Alien mapped drive (`c_remote_drive`) | Done | N/A | WinFsp/subst; `c_remote_windows/src/drive/` |

### Main app (`id.alienai.app` → remote **Android** device)

| Capability | Status | Notes |
|------------|--------|--------|
| Remote tab (view/control) | Done | `ui_device_detail.dart` |
| Files tab UI (`UiDeviceFiles`) | **Partial** | UI is device-agnostic; **listing Android storage fails** (agent FS) |
| `device.fs.list` / `device.fs.read` (chat) | **Partial** | Server + tools **Done**; Android agent returns empty/errors |
| `shell.run` (chat) | **Not started** on Android | Tool registered globally; agent rejects command |
| Skill teach HUD + `remote-teach` | **Partial** | Flutter **Done** (`remote_teach.dart`, HUD); Android agent records **no steps** |
| Skill tab (library/run) | Done | Device-scoped skills; run needs tape + shell parity |
| Copy mentions F9 / “on the PC” | **Partial** | `ui_device_detail.dart` — needs Android-specific teach copy |

### Alien AI Drive (`A:` cloud mount)

| Platform | Status |
|----------|--------|
| Windows | **Done** (`c_remote_drive`, agent toggle) |
| Android | **N/A** — no WinFsp; parity = **Files tab + optional future “cloud folder” in app**, not a drive letter |

### Documentation vs code

| Doc | Says | Code |
|-----|------|------|
| `remote-android.md` | `remote-fs` via SAF / app storage | **Not started** (SAF backend) |
| `ui.md` Android matrix | Files UX when **phone browses remote PC** | **Done** (orthogonal to this plan) |

---

## Outcomes (acceptance)

1. **FS:** Paired Android phone: Files tab lists **granted storage roots** + app-private dirs; upload/download/mkdir/rename/delete work within policy; chat `device.fs.list` / `device.fs.read` return real paths on Android agents.
2. **Shell:** `shell.run` on `type=android` runs **approved** commands (documented allowlist); errors are clear; inst steers Android vs Windows paths.
3. **Teach:** From main app Remote tab on Android device: start teach → steps recorded from viewer input + a11y labels → stop → review → `ReqSkillPut` with steps; optional on-device recording indicator (overlay).
4. **Drive:** Spec + UI copy state **Alien Drive is Windows-only**; Android Files documented as the mountless equivalent; no `A:` implementation on Android.

---

## Master wave map

```text
W0 Spec + path contract (virtual roots, inst)
    │
    ├── W1 Android FS backend (parallel tracks A–D)
    │         └── W1-E Integration tests + manual Files smoke
    │
    ├── W2 Android shell.run (parallel E–G) — can start after W0; ship after W1 if shell reads FS staging
    │
    ├── W3 Android skill teach (parallel H–J) — depends W1 optional, W2 optional for shell steps
    │
    ├── W4 Drive N/A + product copy (parallel K–L) — parallel with W1
    │
    └── W5 Flutter polish + server steering (parallel M–O) — after W1–W3 slices land
              └── W6 E2E checklist + publish
```

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **W0** | Contracts | — | — | Path grammar + inst draft reviewed |
| **W1** | Android FS | A=Kotlin SAF, B=Rust dispatch, C=virtual roots, D=persist grants | W0 | Files tab lists real dirs on device |
| **W2** | Android shell | E=executor, F=security/timeout, G=skill tape shell | W0 | `shell.run` smoke via MCP `tool_exec` |
| **W3** | Android teach | H=recorder, I=overlay, J=Flutter copy | W0; H needs input path | Teach → save → steps in DB |
| **W4** | Drive N/A | K=specs, L=app strings | — | No user expectation of `A:` on Android |
| **W5** | Product wiring | M=tool gating, N=inst.sql, O=ui.md android-remote matrix | W1–W3 | @Android mentions get correct tools |
| **W6** | Verify + publish | — | W1–W5 | Checklist green; APK publish if agent changed |

**Parallel dispatch:** One subagent per track (`model: inherit`). Do not start W6 until W1 Files smoke passes.

---

# W0 — Spec + path contract

- [ ] **W0.1** Add subsection **Android storage paths** to [`_/specs/remote-android.md`](../remote-android.md):
  - Virtual roots: `""` → entry list; `app:` (private), `shared:` (if API allows), `tree:{id}` for SAF grants.
  - Wire paths are **opaque UTF-8** strings (not Windows `C:\`).
  - Mutations denied on `tree:` root without write grant.
- [ ] **W0.2** Add **Android remote Files** matrix to [`_/specs/ui.md`](../ui.md) (when **device type is android**, not “phone browsing PC”).
- [ ] **W0.3** Sketch path grammar in comment atop new `remotes/c_remote_core/src/webrtc/fs_android.rs` (or `fs/platform/android.rs`).
- [ ] **Review gate W0:** Chito confirms virtual root names and SAF UX (one-time folder pick vs per-session).

---

# W1 — Android filesystem (`device.fs` + Files tab)

### Track A — Kotlin SAF service

**Files:** `remotes/c_remote_android/android/.../storage/RemoteStorageBridge.kt` (new), extend `NativeBridge.kt`.

- [ ] **A.1** Persist SAF tree URIs (`SharedPreferences` or Room): `{tree_id, display_name, document_uri, granted_ts}`.
- [ ] **A.2** Activity/intent: **Add folder** from agent UI (MainActivity or Settings card) → `ACTION_OPEN_DOCUMENT_TREE` + `takePersistableUriPermission`.
- [ ] **A.3** Implement: `listChildren(path)`, `readRange(path, offset, max)`, `writeChunk`, `mkdir`, `delete`, `rename` via `DocumentFile` / `ContentResolver`.
- [ ] **A.4** Expose JNI: `nativeFsList`, `nativeFsRead`, … matching Rust expectations (JSON or byte[] protobuf — prefer reusing existing proto decode in Rust).

### Track B — Rust FS dispatch

**Files:** `remotes/c_remote_core/src/webrtc/fs.rs`, new `fs_android.rs`, `#[cfg(target_os = "android")]` in `fs_list` / `fs_read` / `fs_write` / …

- [ ] **B.1** `list_drives()` on Android → virtual roots (not `A:`–`Z:`).
- [ ] **B.2** `path_resolve` on Android → map `tree:{id}/relative/...` to JNI; deny `..`.
- [ ] **B.3** Delegate mutations to JNI; map errors to `RemoteFs*Res.error`.
- [ ] **B.4** Keep Windows path in `#[cfg(windows)]` block unchanged.

### Track C — App-private + downloads shortcuts

- [ ] **C.1** `app:` root lists `context.filesDir`, `cacheDir`, `externalFilesDir` where readable.
- [ ] **C.2** Optional `downloads:` via `MediaStore` read-only listing (document limits in spec).

### Track D — Agent UI surfacing

**Files:** `MainActivity.kt`, strings.

- [ ] **D.1** Paired state card: **Storage access** — count of granted trees + **Add folder** button.
- [ ] **D.2** Status JSON field for Flutter/debug: `storage_grants: N`.

### Track E — Verification

- [ ] **E.1** Rust unit test: `path_resolve` / root listing on Android target (cfg-gated).
- [ ] **E.2** Manual: pair Android agent → desktop app Files tab → list `app:` + SAF tree → upload 1 MB → download → rename → delete.
- [ ] **E.3** MCP: `tool_exec` `device.fs.list` with `owner_iid` 99000, Android `device_iid`, path `app:` or `tree:…`.

**Review gate W1:** Files tab + `device.fs.list` non-empty on Chito Android device.

---

# W2 — Android `shell.run`

**Design (locked in W0 unless Chito changes):** Same tool name `shell.run`; agent runs **`/system/bin/sh -c`** (or `cmd` subset) with **allowlist** — no arbitrary root.

### Track E — Executor

**Files:** `remotes/c_remote_core/src/webrtc/session.rs`, new `android_shell.rs` + JNI `nativeShellRun`.

- [ ] **E.1** `#[cfg(target_os = "android")]` branch in `handle_command` before Windows-only error.
- [ ] **E.2** Allowlist categories: `pm list`, `am start` (explicit packages), `cmd notification`, `input keyevent` (if not duplicating `device.input`), read-only `getprop` — **expand list in spec**.
- [ ] **E.3** Timeout + max output bytes (match Windows 60s cap / truncation).
- [ ] **E.4** Deny by default; return stderr explaining allowlist.

### Track F — Security + audit

- [ ] **F.1** Log command hash + exit code to agent ring (no secrets).
- [ ] **F.2** Document threat model in `remote-android.md` (MDM / owner-trusted device).

### Track G — Skill tape `shell` steps

- [ ] **G.1** `skill_tape.rs`: on Android, `shell` step calls `android_shell` instead of `win_powershell`.

**Verify:** `prompt_run` or MCP with `@Android` mention and a allowlisted command (e.g. `getprop ro.product.model`).

**Review gate W2:** One allowlisted command succeeds; one disallowed command fails closed.

---

# W3 — Android skill teach

**Reminder:** Teach UX is **main app Remote tab** (`RemoteTeachApi`, HUD). Target phone runs recorder + optional overlay — **not** a teach flow inside `id.alienai.remote` settings UI.

### Track H — Recorder on input path

**Files:** `remotes/c_remote_android/src/lib.rs` or `webrtc_bridge.rs`, new `skill_teach_android.rs`, Kotlin a11y metadata.

- [ ] **H.1** `skill_teach::register_platform` — start/stop: show/hide teach overlay (reuse `OverlayMarkerService` pattern).
- [ ] **H.2** On each injected gesture from viewer: if `teach_is_recording()`, call `teach_record_click` with **package/activity + node text** from `AccessControlService` (mirror `skill_teach_remote` + UIA fields).
- [ ] **H.3** `type_text` → `teach_focus_field` + char events.
- [ ] **H.4** Wire `remote-teach` already in `session.rs` — no new channel.

### Track I — On-device affordances

- [ ] **I.1** Recording border or chip (spec: green border analog on Android).
- [ ] **I.2** Global stop: volume key combo or notification action (F9 is N/A).

### Track J — Flutter copy + guards

**Files:** `ui_device_detail.dart`, `ui_remote_teach_hud.dart`.

- [ ] **J.1** Snackbar/HUD strings branch on `device.type == android`.
- [ ] **J.2** Optional: disable teach menu when Accessibility off (with deep link to settings).

**Verify:** Teach 3 taps on Android → stop → review shows steps with labels → save → Skill tab lists steps → Run replays taps.

**Review gate W3:** E2E teach save on Android device.

---

# W4 — Alien mapped drive (N/A on Android)

### Track K — Specs

- [ ] **K.1** [`_/specs/remote-android.md`](../remote-android.md): **Alien AI Drive** explicitly Windows-only; link [`drive.md`](../drive.md) if present.
- [ ] **K.2** [`_/specs/remote.md`](../remote.md): cross-platform table row — Drive vs Files.

### Track L — App copy

- [ ] **L.1** Devices detail: hide/disable Drive toggle when `type == android` (if any drive UI leaks).
- [ ] **L.2** Docs snippet: “Sync cloud files on Android via Files tab, not A:.”

**Review gate W4:** No open issues claiming Android `A:` drive.

---

# W5 — Server + inst steering

### Track M — Tool eligibility

**Files:** `servers/crates/mod_chat/src/tools/builtin/device.rs`, `device_context.rs`, compose filters.

- [ ] **M.1** Resolve device `type` from mention / `device_iid` when building tool catalog.
- [ ] **M.2** `shell.run`: include for `windows`; include for `android` only after W2 with description noting allowlist.
- [ ] **M.3** `device.fs.*`: unchanged names; description mentions Android virtual paths.

### Track N — `inst.sql`

- [ ] **N.1** New or extend `inst.device.android` (facts-only): paths, no Recycle Bin, no `C:\`, prefer `device.input` + `device.fs.*`.
- [ ] **N.2** `computer_use` topic: sub-bullet for Android (no PowerShell bulk extract).

### Track O — Seed live inst

- [ ] **O.1** `inst_put` live after seed change (git seed alone insufficient per `prompt-run-test.mdc`).

---

# W6 — E2E checklist + publish

- [ ] **V.1** `cd remotes && cargo build -p c_remote_android` (NDK target).
- [ ] **V.2** `.\_\scripts\dev\verify_flutter_app.ps1`
- [ ] **V.3** `cd servers && cargo build -p server_ai`
- [ ] **V.4** Manual matrix (one Android + one Windows control):

| Test | Android agent | Windows agent |
|------|---------------|---------------|
| Files list roots | | |
| Chat `device.fs.list` | | |
| `shell.run` allowlisted | | N/A same test |
| Teach save 3 steps | | regression |
| Alien Drive mounted | N/A | smoke |

- [ ] **V.5** If agent changed: `.\_\scripts\deploy\publish_remote_android.ps1` (+ Windows script only if `c_remote_core` FS/shell shared code risks Windows).

---

## Multitask dispatch (suggested wave 1)

After **W0** review, launch in parallel:

| Subagent | Track | Deliverable |
|----------|-------|-------------|
| 1 | W1-A + W1-D | Kotlin SAF + UI |
| 2 | W1-B + W1-C | Rust Android FS |
| 3 | W4-K + W4-L | Drive N/A docs + copy |
| 4 | W5-M (draft only) | Server tool gating design PR |

Wave 2: **W2** (shell), **W3** (teach), **W5-N/O**, then **W6**.

---

## References

| Area | Primary files |
|------|----------------|
| FS wire | `remotes/c_remote_core/src/webrtc/fs.rs`, `session.rs` |
| Android agent | `remotes/c_remote_android/src/webrtc_bridge.rs`, `daemon.rs`, `lib.rs` |
| Windows parity | `remotes/c_remote_windows/src/main.rs`, `input_exec.rs`, `drive/` |
| Flutter Files | `clients/app/lib/widgets/devices/ui_device_files.dart`, `c/remote/remote_fs_api.dart` |
| Flutter teach | `clients/app/lib/c/remote/remote_teach.dart`, `widgets/devices/ui_remote_teach_hud.dart` |
| Chat tools | `servers/crates/mod_chat/src/tools/builtin/device.rs` |
| Prior teach plan | [`2026-09-29-remote-skill-teach-multitask.md`](2026-09-29-remote-skill-teach-multitask.md) |
