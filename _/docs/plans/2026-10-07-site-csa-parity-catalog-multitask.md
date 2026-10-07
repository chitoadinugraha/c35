# Site CSA parity + catalog pagination — multitask plan

**Status (2026-10-07):** Waves 1–7 implemented in repo; cluster DDL for `site.link`, `site.post`, `site.queue`, `site.queue_ticket` applied on `c35`. Remaining ops: `publish_server.ps1` + re-publish guest sites for static JS/CSS and prerendered HTML.

## Waves (done)

| Wave | Scope |
|------|--------|
| 1 | `site-guest.v1.js` / `.css`, defer load from `render.rs`, `__SITE_GUEST__` |
| 2 | `site.link` schema, RPC/tools, boot `links[]`, hub render + Flutter links block |
| 3 | `POST /v1/site/guest-product/list`, prerender `data-next-cursor`, Flutter load-more |
| 4 | `site.post`, boot `posts_preload`, publish `html:/posts/{id}`, **`social_feed` block** (prerender + Flutter) |
| 5–6 | `site.queue` guest take/get HTTP, queue block, reservation placeholder on product detail |
| 7 | `site.create` default **hub** template (`hub_profile`, `links`, `social_feed`, `product_grid`), `order_track` |

## `social_feed` block

- Props: `title`, `limit` (1–20, default 20).
- Published HTML: loads storefront posts from DB at render time (same rows as boot `posts_preload`).
- Flutter preview: uses boot `posts_preload` when block is present.

## Verify

```powershell
cd servers
cargo test -p c35_mod_site
cargo test -p c35_mod_chat --test site_tools_test
cargo build -p server_ai
cd ..\clients\app
flutter test test/guest_site_view_test.dart
```

## Deferred (v1.1+)

- Full reservation UX (CSA date/unit picker)
- Queue staff board / MQTT
- `site.post` chat tools + Sites UITable
- Post detail in **draft** preview (publish path OK)
- Alpine.js parity — **not** planned; vanilla `site-guest` only

## Publish

After server/static changes:

```powershell
.\_\scripts\deploy\publish_server.ps1
```

Re-publish affected guest sites so hubs pick up `social_feed` and load-more markup.
