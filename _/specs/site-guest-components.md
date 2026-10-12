# SiteDoc blocks -> CSA guest_ui (v1)

Maps c35 **SiteDoc** block types ([site.md](site.md)) to CSA **guest_ui** components (source: `D:\csa_site_published\.agents\guest_ui.md`).

**Scope:** v1 blocks validated in `mod_site::doc` plus catalog types declared in `site.proto`. Flutter guest widgets (track W1) consume **`site.boot_get`** JSON; web guest HTML uses prerender + `data-guest` attributes per CSA.

**Canonical guest UI:** **App preview** (`GuestSiteView` in `clients/app/lib/guest_site/`) is the reference for layout and behavior. Published HTML/CSS/JS must match the same boot JSON. Agents: [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../.cursor/rules/site-guest-dual-renderer-parity.mdc). Plan: [`plans/2026-10-11-site-preview-web-renderer-parity-multitask.md`](plans/2026-10-11-site-preview-web-renderer-parity-multitask.md).

## Comparing preview and browser

Operators debug parity across **three surfaces**. Do not compare the wrong pair.

| Surface | Data source | Typical URL / entry |
|---------|-------------|---------------------|
| **In-app preview (Flutter)** | `site.boot_get` with `mode: draft` or `published` | Site editor or `UiSitePreview` (`SitePreviewMode`) |
| **Draft browser HTML** | Live `site.draft` via `page_html_render` (not `site.render`) | `https://alienai.id/{alien_id}?draft=1` or dev `http://localhost:10000/{alien_id}?draft=1` |
| **Published browser HTML** | Rows in `site.render` (`render_key` `html:*`) from the last **Publish** | Bare slug: `http://localhost:10000/{alien_id}` (prod: `https://alienai.id/{alien_id}`) |

**Draft preview vs published HTML:** In-app **Draft** matches unsaved editor work and the **Visit** link (`?draft=1`). The bare slug without query serves the **last publish** only. Edits that are not published will not appear on the bare URL.

**Published mode in preview:** Use **Published** in the preview toggle only when checking public behavior. That mode loads `boot_get` published boot and the Visit overlay opens the bare slug. It should match the browser **after** **Publish** in the app.

**Before comparing to the bare URL:** Run **Publish** so `site.publish` / `site.render` refresh. `site_publish_pending_for_draft` compares draft `render_hash` to the active publish; until they match, the public URL is stale.

**Visit link:** Editor **Draft** + **Open in browser** uses `/{alien_id}?draft=1`. **Published** mode opens `/{alien_id}` with no query. Draft HTML uses `site_draft_html_render` on current `site.draft`.

**Sharing drafts:** `?draft=1` is enough — no preview token. Anyone with the link sees the current draft (same as a public URL with a different snapshot). Legacy `ptoken` query params are ignored.

**Local dev (`dev_server.ps1`):** `C35_GUEST_DEV_LIVE_RENDER=1` (default) re-runs `page_html_render` on each `localhost` request using the **published doc snapshot**, so renderer/CSS/JS code changes show without republishing. Production and non-local hosts still serve cached `site.render` until **Publish**. Unpublished **draft** edits still require the Visit link or in-app Draft preview.

## Web guest assets

- Web guest UI is vanilla JS. No Alpine.js.
- Served files: `/static/site-guest/site-guest.v1.js` on every page (cart, reservation, catalog, orders, contact form, queue). `/static/site-guest/site-guest.effects.v1.js` plus `/static/site-guest/effects/overlay_effects.js` and wasm ONLY when at least one effect has `active !== false` and a known preset id.
- Do not split form or queue into extra script files.
- Boot effect rows: `presetId`, `params` object, `active`.
- `commerce_boot.payment_methods` from `doc_json.payment_accounts`.
- `contact_form` HTML uses `data-guest="form"`.
- Guest HTML `<head>`: `<link rel="icon">` from `meta.favicon`, else `meta.avatar_url`, else hub profile `pic`, else site identity `pic` (not platform `/favicon.ico`).
- Minified JS, `Cache-Control: public, max-age=86400`, gzip at the Cloudflare edge (origin does not store .gz).

