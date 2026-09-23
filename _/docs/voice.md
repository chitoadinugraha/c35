# Voice (STT + TTS)

Status: **locked** 2026-09-22

Speech-to-text (composer mic) and text-to-speech (read aloud, auto-speak) with **cs_bots parity** UX. Three engine modes per direction; only **`cloud`** hits the server and bills the user.

Companion: [billing.md](billing.md) (metered deduct), [ui.md](ui.md) (composer, settings).

Proto: [`../schemas/proto/c35/voice.proto`](../schemas/proto/c35/voice.proto)

---

## Engines

Engine choice is stored in `VoicePrefs` (`voice_stt_engine`, `voice_tts_engine`). Settings → Voice exposes pickers for **web** (default), **local**, and **cloud**.

| Engine | STT | TTS | Server / billing |
|--------|-----|-----|------------------|
| **web** | Chromium public endpoint (`google.com/speech-api/v2/recognize`) | Google Translate TTS URL (`translate_tts`) | None — client-only, **$0** |
| **local** | Same as **web** on desktop (STT `local` is normalized to `web` in prefs) | `flutter_tts` on device | None — **$0** |
| **cloud** | `ReqVoiceStt` → `mod_voice` → Google Cloud Speech | `ReqVoiceTts` → `mod_voice` → Google Cloud Text-to-Speech | Reserve → settle; see [Billing flow](#billing-flow-cloud) |

**Web / local:** no `req_id`, no `billing_reservation`, no balance change.

**Cloud:** requires signed-in session, sufficient balance or quota, and `GOOGLE_CLOUD_API_KEY` on the server. UI caption when cloud is selected: *"Uses Alien AI cloud voice — charged to your balance."*

---

## Client services

Single entry points for the app — pages bind `VoiceApi` once per chat session.

| Service | Role | Key API |
|---------|------|---------|
| **`SttService`** | Mic record/stop, transcribe router | `startRecording()`, `stopAndTranscribe()`, `transcribeRouted()` |
| **`TtsService`** | Speak/stop, engine router | `speak(text)`, `stop()`, `speakRouted()` |
| **`VoiceApi`** | Cloud RPC wrapper | `sttTranscribe(...)`, `ttsSynthesize(...)` |

**Prefs:** `VoicePrefs` — `sttEngine`, `ttsEngine`, `speakEnabled`, `speechLang`, rate/pitch.

**Binding:** `page_ai_home` creates `VoiceApi(chatConn)` and calls `SttService.instance.bindVoiceApi` / `TtsService.instance.bindVoiceApi` in `initState`; clears on `dispose`.

**Routing:**

- STT: `sttEngine == 'cloud'` → `VoiceApi.sttTranscribe`; else `_transcribeWebEndpoint`.
- TTS: `ttsEngine == 'cloud'` → synthesize + `audioplayers`; `web` → fetch MP3 + player; `local` → `flutter_tts` (web TTS falls through to local on failure).

**Files:**

| Path | Purpose |
|------|---------|
| `clients/app/lib/c/stt/stt_service.dart` | Recording + STT router |
| `clients/app/lib/c/tts/tts_service.dart` | TTS router + playback |
| `clients/app/lib/c/voice/voice_api.dart` | Cloud invoke client |
| `clients/app/lib/c/settings/voice_prefs.dart` | Persisted engine + speak toggle |

Cloud errors surface via `ResVoiceStt.error` / `ResVoiceTts.error` and `ui_friendly_error` (e.g. insufficient balance).

---

## Server RPC + billing flow (cloud)

Wire: `InvokeReq.voice_stt` / `InvokeReq.voice_tts` (HTTP + WS). Handler: `c35_mod_voice::voice_stt_rpc` / `voice_tts_rpc` in `wire_http` / `wire_ws`. Auth: session `owner_iid`.

Crate: `servers/crates/mod_voice/` — `voice_stt`, `voice_tts`, Google proxy in `stt.rs` / `tts.rs`, billing helpers in `billing.rs`.

Each request must carry a client-generated **`req_id`** (ULID). Server prefixes `voice_stt_` / `voice_tts_` for dedupe keys.

### Billing flow (cloud)

```
Client                    Server (mod_voice)              Google Cloud
  |  ReqVoiceTts(req_id)    |                                |
  | ----------------------> | voice_billing_gate             |
  |                         | (hold VOICE_TTS_HOLD_USD)      |
  |                         | ------------------------------>|
  |                         |     synthesize / recognize     |
  |                         | <------------------------------|
  |                         | voice_billing_settle           |
  |                         | log_put → ai.log (cost_usd)    |
  |                         | billing_usage_dedupe + deduct  |
  |  ResVoiceTts(audio)     |                                |
  | <---------------------- |                                |
```

Same shape for **`ReqVoiceStt`**. On Google or validation failure: `voice_billing_abort` → `billing_reservation_refund`. Zero retail cost after settle: refund hold, no deduct.

**Log rows:** `kind` = `voice_stt` | `voice_tts`, `topic` = `voice`, `model` = `google.speech` | `google.tts`, `cost_usd` = retail (wholesale × `RETAIL_MARKUP`).

---

## Pricing constants

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

Cloud voice requires a Google Cloud API key with **Speech-to-Text** and **Text-to-Speech** enabled.

| Env var | Required | Notes |
|---------|----------|-------|
| `GOOGLE_CLOUD_API_KEY` | **Yes** (cloud voice) | Primary; used in `mod_voice` STT/TTS |
| `GOOGLE_API_KEY` | Fallback | Accepted if `GOOGLE_CLOUD_API_KEY` unset (same as Gemini embed path) |

**Cluster:** add `GOOGLE_CLOUD_API_KEY` to Kubernetes secret `c35-server-env` (loaded via `envFrom` in [`../deployments/c35-server/deployment.yaml`](../deployments/c35-server/deployment.yaml)). Never commit keys to the repo.

**Local dev:** set in `servers/server_ai/.env.local` or cluster `.env.local` (see `.env.example`).

Missing key → RPC returns friendly *"Cloud voice is temporarily unavailable."* (technical detail in server log only).

---

## cs_bots parity checklist

Reference: `D:\cs_bots` — copy behavior, not imports.

| Feature | c35 location | Status |
|---------|--------------|--------|
| Composer mic (STT) | `widgets/ai/in_composer.dart` + `SttService` | Done |
| Read aloud (assistant context menu) | `page_ai_home.dart` → `onSpeak` → `TtsService.speak` | Done |
| Auto-speak on assistant reply | `page_ai_home.dart` when `VoicePrefs.speakEnabled` | Done |
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
