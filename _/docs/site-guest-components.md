# SiteDoc blocks -> CSA guest_ui (v1)

Maps c35 **SiteDoc** block types ([site.md](site.md)) to CSA **guest_ui** components (source: `D:\csa_site_published\.agents\guest_ui.md`).

**Scope:** v1 blocks validated in `mod_site::doc` plus catalog types declared in `site.proto`. Flutter guest widgets (track W1) consume **`site.boot_get`** JSON; web guest HTML uses prerender + `data-guest` attributes per CSA.

## Block -> component mapping

| c35 `type` | Props (summary) | CSA `data-guest` | Widget / Rust fn (target) | Capability gate | Notes |
|------------|-----------------|------------------|---------------------------|-----------------|-------|
| `hero` | `title`, `subtitle`, `pic`, `cta` | `profile` (hub header) | Profile / hero section | -- | Hub-style title block; not full CSA profile row |
| `markdown` | `body` / rich text | -- | Markdown block | -- | Prerender / Flutter markdown; no CSA hub component |
| `image` | `pic`, `alt`, `caption` | -- | Image block | -- | Single media |
| `gallery` | `pics[]`, `title` | -- | Gallery | -- | Carousel on detail in CSA **Post** pattern |
| `links` | link rows / social | `link` | Link list | -- | Maps to CSA link rows |
| `product_grid` | `filter`, `category`, `limit` | `site_product` | Product cards | `commerce` (sell) | Boot JSON preloads products per block id |
| `contact_form` | fields config | `form` | Form + `ReqSiteFormSubmit` | -- | Alpine/RPC on web; same RPC on Flutter |
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
| Checkout | `checkout` | `mod_site_tx` guest order RPCs |
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
| `mode` | `draft` \| `published` |

## Capability gates

From `site.config.capabilities_json` ([site.md](site.md)):

| Capability | Blocks / tools |
|------------|----------------|
| `commerce` | `product_grid`, cart, checkout, POS tools |
| `booking` | reservation sub-flows on product detail |
| `queue` | `queue` block + queue RPCs |
| `attendance` | Staff-only; not guest blocks |

## Versioning

- New **block types** -> update `site.proto` comment, `mod_site::doc` catalog, this table, and CSA `guest_ui.md` before implementation.
- CSA **guest_ui** catalog is fixed; c35 blocks must map into it or stay presentation-only (markdown, spacer).