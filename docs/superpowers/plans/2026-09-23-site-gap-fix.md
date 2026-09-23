# Site Phase 8 Gap Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Phase 8 gaps between current `mod_site` + Sites page and locked specs (`spec.md`, `_/docs/site.md`, `_/docs/ui.md`) — prompt-primary layout, UITable admin, iframe preview (published + draft), full v1 block renderer, Settings/Domains, pin/rename, and missing `web.builder` tools.

**Architecture:** Keep the locked split: **Home prompt** edits `site.draft.doc_json`; **Sites page** is operational admin (UITable + Preview iframe). Server owns all HTML compilation in `mod_site::render` (remove duplicate render in `mod_chat`). Draft preview uses **signed short-lived tokens** on the guest host (`alienai.id`) so unpublished HTML is never world-readable. Flutter gets a `guestSiteOrigin` config separate from `api.alienai.id`.

**Tech Stack:** Rust (`servers/crates/mod_site`, `mod_chat`), Flutter (`clients/app`), protobuf (`_/schemas/proto/c35/site.proto`), YugabyteDB.

## Global Constraints

- Read `spec.md`, `_/docs/site.md`, `_/docs/ui.md` before coding.
- Guest URLs: `https://alienai.id/{alien_id}/…` only — never `{alien_id}.alienai.id`.
- App WS/RPC host: `https://api.alienai.id` — guest HTML host is separate.
- Layout editor = Home prompt (`web.builder`); no CSA-style visual site builder.
- Money/checkout = `tx.proto` only (Phase 9 — **out of scope** for this plan).
- Naming: `ui_` widgets, `page_` pages, `l()` / `lError()` on client; `ca.L` on server.
- Verify: `cargo build -p server_ai`; `cargo test -p c35_mod_site` when touching site crate; `flutter analyze` in `clients/app`.
- Do not commit unless user asks.

## Out of Scope (separate plans)

| Item | Why |
|------|-----|
| Phase 9 POS (`mod_tx`, Orders tab, `ReqSiteGuestOrderPut`) | Roadmap Phase 9 |
| `site.parent_link` hub tenants | No spec requirement in Phase 8 |
| `ehash_search` embedding regen | Deferred in `site.md` embeddings section |
| Full cert-manager TLS sync | Stub acceptable until deploy track; only document env contract |
| Normalized `site.page` / `site.block` tables | Explicitly deferred in `site.md` |

---

## Gap → Track Map

| Gap | Track |
|-----|-------|
| Preview opens external URL, wrong host (`api` vs `alienai.id`) | W1 |
| `?draft=1` not served | W2 |
| Incomplete block renderer (7 types) | W3 |
| Duplicate render in `mod_chat/tools/builtin/site.rs` | W3 |
| Settings: capabilities + domains missing | W4 |
| Product embed subtable read-only | W4 |
| Pin / rename on site list | W5 |
| Missing `site.contact_put` / `site.object_put` LLM tools | W6 |

---

## Multitask Map

```
WAVE 1 — Server foundations (parallel)
  W2  Draft preview token + guest HTTP ?draft=1
  W3  Full v1 block renderer + dedupe mod_chat render

WAVE 2 — Flutter admin UI (parallel, after W2 URL contract known)
  W1  guestSiteOrigin + Preview iframe (published)
  W4  Settings tab (capabilities + Domains UITable) + embed edit
  W5  Site list pin/rename (Devices pattern)

WAVE 3 — Prompt tools (after W3)
  W6  site.contact_put + site.object_put tools + inst.sql check

WAVE 4 — Integration
  I1  Manual E2E checklist + doc touch-ups
```

### Suggested agent assignments

| Agent | Track | Deliverable |
|-------|-------|-------------|
| A | W2 | Signed draft preview on guest host |
| B | W3 | All v1 blocks render; single render path |
| C | W1 | iframe Preview tab + correct guest URL |
| D | W4 | Settings + Domains + embed CRUD in UITable |
| E | W5 | Pin/rename on Sites master list |
| F | W6 | Two new web.builder tools |
| G | I1 | E2E verification notes |

---

## W2 — Draft preview (signed token)

### Task W2.1: Preview token RPC

**Files:**
- Modify: `_/schemas/proto/c35/site.proto`
- Modify: `servers/crates/wire_ws/src/session.rs` (invoke handler)
- Create: `servers/crates/mod_site/src/site_preview.rs`
- Modify: `servers/crates/mod_site/src/lib.rs`

