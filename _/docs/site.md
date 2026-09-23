# Site (LOCKED)

Status: **locked** 2026-09-21 (revised from 2026-09-20)

Prompt-built websites and business storefronts.

- **Registry + ACL** → `ai.identity(kind=site)` + `ai.identity_grant`
- **All site payload** → YSQL schema **`site`** (does not bloat `ai`)
- **Primary editor** → Home prompt (`@alien_id` / site name); topic **`web.builder`**
- **Admin UI** → Devices-like page + generic **`UITable`** (Airtable-style grids)
- **Guest URLs** → path only: `https://alienai.id/{alien_id}/…` — **never** `{alien_id}.alienai.id`

## Reference

| Project | Borrow |
|---------|--------|
| `D:\csa_site_published` | Publish/render pipeline, guest HTTP router, custom domain + CNAME |
| `E:\Project Archive\id.alienai` | Product catalog shape, POS / tx model |
| c35 Devices page | Master/detail + tabs shell |

## Schema split

```
ai.identity(kind=site)     name, alien_id, pic, owner_iid
ai.identity_grant          staff | manage | owner on site_iid

site.config                capabilities, tz, costing
site.draft                 SiteDoc JSON (presentation)
site.publish               immutable snapshots + render_hash
site.render                compiled HTML bytes (guest serve)
site.domain                custom hostname + tls_status
site.product               catalog (+ site.product_embed sub-rows)
site.contact               CRM / tx subject
site.object                tables, rooms, units
site.parent_link           hub → child tenant

site.tx … site.tx_*        POS (id.alienai model — see tx.md)
```

**Presentation ≠ data.** Guest layout = blocks in `site.draft.doc_json`. Products/contacts/objects live in normalized **`site.*`** tables — blocks and POS reference IDs only.

## Guest routing

| Host | Path | Resolves to |
|------|------|-------------|
| `alienai.id` | `/{alien_id}` | site by `identity.alien_id` |
| `alienai.id` | `/{alien_id}/about` | page inside SiteDoc |
| custom domain (verified) | `/` | site by `site.domain.hostname` (Host header) |

Custom domain: user CNAMEs to `alienai.id` (CF orange cloud OK). TLS cert stored in CF / cert-manager — DB holds **`tls_status`** only.

**API split (implemented):**

| Host | Routes | Purpose |
|------|--------|---------|
| `alienai.id` | `/`, `/{alien_id}/…` | Guest HTML + static (CF proxied) |
| `api.alienai.id` | `/v1`, `/a`, `/ws`, `/fs`, `/livez` | Flutter app WS + invoke + guest HTTP (cart, order) |

Flutter production host: `https://api.alienai.id` (`server_host.dart`, `config.dart`). Server treats `api.alienai.id` as non-guest — never resolves as `alien_id`.

## SiteDoc (block tree)

Stored in `site.draft.doc_json` (v1). Prompt + publish tools edit this JSON. Optional v2: normalize to `site.page` / `site.block` tables for UITable power users.

```json
{
  "pages": [
    {
      "path": "/",
      "title": "Home",
      "blocks": [
        { "id": "b1", "type": "hero", "props": { "title": "…", "pic": "…" } },
        { "id": "b2", "type": "product_grid", "props": { "filter": "recommended" } }
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
| `product_grid` | Pulls from `site.product` |
| `contact_form` | Guest lead capture |
| `map` / `hours` / `queue` | Capability-gated |
| `embed` | iframe / external |
| `spacer` | Layout rhythm |
| `custom_html` | Sandboxed escape hatch |

Capabilities in `site.config.capabilities_json` gate backend features (`commerce`, `booking`, `queue`).

### Block catalog rules

- Platform **block types** and **effect presets** are versioned catalog entries — **immutable** once published.
- Site instances set **`type` + `props` within schema** only; LLM must not extend shared schemas.
- Visual tweaks → `theme` tokens (Tailwind-like) or new catalog version — not per-site schema mutation.

## Tables

See [`../schemas/site.sql`](../schemas/site.sql).

| Table | Synced | UITable tab | Notes |
|-------|--------|-------------|-------|
| `site.config` | yes | Settings | 1:1 site_iid |
| `site.draft` | yes | — | prompt-primary |
| `site.publish` | partial | — | guest read |
| `site.render` | no | — | server compile output |
| `site.domain` | yes | Settings | DNS + TLS status |
| `site.product` | yes | Products | + embed subtable |
| `site.product_embed` | yes | (subtable) | alt labels |
| `site.contact` | yes | Contacts | tx subject |
| `site.object` | yes | Objects | rooms / tables |

Staff: `identity_grant(resource_iid=site_iid, role=staff|manage|owner)`.

## UITable (generic admin grids)

Flutter widget **`UITable`** — collection-driven, like Files detail list view but for sync rows.

```
TableDef (collection.proto)
  → columns (ColDef: key, label, type, readonly, …)
  → subtables (SubTableDef: fk_keys → nested grid on row expand)
