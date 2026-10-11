# Guest preview vs web renderer gaps

**Date:** 2026-10-11  
**Canonical:** App `GuestSiteView` per `.cursor/rules/site-guest-dual-renderer-parity.mdc`.

## Wave 8 verification (2026-10-11)

| Check | Result |
|-------|--------|
| `cargo test -p c35_mod_site --test guest_parity_test --test guest_design_test --test render_test` | **44 pass** (10 + 3 + 31) |
| `flutter test` guest_site_view, guest_site_design, guest_contact_api, guest_site_cart, site_preview_external_url | **22 pass** |
| `site-guest/build.ps1` | pass |
| `check_utf8_sources.ps1 -Changed -Fix` | pass (plan artifacts; full `-Changed` may abort on git CRLF warning for unrelated paths) |

Manual golden-site E2E (draft/published URLs, CSA spot-check) not re-run in Wave 8 — still open below.

## Wave 7 verification (2026-10-11)

| Check | Result |
|-------|--------|
| `cargo test -p c35_mod_site` (guest_parity, render, guest_design) | pass |
| `cargo build -p server_ai` | pass (after `user_asset_rag` borrow fix) |
| `flutter test` guest_site_view + guest_site_design | 16 pass |
| `site-guest/build.ps1` | run in Waves 5–6 |

## Shipped in Waves 0–9 (2026-10-11 multitask)

- **0:** Operator workflow + publish pipeline docs; golden fixture README + `natepaperie_hub.json`.
- **1:** Three-way gap audit ([`2026-10-11-guest-csa-identity-gaps.md`](2026-10-11-guest-csa-identity-gaps.md)); `guest_parity_*.json` + extended `guest_parity_test.rs`.
- **2–3:** Web shell (720px, cart inset), hub hero/profile, links rows + icons, product grid list/grid + in-cart badge, hours/social/strips parity tests.
- **4–5:** Cart/checkout JS aligned with Flutter; product/post detail carousel + lightbox.
- **6:** Contact form API on Flutter; order-track poll labels; cart SharedPreferences; effects pointer-events.
- **7:** Effects preset filter test; z-order documented.
- **8:** **44** Rust + **22** Flutter automated tests green (see table above).
- **9:** Editor “Publish to update public URL” banner; shared `sitePreviewExternalUrl()` for draft `ptoken` Visit links.

## Still open (post–Wave 8)

1. **Live E2E:** `publish_server.ps1` + per-site **Publish**, then hub + `/products/{id}` on prod (or localhost after publish).
2. **Residual GAPs:** see [`2026-10-11-guest-csa-identity-gaps.md`](2026-10-11-guest-csa-identity-gaps.md) — links `placement` port-csa, post carousel polish, optional in-cart badge on CSA catalog parity.
3. **Plan doc encoding:** if `2026-10-11-site-preview-web-renderer-parity-multitask.md` shows mojibake, re-save as UTF-8 (no UTF-16).

## Operator workflow

Use this checklist when validating guest parity on a golden site (e.g. `natepaperie`). See also [Comparing preview and browser](../../site-guest-components.md#comparing-preview-and-browser).

1. **Draft alignment:** In-app preview (**Draft**) should match the browser **Visit** URL: `/{alien_id}?draft=1&ptoken=…` (use the editor overlay, not a hand-typed bare slug).
2. **Published alignment:** In-app preview (**Published**) should match `http://localhost:10000/{alien_id}` (or prod slug) **after** **Publish** in the app.
3. **Checks:** profile avatar on/off, accent, first product grid card, cart bar, one link row, one effect (if enabled).
4. **Detail:** open one product — reserve/pesan rules, price, image.
5. **CSA spot-check:** same flows on the CSA reference site when the block mix matches (visual rhythm; font stack may differ).

Record PASS/GAP here or in Wave 8 verification notes after each full pass.

## Publish pipeline (Wave 0C)

**Confirmed (code):** `site_publish_from_draft` in `servers/crates/mod_site/src/site_publish.rs` always rebuilds HTML before writing `site.render`:

1. Load `site.draft.doc_json`, grant-check owner.
2. `publish_doc_render` → for each SiteDoc page, `page_html_render` → `(render_key, html)` with keys `html:{path}` (default `html:/` if no pages).
3. Same publish pass also renders storefront `html:/products/{id}` and `html:/posts/{id}` for sellable products and posts.
4. Blake3 **bundle** over all `(key, html)` pairs → `site.publish.render_hash`; deactivate prior active row, insert new `site.publish`, update `site.config.published_version_id`.
5. Upsert each page into `site.render` (`body`, `etag` from `render_etag`).
6. HTTP guest routes without `draft=1` serve those cached rows via `render_get`; `?draft=1&ptoken=` bypasses cache and calls `site_draft_html_render` → `page_html_render` on current draft.

Design or block changes therefore require **Publish** to update the bare public URL; draft browser preview does not.

### Manual publish verify (0C.2)

1. Note current hub HTML (optional): `curl -s -D - http://localhost:10000/{alien_id} -o NUL` and save `ETag` or a snippet inside `window.__SITE_GUEST__`.
2. Edit a visible block in the site editor (e.g. hero title).
3. Tap **Publish** in the app (wait for success).
4. Re-fetch: `curl -s http://localhost:10000/{alien_id} | findstr __SITE_GUEST__` — inline boot JSON should reflect the edit; response `ETag` should change if body changed.
5. If the bare URL is unchanged but Draft/Visit shows the edit, publish did not run or `render_hash` still matches (no effective HTML diff); re-check pending publish in the editor.

## Commands

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site --test guest_parity_test --test render_test --test guest_design_test
cargo build -p server_ai

cd D:\c35\clients\app
flutter test test/guest_site_view_test.dart test/guest_site_design_test.dart

cd D:\c35\clients\web\static\site-guest
.\build.ps1
```
