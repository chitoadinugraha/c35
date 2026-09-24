# Site + File CAS — Parallel Implementation Plan

> **For agentic workers:** Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; do not merge unrelated tracks in one session.
>
> **Specs (locked):** [`spec.md`](../../../spec.md) · [`_/docs/site.md`](../../../_/docs/site.md) · [`_/docs/ui.md`](../../../_/docs/ui.md) · [`_/docs/tx.md`](../../../_/docs/tx.md) · [`_/schemas/site.sql`](../../../_/schemas/site.sql) · [`_/schemas/file.sql`](../../../_/schemas/file.sql)

**Goal:** Ship guest sites (`alienai.id/{alien_id}`) with prompt-built layout + UITable admin, and production CAS (512 KiB inline, S3 large blobs, image variants).

**Not in scope (this plan):** Phase 9 full POS editor (`mod_tx` UI) — listed as Track W9 only.

---

## Reference projects (what to copy)

| Project | Path | Borrow for c35 |
|---------|------|----------------|
| **CSA published** | `D:\csa_site_published` | Guest HTTP router, `publish_render`, custom domain + TLS sync, S3 CAS, `/fs/` HEAD/ETag/304, `blob_s3.rs` |
| **csa_os** | `E:\Project Archive\csa_os` | `variants` JSON on canonical hash, `file_variant_set`, optimize-worker *design* (not obj kernel) |
| **id.alienai** | `E:\Project Archive\id.alienai` | POS / `tx.proto` + transaksi editor (Phase 9) |
| **cs_agent** | `D:\cs_agent` | turbojpeg encode pattern (`agents/agent_windows/src/encode`) |
| **c35 today** | `servers/crates/mod_file` | Blake3 CAS, signed URLs, inline YB — **extend**, do not rewrite |

**Do not port wholesale:** CSA 3-pane site editor, csa_os `obj` FS kernel, Scylla `file` tables.

---

## Multitask map

```
WAVE 0 — Schema & docs (mostly done; verify + file.sql extend)
  F0  file.sql extend (store, loc, variants)
  F0b _/docs/file.md

WAVE 1 — Independent foundations (parallel)
  F1  S3 backend ≥512 KiB          ← CSA blob_s3.rs
  F2  /fs HTTP hardening           ← CSA wire_http fs_get/head/put
  W1  mod_site crate scaffold      ← CSA mod_site pattern
  W2  collection.proto + UITable   ← c35 site.md (new widget)

WAVE 2 — Needs wave 1 (parallel pairs)
  F3  variants API + schema wire   ← csa_os file.rs
  F4  image optimize worker        ← csa_os design + cs_agent turbojpeg
  W3  site RPC (draft/product/…)   ← c35 site.proto + CSA service subset
  W4  guest HTTP router            ← CSA mod_site/http.rs

WAVE 3 — Publish & domains (parallel)
  W5  publish_render → site.render ← CSA service publish_render
  W6  custom domain + TLS sync    ← CSA custom_domain.rs + tls_sync.rs
  W7  CF / api split docs + env     ← discussion (no CSA code)

WAVE 4 — Flutter (parallel)
  W8  page_sites + UiTable tabs    ← Devices page + c35 ui.md
  W9  Home web.builder tools       ← inst.web.builder + site_draft_put

WAVE 5 — Integration
  I1  Guest E2E: upload pic → site → CF cache
  I2  file.md + spec.md stale lines cleanup

WAVE 6 — Deferred
  W10 mod_tx + Orders tab           ← id.alienai UI
  W11 site.page/block normalize     ← optional UITable for layout
```

---

## Global constraints

