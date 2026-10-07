# Implementation Plan: Live Call Pricing Fetcher, Dual Voice/Video Rates, Client VAD & Smooth Audio Streaming

> **For agentic workers:** Dispatch one Task per track. Model: inherit only. Verify after edits.

**Goal:** Establish dynamic catalog fetcher sync for live call pricing (Alien AI, Gemini, ChatGPT, Grok), implement dual `Suara / Video` pre-call pricing display with dynamic in-call billing, add mid-call 📎 Klip media attachment, introduce client-side VAD (cutting input token costs by 50–70%), and fix incoming audio stuttering for smooth gapless playback.

---

## 1. Technical Architecture

### A. Dynamic Pricing & 1 FPS Video Economics
* **Gemini / Alien AI (`gemini-3.8-live`)**:
  * 1 FPS = 258 tokens/sec = 15,480 tokens/min.
  * At $0.10 / 1M input tokens = **$0.00155 / min wholesale**.
  * Marked up by `RETAIL_MARKUP = 1.50` $\rightarrow$ `+$0.002325 / min` (+IDR 0.63 – 1.00 / detik).
* **ChatGPT (`gpt-4o-realtime-preview`)**:
  * 1 FPS low-detail = 85 tokens/sec = 5,100 tokens/min.
  * At $5.00 / 1M vision tokens = **$0.0255 / min wholesale**.
  * Marked up by 1.50 $\rightarrow$ `+$0.03825 / min` (+IDR 10.4 / detik).
* **Grok (`grok-2-vision`)**:
  * Sampled on user speech (~1 frame/query) = ~2,500 tokens/min.
  * At $2.00 / 1M vision tokens = **$0.005 / min wholesale**.
  * Marked up by 1.50 $\rightarrow$ `+$0.0075 / min` (+IDR 2.00 / detik).

### B. Dual Pricing Display
In `page_live_call.dart`, before connecting, the pill displays both Voice and Video rates in the user's local currency:
* **Indonesian**: `🎙️ Suara: ~IDR 11.33/dtk   ·   📷 Video: ~IDR 12.80/dtk`
* **English**: `🎙️ Voice: ~IDR 11.33/s   ·   📷 Video: ~IDR 12.80/s`
During the call, elapsed cost dynamically switches between the video rate (when camera is on) and the voice rate (when camera is off).

### C. Client-Side VAD (Voice Activity Detection & Cost Optimization)
* **Problem**: Currently, client continuously uploads 16kHz PCM (32 KB/s) nonstop over WebSocket, billing Gemini ($0.005/min) and OpenAI ($0.06/min) for room silence, breathing, and listening time (60–70% of call duration).
* **Solution**:
  * **RMS / Energy Detection**: Measure RMS amplitude on 16-bit PCM chunks (`Int16List`).
  * **Dynamic Ambient Threshold**: Differentiate speech (> 600 RMS) from ambient room hum (< 400 RMS).
  * **Pre-Speech Ring Buffer (150ms)**: Keep rolling 150ms buffer in memory; when speech begins, flush the pre-buffer first so initial consonants ("p", "t", "k") are never clipped.
  * **Hangover Hold (400ms)**: Keep streaming for 400ms after speech ends to preserve natural sentence cadence.
  * **Silence Gating**: Drop packets during silence > 400ms. Slashes upstream input token consumption and bandwidth by **50% to 70%**.

### D. Audio Playback De-Stuttering (Smooth Gapless Streaming)
* **Root Cause of Stutter**:
  * Currently, `_drainPlayback()` triggers at tiny 250ms slices (`minBytes = 24000 * 2 * 0.25`).
  * Each 250ms slice is converted into a standalone WAV file and played with `await _player.onPlayerComplete.first`.
  * For a 10-second response, the native `AudioPlayer` is torn down, re-initialized, and restarted **40 times**!
  * Native hardware audio buffer tear-down and re-initialization creates an unavoidable **50ms–150ms silent gap** between every slice, sounding robotic and chopped up.
