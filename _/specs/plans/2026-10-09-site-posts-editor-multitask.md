# Site posts editor (CSA parity) — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans`. One **Task subagent per track** in a wave; parent dispatches parallel tracks and does not implement every lane inline. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace the inline “News” card stack with a **Posts** section inside site edit that matches CSA `ui_site_posts_section.dart`: master–detail list, full post editor with photo grid, debounced save, and polish consistent with Products (selection chrome, detail header, empty states).

**Architecture:** **Flutter-only.** `site.post` and `site_post_list` / `site_post_put` / `site_post_delete` already exist (`servers/crates/mod_site/src/site_post.rs`, `SiteApi` in `clients/app/lib/c/site/site_api.dart`). Add a small Dart codec for `media_json` + `thumb` sync. Wire `UiSitePostsEditor` like `UiSiteProductsEditor` (`masterDetail`, `detailId`, narrow drill-back). Reference UX: `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_posts_section.dart`.

**Tech stack:** Flutter `clients/app/lib/widgets/sites/editor/`, `InMediaList` + `askMedia` + `casUpload` (same as product photos).

**Specs:** [`spec.md`](../../spec.md) · [`_/specs/site.md`](../site.md) · CSA posts section (path above) · prior gap note in [`2026-10-08-alienai-platform-home-multitask.md`](2026-10-08-alienai-platform-home-multitask.md) (E1 posts editor — **basic list shipped**, this plan upgrades UX).

---

## Global constraints

- Staff edits use existing WebSocket RPCs only. No new HTTP routes for posts.
- `media_json` is a JSON array, max **10** items (enforced server-side). Each item: `{ "src": "<file storage path>", "type": "image", "sort_order": <int> }` (CSA-compatible; extra keys ignored).
- `thumb` is the cover image path (first media `src` after sort). Guest hub and platform-home JSON use `thumb`; keep it in sync on every put.
- `on_storefront` = CSA `active` (“Show on home” / hub feed). Do not rename the proto field.
- UTF-8 sources; after Dart edits run `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` and `flutter test` on new/changed test files.
- Do not commit unless the user asks. No provider web grounding.
- **Out of scope (follow-up plans):** post reorder drag handles, tags, `publishedAt`, guest HTML carousel (`2026-10-08-site-csa-editor-renderer-effects-multitask.md` R2), Flutter preview showing multi-image carousel in `showGuestSitePostDetailSheet`.

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Menu label | **Posts** (id stays `posts`). Subtitle in chrome: section name + optional post title when drilled. |
| Layout wide | Master list `siteCatalogMasterListW` + detail pane (same gate as contacts/team: `_catalogMasterDetail`). |
| Layout narrow | List only until a post is selected; detail full width; system back clears `detailId`. |
| New post | Toolbar **+** creates row, selects it, persists once (title default `New post` or empty → list shows “Untitled”). |
| Photos | `InMediaList`, `maxCount: 10`, thumb size **56** (CSA `InPic` radius). Images only. |
| Active toggle | **On list row** (quick) **and** in `UiSiteCatalogDetailHeader` (CSA parity). Both patch `on_storefront` and save. |
| Delete | Confirm dialog via `siteCatalogConfirmDelete`; soft-delete via `sitePostDelete`. |
| Platform site `alienai` | Posts section stays enabled; label **Posts** (not “News”). |

---

## Already shipped — do not rebuild

- DB `site.post`, proto `SitePost`, RPC handlers in `site_post.rs` / `wire_ws`.
- `SiteApi.sitePostList` / `sitePostPut` / `sitePostDelete`.
- Minimal `ui_site_posts_editor.dart` (inline cards) and menu item `posts`.
- Guest feed summaries use `thumb` (`render.rs`, `GuestSitePostSummary`).

## Gaps (this plan)

- No master–detail; posts not in `_catalogMasterDetail` / `_narrowCatalogDrill`.
- No `media_json` / photo UI; `thumb` never set from client.
- List UX unlike Products (no thumb, no selection accent, no dedicated detail scroll).
- Menu label “News”; tests expect “News”.
- No unit tests for post media codec.

---

## File map