- **Identity:** `ai.identity(kind=site)` + `ai.identity_grant` only in `ai`.
- **Payload:** YSQL schema **`site.*`**; tx in **`site.tx_*`**.
- **URLs:** `https://alienai.id/{alien_id}/…` — **never** subdomain of `alienai.id`.
- **Custom domain:** CNAME → `alienai.id`, serve `/` by Host header.
- **API:** App WS → `api.alienai.id`; guest order HTTP → same api host.
- **Layout editor:** Home prompt primary; Sites page = UITable + Preview iframe.
- **Money:** typed `tx.proto` only — LLM never invents checkout JSON.
- **Verify:** Rust `cargo build -p server_ai`; Flutter `flutter analyze` + targeted tests.

---

# FILE SYSTEM TRACKS

## F0 — Extend `file.sql` (schema)

**Reference:** csa_os `.agents/file.md` (variants + store/loc); c35 `_/schemas/file.sql`

**Files:**
- Modify: `_/schemas/file.sql`
- Modify: `_/docs/file.md` (create)

**Tasks:**
- [ ] Add columns to `ai.file_blob_meta`: `store` (`inline`|`s3`), `loc` JSONB, `variants` JSONB
- [ ] Document read paths: original vs `variants.thumb` / `variants.small`
- [ ] Update `_/schemas/README.md` — file.sql **locked**, not “planned”
- [ ] Apply order unchanged (file.sql after tx)

**Acceptance:** migrate applies on boot; existing rows default `store=inline`, `variants={}`.

---

## F1 — S3 backend for blobs ≥ 512 KiB

**Reference:** `D:\csa_site_published\crates\store\src\blob_s3.rs`, `file.rs` put/get

**Files:**
- Create: `servers/crates/mod_file/src/s3.rs` (or `servers/crates/store/src/blob_s3.rs`)
- Modify: `servers/crates/mod_file/src/lib.rs` — replace disk shard with S3 when configured
- Modify: `servers/server_ai/.env.example` — `S3_ENDPOINT`, `S3_BUCKET`, keys (OCI)

**Tasks:**
- [ ] Port `BlobS3`: key `fs/{hash}`, path-style, put/get/head/exists
- [ ] `cas_put`: `size >= CAS_INLINE_MAX_BYTES` → S3; fail clear if S3 missing
- [ ] `cas_bytes_get`: resolve inline vs S3 from `file_blob_meta.store`
- [ ] Remove or gate local `CAS_DIR` shard (keep as dev fallback via env `CAS_STORE=disk|s3`)

**Acceptance:** Upload 600 KiB test blob → meta `store=s3`, retrievable via `/fs/{hash}`.

---

## F2 — `/fs` HTTP hardening

**Reference:** `D:\csa_site_published\crates\wire_http\src\lib.rs` — `fs_get`, `fs_head`, `fs_put`, `cache_headers`

**Files:**
- Modify: `servers/crates/mod_file/src/lib.rs`

**Tasks:**
- [ ] `HEAD /fs/{hash}` — Content-Length, ETag, Cache-Control (no body)
- [ ] `GET /fs/{hash}` — ETag = `"hash"`; honor `If-None-Match` → 304
- [ ] Optional: `PUT /fs/{hash}` — verify blake3(body)==hash (CSA pattern)
- [ ] Hash normalize: 64 hex lowercase before lookup
- [ ] Keep signed URL path for private blobs; public avatar path unchanged

**Acceptance:** `curl -I` returns ETag; repeat with `If-None-Match` → 304.

---

## F3 — Variants API

**Reference:** `E:\Project Archive\csa_os\crates\store\src\file.rs` — `file_hash_variant_set`; kernel `file_get_variant`

**Files:**
- Modify: `servers/crates/mod_file/src/lib.rs`
- Create: `_/schemas/proto/c35/file.proto` (optional) or extend wire with `ReqFileVariantPut`
- Modify: `GET /fs/{hash}` — optional query `?v=thumb` resolves via canonical `variants`

**Tasks:**
- [ ] `file_variant_set(pool, canonical_hash, key, variant_hash)`
- [ ] `file_variant_get(pool, canonical_hash, key) -> variant_hash`
- [ ] `GET /fs/{hash}?v=thumb` → lookup parent variants map (or direct hash if 64 hex)
- [ ] RPC or internal only for worker (v1: internal fn sufficient)

