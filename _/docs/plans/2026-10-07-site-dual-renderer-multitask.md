# Site dual renderer + navigation + prompt tools — multitask plan

**Goal:** CSA-style **two renderers** on c35 (Flutter **widget catalog** + Rust **guest HTML**), **sites picker** in account menu (no welcome site chips), **Sites admin** focused on one site (csa editor feel), **full edit via `@mention` + tools** over **WS `ReqSite*`**.

**References:** `_/docs/site.md`, `_/docs/site-ai.md`, `D:\csa_site_published\.agents\guest_ui.md`, `D:\csa_site_published\.agents\concept.md`, prior chat preview work (`2026-10-06-site-preview-card-multitask.md`).

**Hard rules**

- Guest public URLs: `https://alienai.id/{alien_id}/…` — server HTML remains canonical for web/SEO/domains.
- App RPC: **protobuf on WebSocket** (`ChatConn` / `WsReq`) — no new HTTP invoke for app paths.
- One **component catalog** — new block types update **widget + HTML + docs** together.
- Layout primary editor: Home prompt (`web.builder` / `inst.site.builder`); Sites page = operational admin + preview.

---

## Architecture (target)

```
SiteDoc + hydrated rows (products, capabilities, theme)
        │
        ├─► mod_site::render ──► site.render HTML (guest alienai.id)
        │
        └─► site.boot_get (or draft_get + lists) ──► Flutter guest_widgets/*
                ├─ UiSitePreviewCard (expanded)
                ├─ UiSiteDetail Preview tab
                └─ (optional) in-app guest hub route
```

**WebView:** allowed as interim on Preview tab only; **remove** when widget catalog covers v1 blocks (track W5 exit criteria).

---

## Wave map

```
WAVE 1 — Navigation & hints (parallel, low risk)
  N1  Sites picker dialog (Visit | Edit | POS)
  N2  Hint bundle: drop site chips (optional: pin-only max 1)
  N3  PageSites: detail-first route (no master list default)

WAVE 2 — Component catalog contract (parallel)
  C1  Doc + schema: c35 block type ↔ CSA guest_ui mapping
  C2  Proto: site.boot_get (or extend draft_get) for widget hydration
  C3  Server: boot JSON builder shared by preview token path + widgets

WAVE 3 — Flutter widget renderer (parallel after C2)
  W1  Package lib/guest_site/ (or widgets/guest_site/) — port CSA/ca_site_flutter blocks
  W2  UiSitePreviewCard → widgets (remove Dart mocks)
  W3  UiSitePreview tab → widgets; feature flag fallback WebView

WAVE 4 — HTML renderer parity (parallel with W3)
  H1  Audit CSA vs c35 block_html_render; fixture tests from CSA
  H2  CSS/tokens alignment (theme.accent, layout)
  H3  Interactive guest band (forms/cart) — defer or Alpine parity doc

WAVE 5 — Prompt tools & inst (parallel)
  T1  site.config.put tool (+ inst phrases)
  T2  delete / embed tools (product, contact, object, product_embed)
  T3  site.grant.put/delete (staff) if csa editor had staff tab
  T4  inst.site.catalog / compare / commerce live rows + prompt_compose checks

WAVE 6 — Editor shell (csa UX, c35 wire)
  E1  Sites dialog → PageSites(initialSiteIid, tab)
  E2  Optional: port csa staff site screens behind SiteApi adapter
  E3  POS chrome from id.alienai on existing site.tx (separate thin track)

WAVE 7 — Integration & ship
  I1  E2E checklist (create site in chat → picker → preview widget = HTML smoke)
  I2  publish_server + app release notes
```

---

## Track details

### N1 — Sites picker dialog

| Item | Detail |
|------|--------|
| **Files** | `ui_sites_picker_dialog.dart`, `ui_account_menu.dart`, `page_ai_home.dart` |
| **UX** | Compact list: icon, name, `alienai.id/…`; actions **Visit**, **Edit**, **POS** (POS if `commerce`) |
| **Data** | `SiteStore.refresh` / `site_list` WS — same as `PageSites` master |
| **Visit** | `url_launcher` public or draft URL |
| **Edit** | `PageSites(chatConn, initialSiteIid: …)` |
| **POS** | `initialTabRoute: 'site.pos'` |
| **Tests** | Widget test: open dialog, tap Edit navigates with iid |

### N2 — Welcome hints

| Item | Detail |
|------|--------|
| **Files** | `servers/crates/mod_hint/src/bundle.rs` |
| **Change** | Remove `site_rows` → hint items (or only `pinned` site, max 1) |
| **Tests** | Server or integration: hint bundle for user with 5 sites has no `hint.site.*` on hero |

### N3 — PageSites detail-first

| Item | Detail |
|------|--------|
| **Files** | `page_sites.dart` |
| **Change** | `initialSiteIid` required from picker; master list behind “All sites” in dialog only |
| **Desktop** | Keep `UiMasterDetail` when opened without iid (dev) |

---

### C1 — Component catalog doc

| Item | Detail |
|------|--------|
| **Output** | `_/docs/site-guest-components.md` — table: `type`, props schema, CSA `data-guest`, widget class, Rust fn, capability gates |
| **v1 set** | Start from c35 `site.md` block types; map CSA `profile`, `site_product`, `form`, `queue`, … where equivalent |