Web effects host is `site-guest.effects.v1.js` (WASM). Flutter effects use `GuestSiteEffectStack` (Dart painters).

## Block -> component mapping

| c35 `type` | Props (summary) | CSA `data-guest` | Widget / Rust fn (target) | Capability gate | Notes |
|------------|-----------------|------------------|---------------------------|-----------------|-------|
| `hero` | `title`, `subtitle`, `pic`, `cta` | `profile` (hub header) | Profile / hero section | -- | Hub-style title block; not full CSA profile row |
| `markdown` | `body` / rich text | -- | Markdown block | -- | Prerender / Flutter markdown; no CSA hub component |
| `image` | `pic`, `alt`, `caption` | -- | Image block | -- | Single media |
| `gallery` | `pics[]`, `title` | -- | Gallery | -- | Carousel on detail in CSA **Post** pattern |
| `links` | link rows / social | `link` | Link list | -- | Maps to CSA link rows |
| `product_grid` | `filter`, `category`, `limit` | `site_product` | Product cards | `commerce` (sell) | Boot JSON preloads products per block id |
| `contact_form` | fields config | `form` | Form + `ReqSiteFormSubmit` | -- | HTML uses `data-guest="form"`. Vanilla JS in `site-guest.v1.js`; same RPC on Flutter |
| `map` | geo / label | -- | Map embed | optional | CSA has no dedicated map hub block |
| `hours` | schedule rows | `profile` (hours toggle) | Hours table | optional | CSA profile optional hours |
| `queue` | queue config | `queue` | Queue take/track | `queue` | Link to `/queue/...` on web |
| `embed` | `url`, sandbox flags | -- | iframe block | -- | Adjacent to `custom_html` escape hatch |
| `spacer` | `height` | -- | Layout spacer | -- | Rhythm only |
| `custom_html` | sandboxed HTML | -- | Web-only escape | -- | Flutter may skip or WebView fallback |

## Chrome / flows (not SiteDoc blocks)

| Concern | CSA component | c35 source |
|---------|---------------|------------|
| Cart bar | `cart` | Commerce capability + guest JS / Flutter state |
| Checkout | `checkout` | `POST /v1/site/guest-order/put` |
| Reservation sheet | `reservation` | Flutter `guest_site_reservation_sheet.dart`; web `site-guest.v1.js` (`data-guest="reservation"`). Gate: `booking`. Reservable product detail shows **Reservasi** (`guest-reserve-btn`) and does not also show `+ Pesan`. |
| Order status | `order` | `ReqSiteGuestOrderGet` / tx get |
| Featured contacts | `contacts` | `site.contact` rows (future hub block) |
| Social posts | `social_post` | Not in c35 v1 SiteDoc (CSA hub); add block type later |

## Boot JSON (`site.boot_get`)

Flutter and preview use the same payload shape (v1 string `boot_json`).

| Flutter (`GuestSiteBoot`) | Published `__SITE_GUEST__` | JS consumer |
|---------------------------|----------------------------|-------------|
| `siteIid` / `site_id` | `site_iid` | cart, forms, order poll |
| `commerceBoot` | `commerce_boot` | products map, payment methods |
| `design` / theme | `design` + `theme` | layout from HTML/CSS + tokens |
| `orderProgressSteps` | `order_progress_steps` | optional; preview poll is label-only |
| `SiteAiAssistantDraft` / editor | `ai_assistant` | `c35GuestAssistant` FABs + chat/call UI |
| `meta.knowledge[]` (published) | `knowledge` | server-trimmed title+content rows for guest assistant context |

Fields:

