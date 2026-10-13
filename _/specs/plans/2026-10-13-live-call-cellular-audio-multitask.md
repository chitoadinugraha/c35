# Live Call cellular audio — Multitask Plan

> **For agentic workers:** Use `plan-execution.mdc` — dispatch one `Task` subagent per track below; **model: inherit** only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make **Live Call** assistant downlink and user uplink sound **smooth on jittery mobile networks (4G/3G)** by replacing clip-based WAV playback with **streaming PCM playout + adaptive jitter buffer**, then optionally **Opus on the app WebSocket hop**; defer **full WebRTC media plane** to a later spike unless Track H proves necessary.

**Architecture:** Keep **Gemini Live** (and other offers) on the server as **PCM into/out of providers**. Improve only the **app ↔ `server_ai` `/v1/live/ws`** leg:

1. **Phase 1 (client playout):** Ingest `LiveWsAudio` (and legacy raw PCM) into a **ring buffer** clocked by a platform **streaming sink** (Android `AudioTrack`, iOS `AVAudioEngine`, web `AudioContext`). Tune **adaptive prebuffer** from inter-arrival jitter. Retain **`audioplayers` + ping-pong** as fallback on desktop until streaming lands there.
2. **Phase 2 (codec on WS):** Negotiate **`opus`** on connect; client **encodes uplink** speech frames; server **decodes → PCM → Gemini**; server **encodes Gemini PCM → Opus** downlink. **Backward compatible:** default remains PCM (`LiveWsAudio` as today).
3. **Phase 3 (optional):** WebRTC audio leg spike — only if Phase 1–2 do not meet 4G SLO.

**Tech Stack:** Flutter `clients/app` (`LiveCallSession`), `servers/crates/mod_live` (`ws_audio.rs`, `google.rs`), proto `c35/live.proto`, optional Dart package **`opus_flutter`** / **`flutter_opus`** (evaluate in Track G0) or server-side only Opus first on downlink.

**Out of scope (this plan):**

- Changing Gemini / OpenAI / Grok provider wire formats.
- Provider-native web grounding (`web-grounding-cluster-only.mdc`).
- Chromium STT URL (`voice-no-chromium-stt.mdc`).
- Remote device WebRTC viewer (`remote.md`).
- Billing / `ai.live_offer` pricing changes.

## Global Constraints

