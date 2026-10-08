# Site (LOCKED)

Status: **locked** 2026-09-21 (revised 2026-10-08 - domain purchase)

Prompt-built websites and business storefronts.

- **Registry + ACL** → `ai.identity(kind=site)` + `ai.identity_grant`
- **All site payload** → YSQL schema **`site`** (does not bloat `ai`)
- **Primary editors** → Sites page (CSA section menu, Info first) and Home prompt (`@alien_id`, topic `web.builder`)
- **Admin UI** → Sites editor shell (rail + preview). `UITable` remains for power users
- **Guest URLs** → path only: `https://alienai.id/{alien_id}/…` — **never** `{alien_id}.alienai.id`
- **Guest effects** → Web runs `overlay_effects` WASM only when the theme has an active preset. Flutter runs Dart painters. Preset ids match `presets.json`

## Reference

| Project | Borrow |
|---------|--------|
| `D:\csa_site_published` | Publish/render pipeline, guest HTTP router, custom domain + CNAME |
| `D:\csa_site_published` | Also the source for `crates/overlay_effects`, `client/site/src/effects/host.ts`, and `clients/app/lib/widgets/site/ui_site_*_section.dart` (UX only) |
| `E:\Project Archive\id.alienai` | Product catalog shape, POS / tx model |
| c35 Devices page | Master/detail + tabs shell |

## Schema split

```
ai.identity(kind=site)     name, alien_id, pic, owner_iid
ai.identity_grant          staff | manage | guest | owner on site_iid

site.config                capabilities, tz, costing
site.draft                 SiteDoc JSON (presentation)
site.publish               immutable snapshots + render_hash
site.render                compiled HTML bytes (guest serve)
site.domain                custom hostname + tls_status + source (byo | bought)
site.product               catalog (+ site.product_embed sub-rows)
site.contact               CRM / tx subject
site.object                tables, rooms, units
site.parent_link           hub → child tenant

site.work_shift            named shifts (Team / Attendance)
site.work_shift_slot       slots within a shift
site.member_shift          grantee ↔ shift (via site_iid + grantee_iid)
site.member_face           face enroll photos (attendance-gated)
site.presence_location     geo points for Attendance later

site.tx … site.tx_*        POS (id.alienai model — see tx.md)
```

**Presentation ≠ data.** Guest layout = blocks in `site.draft.doc_json`. Products/contacts/objects live in normalized **`site.*`** tables — blocks and POS reference IDs only.

## Guest routing

| Host | Path | Resolves to |
|------|------|-------------|
| `alienai.id` | `/{alien_id}` | site by `identity.alien_id` |
| `alienai.id` | `/{alien_id}/about` | page inside SiteDoc |
| custom domain (verified) | `/` | site by `site.domain.hostname` (Host header) |

## Custom domains (HTTP)

Customers attach their own hostname to a published site. **Do not** point DNS at orange **`alienai.id`** — that host is Cloudflare-proxied for path guest URLs only (`https://alienai.id/{alien_id}/…`).

### Customer DNS

| Case | Record | Target |
|------|--------|--------|
| Subdomain (e.g. `www`) | **CNAME** | **`site.alienai.id`** (grey — proxied **false**) |
| Apex (`example.com`) | **A/AAAA** to origin IP **or** registrar CNAME flatten to `site.alienai.id` | Same addresses as `site.alienai.id` |

Platform DNS: **`site.alienai.id`** → cluster origin (grey, same IP as `api.alienai.id`). It is a **platform host**, not a `site.domain` row — `host_is_primary("site.alienai.id")` is true.

**Verify** (RPC `site_domain_verify`): hostname must CNAME-chain to `C35_DOMAIN_CNAME_TARGET` **or** apex A/AAAA must match that target’s resolved addresses. One verified hostname → one site (`uq_site_domain_hostname`); `www` and apex are separate rows.

**Source:** `site.domain.source` is `byo` (default) or `bought`.

**Bring-your-own:** at most one unverified hostname. `site_domain_list` soft-deletes unverified `byo` rows older than 24 hours (`created_ts`).

**Bought:** Cloudflare Registrar purchase paid from the owner wallet. The platform sets a grey CNAME to `site.alienai.id`. The row is not removed by the 24h sweep. Removing it in the editor does not refund or delete the Cloudflare registration.

After a bought hostname verifies, mail is onboarded (see [mail.md](mail.md)). BYO mail only if the zone is already in our Cloudflare account.

### TLS (origin, cert-manager)

- Certificates are issued on the **origin** via **cert-manager** (per-hostname Ingress → `c35-server`). Private keys and PEM live in **Kubernetes Secrets only**.
- **Never store TLS PEM or private keys in Yugabyte.** `site.domain` holds **`tls_status`**, **`verify_error`**, **`tls_error`**, **`last_verify_ts`** — status and errors for the app UI, not secret material.
- `tls_status`: `pending` | `ready` | `failed` | `disabled` (synced from cluster when TLS sync runs).