**Interfaces — produces:**
```rust
// site_preview.rs
pub async fn site_preview_token_issue(
    pool: &PgPool,
    caller_iid: i64,
    site_iid: i64,
    ttl_secs: u32,
) -> Result<String>; // HMAC token

pub async fn site_preview_token_verify(
    pool: &PgPool,
    site_iid: i64,
    token: &str,
) -> Result<bool>;

pub async fn site_draft_html_render(
    pool: &PgPool,
    site_iid: i64,
    page_path: &str,
) -> Result<(Vec<u8>, String)>; // body, etag
```

**Proto additions:**
```protobuf
message ReqSitePreviewToken {
  int64 site_iid = 1;
  int32 ttl_secs = 2; // default 300
}
message ResSitePreviewToken {
  string token = 1;
  int64 expires_ts_ms = 2;
}
```

- [ ] **Step 1:** Add proto messages; regenerate Dart/Rust pb if repo has a codegen script (or hand-update generated files per repo convention).
- [ ] **Step 2:** Implement HMAC token: payload `{site_iid}:{exp_ms}` signed with `C35_SITE_PREVIEW_SECRET` (fallback: server session secret env). Constant-time compare.
- [ ] **Step 3:** `site_draft_html_render` loads `site.draft.doc_json`, calls existing `publish_doc_render` / `page_html_render` from `render.rs` (do not duplicate HTML).
- [ ] **Step 4:** Wire `ReqSitePreviewToken` in `wire_ws/session.rs`; grant-check via `site_grant_check`.
- [ ] **Step 5:** `cargo build -p server_ai`

### Task W2.2: Guest HTTP `?draft=1&ptoken=…`

**Files:**
- Modify: `servers/crates/mod_site/src/http.rs`
- Test: `servers/crates/mod_site/tests/render_test.rs` (token parse unit test if extracted)

**Behavior:**
- `GET /{alien_id}?draft=1&ptoken=…` → verify token for resolved `site_iid` → render draft HTML on the fly (`Cache-Control: private, no-store`).
- `GET /{alien_id}` without valid draft params → existing published `site.render` path unchanged.
- Invalid/expired token → 403 HTML "Preview expired".

- [ ] **Step 1:** Add `Query` extractor for `draft`, `ptoken` on `guest_site_root` and `guest_site_path`.
- [ ] **Step 2:** Thread draft branch into `serve_render_site` before published check.
- [ ] **Step 3:** Add test: valid token shape parses; invalid returns false (no DB needed).
- [ ] **Step 4:** `cargo test -p c35_mod_site && cargo build -p server_ai`

---

## W3 — Full v1 block renderer + dedupe

### Task W3.1: Implement missing block types in `render.rs`

**Files:**
- Modify: `servers/crates/mod_site/src/render.rs`
- Modify: `servers/crates/mod_site/tests/render_test.rs`

**Block types to add in `block_html`:**

| type | Minimal render |
|------|----------------|
| `gallery` | `<div class="gallery">` grid of `props.pics[]` images |
| `links` | `<ul class="links">` from `props.items[{label,url}]` |
| `contact_form` | `<form>` with fields from `props.fields`; `action` placeholder `#contact` (guest submit = later) |
| `map` | `<div class="map">` embed link or static map img from `props.lat/lng` |
| `hours` | `<table class="hours">` from `props.schedule` |
| `queue` | `<div class="queue">` display number from `props.label` |
| `embed` | sandboxed `<iframe sandbox="" src="…">` from `props.url` |
| `custom_html` | escape/sandbox policy: strip `<script>`, render remainder in `<div class="custom-html">` |

Capability gating (read `site.config.capabilities_json` once per page render):
- `map`, `hours`, `queue` → only render if capability key enabled (`booking`, `queue`, etc. per `site.md`).

- [ ] **Step 1:** Add failing tests per block type (HTML contains expected class/escaped text).
- [ ] **Step 2:** Implement each branch in `block_html`; pass capabilities into `page_html_render`.
- [ ] **Step 3:** `cargo test -p c35_mod_site`

