# Media generation providers

Server-side image, video, and music generation with per-user provider prefs and WS regenerate.

## Identity prefs (`ai.identity.meta.generation`)

| Key | Values | Default |
|-----|--------|---------|
| `image` | `auto`, `gemini`, `grok` | `auto` |
| `video` | `auto`, `seedance`, `gemini` | `auto` |
| `music` | `auto`, `gemini`, `minimax`, `elevenlabs` | `auto` |

Synced on `ReqSessionInit` fields `generation_image`, `generation_video`, `generation_music` (empty = no change).

## Tools

| Tool | Default backend |
|------|-----------------|
| `img.generate` / `img.edit` | Gemini tiers; `auto` may route lite draft to Grok when `C35_IMG_PROVIDER=grok` |
| `vid.generate` | Cloudflare `bytedance/seedance-2.0-mini` (5s default); `gemini` → not enabled yet |
| `music.generate` | `auto`/`elevenlabs` → CF `elevenlabs/music-v2`; `gemini` → Lyria clip; `minimax` → CF `minimax/music-2.6` |

Blocks carry `media_provider`, `media_model`, `tool`, and kind-specific fields in `body`.

## WS `media_regenerate` (177)

`ReqMediaRegenerate`: `msg_id`, `block_index`, optional `provider`, `set_default`.

Reloads the block prompt, re-runs the matching tool, updates `chat_msg.blocks_json`, deducts retail billing, optionally saves provider pref.

## Billing

Wholesale constants in `mod_billing::billing_cost` (`image_tool_*`, `video_tool_wholesale_usd`, `music_tool_wholesale_usd`); retail = 1.5× wholesale.
