# Site blocks, effects, and dual-renderer parity

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Design and Effects editors change what guests see, and the Flutter phone preview and the published web page show the same blocks, chrome, and overlay effects.

**Architecture:** `theme_json` is the single design document (already written by `SiteDesignStore.toThemeMap`). Both renderers read that document plus the same boot lists (products, links, posts, contacts). Flutter paints widgets. Rust emits HTML and `site-guest.v1.css`. They share token names, block types, and effect preset ids. Overlay effects sit under the blocks and above the page background, the same way the CSA guest did.

**Tech Stack:** Flutter `clients/app/lib/guest_site/`, Rust `servers/crates/mod_site`, static `clients/web/static/site-guest/`, CSA reference `D:\csa_site_published`.

**Specs:** [`_/docs/site.md`](../site.md) | [`_/docs/plans/2026-10-07-site-dual-renderer-multitask.md`](2026-10-07-site-dual-renderer-multitask.md) | CSA [`guest_ui.md`](file:///D:/csa_site_published/.agents/guest_ui.md) | CSA [`effects.md`](file:///D:/csa_site_published/.agents/effects.md)

## Global Constraints

- Guest public HTML stays on `alienai.id/{alien_id}` via `mod_site` render. Do not switch the phone preview to a WebView.
- App saves stay on the existing draft WebSocket (`draftPut` / `theme_json`). No new HTTP invoke for the editor.
- Do not add provider web grounding (`googleSearch`, `web_search` tool type).
- New or edited `.dart`, `.rs`, `.css`, `.js`, `.md` files are UTF-8 (no BOM).
- One block type is done only when Flutter and Rust both render it from the same boot fixture.
- Effect preset ids and params match CSA `assets/effects/presets.json`. Do not invent new preset ids.

---

## What is broken today

The designer writes `theme_json` (`base`, `dark`, `accent`, `background`, `card`, `backdrop`, `profile`, `product`, `partners`, `clients`, `blocks`). The guest ignores almost all of it.

| Surface | Reads today | Ignores |
|---|---|---|
| Flutter `guestSiteBlock` | `accent`, `product_design` from meta | profile layout, link card, featured strips, page background, backdrop, global card style |
| Rust `block_html_render` | `accent`, `product_design` from meta | same list |
| Effects editor | placeholder copy | CSA preset catalog, stack, painters |

Designer block id → guest block type:

| Designer id | Guest `type` | Data |
|---|---|---|
| `profile` | `hub_profile` | site name, pic, hours, `profile` object |
| `link` | `links` | `site.link` rows, block override `blocks[].block == "link"` |
| `site_product` | `product_grid` | `site.product` rows, `product` object, block override `site_product` |
| `partners_display` | `partners_display` | contacts whose `meta_json.featured` is `partners`, plus `partners` strip |
| `clients_display` | `clients_display` | contacts whose `meta_json.featured` is `clients`, plus `clients` strip |

Page chrome (theme, background, backdrop, global card) is not a block. It wraps every block.

---

## File map

| File | Role |
|---|---|
| `servers/crates/mod_site/src/guest_design.rs` | Parse `theme_json` into tokens, card CSS, backdrop CSS |
| `servers/crates/mod_site/src/render.rs` | Pass `GuestDesign` into `block_html_render`; emit `:root` and page background |
| `servers/crates/mod_site/src/boot.rs` (or the existing boot builder) | Put `design` and `effects` on boot JSON next to products and links |
| `clients/web/static/site-guest/site-guest.v1.css` | Token-driven hub chrome (cards, profile, strips) |
| `clients/web/static/site-guest/site-guest.effects.js` | Canvas host for overlay presets |
| `clients/app/lib/guest_site/guest_site_design.dart` | Dart twin of `GuestDesign` (wrap `siteDesignResolve`) |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | Apply design to profile, links, products, strips |
| `clients/app/lib/guest_site/guest_site_view.dart` | Page background, backdrop, effect stack |
| `clients/app/lib/widgets/sites/editor/ui_site_effects_editor.dart` | Replace the stub with the CSA effects section |
| `clients/app/lib/c/site/design/site_design_store.dart` | Load and save `effects` |
| `servers/crates/mod_site/tests/guest_design_test.rs` | Token + HTML fixture |
| `clients/app/test/guest_site_design_test.dart` | Same fixture, widget structure |

CSA sources to port, not rewrite:

- Design resolve already in `clients/app/lib/c/site/design/`
- Effects editor: `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_effects_section.dart`
- Painters: `D:\csa_site_published\clients\app\lib\widgets\overlay_effect\`
- Presets: `D:\csa_site_published\clients\app\assets\effects\presets.json`
- Shared sim (web): `D:\csa_site_published\crates\overlay_effects`

---

## Parity rule

A fixture file `servers/crates/mod_site/tests/fixtures/guest_design_min.json` holds one `theme_json`, one page of five blocks (`hub_profile`, `links`, `product_grid`, `partners_display`, `clients_display`), and one active effect.

Both sides must produce:

1. The same token strings: `--accent`, `--page-bg`, `--fg`, `--card-radius`, `--card-bg`, `data-backdrop`, `data-card`.
2. The same block order and `data-guest` values: `profile`, `link`, `site_product`, `partners`, `clients`.
3. Profile shows or hides avatar, title, bio, location, and hours from `profile`.
4. A link block with `cardStyleId: "none"` has no card chrome. Any other id uses the global or override card.
5. Product title, subtitle, and price use the font size, weight, italic, underline, and color from `product`.
6. Boot JSON `effects` equals the saved array. Flutter and web both mount a preset only when `active` is true.

Flutter does not embed the HTML. Identity is the shared boot plus this fixture, checked by `cargo test -p mod_site guest_design` and `flutter test test/guest_site_design_test.dart`.

---

## Wave 1 — Shared design document on the boot

- [ ] **B1.1** Add `guest_design.rs` with `GuestDesign::from_theme_json(&str) -> GuestDesign`. Fields: `accent`, `dark`, `page_bg`, `fg`, `muted`, `card_radius`, `card_bg`, `card_border`, `backdrop_id`, `profile` (mirrors the JSON keys in `SiteDesignStore.toThemeMap`), `product`, `partners`, `clients`, `block_cards` map.
- [ ] **B1.2** Empty or legacy `{"accent":"#ff0000"}` still yields accent `#ff0000`, backdrop `none`, card `solid`, profile defaults (avatar on, title on, bio on, location on, hours on).
- [ ] **B1.3** Test in `guest_design_test.rs`: parse the fixture and assert those token strings.
- [ ] **B1.4** Put the same object on boot JSON as `design`. Flutter `GuestSiteBoot` reads `design` into `guest_site_design.dart` by calling the existing `SiteDesignStore.loadTheme`.
- [ ] **B1.5** `cd servers; cargo test -p mod_site guest_design` passes. `flutter test test/guest_site_design_test.dart` loads the same fixture and expects `store.themeBaseId`, `store.accent`, and `store.profileDesign.showAvatar`.

## Wave 2 — Page chrome (theme, background, backdrop, cards)

- [ ] **C2.1** `render.rs` page wrapper sets `:root { --accent; --page-bg; --fg; --muted; --card-radius; --card-bg; --card-border }` from `GuestDesign`. Body background is `page_bg`. `data-backdrop` is the backdrop id.
- [ ] **C2.2** Solid `background.type == "color"` overrides `page_bg`. `type == "image"` emits a fixed cover image using the existing `/fs/` URL helper. `type == "none"` keeps the theme background.
- [ ] **C2.3** Backdrop ids `none`, `glow`, `mesh`, `grain`, `diamond`, `aurora` each have one CSS class in `site-guest.v1.css`. Flutter `GuestSiteView` paints the matching `BoxDecoration` or the existing backdrop painter from `site_backdrop.dart`.
- [ ] **C2.4** Global card style maps to the CSS variables above. Flutter cards use `siteCardDecorationResolve` with the same id and params.
- [ ] **C2.5** Extend the Rust test: rendered HTML contains `--accent:#` from the fixture and `data-backdrop="glow"` when the fixture backdrop is glow. Widget test finds a `GuestSiteBackdrop` with the same id.

## Wave 3 — Profile, links, products

- [ ] **P3.1** `hub_profile` HTML and `GuestSiteHubProfileBlock` read `design.profile`: avatar size, outline, title size and align, bio size and align, `showAvatar`, `showTitle`, `showBio`, `showLocation`, `showHours`. Hidden flags omit the node (`data-guest="profile"` stays).
- [ ] **P3.2** `links` honor `blocks` entry `link`. `cardStyleId == "none"` renders rows without a card. Otherwise the row uses that card or the global card.
- [ ] **P3.3** `product_grid` applies `design.product` title, subtitle, and price (size, weight, italic, underline, color) in both the Rust inline style and `guestSiteProductTextStyle`. Card chrome uses the `site_product` block override the same way links do.
- [ ] **P3.4** Rust test: profile with `showAvatar: false` has no `<img` inside `[data-guest=profile]`. Link override `none` has no `class="card"`. Product title style contains the fixture font size.
- [ ] **P3.5** Widget test: same three assertions via finders (`find.byKey(Key('guest-profile-avatar'))` absent, link card key absent, product title style size).

## Wave 4 — Featured partner and client strips

- [ ] **F4.1** Boot includes `featured_contacts: [{ id, name, pic, featured }]` from `site.contact` rows whose `meta_json.featured` is `partners` or `clients`. Do not add a SQL column.
- [ ] **F4.2** New arms `partners_display` and `clients_display` in `block_html_render` and `guestSiteBlock`. Header, label, align, item mode (`card`, `icon`, `icon_label`) come from `design.partners` / `design.clients`.
- [ ] **F4.3** Empty list still renders the header when the block is on the page. Both sides use `data-guest="partners"` or `data-guest="clients"`.
- [ ] **F4.4** Fixture test: one partner contact produces one item under the partners header and zero under clients.

## Wave 5 — Effects editor and persistence

- [ ] **E5.1** Add `effects` to `SiteDesignStore` (`id`, `presetId`, `params`, `active`), load and save inside `theme_json`, same shape as CSA `_designEnvelope` effects.
- [ ] **E5.2** Copy `presets.json` to `clients/app/assets/effects/presets.json` and register it in `pubspec.yaml`.
- [ ] **E5.3** Replace `UiSiteEffectsEditor` with the CSA master/detail section: list, add from preset picker, enable switch, param sliders, delete. Wire it in `ui_site_editor_shell.dart` the same way Design is wired (`masterDetail`, detail id, save bus, `onDraftSaved`).
- [ ] **E5.4** Widget test: adding preset `rain_shower` calls the store and `toThemeJson` contains `"presetId":"rain_shower"`.
- [ ] **E5.5** Boot JSON `effects` is that array. Rust test asserts the fixture effect is present and inactive effects are still listed (the host skips paint).

## Wave 6 — Effects paint, both hosts

- [ ] **X6.1** Port `widgets/overlay_effect/` (stack, host, particle painter, the twelve runners) into `clients/app/lib/widgets/overlay_effect/`. `GuestSiteView` stacks `UiOverlayEffectStack` under the block column and above the backdrop. Pointers hit the page, not the effect layer (`IgnorePointer` unless the preset doc says otherwise).
- [ ] **X6.2** Web host `site-guest.effects.js` reads `window.__SITE_BOOT__.effects`, keeps active presets, and draws on a full-viewport canvas behind `.wrap`. Preset ids that have no runner are skipped, not thrown.
- [ ] **X6.3** Web drawing uses `crates/overlay_effects` built to wasm (CSA crate copied under `servers/crates/overlay_effects` or `clients/web/effects`). Flutter keeps the ported CustomPainters for this wave so the phone matches the CSA app. A follow-up may point Flutter at the same crate through FFI. Until then, preset id, params, and active flag are the parity contract, and a painter exists on both sides for every id in `presets.json`.
- [ ] **X6.4** Test: boot with `rain_shower` active makes Flutter find `UiOverlayEffectStack` with that preset id. The JS host unit test (node or rust wasm test) returns a non-empty frame buffer for the same preset after one tick. Unknown preset id yields an empty layer on both.

## Wave 7 — Check

- [ ] **V7.1** `cd servers; cargo test -p mod_site guest_design`
- [ ] **V7.2** `cd clients/app; flutter test test/guest_site_design_test.dart`
- [ ] **V7.3** `powershell -NoProfile -File .\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` from the repo root. If git writes a line-ending warning to stderr, pass the new file paths with `-Files` instead of `-Changed`.
- [ ] **V7.4** Manual: open the site in the screenshot, Design → Theme (dark swatch), Profile (hide avatar), Products (larger price), Effects → Rain. Phone preview and the published page show the same accent, hidden avatar, price size, and rain behind the blocks.

Do not commit unless the user asks.