### Task W3.2: Remove duplicate render from `mod_chat`

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/site.rs`

**Change:** `site_publish_exec` calls `c35_mod_site::site_publish::site_publish_internal` or shared `publish_doc_render` instead of local `render_page_html` / `render_doc_html`.

- [ ] **Step 1:** Delete local render helpers in `site.rs`.
- [ ] **Step 2:** Import and call `mod_site` publish/render functions.
- [ ] **Step 3:** `cargo build -p server_ai`

---

## W1 — Flutter Preview iframe + guest origin

### Task W1.1: Guest origin config

**Files:**
- Modify: `clients/app/lib/c/config.dart`
- Modify: `clients/app/lib/c/conn/server_host.dart` (if origin derived from host picker)

**Interfaces — produces:**
```dart
// config.dart
class C35Config {
  static String authApiBase = authApiProductionUrl;
  static String guestSiteOrigin = 'https://alienai.id'; // NOT api host
}
```

Local dev: when `authApiBase` is `127.0.0.1:8080`, set `guestSiteOrigin` to same host (guest + api share local router).

- [ ] **Step 1:** Add `guestSiteOrigin` with production default `https://alienai.id`.
- [ ] **Step 2:** Update `serverHostInit` to set both bases consistently for local/prod.

### Task W1.2: Preview iframe + draft token

**Files:**
- Modify: `clients/app/lib/c/site/site_api.dart`
- Modify: `clients/app/lib/widgets/sites/ui_site_detail.dart`
- Create: `clients/app/lib/widgets/sites/ui_site_preview.dart` (optional thin wrapper)

**Behavior:**
- Replace `launchUrl` with `UiSitePreview` widget: `HtmlElementView` / `WebView` / `iframe` equivalent (`webview_flutter` if already in pubspec; else `InAppWebView` / platform iframe — match repo dependency).
- Published URL: `{guestSiteOrigin}/{alienId}`.
- Draft URL: fetch `ReqSitePreviewToken` via WS → `{guestSiteOrigin}/{alienId}?draft=1&ptoken={token}`.
- Toggle or default: show **draft** in Preview tab; small label "Draft" vs "Published".
- Refresh preview after Publish succeeds.

- [ ] **Step 1:** Add `sitePreviewToken(siteIid)` to `SiteApi`.
- [ ] **Step 2:** Build iframe widget; handle load error with `uiFriendlyError`.
- [ ] **Step 3:** Remove external `launchUrl` as primary preview (keep optional "Open in browser" icon).
- [ ] **Step 4:** `cd clients/app && flutter analyze`

---

## W4 — Settings, Domains, product embed edit

### Task W4.1: Settings — capabilities editor

**Files:**
- Modify: `clients/app/lib/widgets/sites/ui_site_detail.dart`
- Modify: `clients/app/lib/c/site/site_api.dart` (wrap `ReqSiteConfigPut` if missing)

**UI:** Checkboxes or switches for `commerce`, `booking`, `queue` bound to `capabilities_json`. Save calls `site_config_put`.

- [ ] **Step 1:** Load config on Settings tab open (`siteDraftGet` or dedicated config get).
- [ ] **Step 2:** Toggle UI + save via `ReqSiteConfigPut`.
- [ ] **Step 3:** After save, reload `collectionDefs` (capabilities filter Products/Objects tabs).

### Task W4.2: Settings — Domains UITable

**Files:**
- Modify: `clients/app/lib/widgets/sites/ui_site_detail.dart`
- Modify: `clients/app/lib/c/site/site_api.dart`
- Modify: `clients/app/lib/c/site/site_table_rows.dart`

**Behavior:** Subsection in Settings (or nested tab) using same `UiTable` pattern as Products:
- Columns from `site.domain` TableDef (hostname, is_primary, tls_status, verified).
- Add row → `ReqSiteDomainPut` with new snowflake id.
- Show CNAME hint: "CNAME to alienai.id" + verify token read-only field.

- [ ] **Step 1:** `domainList` / `domainPut` in `SiteApi`.
- [ ] **Step 2:** `siteDomainCells` / `siteDomainApplyCell` helpers.
- [ ] **Step 3:** Render Domains `UiTable` inside Settings tab.

### Task W4.3: Product embed inline edit

**Files:**
- Modify: `clients/app/lib/widgets/sites/ui_site_detail.dart`
- Modify: `clients/app/lib/c/site/site_api.dart`

**Behavior:** In expanded product row subtable:
- `onCellCommit` for embed rows → `productPut` with full product + updated `embeds[]` array (server already supports embeds in `site_product_put`).
- `onAddRow` on subtable adds embed with new `embed_id`.

- [ ] **Step 1:** Track embed edits locally; commit via `productPut`.
- [ ] **Step 2:** `flutter analyze`

