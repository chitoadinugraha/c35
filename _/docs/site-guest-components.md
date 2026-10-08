# SiteDoc blocks -> CSA guest_ui (v1)

Maps c35 **SiteDoc** block types ([site.md](site.md)) to CSA **guest_ui** components (source: `D:\csa_site_published\.agents\guest_ui.md`).

**Scope:** v1 blocks validated in `mod_site::doc` plus catalog types declared in `site.proto`. Flutter guest widgets (track W1) consume **`site.boot_get`** JSON; web guest HTML uses prerender + `data-guest` attributes per CSA.

## Web guest assets

- Web guest UI is vanilla JS. No Alpine.js.
- Served files: `/static/site-guest/site-guest.v1.js` on every page (cart, reservation, catalog, orders, contact form, queue). `/static/site-guest/site-guest.effects.v1.js` plus `/static/site-guest/effects/overlay_effects.js` and wasm ONLY when at least one effect has `active !== false` and a known preset id.
- Do not split form or queue into extra script files.
- Boot effect rows: `presetId`, `params` object, `active`.
- `commerce_boot.payment_methods` from `doc_json.payment_accounts`.
- `contact_form` HTML uses `data-guest="form"`.
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

Flutter and preview use the same payload shape (v1 string `boot_json`):

| Field | Role |
|-------|------|
| `site_id`, `name`, `alien_id`, `avatar_url` | Identity meta (CSA `__SITE_BOOT__` subset) |
| `meta`, `theme` | From `SiteDoc` |
| `pages` | Block tree (`id`, `type`, `props`) |
| `capabilities` | From `site.config.capabilities_json` |
| `product_preload` | Map block id -> product rows for each `product_grid` |
| `commerce_boot.products[]` | `can_reserve`, `duration_value` (default 1), `duration_unit` (default `day`), `reservation_unit_selection` (`guest_picks` or `system`) from `site.product.product_json` |
| `commerce_boot.objects[]` | Reservable `site.object` rows `{id, name, code, pic, kind, product_id}` when `booking` is on; `[]` when booking is off |
| `commerce_boot.payment_methods` | From `doc_json.payment_accounts` |
| `effects[]` | Boot rows `{ presetId, params, active }`. `params` is an object. Web loads the effects script only when one row has `active !== false` and a known preset id |
| `mode` | `draft` \| `published` |

## Reservation sheet

Same behavior on the Flutter preview and the published page (`window.c35ReservationMath` / `site_reservation_math.dart`).

| `duration_unit` | Picker |
|-----------------|--------|
| empty or `day` | Date only (local midnight) |
| `second`, `minute`, `hour`, `week`, `month`, `year` | Date and time (`YYYY-MM-DDTHH:mm`, no timezone suffix) |

Billable quantity is units times duration slices on a half-open window `[start, end)`. The line total is that quantity times the product price per duration unit.

`guest_picks` lets the guest tap a unit. The chosen id is `site_object_id` on `tx.items[].reservations` (`0` means the system assigns any free unit). `POST /v1/site/guest-reservation/availability` fills “units left” and which tiles are free. `guest-order/put` runs the same check again and rejects a double book. Cancelled transactions do not count. The unpaid order is the hold.

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