### Server env (`c35-server`)

| Variable | Default | Role |
|----------|---------|------|
| `C35_DOMAIN_CNAME_TARGET` | `site.alienai.id` | CNAME target for UI copy and DNS verify |
| `C35_PRIMARY_HOSTS` | *(merged)* | Comma-separated **extra** platform hosts; code always includes `alienai.id`, `www.alienai.id`, `site.alienai.id` |
| `C35_TLS_SYNC_ENABLED` | off (`0`) | `1` / `true` — create/update cert-manager Ingress per verified hostname |
| `C35_TLS_NAMESPACE` | `c35` | Namespace for domain Ingress resources |
| `C35_TLS_CLUSTER_ISSUER` | `letsencrypt-prod-dns` | cert-manager `ClusterIssuer` annotation (cluster may override) |

Cluster template: [`_/deployments/c35-server/deployment.yaml`](../deployments/c35-server/deployment.yaml). Local dev: [`servers/server_ai/.env.example`](../../servers/server_ai/.env.example).

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
| `site.product_icon` | no | — | global name_key → iconify id for empty product photos. Not per site. Not `site.product_embed`. |
| `site.contact` | yes | Contacts | tx subject |
| `site.object` | yes | Objects | rooms / tables |
| `site.work_shift` | yes | Team | named shifts |
| `site.work_shift_slot` | yes | (sub) | slots within a shift |
| `site.member_shift` | yes | Team | grantee ↔ shift |
| `site.member_face` | yes | Team | attendance-gated face photos |
| `site.presence_location` | yes | — | geo for Attendance later |

Staff ACL: `identity_grant(resource_iid=site_iid, role=staff|manage|guest|owner)` — see **Team** below. Never a `site_member` table.

## Default product icon

When `site.product.pic` is empty, the product still needs a picture in the editor, the guest app, and the public HTML page. That picture is an Iconify icon chosen from the product name. A real photo always wins. A failed photo URL stays a broken-image fallback and does not pretend to be a drink.

Plan: [`plans/2026-10-08-product-default-icon.md`](plans/2026-10-08-product-default-icon.md).

### How a name becomes an icon

`product_icon_name_key` in `servers/crates/mod_site/src/product_icon.rs` builds the lookup key:

1. Trim and lowercase. Any character that is not a letter becomes a space, so sizes like `500ml` split apart.
2. Drop size, temperature, and filler tokens: `es`, `ice`, `iced`, `hot`, `panas`, `dingin`, `cold`, `warm`, `large`, `small`, `medium`, `regular`, `jumbo`, `big`, `pcs`, `pc`, `ml`, `gr`, `gram`, `kg`, `oz`, `liter`, `l`, `spesial`, `special`, `original`, `new`, and tokens that are only digits.
3. Join the remaining words with a single space.

`Es Kopi Susu` and `Kopi Susu Panas` both become `kopi susu`. `Large Iced Latte 500ml` becomes `latte`.

The key is then matched against a closed kind list in that file. A keyword matches only when its words appear as a contiguous run of tokens, so `tea` does not match inside `steak`. The first kind in the table wins. Unknown kinds, and names that match nothing, use `mdi:shopping`. The model is not allowed to invent an Iconify id. There is no embedding and no full-text index for this. The key is exact.

| Kind | Iconify id | Keywords |
|---|---|---|
| coffee | `mdi:coffee` | kopi, coffee, latte, espresso, americano, cappuccino, mocha, macchiato |
| tea | `mdi:tea` | teh, tea, matcha |
| juice | `mdi:fruit-citrus` | jus, juice, jeruk, smoothie |
| beer | `mdi:beer` | beer, bir |
| wine | `mdi:glass-wine` | wine |
| cocktail | `mdi:glass-cocktail` | cocktail, mojito, mocktail |
| water | `mdi:cup-water` | air mineral, mineral water |
| burger | `mdi:hamburger` | burger, hamburger |
| pizza | `mdi:pizza` | pizza |
| fries | `mdi:french-fries` | fries, kentang goreng |
| rice | `mdi:rice` | nasi, rice |
| noodles | `mdi:noodles` | mie, noodle, ramen, pasta, spaghetti, bakmi, kwetiau |
| bread | `mdi:bread-slice` | roti, bread, toast, sandwich |
| cake | `mdi:cake-variant` | kue, cake, pastry, donat, doughnut, croissant |
| ice_cream | `mdi:ice-cream` | es krim, ice cream, gelato, krim |
| chicken | `mdi:food-drumstick` | ayam, chicken |
| meat | `mdi:food-steak` | steak, daging, sapi, beef |
| fish | `mdi:fish` | ikan, fish, seafood, udang, shrimp |
| soup | `mdi:bowl` | soup, soto, bakso |
| egg | `mdi:egg` | telur, egg, omelet, omelette |
| drink | `mdi:cup` | minuman, drink, soda, milkshake, float, lemonade |
| generic | `mdi:shopping` | no keywords; fallback |