* **Smooth Audio Fix**:
  * **Adaptive Jitter Cushion**: Increase initial playback trigger cushion from 250ms to 500ms–600ms (or on `turnComplete`).
  * **Burst & Continuous Accumulation**: Because upstream LLMs generate audio at 3x–5x real-time speed, accumulate incoming chunks while the current segment is playing into generous continuous segments (1.5s–3s or rest of turn) instead of micro-slicing.
  * **Ping-Pong Dual AudioPlayers**:
    * Utilize `_playerA` and `_playerB`.
    * When Player A is playing chunk N, prepare chunk N+1 on Player B.
    * Trigger Player B 30ms–50ms before Player A ends (or crossfade), completely eliminating the hardware shutdown silence gap.
  * **Graceful Underrun Re-buffering**: If network drops temporarily, hold until a clean 400ms cushion accumulates before resuming instead of stuttering on 30ms crumbs.

### E. Mid-Call 📎 Klip (Media Attachment)
* In-call control bar adds a 📎 button alongside Mute, Camera, and End Call.
* Opens picker for photos (gallery/camera) or documents (PDF, TXT).
* Displays a floating preview chip on the call stage: `[ 📄 invoice.pdf ✕ ]`.
* Transmitted over `/v1/live/ws` as `{"type": "media_attach", "name": "...", "mime_type": "...", "data": "<base64>"}`.
* Server relays images to the multimodal encoder (Gemini `realtimeInput`, OpenAI `input_image`, Grok `image_url`) or extracts document text into a context turn.

---

## 2. Implementation Tracks

```
Wave 1 (Schema, Protobuf & Server Catalog):
├── Track A: Database Schema & Protobuf Migration
│   ├── _/schemas/live_offer.sql: add video_usd_per_min column and seed updates
│   ├── _/schemas/proto/c35/live.proto: add retail_video_usd_per_min to LiveOffer
│   └── Regenerate protobuf bindings (Rust c35_proto & Dart live.pb.dart)
├── Track B: Catalog & Fetcher Calculation
│   ├── servers/crates/mod_live/src/catalog.rs: LiveOfferRow video pricing & live_retail_video_usd_per_min
│   └── servers/crates/mod_live/src/billing.rs: video-weighted duration settlement
└── Track C: Server Media Attachment Handling
    ├── servers/crates/mod_live/src/google.rs: handle media_attach (image / text extraction)
    ├── servers/crates/mod_live/src/openai.rs: handle media_attach
    └── servers/crates/mod_live/src/grok.rs: handle media_attach

Wave 2 (Client Audio Pipeline, VAD & Smooth Streaming):
├── Track D: Client-Side VAD (Energy/RMS + Pre-Speech Ring Buffer)
│   ├── clients/app/lib/c/live/live_call_session.dart: implement ClientVad
│   │   ├── Rolling 150ms pre-speech buffer to prevent initial plosive clipping
│   │   ├── 400ms hangover window for smooth sentence trailing
│   │   └── Silence packet drop to cut 50-70% upstream token consumption
└── Track E: Smooth Gapless Audio Playback Engine
    ├── clients/app/lib/c/live/live_call_session.dart: replace micro-slicing drain
    │   ├── Initial jitter cushion (500ms)
    │   ├── Ping-Pong dual AudioPlayers (_playerA, _playerB) for seamless handoff
    │   └── Burst segment accumulation (1.5s–3.0s continuous blocks)

Wave 3 (Client UI & Integration):
├── Track F: Client Pricing Formatter & Dual Pill Display
│   ├── clients/app/lib/c/live/live_offer.dart: liveOfferPricePerSecDualLocal helper
│   ├── clients/app/assets/translations/{en,id}.json: live.voicePrice / live.videoPrice keys
│   └── clients/app/lib/pages/page_live_call.dart: update pre-call pill & dynamic in-call rate
└── Track G: In-Call Media Attachment UI
    ├── clients/app/lib/c/live/live_call_session.dart: sendMediaAttachment(name, mime, bytes)
    ├── clients/app/lib/pages/page_live_call.dart: 📎 Klip button, bottom sheet picker, floating chip
    └── Image & file picking via image_picker / file_picker

Wave 4 (Verification):
└── Track H: Automated & E2E Verification
    ├── cargo check -p c35_mod_live && cargo test -p c35_mod_live
    ├── cargo build -p server_ai
    ├── flutter analyze lib/c/live lib/pages/page_live_call.dart
    └── flutter test test/live_call_ui_test.dart
```

---

## 3. Verification Commands
- `cd servers; cargo test -p c35_mod_live`
- `cd servers; cargo build -p server_ai`
- `cd clients/app; flutter analyze lib/c/live lib/pages/page_live_call.dart`
- `cd clients/app; flutter test test/live_call_ui_test.dart`