---

## W5 — Site list pin / rename

### Task W5.1: Extend `SiteRow` with list prefs

**Files:**
- Modify: `_/schemas/proto/c35/site.proto` (`SiteRow`)
- Modify: `servers/crates/mod_site/src/site_list.rs`
- Regenerate pb files

**Add to `SiteRow`:**
```protobuf
bool is_pinned = 8;
int32 sort_order = 9;
```

SQL: join `identity_grant` meta like `device_list` — `COALESCE(g.is_pinned, false)`, sort `is_pinned DESC, sort_order, updated_ts DESC`.

### Task W5.2: Flutter pin/rename

**Files:**
- Modify: `clients/app/lib/c/site/site_store.dart`
- Modify: `clients/app/lib/widgets/sites/ui_site_row.dart`
- Modify: `clients/app/lib/pages/page_sites.dart`

**Copy pattern from:** `page_devices.dart` + `device_store.dart`:
- Long-press or trailing menu: Pin, Rename.
- `pinPut` / `renamePut` via `ReqIdentityGrantPatch` + `ReqIdentityPut`.

- [ ] **Step 1:** Server list returns `is_pinned`.
- [ ] **Step 2:** Store methods `pinPut`, `renamePut`.
- [ ] **Step 3:** UI menu on `UiSiteRow`.
- [ ] **Step 4:** `flutter analyze`

---

## W6 — Missing `web.builder` tools

### Task W6.1: `site.contact_put` and `site.object_put` tools

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/site.rs`
- Modify: `servers/crates/mod_chat/src/mention_registry.rs` (tool list for `web.builder`)
- Verify: `_/schemas/inst.sql` `inst.web.builder` mentions contact/object puts

**Interfaces:** Mirror `site_product_put_exec` — typed fields only, grant check, call same SQL as `mod_site::site_contact_put` / `site_object_put` (extract shared put functions if needed to avoid duplication).

- [ ] **Step 1:** `site_contact_put_exec` with fields: `contact_id?`, `name`, `phone`, `email`, `address`, `note`, `is_archived`.
- [ ] **Step 2:** `site_object_put_exec` with fields: `id?`, `client_id`, `name`, `code`, `kind`, `product_id`, flags.
- [ ] **Step 3:** Register tools with `topics: ["web.builder"]`.
- [ ] **Step 4:** Update mention_registry tool allowlist: `site.contact_put`, `site.object_put`.
- [ ] **Step 5:** `cargo build -p server_ai`

---

## I1 — Integration checklist

### Task I1.1: Manual E2E

- [ ] Create site identity with `alien_id`.
- [ ] Home: `@site make a hero titled Hello` → draft updates.
- [ ] Sites Preview: iframe shows draft via token.
- [ ] Publish → iframe shows published HTML at `alienai.id/{alien_id}`.
- [ ] Products UITable: add row, expand embed, add alt label.
- [ ] Settings: toggle `commerce` off → Products tab hidden.
- [ ] Settings: add custom domain row.
- [ ] Pin site → appears at top of list.

### Task I1.2: Doc touch-up (only if behavior changed)

- [ ] `_/docs/site.md` — add one paragraph on draft preview token if not already documented.
- [ ] Do **not** edit `spec.md` unless user asks.

---

## Self-Review (spec coverage)

| Spec requirement | Task |
|------------------|------|
| Prompt-primary layout (`web.builder`) | Already done; W6 extends data puts |
| UITable admin tabs | W4 embed edit; W4 domains |
| Preview iframe | W1 |
| Draft preview `?draft=1` | W2 |
| All v1 block types render | W3 |
| Guest path URLs | W1 guest origin |
| Settings: alien_id, domains, capabilities, publish | W4 + existing publish button |
| Pin/rename nav list | W5 |
| No CSA visual editor | N/A (don't add) |
| Phase 9 Orders/POS | Out of scope |
| TLS sync production | Out of scope (stub stays) |
| Embeddings | Out of scope |

---

## Risk Notes

1. **iframe + local dev:** WebView may block mixed content; use same host for local guest+api or document limitation.
2. **Draft token secret:** Must be set in prod (`C35_SITE_PREVIEW_SECRET`); document in deployment yaml.
3. **`custom_html` XSS:** Keep server-side script strip; never render raw without sanitization.
4. **Proto change (`SiteRow`):** Coordinate server + Flutter pb regen in same wave.