| File | Track | Action |
|------|-------|--------|
| `clients/app/lib/c/site/site_post_media.dart` | M | **Create** — parse/encode `media_json`, paths list, thumb derive |
| `clients/app/test/site_post_media_test.dart` | M | **Create** |
| `clients/app/lib/widgets/sites/editor/ui_site_posts_section.dart` | L | **Create** — list + toolbar + tiles |
| `clients/app/lib/widgets/sites/editor/ui_site_post_detail.dart` | D | **Create** — header, photos, fields, debounced put |
| `clients/app/lib/widgets/sites/editor/ui_site_posts_editor.dart` | O | **Rewrite** — orchestrator (mirror `ui_site_products_editor.dart`) |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` | S | Wire `posts` masterDetail + drill + chrome subtitle |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_menu.dart` | S | Label **Posts** |
| `clients/app/test/platform_site_editor_test.dart` | S | Expect `Posts` not `News` |
| `clients/app/test/site_posts_editor_test.dart` | T | **Create** — widget smoke (list empty, masterDetail row) |
| `clients/app/assets/translations/en.json` | C | `site.posts.*` strings (optional but preferred for polish) |
| `clients/app/assets/translations/id.json` | C | Same keys, natural ID copy |
| `_/specs/site.md` | DOC | One paragraph: Posts editor behavior + `media_json` shape |

Optional hardening (same plan, low priority):

| `servers/crates/mod_site/src/site_post.rs` | H | If `thumb` empty and media non-empty, set thumb from first item on upsert |
| `servers/crates/mod_site/tests/site_post_test.rs` | H | **Create** or extend — thumb backfill |

---

## Visual polish checklist (must pass manual review)

Apply the same editor vocabulary as Products / Contacts:

- List: left **accent** bar when selected (`Color(0xFF34D399)`), subtle row border, **48×48** rounded thumb (`UiImg` + placeholder icon).
- List row: title semibold 14, caption 12 muted one line, trailing `Switch` for `on_storefront`.
- Detail: `UiSiteCatalogDetailHeader` with `Icons.photo_library_outlined`, subtitle explaining hub/home visibility.
- Detail body: `ListView` with `padding: EdgeInsets.fromLTRB(16, 8, 16, 32)`; section label “Photos” `titleSmall` w600; hint “Up to 10 images” 11px muted.
- Fields: `UiSiteEditorLabeledField` + `siteEditorInputDecoration`; title `maxLength: 200` with helper text.
- Errors: persist strip at top of section (red banner) like current posts editor — do not use snackbar-only for save failures.
- Empty list: `UiEmptyState` icon `photo_library_outlined`, CTA via toolbar +.

---

## Wave map

```
WAVE 1  (parallel)
  M   site_post_media.dart + unit tests
  C   translation keys (en + id) — can run parallel with M

WAVE 2  (after M; parallel)
  L   ui_site_posts_section.dart
  D   ui_site_post_detail.dart (imports M)

WAVE 3  (after L + D)
  O   Rewrite ui_site_posts_editor.dart
  S   Shell + menu + platform_site_editor_test

WAVE 4
  T   site_posts_editor_test.dart + verify_flutter subset
  DOC site.md paragraph
  H   (optional) server thumb backfill + rust test
```

---

## Track M — Media codec

**Files:** `clients/app/lib/c/site/site_post_media.dart`, `clients/app/test/site_post_media_test.dart`

**Interfaces:**

- `List<String> sitePostMediaPaths(SitePost post)` — ordered `src` values.
- `String sitePostMediaEncode(List<String> paths)` — JSON string for `post.media_json`.
- `String sitePostThumbFromPaths(List<String> paths)` — first non-empty or `''`.
- `SitePost sitePostWithMedia(SitePost post, List<String> paths)` — sets `media_json` + `thumb`.

- [ ] **M.1** Implement codec (tolerate legacy invalid JSON → `[]`).
- [ ] **M.2** Tests: empty, one path, ten paths, thumb follows first, sort_order increments by 10.

---

## Track C — Copy

**Files:** `clients/app/assets/translations/en.json`, `id.json`

Suggested keys (mirror CSA):

- `site.posts.title` — “Posts”
- `site.posts.subtitle` — “News and updates on your site hub”
- `site.posts.emptyTitle` / `emptySubtitle`
- `site.posts.photos` / `imagesOnlyHint`
- `site.field.caption` / `captionHint` / `articleBody` / `articleBodyHint` — add only if missing

Wire detail header and empty state through `.tr()` where easy; English literals OK for v1 if keys slip.

- [ ] **C.1** Add keys en + id.
- [ ] **C.2** Use keys in section + detail widgets.

---

## Track L — List pane

**Files:** `clients/app/lib/widgets/sites/editor/ui_site_posts_section.dart`

**Pattern:** `UiSiteProductsSection` + CSA `_PostListTile`.

- [ ] **L.1** `UiSiteCatalogToolbar`: hint `Search posts`, `onAdd` → parent callback (no inline persist).
- [ ] **L.2** `_UiSitePostListTile`: thumb from `post.thumb`, title/caption, `Switch` → `onStorefrontChanged(id, value)`.
- [ ] **L.3** Selection styling matches products (accent left border).
- [ ] **L.4** `ReorderableListView` — **not** in v1 (fixed sort_order from server order only).

