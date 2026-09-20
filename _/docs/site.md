# Site (LOCKED)

Status: **locked** 2026-09-20

Prompt-built websites and business storefronts. Registry = **`identity(kind=site)`**; this module adds satellite tables only.

## Reference

| Project | Borrow |
|---------|--------|
| `E:\Project Archive\csa_site_published` | Sites 3-pane shell, publish flow |
| id.alienai | Product catalog shape, embed columns |
| c35 identity | Staff = `identity_grant` |

## Model

```
identity(kind=site)
  └── site_config       capabilities, tz, costing
  └── site_draft        SiteDoc (block tree — free layout)
  └── site_publish      frozen doc + render_hash
  └── site_domain       custom hostname
  └── site_product      catalog data (POS + product_grid blocks)
  └── site_contact      CRM / tx subject
  └── site_object       tables, rooms, units
```

**Presentation ≠ data.** Guest pages are composed from blocks in `doc_json`. Products/contacts/objects are admin **data** tables — blocks reference them (`product_grid`, `contact_card`), not embedded sections.

## SiteDoc (block tree)

```json
{
  "pages": [
    {
      "path": "/",
      "title": "Home",
      "blocks": [
        { "id": "b1", "type": "hero", "props": { "title": "…", "pic": "…" } },
        { "id": "b2", "type": "markdown", "props": { "md": "…" } },
        { "id": "b3", "type": "product_grid", "props": { "filter": "recommended" } }
      ]
    }
  ],
  "theme": { "accent": "#…", "font": "…", "layout": "wide" },
  "meta": { "seo_title": "…", "favicon": "…" }
}
```

### Block types (v1)

| type | Purpose |
|------|---------|
| `hero` | Title, subtitle, pic, CTA |
| `markdown` | Rich text |
| `image` / `gallery` | Media |
| `links` | Link list / social |
| `product_grid` | Pulls from `site_product` |
| `contact_form` | Guest lead capture |
| `map` / `hours` / `queue` | Optional capability blocks |
| `embed` | iframe / external |
| `spacer` | Layout rhythm |
| `custom_html` | Escape hatch (sandboxed render) |

Capabilities in `site_config.capabilities_json` gate backend features (`commerce`, `booking`, `queue`) — not fixed page sections.

## Tables

See [`../schemas/site.sql`](../schemas/site.sql).

| Table | Synced | Notes |
|-------|--------|-------|
| `site_config` | yes | 1:1 site_iid |
| `site_draft` | yes | `doc_json` |
| `site_publish` | partial | Guest read |
| `site_domain` | yes | DNS + TLS |
| `site_product` | yes | + `ehash_search` for embed regen |
| `site_product_embed` | yes | Per-label search vectors (metadata) |
| `site_contact` | yes | Tx subject |
| `site_object` | yes | Deep links |

Staff: `identity_grant(resource_iid=site_iid, role=staff|manage|owner)`.

## Wire

Proto: [`../schemas/proto/c35/site.proto`](../schemas/proto/c35/site.proto)

- `ReqSiteList` — Sites page master
- `ReqSiteDraftGet/Put` — prompt edits `SiteDoc`
- `ReqSitePublish` — render + activate
- `ReqSiteProduct*` / `ReqSiteContact*` / `ReqSiteObject*` — data admin

Sync collections: `site_draft`, `site_product`, `site_contact`, `site_object`.

Guest checkout: `ReqSiteGuestOrderPut` in `tx.proto`.

## UI (future)

Sites 3-pane:

1. **Master** — site list
2. **Design** — prompt + preview iframe (edits blocks)
3. **Data** — products, contacts, objects (fixed admin forms OK)
4. **POS** — tx editor (Phase 9)

## Embeddings

- **`ai.embed_cache`** — LLM API dedupe ([`../schemas/embed.sql`](../schemas/embed.sql))
- **`site_product.ehash_search`** — invalidates entity embed on name/SKU change
- **`site_product_embed`** — alt labels / aliases for semantic product search
- Vector BYTEA / pgvector HNSW — add when `mod_llm` ships (Phase 1+)

## Deferred

- Site subscription billing
- HR / payroll / presence modules
- Static bundle CAS (`render_hash` → `file` schema)