**Acceptance:** canonical hash + thumb variant; guest URL serves smaller bytes.

---

## F4 — Image optimize worker

**Reference:** csa_os `.agents/file.md` write path; `D:\cs_agent\agents\agent_windows\src\encode` (turbojpeg); CSA mime sniff patterns

**Files:**
- Create: `servers/crates/mod_file/src/optimize.rs`
- Hook: after `cas_put` when `mime.starts_with("image/")`

**Tasks:**
- [ ] Async job (NATS or `ai.task` stub): decode → resize → encode
- [ ] **thumb:** webp max 320px (webp crate or image)
- [ ] **small:** JPEG max 1280px via **turbojpeg** (quality ~82)
- [ ] Each output → `cas_put` → `file_variant_set(canonical, "thumb"|"small", …)`
- [ ] Skip if variants already present

**Acceptance:** Upload 4000×3000 JPEG → original + thumb + small hashes within 30s.

**Deps:** F1, F3.

---

# WEB / SITE TRACKS

## W1 — `mod_site` crate scaffold

**Reference:** `D:\csa_site_published\crates\mod_site` layout; c35 `_/docs/server.md`

**Files:**
- Create: `servers/crates/mod_site/` (Cargo.toml, lib.rs, rpc handlers)
- Modify: `servers/Cargo.toml`, `servers/server_ai/Cargo.toml`, wire router

**Tasks:**
- [ ] Crate + `mod_site` in workspace
- [ ] Wire mount: `ReqSiteList`, stub handlers returning empty
- [ ] Grant check: `identity_grant` on `site_iid`
- [ ] SQL against `site.*` tables (not `ai.site_*`)

**Acceptance:** `cargo build -p server_ai`; WS `site_list` returns `[]`.

---

## W2 — `UITable` + `collection.proto`

**Reference:** c35 `_/docs/site.md`, `_/docs/ui.md`; Devices Files list pattern (`ui_device_files.dart`)

**Files:**
- Create: `clients/app/lib/widgets/ui/ui_table.dart`
- Create: `clients/app/lib/c/site/collection_def.dart` (loads `ReqCollectionDefList`)
- Modify: `wire.proto` — already has `collection_def_list`

**Tasks:**
- [ ] Server: `ReqCollectionDefList` — static defs for `site.product`, `site.contact`, `site.object`, `site.domain`
- [ ] Subtable: `site.product` → `site.product_embed`
- [ ] `UITable`: sort, filter, inline edit, expand row → subgrid
- [ ] Sync rows from existing delta collections

**Acceptance:** Flutter widget renders product grid from sync; expand shows embed rows.

**Deps:** W1 for server defs (can mock defs client-side first).

---

## W3 — Site data RPC + sync

**Reference:** c35 `site.proto`; CSA `mod_site/service.rs` product/contact CRUD (Postgres shape)

**Files:**
- Modify: `servers/crates/mod_site/src/` — `site_draft_get/put`, `site_product_*`, etc.
- Modify: sync push for `site_*` collections

**Tasks:**
- [ ] Implement `ReqSiteDraftGet/Put`, `ReqSitePublish` (publish stub OK in wave 2)
- [ ] `ReqSiteProductList/Put`, `ReqSiteContactList/Put`, `ReqSiteObjectList/Put`
- [ ] Sync: `site_draft`, `site_product`, `site_product_embed`, `site_contact`, `site_object`, `site_config`, `site_domain`
- [ ] Validate block props on draft put (schema per block type)

**Acceptance:** Flutter can PUT product row; sync delta returns it.

**Deps:** W1.

---

## W4 — Guest HTTP router

**Reference:** `D:\csa_site_published\crates\mod_site\src\http.rs`

**Files:**
- Create: `servers/crates/mod_site/src/http.rs`
- Modify: `wire_http` merge `site_render_router()`

