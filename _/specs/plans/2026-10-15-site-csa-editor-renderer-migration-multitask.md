# Site — CSA editor + dual renderer migration (keep c35 POS & data)

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks and does not implement every lane inline. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship **CSA-shaped** site editor and **consistent** dual guest renderer (Flutter preview + published web) while **keeping** c35 YSQL `site.*`, `site_iid` = `ai.identity.id`, WebSocket `ReqSite*`, **`mod_tx` / POS / receipts**, and **all existing products** for site **`gucicha`** (owner **99000**).

**Architecture:** Do **not** replace the data plane with CSA `SiteDraft` / Scylla / `mod_site_tx`. Port **CSA UX and render behavior** onto c35:

1. **Read path:** `site_boot_get` + `site_boot_json_assemble` stay authoritative; extend boot fields until CSA guest_ui catalog is satisfied (`site_id` + `site_iid` both set to the same iid).
2. **Write path:** Editor sections call existing **`SiteApi`** / `ReqSite*` (draft `doc_json`, `site.product_put`, links, domains, …). Where CSA edited flat `SiteDraft` fields, add a thin **view-model adapter** (Dart + optional Rust helpers) that maps **CSA field names ↔ `SiteDoc.meta` + normalized tables**.
3. **Render path:** Flutter `guest_site/*` and Rust `render.rs` + `site-guest.v1.js/css` **emulate CSA** `page_guest_hub.dart` + `client/site` + `mod_site` HTML — **vanilla JS only** (no Alpine); port logic from CSA `site.js` into `site-guest.v1.js` where needed.
4. **Frozen boundary:** No edits under `clients/app/lib/widgets/sites/tx/**`, `servers/crates/mod_tx/**`, expense/consumption crates, or `site.tx` schema except guest-checkout **call sites** in guest JS (must keep same HTTP/WS contracts).

