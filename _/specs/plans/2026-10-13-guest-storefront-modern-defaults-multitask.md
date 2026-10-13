# Guest storefront modern defaults & customization — multitask plan

**Goal:** Make published guest sites (web HTML + in-app preview) feel **2024+ catalog / link-in-bio**, not flat 2010s templates — through **better defaults**, **editor presets**, and **theme tokens that actually reach CSS**, while keeping dual-renderer parity ([`site-guest-components.md`](../site-guest-components.md), [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc)).

**Related:** [`2026-10-12-site-modern-design-csa-parity.md`](2026-10-12-site-modern-design-csa-parity.md) (CSA glass + platform landing). This plan focuses on **storefront defaults**, **SiteDoc `theme`**, and **`guest-tone-light` / `guest-tone-dark`** — not re-scoping platform `index.html`.

**Reference site:** `natepaperie` (light mono, `card.radius` 8, outline `#C4C7C5`) — fixes should lift it without manual republish of every token.

---

## 0. Already shipped (baseline — do not redo)

| Item | Where |
|------|--------|
| Hours as hub CTA (`Open until …`) | `guest_schedule.rs`, `site_schedule_status.dart`, `render.rs`, `guest_site_hours.dart` |
| `guest-tone-light` + Inter on non-dark HTML | `render.rs`, `site-guest.v1.css` |
| Grouped link list, soft product cards (CSS override) | `site-guest.v1.css`, partial Flutter in `guest_site_blocks.dart` |
| Catalog filter `hidden` + chip styling | `site-guest.v1.js`, CSS |

Existing sites **keep saved theme JSON** until migration or re-save; CSS overrides help but **editor defaults + token wiring** are the durable fix.

---

## 1. Why sites still look dated

| Signal | Cause today |
|--------|-------------|
| Small sharp cards (8px) | `SiteCardStylePreset` solid default `radius: 8`; Rust `default_radius("solid")` → `8.0` ([`guest_design.rs`](../../servers/crates/mod_site/src/guest_design.rs), [`site_card_style.dart`](../../clients/app/lib/c/site/design/site_card_style.dart)) |
| Gray hairline borders | Palette `outline` baked into `--card-border` (e.g. mono light `#C4C7C5`) — no opacity mix on web |
| System-only typography | Theme `profile.titleFontFamily` / product fonts often empty; only HTML gets Inter via global link |
| “Link” + plain H2 sections | Block titles are raw `h2`; no editor preset for “hide title” / “eyebrow label” |
| ALL CAPS product names | Product **data**, not renderer — document + optional `text-transform` token |
| Flat hub band | `guest-tone-light` gradient is CSS-only; Flutter preview still diverges on spacing/shadows |
| Card params ignored on web | Editor exposes `shadow`, `borderWidth`, `borderOpacity`, `padding` — **web CSS mostly ignores** `card.params` except radius in inline `--card-radius` |
| Dark glass CSA look | Separate track; `glass` card style exists in editor but web parity incomplete |

---

## 2. Customization surface (what operators can already tune)

Document in plan; wire missing pieces in implementation tracks.

### Site theme (`SiteDoc.theme` → `GuestDesign`)

| Area | JSON / keys | Editor UI | Web today | Flutter preview |
|------|-------------|-----------|-----------|-----------------|
| Palette | `base`, `dark`, `accent` | Theme picker | `:root` tokens | `SiteResolvedDesign` |
| Page background | `background.type/color/url` | Design → Background | `page_bg`, backdrop | Same |
| Backdrop effect | `backdrop.id` | Backdrop | `data-backdrop`, effects JS | `GuestSiteEffectStack` |
| Global card | `card.id`, `card.params.*` | Card style | Partial (`radius`, solid fill) | `siteCardWrap` |
| Per-block card | `blocks[].cardStyleId`, `params` | Per-block override | `design.card_wrap(block)` | `cardFor(block)` |
| Hub profile | `theme.profile.*` | Hub section | Inline styles on title/bio/avatar | `SiteProfileDesignDraft` |
| Product typography | `theme.product` or `meta.product_design` | Product design editor | Inline on h3/p/price | Dart typography |
| Featured strips | `partners`, `clients` | Strip design | `featured_strip_html` | `GuestSiteFeaturedStripBlock` |
| Layout width | `meta.guest_layout` `hub` / `store` | Auto or site meta | `guest-layout-*` body class | `GuestSiteBoot` |

### Hub block props (`hub_profile`)

