# Alien AI platform home — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** `https://alienai.id/` (and `/id/`) shows news, featured partners, featured clients, the client list, and links from a reserved site `alien_id=alienai`, edited in the normal site editor. Design and Effects stay disabled for that site. Uid `99000` owns it through `ai.identity_grant`.

**Architecture:** Keep the marketing HTML in `clients/web`. Do not serve `/` through `mod_site` guest HTML (`render.rs` / `site-guest`). A public JSON route reads `site.post`, `site.contact`, and `site.link` for the platform site only. Editors use existing RPCs. Membership stays on `ai.identity_grant` — do not add `site_member`.

**Tech stack:** Rust `mod_site` + `wire_http`, Flutter site editor, static `clients/web/index.html` and `clients/web/id/index.html`.

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/site.md`](../site.md) (Team / ACL)

---

## Global constraints

- Guest URLs stay path-only: `https://alienai.id/{alien_id}/…`. The platform home is `GET /` on `alienai.id`, not `GET /alienai`.
- ACL is only `ai.identity_grant` on `resource_iid = site_iid`. Roles: `owner` | `manage` | `staff` | `guest`. Write requires `manage` or owner. Never reintroduce CSA `site_member`.
- `site.contact.meta_json.featured` is `partners` or `clients` (already the guest featured-strip contract in `guest_design.rs`).
- News is `site.post` with `on_storefront = true`. Links are `site.link` with `active = true`.
- Do not add provider web grounding. Do not commit unless the user asks.
- After Rust edits: `cd servers; cargo test -p mod_site -- platform_site` and `cargo build -p server_ai` if `wire_http` changed.
- After Dart edits: `.\_\scripts\dev\verify_flutter_app.ps1` is too broad for a slice; run the new `flutter test` files plus `check_utf8_sources.ps1 -Changed -Fix`.
- Write `.rs` / `.dart` / `.md` / `.html` as UTF-8 (editor tools, not PowerShell `Set-Content`).

---

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Site handle | `alien_id` exactly `alienai`. Unclaimable: no other identity may take it, and this site may not rename away from it. |
| Owner | `ai.identity.owner_iid = 99000` and an `ai.identity_grant` row `role=owner`, `grantee_iid=99000`. Owner already passes `site_grant_check`; the grant row is what Team lists. Share later via Team (`manage` can write posts/contacts/links; `staff` cannot). |
| Taken handle | If some other non-deleted identity already has `alienai`, boot does **not** steal it. Log an error and skip. Ops frees the handle first. |
| Homepage renderer | Special. Inject sections into the existing marketing pages. Do not call `serve_render_*` or `GuestSiteView` for `/`. |
| Client list | Same rows as featured clients: `meta_json.featured = 'clients'`. The page shows a logo strip and a name list. There is no third contact kind. |
| Featured partners | `meta_json.featured = 'partners'`. |
| Design + Effects | Editor nav items `design` and `effects` are disabled when `alien_id == alienai`. Handle field on Info is read-only. Links, contacts, posts, team, publish stay available. |
| Contacts menu | For this site, Contacts is enabled even when commerce and booking are off. |
| Posts editor | New editor section. Server RPCs already exist (`site_post_list` / `site_post_put` / `site_post_delete`). Flutter has no caller yet. |
| Publish | Public JSON reads the live tables, not `site.render`. Saving a post, contact, or link shows on the home without a guest HTML compile. |
| Locales | English `clients/web/index.html` and Indonesian `clients/web/id/index.html` both mount the same sections. Copy in the section headings follows the page language. Names, titles, and captions stay as stored. |

---

## Already shipped — do not rebuild

- `site.post`, `site.contact`, `site.link` tables (`_/schemas/site.sql`).
- `site_post_list` / `site_post_put` / `site_post_delete` in `servers/crates/mod_site/src/site_post.rs`, wired in `wire_ws`.
- Links editor: `clients/app/lib/widgets/sites/editor/ui_site_links_editor.dart`.
- Featured contact read path: `featured_contacts_for_site` in `guest_design.rs` (`meta_json.featured` in `partners` | `clients`, pic from `meta.pic` or `meta.avatar`).
- Team + `identity_grant`: `_/specs/site.md` Team section. `site_grant_check` in `servers/crates/mod_site/src/grant.rs`.
- Marketing home: `servers/crates/wire_http/src/web.rs` `root_get` serves `clients/web/index.html` when the host is primary.

