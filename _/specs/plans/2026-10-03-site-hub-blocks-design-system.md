# Site Hub Blocks and Guest Design System - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship CSA-quality mobile guest sites using **block-composed SiteDoc only** (hub profile, link stack, commerce, order tracking) with **platform-owned CSS/JS**, **small per-block variants**, and **theme presets**. No `theme.layout` page mode. Customization is **content + allowlisted props per block**, not owner CSS.

**Architecture:** Versioned **hub design system** in `mod_site` (CSS + HTML per block type) plus **guest runtime** bundle (cart, checkout steps, order poll). Extend `site_validate` catalog. `site.create` defaults to **hub template**; inst steers **hub vs landing** as two block stacks. Publish builds `__SITE_BOOT__` when commerce blocks exist.

**Tech Stack:** Rust `mod_site` / `mod_chat` / `mod_tx`, `wire_http`, `clients/web/static/site-guest/`, Flutter `UiSitePreviewCard`, `_/schemas/inst.sql`.

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/site.md`](../site.md) | [`_/specs/site-builder.md`](../site-builder.md) | [`_/specs/site-ai.md`](../site-ai.md) | [`_/specs/tx.md`](../tx.md)

**Reference (HTML/JS only):** `D:\csa_site_published\crates\mod_site\src\render\hub.rs`, `theme.rs`, `boot.rs`; `client/site/src/main.ts`.

---

## Locked design contract

1. Platform owns appearance (HTML, spacing, type, cards, sheets, contrast).
2. Sites customize **per block**: `type` + allowlisted `props` + enum variants only.
3. Theme = tokens / presets (`accent`, `background`, `font`, `text_color` or preset id).
4. **No `theme.layout`** - hub = hub block types on the page.
5. Cart, checkout modal, toasts = injected runtime when `commerce` + `product_grid` (not editable blocks).
6. `custom_html` stays rare; not the default hub path.
7. Preview should match publish (iframe preview token preferred for v1 hub).

---

## Block catalog v1.1

| Block | Purpose | Props / variants |
|-------|---------|------------------|
| `hub_profile` (new) | Avatar, title, bio, chips | `pic`, `title`, `subtitle`, `location_label`, `location_href`, `show_hours` |
| `links` | Link-in-bio | `title`, `links[]` (`label`, `url`, `icon`), `placement`: `list` \| `chip` \| `icon` |
| `product_grid` | Shop | existing props; hub card CSS + cart |
| `order_track` (new) | Guest order status | `title`, `hint` only |
| `contact_form`, `hours`, `spacer` | As today | hub card chrome where applicable |
| `hero`, `markdown`, ... | Landing template only | landing renderer unchanged |

**Templates:**

- **hub** (default `site.create`): `hub_profile` -> `links` -> optional `product_grid` -> optional `contact_form`
- **landing** (`template: "landing"`): `hero` -> `markdown` -> `contact_form`

**Theme presets:** `clean`, `midnight`, `emerald`, `sunset` (resolve to tokens on create / `patch_theme`).

---

## File map

| File | Action |
|------|--------|
| `_/specs/site.md` | Guest design system section |
| `_/specs/site-builder.md` | Hub default + `template` / `theme_preset` |
| `servers/crates/mod_chat/src/site_validate.rs` | Catalog + limits |
| `servers/crates/mod_chat/src/tools/builtin/site.rs` | `site.create` templates |
| `servers/crates/mod_site/src/render/` | Split hub, landing, mod, theme_tokens, boot |
| `clients/web/static/site-guest/site-guest.v1.css` | Hub design system CSS |
| `clients/web/static/site-guest/site-guest.v1.js` | Cart, checkout, lead, tracker |
| `clients/app/lib/widgets/ai/ui_site_preview_card.dart` | Hub blocks |
| `_/schemas/inst.sql` | Hub vs landing steering |
| Tests: `render_test.rs`, `site_tools_test.rs`, `ui_site_preview_card_test.dart` |

---

## Multitask waves

```
WAVE 0  D0   Docs contract (site.md, site-builder.md)
WAVE 1  V1   site_validate catalog + limits
        V2   theme_tokens presets + contrast
WAVE 2  R1   site-guest.v1.css
        R2   hub.rs + landing.rs split
WAVE 3  J1   site-guest.v1.js (cart steps)
        J2   boot.json + script inject on publish
WAVE 4  C1   site.create hub + landing + theme_preset
        C2   inst.site.builder
        C3   Flutter siteCreateDraft align (optional)
WAVE 5  T1   order_track block + guest-order/get
        T2   localStorage + Lacak pesanan from receipt
WAVE 6  P1   UiSitePreviewCard parity
        P2   iframe preview (optional)