| Prop | Purpose |
|------|---------|
| `title`, `subtitle`, `pic` | Hero copy / logo |
| `cta_label`, `cta_href` | Contact pill when hours off |
| `show_hours` | Hours as primary CTA when `meta.open_hours` set |
| `location_label` | Location chip |

### Links block

| Prop | Purpose |
|------|---------|
| `title` | Section eyebrow (often literal `"Link"`) |
| `links[].display` | `list` \| `card` \| `icon` |
| `links[].icon`, `label`, `url` | Row content |

### Product grid

| Prop | Purpose |
|------|---------|
| `title`, `filter`, `category`, `display`, `limit` | Catalog chrome |

### Not in theme (product content)

- Product `name` / `desc` casing, photos, categories — POS/catalog, not guest renderer.

---

## 3. Proposed “Modern” defaults (new sites & one-click preset)

Apply on **new site seed**, **“Modern storefront” theme preset**, and optional **migration** for light hub sites.

| Token / setting | Legacy default | Modern default | Rationale |
|-----------------|----------------|----------------|-----------|
| `card.id` | `solid` | `elevated` or `solid` | Elevated reads cleaner for catalogs |
| `card.params.radius` | `8` | **`16`** | Current mobile catalog norm |
| `card.params.shadow` | `1` | **`2`** | Visible depth without glass |
| `card.params.borderWidth` (solid) | `1` | **`0`** or `0.5` | Borderless + shadow |
| Palette outline usage | 100% `#C4C7C5` | **`outline` at 35–45% opacity** in CSS | Softer edge (computed, not hex) |
| `profile.avatarSize` | `72` | **`88`** | Link-in-bio proportion |
| `profile.titleFontSize` | `18` | **`22`** | Clear hierarchy |
| `profile.bioFontSize` | `12` | **`14`** | Readable tagline |
| `profile.titleFontFamily` | `""` | **`Inter`** (or inherit site font) | Match web font link |
| HTML body class | — | **`guest-tone-light`** / **`guest-tone-dark`** | Already on web; mirror in Flutter shell |
| `meta.guest_layout` | auto | **`store`** when ≥9 products (unchanged) | Wider grid — keep |
| Links `display` default in templates | `list` | **`list`** in grouped card chrome | Editor default block JSON |
| Section titles | User text `"Link"` | Template **`""`** or localized eyebrow | Less boilerplate |
| Product title transform | — | optional `theme.product.titleTransform`: `none` \| `uppercase` | Fix shouty caps without renaming SKUs |
| Typography stack | system | **`Inter`** light / **`Outfit`** dark glass track | Split by `guest-tone-*` |

**Dark “Modern glass” preset** (CSA-aligned): `card.id: glass`, `dark: true`, `backdrop: glow`, defaults from [`2026-10-12-site-modern-design-csa-parity.md`](2026-10-12-site-modern-design-csa-parity.md) — separate preset id `modern-glass-dark`.

---

## 4. Multitask waves

Dispatch **one subagent per track**; each track touches **Rust + CSS and/or Dart** when it affects appearance. Run `verify-after-edit.mdc` per track.

### Wave 1 — Defaults & presets (highest ROI)

| Track | ID | Work |
|-------|-----|------|
| **D1** | `modern-theme-preset-flutter` | Add `modern-light` / `modern-glass-dark` entries in [`site_theme.dart`](../../clients/app/lib/c/site/design/site_theme.dart) + [`site_card_style.dart`](../../clients/app/lib/c/site/design/site_card_style.dart) defaultValue bumps; “Apply Modern preset” button in [`ui_site_design_section.dart`](../../clients/app/lib/widgets/sites/editor/design/ui_site_design_section.dart). |
| **D2** | `modern-theme-preset-rust` | Mirror defaults in `GuestDesign::from_value`, `default_radius`, `guest_root_css`; new sites seed in `inst.sql` / site create tool use modern-light. |
| **D3** | `theme-migration-optional` | Script or `site.draft` one-shot: if `theme.version < 2` and `!dark`, bump radius 8→16, shadow, clear harsh border width; **opt-in** “Upgrade look” in editor. |

**Exit:** New site from template matches Nate-quality look without manual sliders; `guest_design_test` updated.

### Wave 2 — Wire card params to web CSS

| Track | ID | Work |
|-------|-----|------|
| **W1** | `card-params-css-vars` | Emit `--card-shadow`, `--card-border-width`, `--card-border-opacity`, `--card-padding` from `GuestDesign::card_chrome` in `guest_root_css` / inline `card` style. |
| **W2** | `site-guest-css-consume` | Replace hardcoded shadows in `site-guest.v1.css` + `render.rs` critical CSS with vars; reduce `guest-tone-light` `!important` overrides where tokens suffice. |
| **F1** | `flutter-card-parity` | Ensure `siteCardWrap` reads same params for shadow/border (already partial). |