Coffee is before drink, so `kopi susu` is coffee. Non-food names such as `kursi kayu` miss the list and stay on the shopping icon.

A miss that is not a keyword is classified once by `CHEAP_MODEL` (`gemini-3.1-flash-lite`, see [billing.md](billing.md)) into one of the kind ids above, then stored. That call is platform cost. It does not bill the site owner. The same normalized name is never sent to the model again.

The store for that is the global table `site.product_icon` (`name_key`, `icon`, `kind`, `source` `rule` or `llm`). It is shared across sites. It is not `site.product_embed` (that table is search aliases).

### What is implemented

| Piece | State |
|---|---|
| `CHEAP_MODEL` in `c35_mod_llm`, used by compaction, memory extraction, and Gemini speech-to-text | In code. Documented in [billing.md](billing.md). |
| Kind catalog, `product_icon_name_key`, `product_icon_kind_from_rules`, `product_icon_id` | In `mod_site`. Tests: `servers/crates/mod_site/tests/product_icon_test.rs` (5 passing). |
| `site.product_icon` table and `product_icon_ensure` on save when `pic` is empty | In code. Called from `site_product_put`. |
| Wire `icon` and public HTML card | In code. Empty `pic` inlines an SVG. A photo keeps `<img>`. |
| Editor tile, guest app row, and POS thumb | In code. Empty `pic` uses `UiIcon`. A broken photo URL keeps the old fallback. |

An empty photo shows the icon from this catalog in the editor tile, the guest product row, the POS thumb, and the public HTML card. A real photo still wins. A broken photo URL keeps the old broken-image or shopping-bag fallback.

## Team

Sites → **Team** is the CSA-parity staff editor (list, invite, roles, detail, shifts, transfer, remove). Plan: [`plans/2026-10-08-site-team-editor-csa-parity-multitask.md`](plans/2026-10-08-site-team-editor-csa-parity-multitask.md).

### ACL (locked)

- **Only** `ai.identity_grant` on `resource_iid = site_iid`. **Do not** reintroduce CSA `site_member`.
- Roles on the wire: `staff` | `manage` | `guest` | `owner`.
- Rank: **owner > manage > staff > guest**. Guest is read-only (cannot write site data).
- Grantable via put: `staff`, `manage`, `guest` — not `owner` (ownership only via transfer).
- Owner row is always shown in the Team list (synthetic from `site.config.owner_iid` / `ai.identity.owner_iid` if no grant row). Owner cannot be removed or have role changed except via **transfer**.

### Role mapping (CSA UI ↔ c35 grant)

| CSA UI `role` | `identity_grant.role` | Label |
|---------------|------------------------|-------|
| `employee` | `staff` | Staff |
| `manager` | `manage` | Manager |
| `guest` | `guest` | Guest |
| `owner` | `owner` | Owner |

### Invite

- Single field accepts **email** or **alien_id** (optional `@`).
- Server resolves: contains `@` → email via `ai.identity_provider` (`kind='email'`) with `meta->>'email'` fallback; otherwise alien_id / iid.
- Unknown email → hard error `user not found`. **No** pending-invite table in v1.
- Chat tool `site.grant.put` accepts `grantee_email` as well as alien_id / iid.

### HR tables under `site.*`

Work-shift assignment, face enroll, and presence locations live in the **`site`** schema (not `ai`, not a member table):

| Table | Purpose |
|-------|---------|
| `site.work_shift` | Named shift templates per site |
| `site.work_shift_slot` | Time slots within a shift |
| `site.member_shift` | Assignment keyed by `site_iid` + `grantee_iid` + `shift_id` (no FK to `site_member`) |
| `site.member_face` | Face enroll photos when capabilities include attendance |
| `site.presence_location` | Geo points; schema ships with shifts; full Attendance UX is a separate plan |

Team UI consumes shifts (and face when attendance is on). Full Attendance nav (clock-in, geo editor) is out of the Team editor plan.

### Transfer ownership

RPC `site.transfer_ownership`:

1. Caller must be current owner.
2. Target must already have a non-deleted grant (member).
3. Updates `ai.identity.owner_iid` for the site.
4. Demotes previous owner grant to `manage`; promotes target grant to `owner`.

### Deferred / out of scope for Team editor