---

## Track D — Detail pane

**Files:** `clients/app/lib/widgets/sites/editor/ui_site_post_detail.dart`

**Pattern:** CSA `_PostEditor` + product photo upload (`askMedia` → `casUpload` → `fileStoragePath`).

- [ ] **D.1** `UiSiteCatalogDetailHeader`: active = `on_storefront`, delete with confirm body “This post will be removed from your site hub.”
- [ ] **D.2** `InMediaList` `maxCount: 10`, `thumbSize: 56`; add/remove updates local `SitePost` via `sitePostWithMedia`.
- [ ] **D.3** Debounced save **450–600 ms** on text fields; immediate save on media add/remove and toggle.
- [ ] **D.4** Separate `_busy` for uploads vs global list busy (do not block entire list during image pick).
- [ ] **D.5** Scroll: single `ListView` (not nested scrollables).

---

## Track O — Orchestrator

**Files:** `clients/app/lib/widgets/sites/editor/ui_site_posts_editor.dart`

Mirror `UiSiteProductsEditor` state machine:

- `masterDetail`, `detailId`, `onDetailIdChanged`
- `_selectedId` when `masterDetail`
- `_load`, `_posts` map by id, `_put` / `_delete` / `_add`
- Wide: `Row` → `SizedBox(width: siteCatalogMasterListW)` + divider + `Expanded(UiSitePostDetail)`
- Narrow: detail if `detailId != null`, else list
- Empty posts: list with empty state; wide still shows list (no forced detail)

- [ ] **O.1** Replace `_UiSitePostCard` inline editor with section + detail split.
- [ ] **O.2** On add: `sitePostPut` with new row, select returned `post_id`, refresh list item.
- [ ] **O.3** Remove dead code from old card widget.

---

## Track S — Shell + menu

**Files:** `ui_site_editor_shell.dart`, `ui_site_editor_menu.dart`, `platform_site_editor_test.dart`

- [ ] **S.1** `_catalogMasterDetail`: include `section == 'posts'`.
- [ ] **S.2** `_narrowCatalogDrill`: `(section == 'posts' && _catalogDetailId != null)`.
- [ ] **S.3** Pass `masterDetail`, `detailId`, `onDetailIdChanged` into `UiSitePostsEditor`.
- [ ] **S.4** `_chromeSubtitle`: when `section == 'posts' && _catalogDetailId != null`, append truncated post title (load from editor callback or resolve via last-known title in shell — prefer passing `detailTitle` from editor via optional `ValueNotifier` or store title in shell when detail changes; **minimal approach:** subtitle stays “Posts” only for v1 if title lookup is awkward).
- [ ] **S.5** Menu: `SiteEditorMenuItem('posts', …, 'Posts')`.
- [ ] **S.6** Update `platform_site_editor_test` label expectation.

---

## Track T — Tests + verify

- [ ] **T.1** `site_post_media_test.dart` (Track M).
- [ ] **T.2** `site_posts_editor_test.dart`: pump `UiSitePostsEditor` with fake/mock `SiteApi` **or** golden-free smoke using `SitePost` list injected if mock exists; minimum: widget builds list toolbar + empty state.
- [ ] **T.3** `flutter test clients/app/test/site_post_media_test.dart clients/app/test/platform_site_editor_test.dart` (+ site_posts if added).
- [ ] **T.4** `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.

Manual QA (Chito):

1. Wide window: Posts → New post → add 2 photos → title/caption/body → toggle off home → preview hub / platform home if applicable.
2. Narrow: list → post → back → list.
3. Delete post with confirm.

---

## Track DOC — Spec

**File:** `_/specs/site.md`

- [ ] **DOC.1** Under site editor catalog: document Posts section, `on_storefront`, `media_json` shape, 10 image cap, `thumb` cover.

---

## Track H — Server thumb backfill (optional)

**Files:** `site_post.rs`, test

- [ ] **H.1** In `site_post_upsert`, when `post.thumb.is_empty()`, parse `media_json` and set thumb to first object’s `src` string.
- [ ] **H.2** `cargo test -p mod_site` for put with media only.

---

## Dispatch notes for parent agent

| Wave | Tracks | Parallel? |
|------|--------|-----------|
| 1 | M, C | Yes |
| 2 | L, D | Yes (both need M merged) |
| 3 | O, S | Sequential O then S (or one agent if small) |
| 4 | T, DOC, H | T + DOC parallel; H optional |

**Definition of done:** Posts menu opens master–detail editor; photos persist and appear as list thumbs and in guest boot `thumb`; UI matches polish checklist; tests green; spec paragraph added.