**Exit:** Moving “Roundness” / “Shadow” in editor changes published HTML visibly.

### Wave 3 — Typography & section chrome

| Track | ID | Work |
|-------|-----|------|
| **T1** | `font-theme-token` | `theme.typography.fontFamily` → `:root --guest-font`; conditional font link (Inter vs Outfit); Flutter `ThemeData.fontFamily`. |
| **T2** | `section-eyebrow` | Shared class `.guest-section-eyebrow` for `links-block-title`, `product-grid-title`; editor toggle `show_section_title` on blocks. |
| **T3** | `product-title-transform` | Optional `product_design.title_transform` in meta + CSS `text-transform` on `.product-card h3`. |

**Exit:** Nate-style uppercase product names optional; section labels consistent.

### Wave 4 — Hub & layout polish (parity)

| Track | ID | Work |
|-------|-----|------|
| **H1** | `hub-flutter-web-parity` | Extract shared spacing tokens; Flutter hero matches `guest-tone-light` (full-bleed, avatar shadow, CTA pill). |
| **H2** | `hub-customization` | Expose `hub_gradient_strength`, `hub_avatar_size` in profile design (already partial); document in [`site-guest-components.md`](../site-guest-components.md). |
| **H3** | `sticky-cta-earlier` | Sticky bar visible after smaller scroll threshold; label from hours or first link. |

### Wave 5 — Dark glass (CSA) — optional parallel

| Track | ID | Work |
|-------|-----|------|
| **G1** | `guest-tone-dark-css` | `body.guest-tone-dark` glass surfaces, blur, border glow (from CSA plan Phase 2–3). |
| **G2** | `glass-card-web` | Implement `card.id === glass` params (`blur`, `opacity`, `tintStrength`) in CSS `backdrop-filter`. |

### Wave 6 — Verification & docs

| Track | ID | Work |
|-------|-----|------|
| **V1** | `guest-parity-screenshots` | Extend `guest_parity_test` / fixture HTML for `modern-light` theme snapshot strings. |
| **V2** | `docs-user-guide` | Short `_/docs` article: “Refresh your site look” — Apply Modern preset, publish, compare draft URL. |
| **V3** | `natepaperie-fixture` | Add `guest_parity_natepaperie_light.json` regression from real block tree. |

---

## 5. Locked rules

1. **Dual renderer:** Any visible token change → `render.rs` + `site-guest.v1.css` + `guest_site_blocks.dart` (and cart/hours if touched).
2. **Published HTML:** Compiler-only changes bump [`guest_renderer_version`](../../servers/crates/mod_site/src/guest_renderer.rs); theme JSON changes require **Publish** only.
3. **Do not** change product DB casing in migration; use transform token or editor guidance.
4. **Light vs dark:** Modern defaults apply to **light** first; dark glass is preset `modern-glass-dark`, not forced on all sites.

---

## 6. Suggested execution order

```text
Wave 1 (D1 + D2 parallel) → Wave 2 (W1 then W2) → Wave 3 (T1, T2 parallel)
→ Wave 4 (H1) → Wave 6 (V1) → ship
Wave 5 (G1/G2) only if dark CSA parity is still a priority
```

**Quick win for Nate (no migration):** Operator selects **Modern Light** preset in editor → Publish. After Wave 2, slider tweaks apply on web.

---

## 7. Test plan (per wave)

| Check | Command / action |
|-------|------------------|
| Rust design + render | `cd servers && cargo test -p c35_mod_site` |
| Flutter preview | `.\_\scripts\dev\verify_flutter_app.ps1` |
| Live draft | `http://localhost:10000/{alien_id}?draft=1` — body has `guest-tone-light`, Inter, 16px cards after preset |
| Parity | In-app Draft vs `?draft=1` side-by-side (hub, links, grid, cart) |

---

## 8. Open questions (resolve in Wave 1 kickoff)

1. **Auto-migrate** existing published sites on guest renderer version bump, or **editor-only** “Upgrade look”?
2. **Single font** (Inter only) vs **Outfit for dark glass** — confirm brand typography doc.
3. Should **empty link section title** hide the eyebrow row (breaking sites that rely on `"Link"`)? Default new templates to empty; keep old behavior if title non-empty.
