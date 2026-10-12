# Live Call on Flutter Web — Multitask Plan

> **For agentic workers:** Use `plan-execution.mdc` — dispatch one `Task` subagent per track below; **model: inherit** only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make **Live Call** (`PageLiveCall` / `LiveCallSession`) a **supported, testable** experience on Flutter web at `https://alienai.id/app/`, with browser-appropriate mic capture, reliable assistant playback, working attach/camera where the browser allows, and clear errors when it does not.

**Architecture:** Keep the existing server path (`ReqLiveStart` → `/v1/live/ws`). Fix and harden **client-only** gaps: web mic candidate order (16 kHz mono first), autoplay unlock on the user’s Connect gesture, web-safe file pick (`withData: kIsWeb`), and shared mic-stream config with `SttService` to avoid drift. Add a short **supported clients** section to `_/specs/live-call.md`. No provider-native web grounding changes (`web-grounding-cluster-only.mdc`).

**Tech Stack:** Flutter web (`clients/app`), `record`, `audioplayers`, `flutter_webrtc`, `web_socket_channel`, existing `live_call_session_test.dart` patterns.

**Out of scope (this plan):**

- Remote **device WebRTC viewer** on web (stays blocked in `remote_session.dart`).
- New Live backends or `ai.live_offer` rows (already shipped).
- Chromium STT URL (`voice-no-chromium-stt.mdc`).

## Global Constraints