| Field | Role |
|-------|------|
| `site_id`, `name`, `alien_id`, `avatar_url` | Identity meta (CSA `__SITE_BOOT__` subset) |
| `meta`, `theme` | From `SiteDoc` |
| `pages` | Block tree (`id`, `type`, `props`) |
| `capabilities` | From `site.config.capabilities_json` |
| `product_preload` | Map block id -> product rows for each `product_grid` |
| `commerce_boot.products[]` | `can_reserve`, `duration_value` (default 1), `duration_unit` (default `day`), `reservation_unit_selection` (`guest_picks` or `system`), `reservation_inventory_mode` (`capacity` or `objects`), `reservation_capacity`, `reservation_hold_ttl_seconds` (default 3600) from `site.product.product_json` |
| `commerce_boot.objects[]` | Reservable `site.object` rows `{id, name, code, pic, kind, product_id}` when `booking` is on; `[]` when booking is off |
| `commerce_boot.payment_methods` | From `doc_json.payment_accounts` |
| `effects[]` | Boot rows `{ presetId, params, active }`. `params` is an object. Web loads the effects script only when one row has `active !== false` and a known preset id |
| `mode` | `draft` \| `published` |
| `ai_assistant` | Guest Alien AI chrome: `chat_enabled`, `call_enabled`, `chat_intro`, `chat_placeholder`, `call_intro`, legacy `floating_bubble` → chat |
| `knowledge` | Published knowledge rows `{title, content}` (capped in `mod_site::site_assistant`) |

## Alien AI assistant (guest chrome)

| Concern | Web | Boot / DOM |
|---------|-----|------------|
| Chat FAB + panel | `c35GuestAssistant.openChat` / `sendChat` | `ai_assistant.chat_enabled`; `data-guest-assistant` on `#c35-guest-assistant-root` and chat sheet |
| Call overlay | `c35GuestAssistant.startCall` / `endCall` | `ai_assistant.call_enabled`; `data-guest-assistant="call"` |
| Cart dock | Chat FAB docks left of **Pesan** when `#c35-guest-cart-row` visible | `.guest-cart-row--assistant` + `#c35-guest-cart-trailing` |
| Chat API | `POST https://api.alienai.id/v1/site/guest-assistant/chat` (SSE or JSON) | `visitor_id` in `localStorage`; optional `cart` payload from `c35GuestCart.checkoutLines()` |

## Reservation sheet

Same behavior on the Flutter preview and the published page (`window.c35ReservationMath` / `site_reservation_math.dart`).

| `duration_unit` | Picker |
|-----------------|--------|
| empty or `day` | Date only (local midnight) |
| `second`, `minute`, `hour`, `week`, `month`, `year` | Date and time (`YYYY-MM-DDTHH:mm`, no timezone suffix) |

Billable quantity is units times duration slices on a half-open window `[start, end)`. The line total is that quantity times the product price per duration unit.

`guest_picks` lets the guest tap a unit. The chosen id is `site_object_id` on `tx.items[].reservations` (`0` means the system assigns any free unit). `POST /v1/site/guest-reservation/availability` fills “units left” and which tiles are free. `guest-order/put` runs the same check again and rejects a double book. Cancelled transactions do not count. The unpaid order is the hold.

**Merchant setup (Home):** seed inst `inst.site.reservation` in [`_/schemas/inst.sql`](../schemas/inst.sql) — enable `booking`, set reservation fields in `product_json`, add units via `site.object_put`. Live cluster needs `inst_put` after deploy.

**CSA parity (in progress):** per-seat picks when `units > 1`, `reservation_inventory_mode` / `reservation_capacity` availability, and `reservation_hold_ttl_seconds` on overlap — see [`plans/2026-10-12-site-reservation-csa-gaps-multitask.md`](plans/2026-10-12-site-reservation-csa-gaps-multitask.md).

## Capability gates

From `site.config.capabilities_json` ([site.md](site.md)):

| Capability | Blocks / tools |
|------------|----------------|
| `commerce` | `product_grid`, cart, checkout, POS tools |
| `booking` | Objects tab, reservation sheet, `commerce_boot.objects[]` |
| `queue` | `queue` block + queue RPCs |
| `attendance` | Staff-only; not guest blocks |

## Versioning

- New **block types** -> update `site.proto` comment, `mod_site::doc` catalog, this table, and CSA `guest_ui.md` before implementation.
- CSA **guest_ui** catalog is fixed; c35 blocks must map into it or stay presentation-only (markdown, spacer).