**Tasks:**
- [ ] Primary host: `GET /{alien_id}`, `GET /{alien_id}/{page_path}`
- [ ] Custom domain: `try_custom_domain_root` — Host → `site.domain`
- [ ] Reserved paths list (match CSA `RESERVED`)
- [ ] Serve from `site.render` blob; 404 offline page

**Acceptance:** `curl https://alienai.id/{alien_id}` returns HTML when published.

**Deps:** W5 for real HTML content (can return stub HTML first).

---

## W5 — Publish pipeline (`publish_render`)

**Reference:** `D:\csa_site_published\crates\mod_site\src\service.rs` `publish_render`; `render/hub.rs`, `boot.rs`

**Files:**
- Create: `servers/crates/mod_site/src/render/` — block HTML renderer (v1 types only)
- Modify: `site.publish` + `site.render` writes

**Tasks:**
- [ ] `ReqSitePublish` → snapshot `site.publish`, compile HTML
- [ ] Block types v1: `hero`, `markdown`, `product_grid`, `spacer`, `image`
- [ ] `product_grid` loads `site.product` at render time (not embedded in doc)
- [ ] Store `site.render[html:/]` + etag blake3
- [ ] Product pics use `/fs/{hash}?v=thumb` when F3 done

**Acceptance:** Publish → guest URL shows block layout + products.

**Deps:** W3, W4; F3 optional for thumbs.

---

## W6 — Custom domain + TLS

**Reference:** `D:\csa_site_published\crates\mod_site\src\custom_domain.rs`, `tls_sync.rs`

**Files:**
- Create: `servers/crates/mod_site/src/domain.rs`, `tls_sync.rs`
- RPC: `ReqSiteDomainPut`, verify token, DNS check

**Tasks:**
- [ ] CNAME verify (platform target `alienai.id`)
- [ ] `site.domain.tls_status` updates
- [ ] cert-manager Ingress sync per verified domain (k8s only)
- [ ] Settings tab: domain list in UITable

**Acceptance:** Test domain verifies; TLS status `pending` → `ready`.

**Deps:** W4.

---

## W7 — Infra split (env + deploy)

**Reference:** CSA primary hosts env; discussion — CF orange + api host

**Files:**
- Modify: `_/deployments/c35-server/deployment.yaml`, `_/docs/site.md`
- Env: `C35_PUBLIC_ORIGIN`, `C35_API_ORIGIN`, `CSA_PRIMARY_HOSTS` equivalent

**Tasks:**
- [ ] Document: guest HTML on `alienai.id`, WS on `api.alienai.id`
- [ ] Traefik routes: path `/{alien_id}` → mod_site; `/v1/ws` → api host
- [ ] CF cache rules for `/fs/*` and published HTML

**Acceptance:** Deploy doc + env example; no code blockers.

---

## W8 — Flutter Sites page

**Reference:** `clients/app/lib/pages/page_devices.dart`, `ui_device_detail.dart`; c35 `_/docs/ui.md`

**Files:**
- Create: `clients/app/lib/pages/page_sites.dart`
- Create: `clients/app/lib/widgets/sites/ui_site_detail.dart`, `ui_site_row.dart`
- Modify: avatar nav → Sites

**Tasks:**
- [ ] Master/detail: site list → tabs Preview | Products | Contacts | Objects | Settings
- [ ] Preview: iframe `alienai.id/{alien_id}?draft=1`
- [ ] Data tabs: `UITable` per W2
- [ ] Settings: alien_id, publish button, capabilities fields

**Acceptance:** Manual: pick site → Products tab edits sync to server.

**Deps:** W2, W3.

---

## W9 — Prompt `web.builder` tools

