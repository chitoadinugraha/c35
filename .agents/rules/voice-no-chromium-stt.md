# Voice STT — no Chromium / web public endpoint

Same as [`.cursor/rules/voice-no-chromium-stt.mdc`](../../.cursor/rules/voice-no-chromium-stt.mdc).

**Hard rule:** Do not implement, restore, suggest, or retry client STT via `google.com/speech-api/v2/recognize` (Chromium `client=chromium`, `audio/l16`, cs_bots `_transcribeWebEndpoint`, or STT web/local routing to that URL). Attempted multiple times; not supported.

**Use:** Cloud STT only — `VoiceApi` / `ReqVoiceStt` / `mod_voice`. TTS may still use web/local per `_/docs/voice.md`; that does not apply to STT.

**Settings:** Speech to text = Cloud only. `VoicePrefs` STT = `cloud`. See `_/docs/voice.md`.