- Read `spec.md`, `_/specs/live-call.md`, `_/specs/voice.md`, `_/specs/ui.md` (# Talk vs Live Call) before coding.
- Verify Flutter: `.\_\scripts\dev\verify_flutter_app.ps1`; `flutter test` for touched tests.
- Verify server: `cd servers && cargo build -p server_ai`; `cargo test -p c35_mod_live` when `mod_live` changes.
- UTF-8: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Proto changes: edit `_/schemas/proto/c35/live.proto`, regenerate Dart/Rust bindings per repo convention.
- Subagent model: **inherit** (not `*-fast`).
- Do not git commit unless the user asks.

---

## Problem statement (locked diagnosis)

| Symptom on 4G | Likely cause | Fix track |
|---------------|--------------|-----------|
| Choppy / “glued” assistant voice | Downlink: **WAV + `audioplayers` per chunk**, fixed 450 ms coalesce, single player | **1, 2, 3** |
| Long silence then burst | Jitter + underrun on playout buffer | **1** (adaptive buffer) |
| High WS bytes (secondary on 4G) | **Uncompressed PCM** both directions | **4, 5** |
| Mic feels laggy | VAD + RTT (not codec today); uplink is **raw 16 kHz PCM** when speaking | **4** (smaller frames), **1** (downlink barge-in unchanged) |

**Note:** WAV is **not** sent over the network; it is only a local playback wrapper today.

---

## Multitask map

```
Track 0 (Metrics + throttle repro) ──► all tracks
Track 1 (Jitter buffer + adaptive) ──► 2, 3, 4, 5
Track 2 (Ping-pong audioplayers)     ──► 6 (fallback parity)
Track 3A (Android stream playout)    ──► 6
Track 3B (iOS stream playout)        ──► 6
Track 3C (Web AudioContext playout)  ──► 6
Track 3D (Desktop fallback policy)   ──► 6
Track 4 (Opus uplink)                ──► 5, 6
Track 5 (Opus downlink)              ──► 6
Track G0 (Opus dependency spike)     ──► 4, 5  (parallel with 1 once 0 done)
Track 6 (Integration QA + SLO)       ──► 7
Track 7 (Spec + tests)               ──► after 6
Track H (WebRTC spike — optional)    ──► product gate only
```

| Track | Focus | Depends |
|-------|--------|---------|
| **0** | Repro, Chrome throttling, debug metrics | — |
| **1** | `LivePcmJitterBuffer` + adaptive prebuffer (unit-tested) | 0 |
| **2** | Dual `AudioPlayer` ping-pong + wire into buffer drain | 1 |
| **3A** | Android streaming PCM sink | 1 |
| **3B** | iOS streaming PCM sink | 1 |
| **3C** | Web `AudioContext` queue | 1 |
| **3D** | Desktop: streaming if easy, else enhanced fallback | 1, 2 |
| **G0** | Choose Opus library + frame size (20 ms) | 0 |
| **4** | Opus uplink + server decode to Gemini PCM | G0, 1 |
| **5** | Opus downlink + client decode to jitter buffer | G0, 1, 3* |
| **6** | E2E matrix, 4G/3G throttling sign-off | 3A–3D, 2, 4?, 5? |
| **7** | `live-call.md` + automated tests | 6 |
| **H** | WebRTC audio feasibility doc (no prod unless approved) | 6 fail SLO |

**Parallel wave 1:** Track **0**  
**Parallel wave 2:** Track **1** + Track **G0**  
**Parallel wave 3:** Track **2** + **3A** + **3B** + **3C** + **3D**  
**Parallel wave 4:** Track **4** + **5** (5 can start with downlink-only after 3A/B/C ingest path exists)  
**Parallel wave 5:** Track **6**  
**Parallel wave 6:** Track **7**  
**Track H:** only if Track **6** misses SLO after Phase 1–2

---

## SLO (sign-off bar)

Test on **Chrome Android** and **physical device 4G** (not only Wi‑Fi), plus DevTools **Slow 4G** on desktop web.

| Metric | Target |
|--------|--------|
| Subjective | No “glued” gaps in 30 s continuous assistant speech at Slow 4G |
| Underruns | `< 1` audible underrun per 60 s assistant speech (log `live_audio_underrun`) |
| Mouth-to-ear (Wi‑Fi) | Do not regress median vs current baseline by **> 150 ms** |
| Mouth-to-ear (Slow 4G) | Accept **+200–400 ms** vs Wi‑Fi if needed for smoothness (configurable profile) |
| CPU / battery | No sustained > 15% CPU on mid-range Android during speak-only call |

---

## Track 0 — Repro baseline and metrics

**Deliverable:** `.cache/live-call-audio-matrix.md` (gitignored notes OK).

### Task 0.1: Throttled repro checklist

- [ ] **Step 1:** Android or Chrome → Live Call → **Call Alien AI** → ask for a **30 s spoken answer** (e.g. “Explain how photosynthesis works in simple terms”).
- [ ] **Step 2:** Repeat with Chrome DevTools **Network → Slow 4G** (web) or real 4G (device).
- [ ] **Step 3:** Record PASS/GAP: connect, uplink heard, downlink smoothness (1–5), barge-in works.

### Task 0.2: Client debug counters (minimal)

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart`

- [ ] Add debug-only counters (guarded by `kDebugMode` or `assert`): `downlinkFrames`, `downlinkBytes`, `playoutUnderruns`, `maxBufferMs`, `interArrivalMsP95`.
- [ ] Log one line on hangup: `[LiveCallSession] audio stats: ...`

**Exit criteria:** Can compare before/after on same prompt and network profile.

---

## Track 1 — Jitter buffer (Dart, test-first)

**Deliverable:** Pure-Dart buffer used by all playout backends.

### Task 1.1: Create `LivePcmJitterBuffer`

**Files:**

- Create: `clients/app/lib/c/live/live_pcm_jitter_buffer.dart`
- Create: `clients/app/test/live_pcm_jitter_buffer_test.dart`

**Behavior:**

- `write(Uint8List pcm)` append; track sample rate.
- `readFrame(int frameSamples)` or `takeForPlayback(int maxBytes)` for clock consumer.
- `targetBufferMs` adaptive: increase when inter-arrival **> 80 ms** p95; decrease slowly when stable (floor **250 ms**, ceiling **1200 ms** on mobile).
- `underrun` callback when consumer starves.

- [ ] **Step 1:** Tests: empty read, fill/drain, cap at ceiling, adaptive grows on jitter pattern.
- [ ] **Step 2:** Implement buffer; no platform code.

### Task 1.2: Integrate ingest path

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart` (`_ingestDownlinkPcm`, `_playGeminiAudio`)

- [ ] Route all downlink PCM into `LivePcmJitterBuffer` instead of `_incomingPcm` `BytesBuilder` only.
- [ ] Keep `_handleInterruption()` clearing buffer + epoch semantics.

**Exit criteria:** Tests green; session still plays via existing `_drainPlayback` (temporary).

---

## Track 2 — Ping-pong `audioplayers` (quick win / desktop fallback)

**Problem:** `_playerB` is configured but `_drainPlayback` only uses `_playerA`.

### Task 2.1: Alternate players per chunk

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart`

- [ ] While player A plays chunk *n*, prepare WAV for chunk *n+1* (decode in memory).
- [ ] Start B on A complete (toggle); cancel both on interruption.
- [ ] Read from jitter buffer with **smaller chunks** (e.g. **80–120 ms**) when using fallback path to reduce gap risk.

**Files:**

- Modify: `clients/app/test/live_call_session_test.dart` — add test that alternation flag toggles (mock players if needed).

**Exit criteria:** Audible improvement on Slow 4G vs baseline OR measurable fewer underruns in Track 0 metrics.

---

## Track 3A — Android streaming playout

### Task 3A.1: Platform channel `LivePcmAudioOut`

**Files:**

- Create: `clients/app/lib/c/live/live_pcm_playout.dart` (abstract: `start`, `write`, `stop`, `setSampleRate`)
- Create: `clients/app/android/.../LivePcmAudioOut.kt` — `AudioTrack` `MODE_STREAM`, `ENCODING_PCM_16BIT`, usage `VOICE_COMMUNICATION`
- Modify: `clients/app/android/.../MainActivity.kt` (register plugin/method channel)

- [ ] Dedicated thread or `AudioTrack.write` blocking loop fed from Dart via **chunked invoke** or **EventChannel** (prefer batch 20–40 ms to reduce JNI).
- [ ] Match `LiveCallSession` `AudioContext` communication mode (already sets `inCommunication`).

### Task 3A.2: Wire session to streaming on Android

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart`

- [ ] If `defaultTargetPlatform == android` && streaming init OK → consume jitter buffer on timer/isolate; **disable** `_drainPlayback` WAV path.
- [ ] Fallback to Track 2 on init failure.

**Exit criteria:** 30 s speech smooth on device 4G; underrun counter meets SLO.

---

## Track 3B — iOS streaming playout

### Task 3B.1: `AVAudioEngine` + player node

**Files:**

- Create: `clients/app/ios/Runner/LivePcmAudioOut.swift` (or Obj-C bridge)
- Wire in `AppDelegate`

- [ ] `playAndRecord` category, bluetooth options aligned with existing `AudioContextIOS`.
- [ ] Schedule `AVAudioPCMBuffer` in 20–40 ms frames from Dart.

### Task 3B.2: Session wiring (mirror 3A.2)

**Exit criteria:** Same SLO as 3A on iOS cellular.

---

## Track 3C — Web AudioContext playout

### Task 3C.1: `dart:js_interop` or `web` package AudioContext

**Files:**

- Create: `clients/app/lib/c/live/live_pcm_playout_web.dart` (conditional import)
- Modify: `clients/app/lib/c/live/live_pcm_playout.dart` — factory `LivePcmPlayout.create()`

- [ ] Reuse **Connect** gesture: create/resume `AudioContext` in `unlockWebAudioPlayback`.
- [ ] Schedule buffers at `currentTime + lookahead` (50–100 ms); drift correction when queue depth diverges.

**Exit criteria:** Slow 4G in Chrome desktop meets SLO; no autoplay regressions.

---

## Track 3D — Desktop fallback policy

### Task 3D.1: Windows / macOS / Linux

- [ ] **Preferred:** If PortAudio-style plugin exists in repo deps, use streaming; else **Track 2** enhanced fallback only.
- [ ] Document in matrix: desktop cellular tethering tested optional.

**Exit criteria:** No regression on Windows Live Call (existing primary desktop).

---

## Track G0 — Opus dependency spike (short)

### Task G0.1: Evaluate encoder on Android/iOS/Web

- [ ] Compare **`opus_flutter`** / **`flutter_opus`** / FFI to `libopus` — license, size, ARM64, web WASM.
- [ ] Lock **20 ms frames**, **16 kHz mono** uplink, **24 kHz mono** downlink (resample on server if needed).
- [ ] Document choice in plan appendix (comment in `live-call.md`).

**Exit criteria:** Hello-world encode/decode roundtrip in a **unit test** or tiny `flutter test` with fixture.

---

## Track 4 — Opus uplink (client encode, server decode)

### Task 4.1: Proto + negotiation

**Files:**

- Modify: `_/schemas/proto/c35/live.proto`

```protobuf
enum LiveWsAudioCodec {
  LIVE_WS_AUDIO_CODEC_PCM_S16LE = 0;
  LIVE_WS_AUDIO_CODEC_OPUS = 1;
}

message LiveWsAudio {
  uint32 sample_rate_hz = 1;
  bytes pcm_s16le = 2; // PCM path (legacy)
  LiveWsAudioCodec codec = 3;
  bytes encoded = 4;   // Opus payload when codec == OPUS
}
```

- [ ] Regenerate Dart + Rust prost types.
- [ ] Server `ready` JSON extension: `"audio_uplink":"opus"|"pcm"` (client proposal in first text message or query param `?uplink=opus` — pick one, document in spec).

### Task 4.2: Client uplink encoder

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart` (`_processMicChunkWithVad`, `_sendWs`)

- [ ] When negotiated: send **binary** frames with magic `0xC3 0x35` + `LiveWsAudio` **OPUS** (do not send raw PCM).
- [ ] Only encode when `shouldTransmit` (preserve VAD savings).

### Task 4.3: Server decode → Gemini

**Files:**

- Modify: `servers/crates/mod_live/src/google.rs` (binary PCM handler ~line 421)
- Create: `servers/crates/mod_live/src/opus_codec.rs` (decode with `audiopus` or `opus` crate)
- Modify: `servers/crates/mod_live/src/ws_audio.rs` (`decode_audio_frame` returns PCM bytes)

- [ ] Decode Opus → PCM s16le 16 kHz before `realtimeInput` base64 JSON.
- [ ] Feature-flag: `C35_LIVE_OPUS_UPLINK=1`.

**Tests:**

- `servers/crates/mod_live/tests/live_opus_roundtrip_test.rs` — fixture frame decodes to expected PCM length.

**Exit criteria:** Gemini still hears user; bandwidth down on speech (~10×) in Wireshark/tcpdump sample.

---

## Track 5 — Opus downlink (server encode, client decode)

### Task 5.1: Server encode after Gemini strip

**Files:**

- Modify: `servers/crates/mod_live/src/ws_audio.rs` (`encode_audio_frame` — add Opus mode)
- Modify: `servers/crates/mod_live/src/google.rs` (`live_client_send_gemini_value` path)

- [ ] When session negotiated `downlink=opus`, encode PCM chunks to Opus before WS send.
- [ ] Coalesce to **20–60 ms** Opus frames to balance latency vs efficiency.

### Task 5.2: Client decode → jitter buffer

**Files:**

- Modify: `clients/app/lib/c/live/live_call_session.dart` (`_ingestDownlinkPcm`)

- [ ] If `codec == OPUS`, decode to PCM then `LivePcmJitterBuffer.write`.
- [ ] Streaming playout (Track 3) consumes PCM as today.

**Exit criteria:** Slow 4G smoothness **≥** PCM-only with Track 3; lower `downlinkBytes` counter.

---

## Track 6 — Integration QA

### Task 6.1: Matrix

| Profile | Android | iOS | Web Chrome | Windows |
|---------|---------|-----|------------|---------|
| Wi‑Fi | | | | |
| 4G / Slow 4G | | | | |
| Opus off (PCM) | | | | |
| Opus on | | | | |

- [ ] Barge-in during assistant speech.
- [ ] Tool hop mid-call (web search) — no permanent audio stall.
- [ ] Hangup / interrupt (`serverContent.interrupted`) clears buffer without crash.

### Task 6.2: Regression

```powershell
cd D:\c35\clients\app
flutter test test/live_call_session_test.dart test/live_pcm_jitter_buffer_test.dart
.\_\scripts\dev\verify_flutter_app.ps1
cd D:\c35\servers
cargo test -p c35_mod_live
cargo build -p server_ai
```

**Exit criteria:** SLO table in this plan satisfied.

---

## Track 7 — Spec and tests

### Task 7.1: `_/specs/live-call.md`

- [ ] New section **Playout and jitter buffer** (streaming PCM, adaptive buffer targets).
- [ ] New section **Optional Opus on app WebSocket** (negotiation, backward compatible PCM).
- [ ] Clarify: **user uplink** remains PCM until Track 4 ships; **no WAV on wire**.

### Task 7.2: Automated coverage

- [ ] `live_pcm_jitter_buffer_test.dart` — adaptive + underrun.
- [ ] `ws_audio` Rust tests — Opus roundtrip if Track 5 shipped.
- [ ] Optional: golden log line test for hangup stats in debug.

---

## Track H — WebRTC audio spike (optional, product gate)

**Only if Track 6 fails SLO after Tracks 1–5.**

### Task H.1: Design note (max 2 pages in `_/specs/plans/` or section in `live-call.md`)

- [ ] Diagram: Client WebRTC (Opus) ↔ `server_ai` media endpoint ↔ PCM Gemini bridge.
- [ ] Estimate: SFU vs single peer, TURN for 4G, Flutter `flutter_webrtc` audio track vs WS.
- [ ] Cost / ops impact (k3s, UDP, firewall).

**No production code** in Track H unless user explicitly approves follow-up plan.

---

## Self-review (spec coverage)

| Requirement | Track |
|-------------|-------|
| App WS downlink `LiveWsAudio` | 1, 3, 5 |
| App WS uplink 16 kHz PCM | 4 (optional Opus) |
| Gemini `realtimeInput` PCM | 4 decode |
| Talk vs Live separation | unchanged |
| `voice-no-chromium-stt` | unchanged |
| Verify after edit | 6, 7 |

---

## Execution handoff

When the user asks to **implement**:

1. **Wave 1:** `Task` → Track **0**
2. **Wave 2:** `Task` → Track **1** + Track **G0**
3. **Wave 3:** `Task` → Tracks **2**, **3A**, **3B**, **3C**, **3D** (parallel)
4. **Wave 4:** `Task` → Tracks **4** + **5** (after G0 + ingest path ready)
5. **Wave 5:** `Task` → Track **6** → Track **7**
6. Track **H** only on SLO miss

**Recommended MVP for first merge:** Tracks **0, 1, 2, 3A** (Android cellular) + **7** spec slice for playout — Opus (**4, 5**) as second PR.

Do not publish `server_ai` or remote agent until server tracks tested; cluster publish per `cluster-buildkit.mdc` when user requests release.
