# Live Call

Voice sessions on the home welcome screen, separate from the chat model picker.

Live Call is duplex audio, billed per minute, on `ai.live_offer`. **Talk** is turn-based: the same Home thread, mic in, one prompt out ([ui.md](ui.md#talk)). A Talk send does not call `ReqLiveStart`.

## Catalog

Rows in **`ai.live_offer`** (see `_/schemas/live_offer.sql`). Not synced into `ai.llm_model`. Session init returns **`LiveCatalog`** on `ResSessionInit.live`.

| id | UI | Backend (v1) |
|----|-----|----------------|
| `live.alienai` | Call Alien AI | `gemini-3.8-live` + `inst.general` |
| `live.gemini` | Call Gemini | `gemini-3.8-live` |
| `live.gemini.thinker` | Call Gemini Thinker | `gemini-3.8-live-extended-thinking` |
| `live.chatgpt` | Call ChatGPT | disabled — **Coming soon** (OpenAI Realtime not shipped) |
| `live.grok` | Call Grok | disabled — **Coming soon** (xAI realtime not shipped) |

Retail **~$/min** on chip = `(input_usd_per_min + output_usd_per_min) × 1.5`.

## Welcome chip UX

Composer family drives **primary label**; **`live_offer`** drives menu rows (see `_/docs/plans/2026-10-05-live-call-multitask.md`).

## RPC

- `ReqLiveStart` / `ResLiveStart` on app WS (`live_start = 179`).
- **`C35_LIVE_ENABLED=1`** required on **release** builds; debug `server_ai` enables live by default. Set `C35_LIVE_ENABLED=0` to disable locally. Without live enabled: `"Live call is not available yet"`.
- Track C (not shipped): `/v1/live/ws` Gemini Live proxy.
- Track C: `/v1/live/ws` proxies Gemini Live (`C35_LIVE_ENABLED=1`).

## Realtime smoke (dev)

Binary `live_realtime_smoke` sends one PCM clip to Gemini Live, ChatGPT Realtime, and Grok Voice in parallel.

```powershell
cd servers
cargo run -p c35_mod_live --bin live_realtime_smoke
```

| Env | Effect |
|-----|--------|
| `LIVE_SMOKE_WAV` | Use existing 16 kHz mono WAV instead of TTS |
| `LIVE_SMOKE_GEMINI_MODEL` | Gemini bidi model (default `gemini-3.8-live`, same as `ai.live_offer`) |
| `OPENAI_API_KEY` / `XAI_API_KEY` | Direct WebSocket to OpenAI / xAI |
| `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_AI_GATEWAY_ID` | CF AI Gateway (same as HTTP chat in `mod_llm`) |
| `LIVE_REALTIME_VIA_CF` | `1` = CF only for ChatGPT/Grok legs; `0` = direct only; unset = auto (CF when gateway env is ready) |
| `LIVE_REALTIME_CF_FALLBACK` | `1` = after a failed CF leg, retry direct WebSocket (default off) |

**Direct** (unchanged): `wss://api.openai.com/v1/realtime`, `wss://api.x.ai/v1/realtime`.

**Via CF** (alternative): `wss://gateway.ai.cloudflare.com/v1/{account}/{gateway}/openai?model=…` and `…/grok/v1/realtime?model=…` with header `cf-aig-authorization: Bearer {CLOUDFLARE_API_TOKEN}`; optional `Authorization: Bearer {provider key}` when not using gateway BYOK. Smoke labels: `chatgpt_realtime_cf`, `grok_voice_cf`.

Helpers: `c35_mod_llm::cf_realtime_ws_url`, `cf_realtime_ws_header_pairs`, `CfRealtimeUpstream`.

## Ops

Apply schema: `_/schemas/migrations/20261005_live_offer_v1.sql` or boot migrate after bundle hash change. Rollout `server_ai` after edits.
