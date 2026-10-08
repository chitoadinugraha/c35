# Live Call Seamless Handover, Autonomous Topic Reset, and Camera Pipeline

> **For agentic workers:** Dispatch one Task per track. Model: inherit only. Verify after edits.

**Goal:** Eliminate dead air on Live Call topic changes with Make-Before-Break WebSocket handover, enable hands-free autonomous return to the general topic (prompt-steered `topic_reset` + turn-based drift detection), and plan live camera vision streaming and audio pipeline optimizations.

---

## 1. Architecture Overview

### A. Make-Before-Break Hot Handover
Previously, the server dropped the old Gemini WebSocket *before* resolving the database context and connecting to the new Gemini endpoint, causing ~600–1000ms of dead air where user mic audio was dropped.
In the new flow:
1. When a topic change is scheduled, the old Google WebSocket remains open, streaming and listening.
2. The server pre-warms the new connection in the background (resolves mention DB context, tools, and connects to Gemini Live with `sessionResumption.handle`).
3. Sends `setup` to the new socket and awaits `setupComplete`.
4. Atomically swaps active TX/RX sinks, sends `live_focus_pin` or text seed, notifies the client UI, and closes the old socket cleanly.

### B. Autonomous Topic Reset & Drift Detection
Users do not say explicit commands to return to the general topic. We support two complementary layers:
1. **Model Autonomous Tool (`topic_reset`)**: Declared to Gemini Live when an active mention is set. System prompt instructs Gemini to call `topic_reset` whenever the user naturally drifts away to general or unrelated matters.
2. **Deterministic Consecutive Drift Counter**: If 5 consecutive user turns complete without any mention tool execution or relevant context, the server automatically demotes the session to general.
3. Both triggers send `{"live":"mention","mention_ids":[],"label":"","switching":false}` to the Flutter client so the `UiMentionChip` disappears without manual tapping.

### C. Live Camera Video Streaming (Planned Track)
- Flutter UI adds a camera preview/toggle icon on the live call stage.
- Streams 1 fps JPEG frames (e.g. 640x480, q=50) encoded as base64 to server:
  `{"type":"video","data":"...","mime_type":"image/jpeg"}`
- Server forwards directly into Gemini Live's `realtimeInput.video` endpoint (identical to the existing `device_screenshot` video injection).

### D. Audio Pipeline Upgrade (Planned Track)
- Instant 0ms acoustic ducking (-12dB) on the Flutter client upon local speech onset before the server round-trip.
- Transitioning from discrete chunked WAV playback to continuous PCM streaming.

---

## 2. Tracks & Implementation Map

```
Wave 1 (Active Implementation):
├── Track A: Server Make-Before-Break Handover (servers/crates/mod_live/src/google.rs)
└── Track B: Autonomous Topic Reset & Drift Detection (servers/crates/mod_live)

Wave 2 (Planned Tracks):
├── Track C: Live Camera Multimodal Video Streaming (Flutter + Server Relay)
└── Track D: Audio Pipeline Upgrade (Local Ducking + Continuous PCM Stream)

Wave 3:
└── Track E: Documentation & End-to-End Verification (_/specs/live-call.md)
```

---

## 3. Verification Commands
- Rust: `cd servers; cargo build -p server_ai; cargo test -p c35_mod_live`
- Flutter: `cd clients/app; flutter analyze`