## Gaps

- Nothing stops a user from claiming handle `alienai`.
- No boot row for that site, no grant for `99000`.
- Contacts editor has no featured picker (`ui_site_contacts_editor.dart`). Contacts menu is off unless commerce or booking (`ui_site_editor_menu.dart`).
- No posts editor and no `SiteApi` post methods.
- `index.html` has no news / partners / clients / links blocks.
- Design and Effects are always available.

---

## File map

| File | Track | Action |
|------|-------|--------|
| `servers/crates/mod_site/src/platform_site.rs` | S | **Create** — constant, ensure, public payload |
| `servers/crates/mod_site/src/lib.rs` | S | Export module |
| `servers/crates/mod_site/src/site_handle.rs` | S | Reject claim / rename of `alienai` |
| `servers/crates/mod_identity/src/identity_put.rs` | S | Reject `alien_id=alienai` on create/update |
| `servers/crates/mod_site/src/http.rs` | S | Add `alienai` to `RESERVED` so `/{alien_id}` never serves this site |
| `servers/crates/wire_http/src/web.rs` | S | `GET /v1/site/platform-home` JSON; call ensure on process boot if a boot hook already exists, else from `root_get` once |
| `servers/crates/mod_site/tests/platform_site_test.rs` | S | **Create** |
| `clients/app/lib/c/site/platform_site.dart` | E | **Create** — `platformSiteAlienId = 'alienai'` |
| `clients/app/lib/c/site/site_api.dart` | E | Post list/put/delete |
| `clients/app/lib/widgets/sites/editor/ui_site_posts_editor.dart` | E | **Create** |
| `clients/app/lib/widgets/sites/editor/ui_site_contacts_editor.dart` | E | Featured picker; write `meta_json.featured` and `meta_json.pic` |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_menu.dart` | E | Disable design + effects; force contacts on |
| `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` | E | Posts section; pass platform flag |
| `clients/app/lib/widgets/sites/editor/ui_site_info_editor.dart` | E | Read-only handle |
| `clients/app/test/platform_site_editor_test.dart` | E | **Create** |
| `clients/web/platform-home.js` | H | **Create** — fetch + render sections |
| `clients/web/index.html` | H | Mount points |
| `clients/web/id/index.html` | H | Mount points (`data-lang="id"`) |
| `_/specs/site.md` | S | Platform site section |

---

## Public JSON contract

`GET /v1/site/platform-home` — no auth. `Content-Type: application/json`. Cache `public, max-age=30`.

```json
{
  "alien_id": "alienai",
  "posts": [
    {"post_id": 1, "title": "", "caption": "", "body": "", "thumb": "", "created_ts": ""}
  ],
  "partners": [
    {"contact_id": 1, "name": "", "pic": "", "url": ""}
  ],
  "clients": [
    {"contact_id": 2, "name": "", "pic": "", "url": ""}
  ],
  "links": [
    {"link_id": 1, "label": "", "url": "", "icon": ""}
  ]
}
```

Rules:

- Missing platform site → `200` with four empty arrays (homepage still renders).
- Posts: `deleted_ts IS NULL AND on_storefront = TRUE`, `ORDER BY sort_order, post_id DESC`, cap 12.
- Partners / clients: non-deleted, not archived, `meta_json->>'featured'` equals that kind, `ORDER BY name`. `url` from `meta_json.url` (empty string if absent). `pic` through existing `pic_url`.
- Links: non-deleted, `active = TRUE`, `ORDER BY sort_order, link_id`.
- Do not include emails, phones, notes, or grant data.

---

## Multitask waves

```
WAVE 1  S1  Unclaimable handle + boot ensure + owner grant 99000 + public JSON
        E1  Posts editor + featured picker + disable Design/Effects
        H1  Homepage sections (platform-home.js + both index.html)
WAVE 2  D1  site.md platform section (if S1 did not land it)
        T1  cargo test + flutter test + utf8 check
