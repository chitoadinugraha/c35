# User location (device, manual, IP)

Approximate **city / region / country** personalizes local answers (weather, bioskop, nearby) and SearXNG `language` on `web.search`.

## Precedence

| `meta.location.source` | How it is set |
|------------------------|---------------|
| `user` | Manual edit in Settings |
| `device` | User allowed GPS; client reverse-geocodes and syncs on `session_init` |
| `ip` | Server Cloudflare geo headers when client sends no city |

IP backfill does not overwrite `user` or `device`.

## Client

- Android/iOS: in-app consent dialog, then `ACCESS_COARSE_LOCATION` (no background).
- Deny: server IP geo on next `session_init`.
- Desktop: Settings + IP only.

## Prompt

- System block: `[USER LOCATION]` in `mod_chat/prompt/time.rs` when `location_city` is set.
- Inst: `inst.web_search` — include user city in `web.search` query for local intents.

## Play Console

Declare **approximate location** (foreground), Data safety, and privacy policy when shipping device location.