- Read `spec.md`, `_/specs/live-call.md`, `_/specs/ui.md` (# Talk vs Live Call), `_/specs/voice.md` before coding.
- Verify Flutter: `.\_\scripts\dev\verify_flutter_app.ps1`; `flutter test` for touched tests.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Subagent model: **inherit** (not `*-fast`).
- Do not commit unless the user asks.
- Web publish (after QA): `.\_\scripts\deploy\deploy_app\push_web.dart` per `_/specs/app-release.md` — not part of dev tracks unless user requests release.

---

## Multitask map

```
Track 0 (Repro + matrix)     ──► all implementation tracks
Track A (Mic uplink web)     ──► Track D
Track B (Playback web)       ──► Track D
Track C (Page web UX)        ──► Track D
Track D (Integration QA)     ──► Track E + Track F
Track E (Automated tests)    ──► parallel with D once A–C land
Track S (WS smoke, optional) ──► parallel with 0 if connect fails before mic
```

| Track | Focus | Depends |
|-------|--------|---------|
| **0** | Repro script, browser matrix, PASS/GAP log | — |
| **A** | Web-first PCM stream candidates + shared config with STT | 0 |
| **B** | Autoplay / playback unlock on web | 0 |
| **C** | `PageLiveCall` attach/camera/speaker web behavior | 0 |
| **D** | End-to-end manual sign-off on matrix | A, B, C |
| **E** | Unit/widget tests (no browser CI required) | A, B, C |
| **F** | Spec + optional user doc | D |
| **S** | Confirm `/v1/live/ws` from browser origin (only if Track 0 shows WS failure) | 0 |

**Parallel wave 1:** Track **0** (gate)  
**Parallel wave 2:** Track **A** + Track **B** + Track **C** (+ **S** if needed)  
**Parallel wave 3:** Track **D** + Track **E**  
**Wave 4:** Track **F**

---

## Track 0 — Repro baseline and browser matrix

**Deliverable:** `.cache/live-call-web-matrix.md` (gitignored notes OK) or a short section pasted in PR — not required in repo unless user wants it committed.

### Task 0.1: Manual repro checklist

- [ ] **Step 1:** Build web locally:

```powershell
cd D:\c35\clients\app
flutter build web --base-href /app/
```

Serve with any static server on **HTTPS** or `localhost` (mic requires secure context except localhost).

- [ ] **Step 2:** Sign in as **99000** (or dev account with Frontier quota). Open Home → **Call** → pick **Call Alien AI** (or any enabled offer).

- [ ] **Step 3:** Record per browser:

| Browser | Connect | Mic uplink (model hears you) | Downlink audio | Camera toggle | File attach | Notes |
|---------|---------|------------------------------|----------------|---------------|-------------|-------|
| Chrome desktop | | | | | | |
| Edge desktop | | | | | | |
| Firefox desktop | | | | | | |
| Safari macOS | | | | | | |
| Chrome Android | | | | | | |
| Safari iOS | | | | | | |

- [ ] **Step 4:** For each failure, capture: console errors, `LiveCallSession` debug lines, network WS close code on `/v1/live/ws`.

**Exit criteria:** Matrix filled; implementation tracks target **red** cells only (do not gold-plate working paths).

---

## Track A — Mic uplink (web-first stream config)

**Problem:** On web, `LiveCallSession._startMic` uses the **desktop** candidate list (48 kHz stereo first). Server expects **16 kHz mono** PCM uplink. Resampling works but increases failure modes and latency. `SttService` and `LiveCallSession` duplicate candidate lists.

### Task A.1: Shared mic stream candidates

**Files:**

- Create: `clients/app/lib/c/audio/mic_stream_candidates.dart`
- Modify: `clients/app/lib/c/live/live_call_session.dart` (`_startMic` candidate loop)
- Modify: `clients/app/lib/c/stt/stt_service.dart` (`startRecording` candidate loop)

**Interfaces:**

- Produces: `List<({int sampleRate, int numChannels, int bitRate})> micStreamCandidates({required bool isMobile, required bool isWeb})`

- [ ] **Step 1: Add helper** (`mic_stream_candidates.dart`):

```dart
typedef MicStreamCandidate = ({int sampleRate, int numChannels, int bitRate});

List<MicStreamCandidate> micStreamCandidates({required bool isMobile, required bool isWeb}) {
  if (isMobile || isWeb) {
    return [
      (sampleRate: 16000, numChannels: 1, bitRate: 256000),
      (sampleRate: 48000, numChannels: 1, bitRate: 768000),
      (sampleRate: 44100, numChannels: 1, bitRate: 705600),
    ];
  }
  return [
    (sampleRate: 48000, numChannels: 2, bitRate: 1536000),
    (sampleRate: 48000, numChannels: 1, bitRate: 768000),
    (sampleRate: 44100, numChannels: 2, bitRate: 1411200),
    (sampleRate: 44100, numChannels: 1, bitRate: 705600),
    (sampleRate: 16000, numChannels: 1, bitRate: 256000),
  ];
}
```

- [ ] **Step 2:** In `live_call_session.dart`, replace inline `candidates` with:

```dart
final bool isMobile = !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
final candidates = micStreamCandidates(isMobile: isMobile, isWeb: kIsWeb);
```

- [ ] **Step 3:** In `stt_service.dart`, use the same helper for the non-cached candidate list (keep `_workingStreamConfig` behavior unchanged).

- [ ] **Step 4:** Run `flutter test test/live_call_session_test.dart` and STT-related tests if any.

Run: `cd D:\c35\clients\app; flutter test test/live_call_session_test.dart`

Expected: PASS (no behavior change on desktop tests).

### Task A.2: Web microphone error copy

**Files:**

- Modify: `clients/app/lib/c/stt/stt_mic_permission.dart` (`sttMicErrorMessage`)

- [ ] **Step 1:** When `kIsWeb`, return actionable copy:

```dart
if (kIsWeb) {
  return 'Microphone blocked or unavailable. Click the lock or site-settings icon in the browser address bar and allow microphone access for this site, then try again.';
}
```

(before the generic fallback at the end of the function).

- [ ] **Step 2:** Ensure `PageLiveCall._connect` still surfaces `sttMicErrorMessage()` when `sttMicPermissionEnsure` / `hasPermission` fails.

---

## Track B — Assistant playback (web autoplay)

**Problem:** Browsers block audio until a **user gesture**. Connect is a gesture, but `audioplayers` may not unlock until the first `play()` runs in that gesture chain.

### Task B.1: Unlock audio on Connect

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart`
- Modify: `clients/app/lib/pages/page_live_call.dart` (`_connect` — optional ordering)

**Interfaces:**

- Produces: `Future<void> LiveCallSession.unlockWebAudioPlayback()` — no-op when `!kIsWeb`.

- [ ] **Step 1:** Add to `LiveCallSession`:

```dart
Future<void> unlockWebAudioPlayback() async {
  if (!kIsWeb) return;
  try {
    await initAudioContext();
    // Minimal valid WAV (silence, ~50ms @ 16kHz mono) — reuse SttService.pcmToWav if available.
    final silence = Uint8List(1600); // 50ms * 16kHz * 2 bytes
    final wav = SttService.pcmToWav(silence, sampleRate: 16000, channels: 1);
    await _playerA.play(BytesSource(wav), volume: 0.01);
    await _playerA.stop();
  } catch (e) {
    debugPrint('[LiveCallSession] unlockWebAudioPlayback: $e');
  }
}
```

- [ ] **Step 2:** In `PageLiveCall._connect`, after mic permission succeeds and **before** `widget.conn.liveStart`, call:

```dart
await _session.unlockWebAudioPlayback();
```

- [ ] **Step 3:** Manual verify on Chrome: connect → hear model within ~2s of `live":"ready"`.

- [ ] **Step 4:** If playback still silent, in `_drainPlayback` log first `play` error at `debugPrint` and set `error.value` with suffix `(check browser autoplay / mute tab)`.

---

## Track C — `PageLiveCall` web UX fixes

### Task C.1: Document attach on web

**Files:**

- Modify: `clients/app/lib/pages/page_live_call.dart` (`_pickAndAttachMedia`)

**Problem:** `FilePicker.platform.pickFiles(withData: false)` does not populate `file.bytes` on web; `platformFileBytes` returns null (`ask_media.dart` pattern).

- [ ] **Step 1:** Add import: `package:flutter/foundation.dart` show `kIsWeb`.

- [ ] **Step 2:** Change file branch to:

```dart
final result = await FilePicker.platform.pickFiles(
  withData: kIsWeb,
  lockParentWindow: !kIsWeb,
);
```

- [ ] **Step 3:** On failure after pick, `setState(() => _error = uiFriendlyError('Could not read file'));` (or use existing attach error string).

- [ ] **Step 4:** Manual test on Chrome web: attach PDF/image during active call → server receives `media_attach` (check `ai.log` or live trace).

### Task C.2: Camera controls on web

**Files:**

- Modify: `clients/app/lib/pages/page_live_call.dart` (camera / flip buttons)
- Modify: `clients/app/lib/c/live/live_call_session.dart` (`switchCamera` — guard)

- [ ] **Step 1:** On web, `Helper.switchCamera` may be unsupported; wrap `switchCamera` so failures do not set session `error` (debugPrint only).

- [ ] **Step 2:** If `captureFrame` fails repeatedly on web, show one-line hint on camera tile: “Camera preview may be unavailable in this browser.”

- [ ] **Step 3:** Manual test: camera on Chrome desktop; note Safari limitations in Track F matrix.

### Task C.3: Speaker toggle on web

**Files:**

- Modify: `clients/app/lib/pages/page_live_call.dart`

- [ ] **Step 1:** When `kIsWeb`, speaker toggle adjusts **player volume** only (`toggleSpeaker` already sets volume) — hide or disable `Helper.setSpeakerphoneOn` expectations in UI tooltip (optional subtitle: “Uses browser volume”).

---

## Track D — Integration sign-off

### Task D.1: Matrix re-run

- [ ] Repeat Track 0 matrix on a **debug web build** after A+B+C.
- [ ] **Pass bar (v1):** Chrome + Edge desktop **must** pass Connect + uplink + downlink. Safari/iOS: best-effort documented in spec (may be partial).
- [ ] **Talk mode sanity:** One Talk mic send on web still works (`SttService` shared candidates).

### Task D.2: Billing / quota smoke

- [ ] Start a short live call on web; confirm timer ticks and hangup does not leave WS open (DevTools → Network → WS closed).

---

## Track E — Automated tests

### Task E.1: Mic candidate helper tests

**Files:**

- Create: `clients/app/test/mic_stream_candidates_test.dart`

- [ ] **Step 1:**

```dart
import 'package:alienai_c35/c/audio/mic_stream_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web prefers 16k mono first', () {
    final c = micStreamCandidates(isMobile: false, isWeb: true);
    expect(c.first.sampleRate, 16000);
    expect(c.first.numChannels, 1);
  });

  test('desktop non-web keeps stereo 48k first', () {
    final c = micStreamCandidates(isMobile: false, isWeb: false);
    expect(c.first.sampleRate, 48000);
    expect(c.first.numChannels, 2);
  });
}
```

Run: `flutter test test/mic_stream_candidates_test.dart`

### Task E.2: Web error message test

**Files:**

- Create: `clients/app/test/stt_mic_permission_web_test.dart`

- [ ] Test `sttMicErrorMessage()` contains `browser` when `kIsWeb` is true — use conditional import or test the web branch via a small `sttMicErrorMessageForPlatform({required bool web})` if `kIsWeb` is const in tests (prefer extracting one line for testability without mocking foundation).

Minimal approach: export package-private test hook:

```dart
// stt_mic_permission.dart
@visibleForTesting
String sttMicErrorMessagePlatform({required bool isWeb, ...}) { ... }
```

### Task E.3: Existing live session tests stay green

Run: `flutter test test/live_call_session_test.dart`

---

## Track F — Spec and docs

### Task F.1: `_/specs/live-call.md`

**Files:**

- Modify: `_/specs/live-call.md` (new section **Supported clients**)

- [ ] Add table:

| Client | Live Call |
|--------|-----------|
| Flutter Android / iOS | Supported (primary) |
| Flutter Windows / macOS / Linux | Supported |
| Flutter web (`/app/`) | Supported — Chrome/Edge desktop (v1); Safari/iOS best-effort |
| Remote WebRTC viewer | Not on web (see `remote.md`) |

- [ ] Note: mic requires HTTPS (or localhost); Frontier quota routing unchanged.

### Task F.2: Optional user guide (prompt-first)

**Files (optional):**

- Create: `_/docs/en/voice/live-call-web.md` and `_/docs/id/voice/live-call-web.md` with `path: both` — only if product wants public docs; otherwise skip (YAGNI).

---

## Track S — Server WebSocket smoke (conditional)

**Only if Track 0 shows WS connect/auth failure before mic issues.**

### Task S.1: Browser WS handshake

- [ ] From DevTools on web app, confirm `wss://api.alienai.id/v1/live/ws?...` reaches `{"live":"ready"}`.
- [ ] If 401/403: trace JWT query param in `LiveCallSession.liveWsUri` vs server `mod_live` ticket validation (`servers/crates/mod_live/src/rpc.rs`).
- [ ] Fix only auth/path bugs — do not add CORS workarounds for WS (not applicable).

---

## Self-review (spec coverage)

| Requirement | Task |
|-------------|------|
| 16 kHz PCM uplink (`live-call.md` App WS audio) | A |
| Downlink `LiveWsAudio` / playback | B |
| No provider web grounding | N/A (unchanged) |
| Talk vs Live separation (`ui.md`) | F (docs only) |
| Web file attach | C.1 |
| Cluster-only web search in live tools | N/A (server already) |

---

## Execution handoff

When the user asks to implement, run **wave 1** (`Task` subagent: Track 0). Then **wave 2** (Tracks A, B, C in parallel). Then D + E, then F.

Do not publish web to production until Track D pass bar is met.