WAVE 7  X1   cargo test + utf8 check
        X2   manual E2E checklist
```

Dispatch parallel tracks per `plan-execution.mdc`. Do not commit unless user asks.

---

## WAVE 0 - Docs (Track D0)

- [ ] **D0.1** `_/specs/site.md`: design contract, block table, templates, explicit no `theme.layout`.
- [ ] **D0.2** `_/specs/site-builder.md`: hub skeleton, `template`, `theme_preset`.
- [ ] **D0.3** Optional `spec.md` index line.

---

## WAVE 1 - Validation (V1, V2 parallel)

### V1

- [ ] **V1.1** Add `hub_profile`, `order_track` to `BLOCK_TYPES`.
- [ ] **V1.2** Extend `links` props and link item keys.
- [ ] **V1.3** Max 40 blocks/page, 30 links per `links` block.
- [ ] **V1.4** URL allowlist: http, https, tel, mailto, `#`.
- [ ] **V1.5** `site_tools_test.rs` coverage.

### V2

- [ ] **V2.1** `theme_preset_resolve` (four presets).
- [ ] **V2.2** `theme_css_vars` for guest `:root`.
- [ ] **V2.3** `contrast_check_accent` on publish (warn v1).
- [ ] **V2.4** Unit tests in `mod_site`.

**Verify:** `cargo test -p mod_chat -- site_tools`; `cargo test -p mod_site`

---

## WAVE 2 - Render (R1, R2)

### R1 CSS

- [ ] **R1.1** Port CSA hub classes to `site-guest.v1.css`.
- [ ] **R1.2** Mobile column ~28rem, safe-area, 44px targets.
- [ ] **R1.3** Document CSS version bump in site.md.

### R2 Rust

- [ ] **R2.1** Link CSS; `body.guest-hub`.
- [ ] **R2.2** `hub.rs` partials.
- [ ] **R2.3** `landing.rs` = moved existing blocks.
- [ ] **R2.4** Dispatch by block type.
- [ ] **R2.5** `render_test.rs` snapshots.

**Verify:** `cd servers && cargo build -p server_ai && cargo test -p mod_site`

---

## WAVE 3 - Runtime (J1, J2)

- [ ] **J1.1** Extract cart/lead JS from `render.rs`.
- [ ] **J1.2** Checkout steps: confirm, payment, pay_detail.
- [ ] **J1.3** Payment methods from boot; fallback cash/qris/transfer.
- [ ] **J1.4** Stock from boot products.
- [ ] **J2.1** `boot.rs`: site_iid, name, products, payment_methods, api_base.
- [ ] **J2.2** Inject `__SITE_BOOT__` + deferred JS when commerce or `order_track`.
- [ ] **J2.3** `api.alienai.id` on production guest host.

---

## WAVE 4 - Create and inst (C1-C3)

- [ ] **C1.1** `template`: `hub` (default) | `landing`.
- [ ] **C1.2** Hub default doc blocks.
- [ ] **C1.3** `theme_preset` on create.
- [ ] **C2.1** inst hub default; landing phrases.
- [ ] **C2.2** Steer patch per block; presets for colors.
- [ ] **C2.3** `prompt_compose` smoke phrase.
- [ ] **C3** Flutter `siteCreateDraft` hub blocks + tests.

---

## WAVE 5 - Order tracker (T1, T2)

- [ ] **T1.1** `order_track` UI + `guest-order/get`.
- [ ] **T1.2** TxState to step labels (id-ID).
- [ ] **T2.1** localStorage orders per site_iid.
- [ ] **T2.2** Receipt -> tracker link.

---

## WAVE 6 - Preview (P1, P2)

- [ ] **P1** Flutter hub_profile, links placements, order_track.
- [ ] **P2** WebView preview token (optional).

**Verify:** `.\_\scripts\dev\verify_flutter_app.ps1`

---

## WAVE 7 - Verification

- [ ] **X1** `cargo build -p server_ai`; `cargo test -p mod_site -p mod_chat`; `check_utf8_sources.ps1 -Changed -Fix`
- [ ] **X2** E2E: chat create, publish, mobile hub, cart, track after POS state change

---

## Out of scope

CSA SiteDraft / hub editor UI; `theme.layout`; site subscription quotas; `hub_posts`; full reservations; guest Alien bubble; HR / site_member.

## v2 backlog

`hub_posts`; payment methods admin in site.config; guest login + my orders; effects backdrop block; render_hash pins CSS version.

## Risks

| Risk | Mitigation |
|------|------------|
| render regression | landing extract + snapshots |
| static assets on guest host | verify wire_http |
| bad URLs from LLM | validate on patch |