**Tech stack:** Flutter `widgets/sites/editor/`, `guest_site/`, `c/site/site_api.dart`; Rust `c35_mod_site` (`site_boot.rs`, `render.rs`, `guest_design.rs`); static `clients/web/static/site-guest/`; tests `mod_site/tests/*`, `clients/app/test/guest_site_*`, `platform_site_editor_test.dart`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md) · [`_/specs/tx.md`](../tx.md) · CSA [`.agents/guest_ui.md`](file:///D:/csa_site_published/.agents/guest_ui.md) · CSA [`_/docs/site/guest-ui.md`](file:///D:/csa_site_published/_/docs/site/guest-ui.md)

**Related plans (reuse, do not duplicate finished work):**

| Plan | Reuse |
|------|--------|
| [`2026-10-08-site-csa-editor-renderer-effects-multitask.md`](2026-10-08-site-csa-editor-renderer-effects-multitask.md) | Editor menu gaps, WASM effects, section list |
| [`2026-10-11-site-preview-web-renderer-parity-multitask.md`](2026-10-11-site-preview-web-renderer-parity-multitask.md) | Block matrix, fixture tests, app-canonical process |
| [`2026-10-08-site-guest-csa-commerce-parity-multitask.md`](2026-10-08-site-guest-csa-commerce-parity-multitask.md) | Cart/checkout — **must stay on c35 guest order APIs** |
| [`2026-09-21-site-file-parallel.md`](2026-09-21-site-file-parallel.md) | **Do not** port CSA 3-pane wholesale or Scylla |

---

## Global constraints

- **`site_iid`** = site identity iid; boot JSON includes **`site_id`** alias (same number) for CSA-shaped JS.
- **Products** live in **`site.product`** (`product_id` int64). Guest blocks reference catalogs by filter/id — **never** move product rows into `doc_json` as the source of truth.
- Guest URLs: `https://alienai.id/{alien_id}/…`. Preview: **`GuestSiteView`** + `site.boot_get` — not a WebView of published HTML.
- Staff edits: WebSocket **`ReqSite*`** only (no CSA `POST /a/http` for editor).
- Guest checkout: existing c35 guest HTTP + **`mod_tx::guest_order`** — POS and reports unchanged.
- No provider web grounding. UTF-8 sources; verify per `verify-after-edit.mdc`.
- Bump **`GUEST_RENDERER_VERSION`** + `publish_site_guest_renderer_version.ps1` only when compile output changes ([`site-guest-renderer-version.mdc`](../../.cursor/rules/site-guest-renderer-version.mdc)).

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| **Data** | YSQL `site.*` + `ai.identity` unchanged. No CSA `site` / `site_member` tables. |
| **Products (gucicha)** | Migration is **UI/render only**; **no** product_id renumbering. Wave 0 snapshot is the rollback contract. |
| **POS / receipt / transaksi** | **Out of scope** except verifying guest orders still create `site.tx` with correct `site_iid`. |
| **Editor** | CSA **section menu + section widgets** (from `D:\csa_site_published\clients\app\lib\widgets\site\`, `page_site_editor.dart`) ported to c35 paths; wire to **`SiteApi`**. |
| **Dual renderer** | Target **CSA look & hub flows** on both Flutter and web; single boot JSON. |
| **Alpine** | **Not shipped** — port CSA `client/site` behaviors into **`site-guest.v1.js`**. |
| **Personal expense** | `site_iid == owner_iid` txs untouched. |

---

## CSA → c35 mapping (implementers)

| CSA | c35 (keep) |
|-----|------------|
| `site_id` | `site_iid` (= `ai.identity.id` for `kind=site`) |
| `SiteDraft` (editor state) | Adapter over `SiteDraft` proto **shape in UI only**; persist via `doc_json` + `site.product_*`, `site_link`, … |
| `handle` | `alien_id` |
| `SiteProduct.id` (string) | `product_id` (int64) — adapter converts in boot preload only |
| `__SITE_BOOT__` hub fields | Assembled in `site_boot_json_assemble` → inlined as **`__SITE_GUEST__`** (+ `__SITE_BOOT__.effects` when needed) |
| `page_guest_hub.dart` | `guest_site/guest_site_view.dart` + blocks (port deltas from CSA) |
| `page_site_editor.dart` | `widgets/sites/editor/ui_site_editor_shell.dart` + sections |

---

## Wave map

```
WAVE 0  Safety + baseline (gucicha)
  G0   DB snapshot + product inventory script
  G1   Branch/tag legacy renderer + editor
  G2   Golden boot JSON fixtures from live gucicha (draft + published)

WAVE 1  (parallel audit — read-only)
  A1   CSA editor section list vs c35 editor nav (gap table)
  A2   CSA guest_ui matrix vs guest_site_blocks + render.rs (gap table)
  A3   Boot field diff: CSA guest_ui.md vs site_boot.rs output
  A4   Document adapter API: site_draft_adapter.dart (read/write field map)

WAVE 2  Adapter + boot (server + client foundation)
  B1   Rust: optional site_draft_view_json for editor (assemble read-only CSA-shaped JSON from DB)
  B2   Dart: SiteDraftAdapter (load from SiteApi + sync collections; save debounced to existing RPCs)
  B3   Tests: gucicha fixture — product count, names, prices unchanged after adapter round-trip (no-op save)

WAVE 3  (parallel — dual renderer, after B2 boot stable)
  R1   Flutter: port CSA hub/detail UX from page_guest_hub → guest_site/* (one subagent per block family)
  R2   Web: port CSA mod_site HTML + site-guest JS/CSS deltas (match R1 fixtures)
  R3   Parity: extend guest_design_test + guest_site_* tests using G2 fixtures
  R4   Commerce UI only: cart/checkout labels/flows — **same** guest order endpoints as today

WAVE 4  (parallel — CSA editor, after B2)
  E1   Shell: CSA menu order, default Info, section ids (from page_site_editor)
  E2   Port CSA widgets/site sections → c35 editor (design, effects, links, info, …) via SiteDraftAdapter
  E3   Products section: still **site.product** RPCs — no SiteDraft.products[] persistence
  E4   Editor preview pane: GuestSiteView unchanged entrypoint; refreshes on adapter save

WAVE 5  POS & data regression (mandatory gate)
  P0   product row count + checksum for gucicha site_iid (SQL)
  P1   Manual: staff POS open, sell one item, receipt print/PDF smoke
  P2   Manual: guest checkout on gucicha → tx appears in POS queue/reports
  P3   prompt_run / site.query.run smoke for sales report (99000, gucicha site_iid)

WAVE 6  Ship
  V1   verify_flutter_app.ps1 + cargo test -p c35_mod_site
  V2   publish_server when Rust/static changed; Publish gucicha; optional renderer version bump
  V3   Update site-guest-components.md + short note in site.md (CSA editor/renderer migration complete)
```

---

## Wave 0 — G0 / G1 / G2 (gucicha safety)

**Resolve `site_iid`:** `SELECT id FROM ai.identity WHERE LOWER(alien_id) = 'gucicha' AND kind = 'site' AND deleted_ts IS NULL` (expect owner **99000**).

### G0 — Snapshot

- [ ] **G0.1** Export rows (YB/psql): `site.config`, `site.draft`, `site.publish` (active), `site.product`, `site.product_embed`, `site.link`, `site.contact`, `site.object`, `site.domain` for `site_iid = :gucicha`.
- [ ] **G0.2** Save to `_/specs/plans/fixtures/gucicha-pre-csa-migration/` (JSON or `.sql` inserts) — **git-tracked** snapshot for regression.
- [ ] **G0.3** Script `_/scripts/dev/site_gucicha_inventory.ps1`: prints `product_count`, `max(product_id)`, sample of 5 names/prices — run before/after every wave touching editor/boot.

### G1 — Legacy backup in repo

- [ ] **G1.1** Tag: `site-pre-csa-migration-2026-10-15` (or branch `backup/site-editor-renderer-pre-csa`).
- [ ] **G1.2** Optional: copy trees to `clients/app/lib/_legacy_site/` only if needed for diff — prefer tag over duplicating code long-term.

### G2 — Golden boot

- [ ] **G2.1** MCP `tool_exec` or WS: `site.boot_get` for gucicha, modes `draft` and `published` → save as `mod_site/tests/fixtures/gucicha_boot_draft.json` and `gucicha_boot_published.json` (redact secrets).
- [ ] **G2.2** Add test `guest_gucicha_boot_product_count` — assert `products` / preload keys match G0 product_count.

---

## Wave 1 — Audit tracks (read-only)

### A1 — Editor gap

**CSA reference:** `D:\csa_site_published\clients\app\lib\pages\site\page_site_editor.dart`, `widgets/site/ui_site_*_section.dart`.

**c35 reference:** `clients/app/lib/widgets/sites/editor/site_editor_nav.dart`, `ui_site_editor_shell.dart`.

- [ ] Produce `/_/specs/plans/artifacts/2026-10-15-csa-editor-gap.md`: section id, CSA file, c35 file, persist target (`doc_json` path vs `ReqSite*`), status PASS/GAP.

### A2 — Renderer gap

- [ ] Same artifact for guest_ui catalog rows vs `guest_site_blocks.dart` + `render.rs` `block_html_render`.

### A3 — Boot gap

- [ ] Table: CSA `__SITE_BOOT__` keys vs `site_boot_json_assemble` — mark each REQUIRED for CSA JS / OPTIONAL / c35-only.

### A4 — Adapter spec

- [ ] Create `clients/app/lib/c/site/site_draft_adapter.dart` design doc section in artifact: field → load from / save to.

---

## Wave 2 — B1 / B2 / B3 (adapter foundation)

**Files (create):**

- `clients/app/lib/c/site/site_draft_adapter.dart`
- `servers/crates/mod_site/src/site_draft_view.rs` (optional HTTP/WS helper for editor only)
- `clients/app/test/site_draft_adapter_gucicha_test.dart`
- `servers/crates/mod_site/tests/gucicha_adapter_test.rs`

**Interfaces:**

- `SiteDraftAdapter.load(siteIid)` → CSA-shaped in-memory model for UI.
- `SiteDraftAdapter.flush()` → existing `SiteApi.draftPut`, `productPut`, `linkPut`, … — **no new tables**.

- [ ] **B3.1** Test: load gucicha → `flush()` without edits → G0 product_count unchanged.
- [ ] **B3.2** Test: round-trip theme/meta fields in `doc_json` only where adapter owns them.

---

## Wave 3 — Dual renderer (parallel)

**Do not touch:** `widgets/sites/tx/**`, `mod_tx/**`.

### R1 — Flutter (subagent per family)

| Track | CSA source | c35 target |
|-------|------------|------------|
| R1a | `page_guest_hub.dart` shell/tab chrome | `guest_site_view.dart`, shell |
| R1b | product cards + detail | `guest_site_product*.dart` |
| R1c | posts + detail | `guest_site_post*.dart` |
| R1d | forms, queue, order track | matching `guest_site_*.dart` |

Each track: same JSON fixture as R2; extend widget tests.

### R2 — Web

- `servers/crates/mod_site/src/render.rs`, `guest_design.rs`
- `clients/web/static/site-guest/src/site-guest.v1.js`, `.css`
- Run `clients/web/static/site-guest/build.ps1` after JS changes.

### R3 — Parity tests

- [ ] Every R1/R2 GAP from A2 closed with `guest_design_test` or `guest_site_*_test` using G2 fixtures.

### R4 — Guest checkout boundary

- [ ] Diff CSA checkout **behavior only**; keep c35 URLs and request bodies (`guest_order_put`, payment methods from `commerce_boot`).
- [ ] Test: mock guest order → `site.tx` row with `site_iid = gucicha`, `owner_iid` = staff context unchanged.

---

## Wave 4 — CSA editor (parallel)

**CSA UX source:** `D:\csa_site_published\clients\app\lib\widgets\site\`.

**c35 target:** `clients/app/lib/widgets/sites/editor/`.

### E1 — Shell

- [ ] Menu order match CSA; default section **Info**; preview pane wired to `GuestSiteView`.

### E2 — Sections

Port each `ui_site_*_section.dart` pattern:

- Read/write via **`SiteDraftAdapter`**, not `ca_pb.SiteDraft` persistence.
- **Products (E3):** list/edit still `SiteApi.productList` / `productPut` — adapter maps rows to CSA list UI only.

### E4 — Save / flush

- [ ] Reuse `site_editor_flush_coordinator` — adapter registers same save bus as today.

---

## Wave 5 — POS & gucicha regression gate

**Hard gate:** Wave 6 cannot start until P0–P2 pass.

- [ ] **P0** `site_gucicha_inventory.ps1` matches G0 baseline.
- [ ] **P1** Staff POS: add line, pay, receipt preview (Windows or documented platform).
- [ ] **P2** Guest: add to cart on web preview, checkout, confirm tx in site editor / UITable tx tab.
- [ ] **P3** `site.query.run` or stock report for gucicha returns same order of magnitude as pre-migration (spot-check).

---

## Wave 6 — Ship

- [ ] **V1** `.\_\scripts\dev\verify_flutter_app.ps1`; `cd servers; cargo test -p c35_mod_site`
- [ ] **V2** If `render.rs` or static guest bundle changed: `publish_server.ps1`, Publish gucicha in app, verify bare URL + preview parity.
- [ ] **V3** Docs: update [`site-guest-components.md`](../site-guest-components.md) if `data-guest` or boot keys changed.

---

## Out of scope (explicit)

- CSA `mod_site_tx` / Postgres+Scylla site document store
- Replacing `widgets/sites/tx/*` or receipt PDF pipeline
- Renumbers or bulk reimport of `site.product`
- Personal `consumption.*` / `expense.*` tools
- UITable removal (stays for power users)

---

## Subagent dispatch cheat sheet

| Wave | Parallel tasks |
|------|----------------|
| 1 | A1, A2, A3 → then A4 |
| 2 | B1 + B2 parallel → B3 |
| 3 | R1a–R1d, R2 parallel after B3; R3 follows; R4 with R2 |
| 4 | E1 then E2 sections split by file; E3 with products section; E4 last |
| 5 | P0 automated; P1–P3 human or device tools (99000) |
| 6 | V1 → V2 → V3 |

---

## Success criteria (user-facing)

1. Sites editor **looks and navigates like CSA** (Info-first rail, same section set).
2. **Draft preview** and **published web** match each other and CSA hub UX for gucicha.
3. **All gucicha products** present with same `product_id` and sellable from POS and guest grid.
4. **POS, receipts, guest→kitchen tx flow** behave as before migration.