**Reference:** `_/schemas/inst.sql` `inst.web.builder`; CSA prompt tools pattern

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/` — site tools
- Modify: topic routing for `@alien_id` / site name

**Tasks:**
- [ ] Tools: `site.draft_put`, `site.publish`, `site.product_put` (typed)
- [ ] Resolve `site_iid` from mention / alien_id / name
- [ ] Block prop validation; reject unknown keys
- [ ] No tx/checkout tools in web.builder scope

**Acceptance:** Home prompt “@shop make hero title red” updates draft; Preview reflects change.

**Deps:** W3, W5.

---

## W10 — POS / Orders (Phase 9 — deferred)

**Reference:** `E:\Project Archive\id.alienai` transaksi editor; c35 `tx.proto`

**Tasks:**
- [ ] `mod_tx` crate, `site.tx_*`
- [ ] Orders tab: UITable list + id.alienai ledger editor
- [ ] Guest: `ReqSiteGuestOrderPut` HTTP on api host
- [ ] Borrow CSA `mod_site_tx` guest order **flow** only

---

# INTEGRATION

## I1 — E2E checklist

- [ ] Upload product image → F4 variants → product_grid shows thumb
- [ ] Prompt layout change → publish → `alienai.id/{alien_id}` cached at CF
- [ ] Custom domain serves same site on `/`
- [ ] Large file ≥512 KiB lands in S3, serves via `/fs/`

## I2 — Doc cleanup

- [ ] `spec.md` — remove “512k TBD”, “file later”
- [ ] `_/docs/architecture.md` — file CAS implemented
- [ ] `_/docs/file.md` — canonical file spec

---

# Parallel dispatch schedule

| Wave | Parallel tracks | Blocked by |
|------|-----------------|------------|
| **0** | F0, F0b | — |
| **1** | F1, F2, W1, W2 | F0 for F1/F3 schema columns |
| **2** | F3, F4, W3, W4 | F1+F0; W1 |
| **3** | W5, W6, W7 | W3+W4; F1 for prod assets |
| **4** | W8, W9 | W2+W3+W5 |
| **5** | I1, I2 | all above |

### Suggested agent assignments (8 workers max)

| Agent | Track | Deliverable |
|-------|-------|-------------|
| A | F0 + F1 | S3 CAS + extended schema |
| B | F2 + F3 | HTTP + variants API |
| C | F4 | Image worker (after B) |
| D | W1 + W3 | mod_site RPC + sync |
| E | W4 + W5 + W6 | Guest HTTP + publish + domain |
| F | W2 + W8 | UITable + Sites Flutter page |
| G | W7 + W9 | Infra docs + prompt tools |
| H | I1 + I2 | E2E + doc cleanup |

---

# Must-implement summary (checklist)

## File system (must)

| # | Item | From |
|---|------|------|
| F1 | S3 ≥512 KiB (OCI) | CSA `blob_s3.rs` |
| F2 | HEAD, ETag, 304, hash normalize | CSA `wire_http` |
| F3 | `variants` thumb/small on meta | csa_os `file.md` + `file.rs` |
| F4 | Async image optimize (webp thumb, turbojpeg small) | csa_os + cs_agent |
| F0 | `store`, `loc`, `variants` columns | csa_os schema |

## Web / site (must)

| # | Item | From |
|---|------|------|
| W1 | `mod_site` crate | CSA crate pattern |
| W2 | `UITable` + `TableDef` | c35 docs + Devices UI |
| W3 | Site RPC + sync (`site.*`) | c35 proto + CSA CRUD |
| W4 | Guest router path + custom Host | CSA `http.rs` |
| W5 | Block renderer + `site.render` | CSA `publish_render` |
| W6 | Domain verify + TLS sync | CSA `custom_domain`, `tls_sync` |
| W7 | api.alienai.id + CF split | design |
| W8 | Sites page (Devices-like tabs) | c35 ui.md |
| W9 | `web.builder` LLM tools | c35 inst + CSA tools pattern |

## Later (must for POS, not this wave)

| # | Item | From |
|---|------|------|
| W10 | `mod_tx` + Orders tab | id.alienai |
| W11 | Normalized page/block tables | c35 deferred |
