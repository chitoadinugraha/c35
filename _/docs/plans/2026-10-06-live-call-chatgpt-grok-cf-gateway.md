# Live Call: ChatGPT & Grok via Cloudflare AI Gateway

> **For agentic workers:** Dispatch one Task per track. Model: inherit only. Verify after edits.

**Goal:** Implement Live Call support for ChatGPT (OpenAI Realtime) and Grok (xAI) routed through Cloudflare AI Gateway, supporting bidirectional audio, multimodal camera frames, live turn persistence, and testing via synthesized TTS audio.

---

## 1. Architecture Overview

### A. ChatGPT (`live.chatgpt`) via Cloudflare AI Gateway
- **Upstream WebSocket**:
  `wss://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/openai?model=gpt-4o-realtime-preview`
- **Headers**:
  `cf-aig-authorization: Bearer {cf_token}`
  `Authorization: Bearer {openai_key}` (or BYOK on Cloudflare)
  `OpenAI-Beta: realtime=v1`
- **Session Setup**:
  Sends `session.update` with `modalities: ["text", "audio"]`, `voice: "alloy"`, `input_audio_format: "pcm16"`, `output_audio_format: "pcm16"`, server VAD.
- **Audio Relay**:
  Client 16kHz PCM is resampled/streamed as `input_audio_buffer.append` (base64 PCM16 24kHz).
  OpenAI's `response.audio.delta` is streamed back to client as 24kHz PCM.
- **Video / Camera Frame Ingestion**:
  Client `{"type":"video", "data":"...", "mime_type":"..."}` is relayed via `conversation.item.create` with `input_image`.

### B. Grok (`live.grok`) via Cloudflare AI Gateway
- **Upstream Endpoint**:
  `https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/grok/v1/chat/completions` (model: `grok-2-latest` or `grok-2-vision-1212`)
- **Headers**:
  `cf-aig-authorization: Bearer {cf_token}`
  `Authorization: Bearer {xai_key}`
- **Voice Loop**:
  1. User mic audio buffered with VAD / speech silence detection.
  2. Transcribed via STT (Whisper on Cloudflare Workers AI or local STT).
  3. Streamed to Grok with current conversation history + latest video frame (if camera active).
  4. Grok tokens stream into low-latency sentence-chunked TTS.
  5. TTS PCM 24kHz streamed over `/v1/live/ws` to client with transcription captions.

### C. Unified Dispatcher in `servers/crates/mod_live/`
- `live_proxy_run` in `servers/crates/mod_live/src/` dispatches based on `offer.provider`:
  - `"google"` -> `live_google_run`
  - `"openai"` -> `live_openai_run`
  - `"xai"` -> `live_grok_run`
- `ai.live_offer`: Enable `live.chatgpt` and `live.grok`.

---

## 2. Tracks & Implementation Map

```
Wave 1 (Parallel Tracks):
├── Track A: OpenAI Realtime via CF Gateway (`servers/crates/mod_live/src/openai.rs`)
├── Track B: Grok Streaming Voice via CF Gateway (`servers/crates/mod_live/src/grok.rs`)
└── Track C: Catalog & Dispatcher Integration (`catalog.rs`, `lib.rs`, `rpc.rs`, SQL seeds)

Wave 2:
└── Track D: End-to-End TTS Audio Verification & Smoke Testing
    - Synthesize "what time is now?" into 16kHz PCM.
    - Test live call session with `live.chatgpt`.
    - Test live call session with `live.grok`.
    - Verify speech audio returned and transcription validated.
```

---

## 3. Verification Commands
- `cd servers; cargo check -p c35_mod_live; cargo test -p c35_mod_live`
- `cd servers; cargo build -p server_ai`