```

S1, E1, and H1 do not share files. H1 codes against the JSON contract above. E1 uses `platformSiteAlienId = 'alienai'` in Dart and does not import the Rust module.

### Parallel assignment

| Wave | Agent A | Agent B | Agent C |
|------|---------|---------|---------|
| 1 | S1 server | E1 Flutter editor | H1 marketing home |
| 2 | T1 verify | D1 docs only if missing | — |

---

## Track S1 — Reserved site, grant, public JSON

**Files:** `platform_site.rs`, `lib.rs`, `site_handle.rs`, `identity_put.rs`, `http.rs` `RESERVED`, `wire_http` route, `platform_site_test.rs`, `_/specs/site.md`.

- [ ] **S1.1** `pub const PLATFORM_SITE_ALIEN_ID: &str = "alienai";` and `pub fn platform_site_alien_id_is(raw: &str) -> bool` (trim, ascii case-insensitive).
- [ ] **S1.2** `site_handle_put`: if the site's current `alien_id` is the platform id, bail `platform site handle is locked`. If `new_alien_id` normalizes to it and the site is not already that identity, bail `handle is reserved`.
- [ ] **S1.3** `identity_put` create and update: same reserved bail when the requested `alien_id` is `alienai` and the row is not the existing platform site.
- [ ] **S1.4** Add `"alienai"` to `RESERVED` in `http.rs` so `https://alienai.id/alienai` stays the not-found page. `GET /` stays in `web.rs`.
- [ ] **S1.5** `platform_site_ensure(pool)`:
  1. Select `id, owner_iid` from `ai.identity` where `kind='site'` and `lower(alien_id)='alienai'` and `deleted_ts IS NULL`.
  2. If a row exists and `owner_iid != 99000`, return `Err` (do not steal).
  3. If missing, insert identity (`kind='site'`, `alien_id='alienai'`, `name='Alien AI'`, `owner_iid=99000`) plus `site.config` (`owner_iid=99000`, `tz='Asia/Jakarta'`) plus an empty `site.draft` if that table requires a row for the editor to open. Use `snowflake_id()` the same way `identity_put` does. Confirm user `99000` exists first; if not, return `Err` and do not insert.
  4. Upsert `ai.identity_grant` (`resource_iid=site id`, `grantee_iid=99000`, `role='owner'`, `deleted_ts=NULL`). Owner grant is allowed here because this is platform boot, not `site.grant.put` (that path refuses `role=owner`).
- [ ] **S1.6** Call `platform_site_ensure` from the server boot path that already runs schema/seed work. If no such hook is obvious, call it at the start of `platform_home_get` so the first request creates the row. Do not call it on every guest site request.
- [ ] **S1.7** `platform_home_payload(pool) -> Value` matching the JSON contract. Route in `wire_http`: `GET /v1/site/platform-home`.
- [ ] **S1.8** Tests in `platform_site_test.rs` (sqlx test or pure functions where the pool is heavy):
  - `platform_site_alien_id_is(" AlienAI ")` is true; `"alien"` is false.
  - Payload grouping: a contact meta `featured=partners` lands in `partners` only; `clients` lands in `clients` only; archived excluded; post with `on_storefront=false` excluded.
  - Handle helper used by `site_handle_put` rejects assigning `alienai` to a different site id.
- [ ] **S1.9** Add a short **Platform site** subsection to `_/specs/site.md`: handle `alienai`, unclaimable, owner `99000` via `identity_grant`, public JSON path, editor disables Design and Effects, home is not the guest renderer.

**Acceptance:** `cargo test -p mod_site -- platform_site` passes. `GET /v1/site/platform-home` returns the four keys. A second site cannot take `alienai`.

---

## Track E1 — Editor: posts, featured, locked chrome

**Files:** `platform_site.dart`, `site_api.dart`, `ui_site_posts_editor.dart`, `ui_site_contacts_editor.dart`, `ui_site_editor_menu.dart`, `ui_site_editor_shell.dart`, `ui_site_info_editor.dart`, `platform_site_editor_test.dart`.

