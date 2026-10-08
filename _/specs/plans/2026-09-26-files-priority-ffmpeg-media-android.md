# Remote Files priority, FFmpeg OTA, media streaming, Android polish

> **Status:** implemented (2026-09-26) — verify on paired VM + Android device  
> **Goal:** Ship fs traffic prioritization + upload throttle, FFmpeg sidecar OTA (server catalog → NATS + `/version` → agent/app install), file→WebRTC media MVP (HW encode, FFmpeg fallback), and Android Files UX parity where platform allows.

**Architecture (locked for this plan):**

- **Fs priority:** Client-side scheduler on single `remote-fs` SCTP channel — no second channel in v1.
- **FFmpeg:** Not in app/agent bundle; CAS zip under `AlienAI/ffmpeg/`; Blake3 verify; integer `version` in `ai.config`.
- **Version source:** Server publish pipeline (+ optional daily pin job); clients poll `/version` and listen `c35.release.ffmpeg-{platform}`.
- **Media encode:** On **remote agent** (Windows first) — MF hardware H.264 when possible; spawn pinned `ffmpeg.exe` on fallback.
- **Android:** No ffmpeg binary OTA on Play; Files polish = picker, SAF paths, preview, transfers, layout — not desktop drag-drop.

Read first: [`spec.md`](../../spec.md), [`_/specs/remote.md`](../remote.md), [`_/specs/auto-update.md`](../auto-update.md), [`_/specs/ui.md`](../ui.md#files-tab-remote).

---

## Wave 0 — Docs lock (parallel, no code deps)

| ID | Task | Output |
|----|------|--------|
| W0-A | Extend `auto-update.md` | `app.release.c35.ffmpeg-windows` JSON shape, NATS `c35.release.ffmpeg-windows`, install paths, atomic extract |
| W0-B | Extend `remote.md` | Fs priority table; media `RemoteMediaOpen` sketch; HW→ffmpeg pipeline; screen vs file track rule |
| W0-C | Extend `ui.md` | Android Files matrix (supported / degraded / N/A) |

**Acceptance:** Docs match decisions in this plan; no TBD on version keys or NATS subjects.

---

## Wave 1 — Fs priority + throttle (Flutter only)

| ID | Task | Files | Acceptance |
|----|------|-------|--------------|
| W1-A | **Priority queue** in `RemoteFsApi` | `remote_fs_api.dart` | High: `fsList`, `fsMkdir`, `fsDelete`, `fsRename`, preview `fsRead` (tagged). Low: transfer `fsRead`/`fsWrite`. High always preempts low. |
| W1-B | **Transfer throttle** | `remote_fs_transfer.dart` | Configurable max KB/s or inter-chunk delay on low-priority writes; pause low queue when high pending |
| W1-C | **UI hooks** | `ui_device_files.dart` | Preview/list calls use high priority; show “transfer paused” optional; `flutter analyze` clean |

**Verify:** Manual — start 100MB upload, expand folder + open `.txt` preview — listing/preview respond without multi-second stall.

**Depends:** none.

---

## Wave 2 — FFmpeg release catalog (server + publish)

| ID | Task | Files | Acceptance |
|----|------|-------|--------------|
| W2-A | **Config key** | `_/schemas/` or seed in deploy | `app.release.c35.ffmpeg-windows`: `{ version, hash, size, min_agent_build? }` |
| W2-B | **`GET /version/ffmpeg-windows`** | `wire_http` / version handler | Returns same JSON as `ai.config`; mirrors `/version/windows` auth/cache |
| W2-C | **Publish script** | `_/scripts/deploy/deploy_remote/` or `deploy_tools/` | Zip ffmpeg build → CAS → upsert `ai.config` → NATS `c35.release.ffmpeg-windows` |
| W2-D | **Daily pin job** (optional v1) | fetcher cron or deploy doc | Document: daily re-publish or version bump script; not required for MVP if manual publish OK |

**Verify:** `curl https://api.alienai.id/version/ffmpeg-windows` returns JSON; NATS message on publish.

**Depends:** W0-A.

---

## Wave 3 — FFmpeg install (agent + desktop app)

| ID | Task | Files | Acceptance |
|----|------|-------|--------------|
| W3-A | **Agent downloader** | `c_remote_core/src/update.rs` or `tools/ffmpeg.rs` | Path `%LOCALAPPDATA%\AlienAI\ffmpeg\`; staged download; Blake3; version file |
| W3-B | **Agent NATS + poll** | `update_run_loop`, agent WS relay | On `c35.release.ffmpeg-windows` + startup poll of `/version/ffmpeg-windows`; download if `remote_version > local` |
| W3-C | **App listener** | `app_update_service.dart`, `app_release.dart` | Deferred launch (~3s) + existing poll + NATS branch; if only ffmpeg newer → download tools zip only |
| W3-D | **Settings / status** (minimal) | Optional UI | Show ffmpeg version installed / update available (desktop) |

**Note:** Agent is primary **executor** for media; app may download same zip only if app spawns ffmpeg locally — prefer **agent-only** binary unless product needs app-side ffmpeg.

**Verify:** Bump `ai.config` version → agent downloads without full agent OTA; app does not reinstall APK for ffmpeg-only bump.

**Depends:** W2-B, W2-C.

---

## Wave 4 — Media streaming MVP (file → WebRTC video)

| ID | Task | Files | Acceptance |
|----|------|-------|--------------|
| W4-A | **Proto + signaling** | `remote.proto`, `session.rs` | `RemoteMediaOpen/Close/Status`; pause screen capture when playing file (locked in W0-B) |
| W4-B | **HW encode path** | `c_remote_windows` media module | MF: demux/decode → H.264 MFT → `TrackLocalStaticSample` on existing or secondary track |
| W4-C | **FFmpeg fallback** | same | If HW fails or unsupported: `AlienAI/ffmpeg/ffmpeg.exe -i ...` pipe or segment encode; same track feed |
| W4-D | **Flutter** | `ui_device_files.dart`, remote session | “Play” on video files; subscribe to track / reuse `RTCVideoRenderer`; stop restores screen |
| W4-E | **Requires ffmpeg** | agent | Clear error if exotic format and ffmpeg missing |

**Verify:** Play `.mp4` on paired VM; viewer sees video; screen share resumes on stop; relay path smoke.

**Depends:** W3-A (ffmpeg on agent), W0-B, W1 optional (priority during play).

---

## Wave 5 — Android Files polish

| ID | Task | Files | Acceptance |
|----|------|-------|--------------|
| W5-A | **Picker + paths** | `ui_device_files.dart`, `remote_fs_transfer.dart` | `file_picker` + content URIs: copy to temp or stream upload without assuming `dart:io` path on all URIs |
| W5-B | **Paste / share** | same | Document N/A for Explorer paste; support share-intent → upload queue if feasible |
| W5-C | **Download** | same | SAF directory picker; write via platform channels or `file_picker` save |
| W5-D | **Layout** | same | Narrow preview drill-in; transfer panel on master when tablet layout |
| W5-E | **Background** | docs + minimal | Warn when app backgrounded during transfer; optional wakelock during active job |

**Explicit N/A:** `desktop_drop`, Windows `Pasteboard.files()` paths, local ffmpeg OTA on Android Play build.

**Verify:** `flutter analyze`; manual on Android device — upload, list, preview text/image, download one file.

**Depends:** W1 (throttle helps mobile); not blocked on W4.

---

## Multitask dispatch map

Execute with **one subagent per row** (`model: inherit`). Respect wave order.

```
Wave 0 (parallel):  W0-A, W0-B, W0-C
Wave 1 (parallel):  W1-A, W1-B → then W1-C
Wave 2 (parallel):  W2-A, W2-B, W2-C, W2-D
Wave 3 (parallel):  W3-A, W3-B | W3-C, W3-D
Wave 4 (sequential after W3): W4-A → W4-B ∥ W4-C → W4-D → W4-E
Wave 5 (parallel with W4): W5-A … W5-E (can start after W1)
```

---

## Out of scope (this plan)

- Second `remote-fs-bulk` data channel
- Server-side ffmpeg (cluster fetcher running encode)
- iOS Files / ffmpeg
- Full Task/Skill device tabs

---

## Success criteria (release)

1. Upload running does not block folder list or 2MB text preview (W1).
2. `/version/ffmpeg-windows` + NATS push installs ffmpeg on agent without agent binary bump (W2–W3).
3. One video file plays over WebRTC on Windows with HW or ffmpeg (W4).
4. Android: upload + list + preview + download documented and working (W5).
