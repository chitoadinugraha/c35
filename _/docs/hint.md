# Home hints (LOCKED)

Status: **locked** 2026-09-23

Precompiled shortcut chips on the Home empty state (new chat hero). Server builds a nested `HintCatalog` tree per user; client caches protobuf for instant paint and refreshes via `SessionInit`.

## Tables

| Table | Role |
|-------|------|
| `ai.hint` | Platform catalog (`hint.consumption_add`, `hint.expense_add`) |
| `ai.user_asset_touch` | Per-user last access (`user_iid`, `asset_iid`, `asset_kind`, `last_accessed_ts`) |
| `ai.hint_bundle` | Materialized `HintCatalog` protobuf (`user_iid` PK, `body` BYTEA, `compiled_locale`) |

DDL: [`../schemas/hint.sql`](../schemas/hint.sql)

Labels use `ai.translation` keys (`hint.*.label`, `hint.*.send_text`).

## Wire

Proto: [`../schemas/proto/c35/hint.proto`](../schemas/proto/c35/hint.proto)

- `ReqSessionInit.hints_since_ms` — client watermark
- `ResSessionInit.hints` — `HintCatalog { updated_ts_ms, items[] }`
- If unchanged: `updated_ts_ms` only, empty `items`
- `ReqHintTouch` / `ResHintTouch` — record Visit/POS (upsert touch + invalidate bundle)
- `ReqSiteConfigPut` / `ResSiteConfigPut` — update `site.config.capabilities_json` (manage grant)
- `ReqTranslationPut` / `ResTranslationPut` — root admin upsert `ai.translation` (invalidates all bundles when `category=hint` or `key` starts with `hint.`)

## Tree shape

```text
Track Consumption     [pick_image → text + inst]
Track Expense         [send_text]
{Site 1}              → Visit | POS (if commerce)
{Site 2}              → Visit | POS
{Site 3}              → Visit | POS
More (if >3)          → remaining sites (each → Visit | POS)
```

- `items.isEmpty` → run `HintAction` on tap
- `items.nonEmpty` → dropdown menu

### Actions

| kind | payload | client behavior |
|------|---------|-----------------|
| `send_text` | `{ "text", "inst_id"? }` | send chat message |
| `pick_image` | `{ "text", "inst_id"? }` | image picker + send |
| `open_url` | `{ "url", "site_iid", "asset_kind" }` | external browser + touch |
| `navigate` | `{ "route": "site.pos", "site_iid", "asset_kind" }` | Sites page POS tab + touch |

POS child only when `site.config.capabilities_json.commerce = true`.

## Compiler (`hint_bundle_compile`)

Read-heavy → **no JOIN on SessionInit read**. Compile on cache miss or after invalidation.

1. Load `ai.hint` (scope `role:personal_assistant`)
2. Load visible sites (owner or grant), order: `grant.is_pinned DESC`, `user_asset_touch.last_accessed_ts DESC`, `name ASC`
3. Top 3 as site chips; rest under `hint.sites.more`
4. Translate labels for user locale (`compiled_locale` stored on bundle)
5. Encode protobuf → UPSERT `ai.hint_bundle`

One bundle per user. Locale change → `compiled_locale` mismatch → recompile on next SessionInit.

## Invalidation

`DELETE FROM ai.hint_bundle WHERE user_iid = $1`

| Event | Invalidate |
|-------|------------|
| Site identity rename/pic/alien_id | `hint_invalidate_for_asset(site_iid)` |
| Site publish / `site_config_put` | `hint_invalidate_for_asset(site_iid)` |
| Translation admin (`translation_put`, hint keys) | `hint_invalidate_all()` |
| Grant pin/archive (site) | grantee |
| `user_asset_touch` upsert | that user |
| Locale change | lazy recompile via `compiled_locale` |
| Catalog / hint translation change | all users (`hint_invalidate_all`) |

**Rule:** new hint asset types (device, bot, …) must add compiler input + invalidation hook.

## Client

- `HintStore` — SharedPreferences cache (`c35.hint.rev`, base64 pb)
- Restore at boot → instant hero; merge on `SessionInit`
- `hintsOfflineFallbackItems()` — emergency only when server returns nothing

## Related

- Shell UI: [ui.md](ui.md) (Home hero hints)
- Sync: [sync.md](sync.md) (`hints_since_ms` in SessionInit)
- Sites / POS: [site.md](site.md), [tx.md](tx.md)
- Cursor rule: [`.cursor/rules/hint.mdc`](../.cursor/rules/hint.mdc)