### C2 — Wire boot payload

| Item | Detail |
|------|--------|
| **Proto** | `ReqSiteBootGet { site_iid, mode: draft|published }` → `ResSiteBootGet { boot_json }` |
| **WS** | `wire.proto` field + `wire_ws` → `mod_site::site_boot_get` |
| **Client** | `SiteApi.bootGet`, `ChatConn` wrapper |

### C3 — Server boot builder

| Item | Detail |
|------|--------|
| **Rust** | Single module builds JSON: site meta, theme, pages/blocks, product preload for grids, capabilities |
| **Reuse** | Same product queries as `product_rows_for_grid` in `render.rs` |

---

### W1 — Flutter guest_widgets package

| Item | Detail |
|------|--------|
| **Source** | Port from `D:\csa_site_published` / `A:\ca_site_flutter` per `flutter_client.md` |
| **API** | `GuestSiteView({ required Map boot, SitePreviewMode mode })` |
| **Scope** | Hub blocks v1 only; detail routes later |

### W2 — Chat preview card

| Item | Detail |
|------|--------|
| **Files** | `ui_site_preview_card.dart` |
| **Change** | Expanded area = `GuestSiteView` + `bootGet`; collapsed unchanged (title + URL + menu) |
| **Remove** | `_buildBlock` mocks when parity met |

### W3 — Sites Preview tab

| Item | Detail |
|------|--------|
| **Files** | `ui_site_preview.dart` |
| **Change** | Default `GuestSiteView`; `kSitePreviewUseWebView` flag until W5 |
| **Reload** | On publish / draft put / `reloadNonce` refetch boot |

---

### H1 — HTML parity tests

| Item | Detail |
|------|--------|
| **Files** | `mod_site/tests/render_test.rs`, fixtures from CSA |
| **Gate** | Each catalog row has HTML snapshot test |

### H2 — Token/CSS

| Item | Detail |
|------|--------|
| **Align** | `theme` JSON → CSS variables match Flutter `ThemeExtension` for guest |

### H3 — Guest JS (optional phase)

| Item | Detail |
|------|--------|
| **Note** | CSA `client/site/site.js` for cart/forms; c35 may use simpler guest HTTP until commerce guest path needs parity |

---

### T1 — site.config.put tool

| Item | Detail |
|------|--------|
| **Rust** | Tool → `site_config_put` |
| **Inst** | Phrases: enable POS, booking, queue |

### T2 — Deletes & embeds

| Item | Detail |
|------|--------|
| **Tools** | `site.product.patch` soft-delete or `site.product.delete`; `site.product_embed.put` |

### T3 — Grants

| Item | Detail |
|------|--------|
| **Tools** | `site.grant.put` / `site.grant.delete` → `ai.identity_grant` |

### T4 — Inst verification

| Item | Detail |
|------|--------|
| **MCP** | `prompt_compose` / `prompt_run` for `@site` price change, layout patch, compare two sites |

---

### E1–E3 — Editor shell

| Item | Detail |
|------|--------|
| **E1** | Wire picker → tabs (already partial) |
| **E2** | Only if csa screens exceed UITable: adapter `SiteApi` ↔ `ReqSite*` |
| **E3** | POS UI polish — `widgets/sites/tx/*` (id.alienai reference), not guest renderer |

---

### I1 — E2E checklist

- [ ] User with 10 sites: welcome has no site chips; picker lists all.
- [ ] Chat `site.create` → card expands → widget preview matches guest HTML smoke (same title/hero).
- [ ] Draft Visit URL works in browser.
- [ ] `@site` → `site.patch` / `site.publish` in `prompt_run`.
- [ ] UITable product edit still syncs; widget `product_grid` updates after refresh.
- [ ] WebView flag off: Preview tab still usable.

---

## Agent assignment (suggested)

| Agent | Wave | Track |
|-------|------|-------|
| A | 1 | N1 + N3 |
| B | 1 | N2 |
| C | 2 | C1 + C2 + C3 |
| D | 3 | W1 + W2 |
| E | 3 | W3 |
| F | 4 | H1 + H2 |
| G | 5 | T1–T4 |
| H | 6 | E1 (E2/E3 if scoped) |
| I | 7 | I1 |

**Dependencies:** W1 blocked on C2/C3. H1 can start with existing SiteDoc. T* mostly independent. N* can ship first.

---

## Verify (per track)

| Area | Command |
|------|---------|
| Rust | `cd servers && cargo build -p server_ai && cargo test -p c35_mod_site` |
| Flutter | `.\_\scripts\dev\verify_flutter_app.ps1`; `flutter test` for guest_site + preview card |
| UTF-8 | `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` |
| Prompt | MCP `prompt_compose` / `prompt_run` (`owner_iid` 33000 regression, 99000 spot checks) |

---

## Out of scope (this plan)

- Full CSA hub URL routing (`/products/{id}`) migration without spec change
- Replacing guest HTML with Flutter Web for `alienai.id`
- Normalized `site.page` / `site.block` tables (site.md deferred)
- id.alienai POS full port (track E3 is styling only unless expanded)

---

## Publish

After server tracks: `.\_\scripts\deploy\publish_server.ps1`  
After app tracks: `.\_\scripts\deploy\publish_app_release.ps1` (user promotes)