- [ ] **E1.1** `const platformSiteAlienId = 'alienai';` and `bool isPlatformSiteAlienId(String? id)`.
- [ ] **E1.2** Menu: `siteEditorMenuGroups` takes an optional `bool platformSite`. When true, items `design` and `effects` have `enabled: false` and subtitle `Managed on the Alien AI home`. Item `contacts` is `enabled: true` even when caps are off. Add item `posts` (`Icons.newspaper_outlined`, label `News`) in the Site group, after Links.
- [ ] **E1.3** Shell: pass `platformSite: isPlatformSiteAlienId(site.alienId)`. If the selected section is `design` or `effects` on a platform site, fall back to `info`. Wire section `posts` to `UiSitePostsEditor`.
- [ ] **E1.4** `SiteApi`: `sitePostList`, `sitePostPut`, `sitePostDelete` calling the existing wire RPCs (`ReqSitePostList` / `Put` / `Delete`). Mirror the links methods in the same file.
- [ ] **E1.5** `UiSitePostsEditor`: list, add, edit title + caption + body, toggle `on_storefront` (label `Show on home`), delete. Save through the editor save bus if the shell already provides it; otherwise save on button press the way links do. Cap copy: title 200 chars (server rejects longer).
- [ ] **E1.6** Contacts detail: dropdown **Featured** with `None`, `Partner`, `Client`. On save, set `meta_json.featured` to `partners`, `clients`, or remove the key for None. Keep existing name/phone/email/note fields. If the contact form already has a picture control, write that URL to `meta_json.pic`. If it does not, add a single pic URL field — the home uses `meta.pic`.
- [ ] **E1.7** Info: when `isPlatformSiteAlienId`, the handle control is read-only and shows `alienai.id/alienai` is not the public home — the public home is `https://alienai.id/`. Do not call `siteHandlePut` for this site.
- [ ] **E1.8** Widget/unit test `platform_site_editor_test.dart`:
  - `isPlatformSiteAlienId('alienai')` true.
  - Menu for `platformSite: true` has `design.enabled == false`, `effects.enabled == false`, `contacts.enabled == true`, and contains `posts`.
  - Menu for `platformSite: false` leaves design and effects enabled.

**Acceptance:** Opening the `alienai` site in the editor shows News and Contacts, and Design and Effects do not navigate. A contact saved as Partner is stored with `featured=partners`.

---

## Track H1 — Special homepage sections

**Files:** `clients/web/platform-home.js`, `clients/web/index.html`, `clients/web/id/index.html`.

- [ ] **H1.1** `platform-home.js` fetches `/v1/site/platform-home` and fills four mounts:
  - `#platform-news` — title, caption, date. Empty array removes the section.
  - `#platform-partners` — pic + name, link when `url` is non-empty.
  - `#platform-clients` — same strip, then a text list (`#platform-client-list`) of the same `clients` array.
  - `#platform-links` — label links.
- [ ] **H1.2** Headings: read `document.documentElement.dataset.siteLocale`. `id` → `Berita`, `Mitra`, `Klien`, `Tautan`. Otherwise `News`, `Partners`, `Clients`, `Links`.
- [ ] **H1.3** Insert the four `<section>` mounts into both HTML files before the existing footer, using the page's current Tailwind classes (`dark:bg`, `brand`, `max-w`). Do not load `site-guest` JS or WASM. Do not duplicate the marketing hero.
- [ ] **H1.4** Fetch failure leaves the mounts empty and does not throw into the rest of the page. `rel="noopener"` on external links. Ignore `javascript:` URLs.

**Acceptance:** With the API returning one partner, one client, one post, and one link, both locales show those four blocks and no guest-site stylesheet.

---

## Track T1 — Verify

- [ ] **T1.1** `cd servers; cargo test -p mod_site -- platform_site`
- [ ] **T1.2** `cd servers; cargo build -p server_ai` (wire_http route).
- [ ] **T1.3** `cd clients/app; flutter test test/platform_site_editor_test.dart`
- [ ] **T1.4** `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`

---

## Out of scope

- Replacing the marketing hero, pricing, or download buttons.
- Guest renderer themes, navigation chrome, or overlay effects for this site.
- A separate client-list table.
- Granting anyone other than `99000` in this plan (Team invite already does that).
- Publishing a new cluster image (do that only when asked).