| Item | Notes |
|------|-------|
| Pending email invites | Users who do not exist yet — not in v1 |
| `membersLimit` hard seat cap | Show member **count only** until site billing quota exists |
| Full Attendance nav | Clock-in / geo editor UX — separate plan (schema may land with Team) |
| Payroll / face matching at POS | Still deferred |

**Supersedes** the guest-commerce plan’s blanket “Full HR deferred” for the **Team editor** path (shifts, face enroll storage, transfer). Attendance **clock-in** and payroll remain deferred. See [`plans/2026-10-08-site-guest-csa-commerce-parity-multitask.md`](plans/2026-10-08-site-guest-csa-commerce-parity-multitask.md) Out of scope.

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
| `site.pic.generate` | Generate a picture and store `/fs/{hash}` on the site icon (`ai.identity.pic`), the product photo (`site.product.pic`), or an extra photo (`product_json.pics`). Frontier quota only. Inst: `inst.task.site_pic_generate` (excludes `img.generate`). |
| `site.contact_put` / `site.object_put` | data rows |

Instruction seed: [`../schemas/inst.sql`](../schemas/inst.sql) → `inst.web.builder`.

Editor entry points for `askImageGenerate`: the product hero alien badge (slot `product`), More photos (`askMedia` with `allowGenerate: true`), and Site Info avatar Generate (slot `siteIcon`).

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

### Guest Interactive Client Runtime

The rendered HTML compiled by `render.rs` includes a lightweight, zero-build client-side runtime for visitor commerce and lead capture:

1. **Guest Cart & Checkout Drawer**:
   - `product_grid` cards include an **"Add to Cart" / "Pesan"** button.
   - Sticky bottom bar shows running total, item count, and an expand button.
   - Expanding opens a bottom sheet / drawer with:
     - Item quantity steppers (`+` / `-`) and optional per-item note.
     - Customer details: name, phone / WhatsApp, fulfillment mode (dine-in / room / table / delivery).
     - Payment selection: Cash on Delivery / Counter, Bank Transfer, or QRIS.
   - Submission: POST JSON payload to `https://api.alienai.id/v1/site/guest-order/put` (`ReqSiteGuestOrderPut`).
   - Confirmation: Displays receipt card with order ID and summary.

2. **Guest Contact / Lead Capture**:
   - `contact_form` blocks submit via async POST to `https://api.alienai.id/v1/site/guest-contact/put`.
   - Payload writes to `site.contact` (with `source = 'guest_form'`), and triggers notification to site staff.

## Wire

| Proto | Purpose |
|-------|---------|
| [`site.proto`](../schemas/proto/c35/site.proto) | SiteDoc, draft, publish, product, contact, object, guest contact RPC |
| [`collection.proto`](../schemas/proto/c35/collection.proto) | `TableDef` / `ReqCollectionDefList` for UITable |
| [`tx.proto`](../schemas/proto/c35/tx.proto) | POS + guest checkout (`ReqSiteGuestOrderPut`, `ReqSiteGuestOrderGet`) |

RPC summary:

- `ReqSiteList` — Sites nav list
- `ReqSiteDraftGet/Put` — prompt edits SiteDoc
- `ReqSitePublish` — render + activate
- `ReqSiteProduct*` / `ReqSiteContact*` / `ReqSiteObject*` — data CRUD
- `ReqSiteDomainPut/Verify` — custom domain attachment and verification
- `ReqSiteDomainSearch` / `ReqSiteDomainCheck` / `ReqSiteDomainBuy` — registrar search, quote check, and wallet purchase
- `ReqCollectionDefList` — UITable column metadata
- `ReqSiteGuestOrderPut/Get` — guest storefront checkout and order status
- `ReqSiteGuestContactPut` — guest contact form submission

Sync collections: `site_draft`, `site_product`, `site_product_embed`, `site_contact`, `site_object`, `site_domain`, `site_config`.

## UI

Sites page = **Devices pattern** (see [`ui.md`](ui.md)):

- Nav: site list (pin, rename, alien_id)
- Detail tabs: **Preview** | **Products** | **Contacts** | **Objects** | **Team** | **Settings** | **Orders** (Phase 9)
- Team = CSA-parity staff editor (see **Team** above); not a draft autosave bag
- No CSA-style visual hub editor

## Embeddings

- `ai.embed_cache` — LLM API dedupe
- `site.product.ehash_search` — regen on name/SKU change
- `site.product_embed` — alt labels for semantic search

## Deferred

- Normalized `site.page` / `site.block` tables (UITable for layout structure)
- `render_hash` → `file` schema CAS
- Site subscription billing / member seat hard limits
- Attendance clock-in UX, payroll, POS face matching (Team editor HR tables + transfer are **in scope** — see **Team**)