```

| Tab | `TableDef.collection` | Subtable |
|-----|-------------------------|----------|
| Products | `site.product` | `site.product_embed` |
| Contacts | `site.contact` | — |
| Objects | `site.object` | — |
| Domains | `site.domain` | — |
| Orders (Phase 9) | `site.tx` | `site.tx_item`, `site.tx_payment` (browse); edit uses tx ledger UI |

Prompt and UITable both call the same RPC/sync puts — one normalized source of truth in YB.

## Prompt editor (`web.builder`)

Topic **`web.builder`** on Home assistant when user mentions a site (`@alien_id`, site name).

| Tool | Edits |
|------|-------|
| `site.draft_put` | SiteDoc blocks + theme |
| `site.publish` | compile → `site.render` + activate `site.publish` |
| `site.product_put` | catalog rows (prefer UITable for bulk) |
| `site.contact_put` / `site.object_put` | data rows |

Instruction seed: [`../schemas/inst.sql`](../schemas/inst.sql) → `inst.web.builder`.

Layout changes → prompt. Bulk catalog edits → UITable. Money/stock → **tx API only** (never free-form LLM JSON).

### Multi-site mentions

Composer may attach **multiple** `@site` mentions in one turn (e.g. compare profitability). Server builds **`MentionContext`** with `sites: Vec<SiteContext>` — see [site-ai.md](site-ai.md).

- **Writes** (`site.product_put`, `site.tx.put`, …): **one `site_iid` per call**; default only when exactly one site mentioned.
- **Reads / compare / reports**: **`site.query.run`** with query catalog ids — not raw SQL, not multi-site write tools.

Capability `commerce` gates POS tools and hint **POS** chip ([hint.md](hint.md)).

## Publish pipeline

```
site.draft.doc_json
  → ReqSitePublish
  → site.publish (immutable snapshot, render_hash)
  → server render job
  → site.render[html:/, …]   (+ blake3 etag)
  → guest HTTP serve (CF cache)
```

Port compile/serve from `csa_site_published` `mod_site` (`publish_render`, `site_render_router`).

## Wire

| Proto | Purpose |
|-------|---------|
| [`site.proto`](../schemas/proto/c35/site.proto) | SiteDoc, draft, publish, product, contact, object RPC |
| [`collection.proto`](../schemas/proto/c35/collection.proto) | `TableDef` / `ReqCollectionDefList` for UITable |
| [`tx.proto`](../schemas/proto/c35/tx.proto) | POS + guest checkout |

RPC summary:

- `ReqSiteList` — Sites nav list
- `ReqSiteDraftGet/Put` — prompt edits SiteDoc
- `ReqSitePublish` — render + activate
- `ReqSiteProduct*` / `ReqSiteContact*` / `ReqSiteObject*` — data CRUD
- `ReqCollectionDefList` — UITable column metadata

Sync collections: `site_draft`, `site_product`, `site_product_embed`, `site_contact`, `site_object`, `site_domain`, `site_config`.

Guest checkout: `ReqSiteGuestOrderPut` in `tx.proto` (HTTP on api host).

## UI

Sites page = **Devices pattern** (see [`ui.md`](ui.md)):

- Nav: site list (pin, rename, alien_id)
- Detail tabs: **Preview** | **Products** | **Contacts** | **Objects** | **Settings** | **Orders** (Phase 9)
- No CSA-style visual hub editor

## Embeddings

- `ai.embed_cache` — LLM API dedupe
- `site.product.ehash_search` — regen on name/SKU change
- `site.product_embed` — alt labels for semantic search

## Deferred

- Normalized `site.page` / `site.block` tables (UITable for layout structure)
- `render_hash` → `file` schema CAS
- Site subscription billing
- HR / payroll / presence modules
