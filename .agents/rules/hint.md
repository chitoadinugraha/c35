---
description: Home hint chips — catalog, user_asset_touch, precompiled hint_bundle, SessionInit cache
globs: _/schemas/hint.sql,_/schemas/translation.sql,_/schemas/proto/c35/hint.proto,_/schemas/proto/c35/session.proto,servers/crates/mod_hint/**,servers/crates/mod_identity/src/session_init.rs,servers/crates/wire_ws/src/session.rs,clients/app/lib/c/chat/space_hints.dart,clients/app/lib/c/hint/**,clients/app/lib/widgets/ai/ui_hints.dart,clients/app/lib/pages/page_ai_home.dart
alwaysApply: false
---

# Home hints (precompiled)

Read this before adding hint rows, site/device chips, or SessionInit slices.

## Model (3 tables)

| Table | Role |
|-------|------|
| `ai.hint` | Platform catalog seeds (`hint.consumption_add`, `hint.expense_add`) |
| `ai.user_asset_touch` | Per-user activity (`user_iid`, `asset_iid`, `asset_kind`, `last_accessed_ts`) |
| `ai.hint_bundle` | Materialized `HintCatalog` protobuf (`user_iid` PK, `body` BYTEA) |

**One bundle per user** — not per locale. `compiled_locale` column records which locale was used; recompile when user locale changes.

Labels use `ai.translation` keys (`hint.*.label`, `hint.*.send_text`).

## Wire

```protobuf
message HintItem {
  string id = 1;
  string label = 2;
  string icon = 3;
  int32 sort = 4;
  HintAction action = 5;       // leaf only
  repeated HintItem items = 6; // non-empty → dropdown (Visit / POS / …)
}
message HintCatalog {
  int64 updated_ts_ms = 1;
  repeated HintItem items = 2;
}
```

`ResSessionInit.hints` + `ReqSessionInit.hints_since_ms`. If unchanged, return `updated_ts_ms` only (empty `items`).

Client: restore cached pb from SharedPreferences → instant hero; merge on SessionInit.

## Compiler (`hint_bundle_compile`)

Read-heavy → **never JOIN on SessionInit**. Compile only on miss/invalidation.

```text
1. Load enabled ai.hint (scope role:personal_assistant)
2. Load visible sites (owner_iid OR identity_grant), order by:
     grant.is_pinned DESC,
     user_asset_touch.last_accessed_ts DESC NULLS LAST,
     identity.name ASC
3. Top 3 sites → HintItem with children [Visit, POS]
4. Remaining sites → hint.sites.more group
5. POS child only when site.config capabilities include commerce
6. Translate label keys for user's current locale
7. Encode HintCatalog → UPSERT ai.hint_bundle
```

## Invalidation (required on every new asset type)

Call `hint_invalidate(user_iid)` → `DELETE FROM ai.hint_bundle WHERE user_iid = $1`.

| Event | Who to invalidate |
|-------|-------------------|
| `ai.hint` / hint translation change | `translation_put` (invoke) → `hint_invalidate_all` |
| `site.config` capabilities (`site_config_put`) | `hint_invalidate_for_asset(site_iid)` |
| Site identity rename/pic/alien_id | owner + grantees of that site |
| `identity_grant` add/remove | grantee |
| `site.config` capabilities | owner + grantees |
| `user_asset_touch` upsert (Visit/POS/open) | that user only |
| User locale change (settings) | that user only |
| **New asset in hints** (device, bot, …) | hook the asset's write path + list fan-out helper |

Fan-out helper: `hint_invalidate_for_asset(asset_iid)` → all `user_asset_touch` rows + owner + grantees.

**Rule:** adding a new hint source (e.g. devices) requires (1) compiler input, (2) invalidation hook on that asset's mutations, (3) seed/translation keys if catalog-backed.

## `ai.user_asset_touch` indexes

```sql
PRIMARY KEY (user_iid, asset_iid)
CREATE INDEX idx_user_asset_touch_recent
  ON ai.user_asset_touch (user_iid, last_accessed_ts DESC)
  WHERE deleted_ts IS NULL;
CREATE INDEX idx_user_asset_touch_asset
  ON ai.user_asset_touch (asset_iid)
  WHERE deleted_ts IS NULL;
```

`asset_kind`: `site` | `device` | … (extensible). Upsert on Visit/POS/site page open.

## Client UI

- `items.isEmpty` → run `HintAction` (send_text, pick_image, open_url, navigate)
- `items.nonEmpty` → menu dropdown (leading icons per `ui-dropdown.mdc`)
- Keep `hintsOfflineFallback()` only as offline emergency

## Payload keys

Catalog actions use `payload_json.text` (not `send_text`). Site Visit includes `site_iid` + `asset_kind` for touch. POS requires `capabilities_json.commerce = true` (default false when missing).

## Checklist (new hint feature)

- [ ] Seed `ai.hint` + `ai.translation` keys (en + id)
- [ ] Compiler builds correct tree
- [ ] Invalidation wired on all dependency writes (incl. `site_publish`, future `site.config` put)
- [ ] `ReqHintTouch` upserts `user_asset_touch`
- [ ] SessionInit returns hints; client `HintStore` caches pb
- [ ] Dropdown actions: Visit (`open_url`), POS (`navigate site.pos`)
- [ ] Canonical doc: [`_/docs/hint.md`](../../_/docs/hint.md)
