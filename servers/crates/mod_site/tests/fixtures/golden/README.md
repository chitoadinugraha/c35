# Golden guest boot fixtures

Full `site.boot_get` JSON snapshots (draft and published) for real commerce sites live here as:

- `{alien_id}_boot_draft.json`
- `{alien_id}_boot_published.json`

Redact secrets only (signed `/fs/` tokens, API keys). Keep `pages`, `theme`, `design`, `product_preload`, and `commerce_boot` shape intact.

## Export via MCP (`site.boot_get`)

1. Resolve `site_iid` (example `natepaperie` → `80157132410142720`).
2. Call `site.boot_get` twice with the same `site_iid`:
   - `mode`: `draft`
   - `mode`: `published`
3. Save the response `boot_json` string to the filenames above.
4. Run `cargo test -p c35_mod_site --test guest_parity_test` to confirm boot key parity still passes.

`natepaperie_hub.json` is a **blocks-only** slice from `site.draft` (home page). It is used for HTML parity tests without storing a full boot blob in git.
