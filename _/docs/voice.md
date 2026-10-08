# Voice (STT + TTS)

Status: **locked** 2026-09-22

Speech-to-text (composer mic) and text-to-speech (read aloud, auto-speak) with **cs_bots parity** UX. Three engine modes per direction; only **`cloud`** hits the server and bills the user.

Companion: [billing.md](billing.md) (metered deduct), [ui.md](ui.md) (composer, settings).

Proto: [`../schemas/proto/c35/voice.proto`](../schemas/proto/c35/voice.proto)

---

## Engines

Engine choice is stored in `VoicePrefs` (`voice_stt_engine`, `voice_tts_engine`). **STT is cloud-only** (legacy public Chromium STT is removed — endpoint no longer reliable). **TTS** supports **web**, **local**, and **cloud** in settings; default **cloud**. Only **cloud STT/TTS** hits the server and bills the user.

| Engine | STT | TTS | Server / billing |
|--------|-----|-----|------------------|
| **web** | — (not supported; use **cloud**) | Google Translate TTS URL (`translate_tts`) | TTS only — client, **$0** |
| **local** | — | `flutter_tts` on device | **$0** |
| **cloud** | `ReqVoiceStt` → `mod_voice` → Cloudflare Whisper Large v3 Turbo (fallback Gemini / Google) | `ReqVoiceTts` → `mod_voice` → Google Cloud Text-to-Speech | Reserve → settle; see [Billing flow](#billing-flow-cloud) |

**Web / local:** no `req_id`, no `billing_reservation`, no balance change.

**Cloud:** requires signed-in session, sufficient balance or quota, and `CLOUDFLARE_API_TOKEN` (or `GOOGLE_CLOUD_API_KEY` / `GEMINI_API_KEY`) on the server. UI caption when cloud is selected: *"Uses Alien AI cloud voice — charged to your balance."*

---

## Client services

Single entry points for the app — pages bind `VoiceApi` once per chat session.

| Service | Role | Key API |
|---------|------|---------|
| **`SttService`** | Mic record/stop, transcribe router, adaptive VAD | `startRecording()`, `stopAndTranscribe()`, `transcribeRouted()` |
| **`TtsService`** | Speak/stop, engine router | `speak(text)`, `stop()`, `speakRouted()` |
| **`VoiceApi`** | Cloud RPC wrapper | `sttTranscribe(...)`, `ttsSynthesize(...)` |

**Voice Activity Detection (VAD):**
- Tracks continuous ambient noise floor (`_noiseFloorDb`).
- Detects human voice via dynamic SNR delta: $\max(\text{Ambient Floor} + 8\text{ dB}, -54\text{ dB})$ (+1 dB in talk mode). The floor tracks up to −25 dB, follows stationary noise upward, and creeps up under sustained loud input, so noisy rooms don't read as endless speech. A high peak alone does not count as speech unless it is also >5 dB above the floor.
- Recorder is opened with `noiseSuppress` + `echoCancel` (Android/iOS/web; ignored on desktop). `autoGain` stays off (it amplifies noise).
- Filters out static hiss, fan/AC hum, and transient clicks.
- **Composer** mic: triggers `onAutoStop` after **700ms** of silence following speech with live text (**1100ms** with no text yet).
- **Talk** mic (`SttVadMode.talk`): silence VAD is off so background noise cannot block end-of-turn; user taps mic again, **Send** on the transcript chip, or hits the **60s** cap.

**Latency optimizations (STT):**
- `SttService.prewarm()` (called on composer focus) resolves and caches the mic device (60s TTL); the last working PCM stream config is tried first on `startRecording`.
- Interim snapshots tick every 250ms (min 0.6s audio) and use a **sliding window**: text is committed at a pause once the window passes 6s (forced at 12s) so each upload stays small.
- Leading/trailing silence is trimmed (`trimSilence`, 250ms pad) from interim and final audio before upload.
- `stopAndTranscribe` sets `isTranscribing` immediately so the UI shows feedback during recorder shutdown.
- Server: `voice_stt` runs the billing hold concurrently with the upstream call; shared `reqwest` client uses keep-alive pooling and `TCP_NODELAY`.

**Prefs:** `VoicePrefs` — `sttEngine`, `ttsEngine`, `speechLang`, rate/pitch, `talkEnabled`, `talkSpeakEnabled` (key `voice_talk_speak_enabled`, default **on** for Talk auto read-aloud).

**Talk** (`talkEnabled`, key `voice_talk_enabled`, default false) is the Home surface switch, not an engine. Off is Chat mode. On replaces the thread and composer with the one-page stage in [ui.md](ui.md#talk). The same `SttService` / `TtsService` path runs. `talkSpeakEnabled` controls the stage speaker icon and auto TTS after each Talk turn. **Chat** does not auto read aloud; use the assistant bubble menu **Read aloud**. Starting the Talk mic stops TTS. Idle / listening / thinking / usage copy for the status row above the controls is defined in [ui.md](ui.md#talk).

**Binding:** `page_ai_home` creates `VoiceApi(chatConn)` and calls `SttService.instance.bindVoiceApi` / `TtsService.instance.bindVoiceApi` in `initState`; clears on `dispose`.

**Routing:**

- STT: always **cloud** → `VoiceApi.sttTranscribe`.
- TTS: `ttsEngine == 'cloud'` → synthesize + `audioplayers`; `web` → fetch MP3 + player; `local` → `flutter_tts` (web TTS falls through to local on failure).

**Read aloud text:** `speechTextClean` turns markdown into plain speech before any engine. Headings, emphasis, links, and code markers are removed. Short bullet and numbered items in one list are joined with commas so the voice does not pause after each marker. Talk auto-speak (`TtsStreamQueue`) keeps those lines in one clip until a paragraph is long (about 700 characters) or the reply ends. **Stop** (composer "Speaking in ...") cancels that queue, drops clips not yet played, and disposes the current player so playback cannot continue.

**Files:**

| Path | Purpose |
|------|---------|
| `clients/app/lib/c/stt/stt_service.dart` | Recording + adaptive VAD + STT router |
| `clients/app/lib/c/tts/tts_service.dart` | TTS router + playback |
| `clients/app/lib/c/voice/voice_api.dart` | Cloud invoke client |
| `clients/app/lib/c/settings/voice_prefs.dart` | Persisted engine, speak toggle, Talk surface |
| `clients/app/lib/widgets/ai/ui_talk_stage.dart` | Talk layout. No STT, TTS, or prompt I/O |

Cloud errors surface via `ResVoiceStt.error` / `ResVoiceTts.error` and `ui_friendly_error` (e.g. insufficient balance).

---

## Server RPC + billing flow (cloud)

Wire: `InvokeReq.voice_stt` / `InvokeReq.voice_tts` (HTTP + WS). Handler: `c35_mod_voice::voice_stt_rpc` / `voice_tts_rpc` in `wire_http` / `wire_ws`. Auth: session `owner_iid`.

Crate: `servers/crates/mod_voice/` — `voice_stt`, `voice_tts`, Cloudflare/Gemini/Google proxy in `stt.rs` / `tts.rs`, billing helpers in `billing.rs`.

Each request must carry a client-generated **`req_id`** (ULID). Server prefixes `voice_stt_` / `voice_tts_` for dedupe keys. When `req_id` contains `interim`, the billing gate is bypassed (interim snapshots are free for the user).

### Billing flow (cloud)

```
Client                    Server (mod_voice)            Cloudflare Workers AI
  |  ReqVoiceStt(req_id)    |                                |
  | ----------------------> | voice_billing_gate             |
  |                         | (hold VOICE_STT_HOLD_USD)      |
  |                         | ------------------------------>|
  |                         |     @cf/openai/whisper-large-v3-turbo
  |                         | <------------------------------|
  |                         | voice_billing_settle           |
  |                         | log_put → ai.log (cost_usd)    |
  |                         | billing_usage_dedupe + deduct  |
  |  ResVoiceStt(text)      |                                |
  | <---------------------- |                                |
```

On upstream or validation failure: `voice_billing_abort` → `billing_reservation_refund`. Zero retail cost after settle: refund hold, no deduct.

**Log rows:** `kind` = `voice_stt` | `voice_tts`, `topic` = `voice`, `model` = `cloudflare.whisper` | `google.tts`, `cost_usd` = retail (wholesale × `RETAIL_MARKUP`).

---

## Pricing & Cloudflare Workers AI Costs

### Upstream Model: `@cf/openai/whisper-large-v3-turbo`
- **Cost Metric:** Measured in **Neurons** ($0.011 per 1,000 Neurons).
- **Exact Consumption:** **~0.777 Neurons per second** of audio (~46.6 Neurons per minute).
- **Fractional Accounting:** Cloudflare does **NOT** round up to 1 neuron per call. Exact fractional compute (e.g. `0.7771706284`) is accumulated.
- **Free Daily Quota:** **10,000 Neurons / day FREE** on every account:
  $$\frac{10,000\text{ Neurons}}{46.6\text{ Neurons/min}} \approx 214.5\text{ minutes of audio/day completely FREE}$$
- **Overage Cost:**
  $$\frac{46.6\text{ Neurons}}{1,000\text{ Neurons}} \times \$0.011 = \mathbf{\$0.00051\text{ / audio minute}} \quad (\approx \text{Rp } 8.2\text{ / minute})$$
  *(Roughly 10x cheaper than Google Cloud Speech at $0.006/min).*

### Platform Retail Pricing
Defined in `servers/crates/mod_billing/src/billing_cost.rs` — **single source of truth** for holds and retail meters:

| Constant | Value | Meaning |
|----------|-------|---------|
| `VOICE_STT_HOLD_USD` | `0.01` | Escrow while STT in flight |
| `VOICE_TTS_HOLD_USD` | `0.01` | Escrow while TTS in flight |
| `VOICE_STT_USD_PER_MIN` | `0.006` | Retail $/minute of audio (estimated from bytes + mime) |
| `VOICE_TTS_USD_PER_1K_CHARS` | `0.004` | Retail $/1k characters spoken |
| `RETAIL_MARKUP` | `1.50` | Wholesale → retail (`billing_to_retail_usd`) |

**Wholesale estimate:** `mod_voice::billing` — duration from WAV header or mime heuristics (STT); char count (TTS). Settled amount = `billing_to_retail_usd(wholesale)`.

**Tune pricing:** edit constants in `billing_cost.rs` only; redeploy server. No client change required.

Tests: `servers/crates/mod_voice/tests/voice_billing_test.rs`.

---

## Cluster secrets

Cloud voice uses Cloudflare Workers AI with fallback to Gemini / Google Cloud Speech.

| Env var | Required | Notes |
|---------|----------|-------|
| `CLOUDFLARE_API_TOKEN` | **Recommended** | Cloudflare API token with `Workers AI: Edit` and `AI Gateway: Run` permissions |
| `CLOUDFLARE_ACCOUNT_ID` | Optional | Defaults to `13bbda4c964029cb15bb16c7d57ec548` |
| `CLOUDFLARE_AI_GATEWAY_URL` | Optional | Custom Cloudflare AI Gateway endpoint URL |
| `GEMINI_API_KEY` | Fallback | Used if Cloudflare is unreachable |
| `GOOGLE_CLOUD_API_KEY` | Fallback | Used for Google TTS synthesize |

**Cluster:** add keys to Kubernetes secret `c35-server-env` (loaded via `envFrom` in [`../deployments/c35-server/deployment.yaml`](../deployments/c35-server/deployment.yaml)). Never commit keys to the repo.

**Local dev:** set in `d:\c35\.env.local` or `D:\alienai_proto\cluster\.env.local` (see `.env.example`).

Missing key → RPC returns friendly *"Cloud voice is temporarily unavailable."* (technical detail in server log only).

---

## cs_bots parity checklist

Reference: `D:\cs_bots` — copy behavior, not imports.

| Feature | c35 location | Status |
|---------|--------------|--------|
| Composer mic (STT) | `widgets/ai/in_composer.dart` + `SttService` | Done |
| Read aloud (assistant context menu) | `page_ai_home.dart` → `onSpeak` → `TtsService.speak` | Done |
| Auto-speak on assistant reply | `page_ai_home.dart` when Talk on and `talkSpeakEnabled` | Done |
| Stop TTS when user sends new message | `page_ai_home.dart` prompt send | Done |
| Speak toggle in avatar menu | `widgets/ui/ui_account_menu.dart` + `UiAppToggle` | Done |
| Engine pickers (web / local / cloud) | `pages/page_settings.dart` | Done |
| Public web STT/TTS endpoints | `SttService._transcribeWebEndpoint`, `TtsService._fetchWebTtsBytes` | Done |
| Cloud STT/TTS + billing | `mod_voice` + `VoiceApi` | Done |
| Widget test: Read aloud menu item | `clients/app/test/voice_ux_test.dart` | Done |
| Unit tests: engine routing | `stt_service_test.dart`, `tts_service_test.dart` | Done |

**Verify:**

```powershell
cd clients/app
flutter analyze
flutter test

cd servers
cargo test -p c35_mod_voice
cargo build -p server_ai
```
