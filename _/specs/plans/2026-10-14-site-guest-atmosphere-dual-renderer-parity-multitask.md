# Site guest atmosphere — dual-renderer parity (all sites)

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline. Subagent **model: inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** For **every** guest site (hub and store, light and dark, all backdrop presets), **Flutter preview** and **published web HTML** show the **same atmosphere**: full-viewport backdrop stack, **no cropped hero gradient box**, hub profile fade into page background, and matching tone tokens — from the **same** `GuestDesign` / theme JSON.

**Architecture:** Web already implements the CSA **`guest-backdrop`** stack in `guest_atmosphere_html` + `site-guest.v1.css`. This plan **locks that stack as the shared contract** and brings **`GuestSiteView`** (`_GuestSiteCanvas`, `GuestSiteHeroBlock`, `GuestSiteHubProfileBlock`) in line. Shared parsing stays **`guest_design.rs`** ↔ `siteDesignResolve` / `site_backdrop.dart`. Do **not** fix preview with a WebView.

**Exception to “app canonical”:** For **atmosphere only**, the **layer model below** is canonical (web + Rust already match CSA). Other guest UX remains **Flutter-first** per [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc).

**Tech stack:** Rust `c35_mod_site` (`render.rs`, `guest_design.rs`); `clients/web/static/site-guest/site-guest.v1.css`; Flutter `guest_site_view.dart`, `guest_site_blocks.dart`, `c/site/design/site_backdrop.dart`.

**Specs (read first):** [`spec.md`](../../spec.md) · [`_/specs/site-guest-components.md`](../site-guest-components.md) · [`2026-10-11-site-preview-web-renderer-parity-multitask.md`](2026-10-11-site-preview-web-renderer-parity-multitask.md)

**Related shipped work:** Track A backdrop (web) · [`2026-10-14-guest-csa-modernize-shipped.md`](artifacts/2026-10-14-guest-csa-modernize-shipped.md)

---

## Global constraints

- Atmosphere changes apply to **home**, **subpages**, **product/post detail**, and **offline** guest shells that call `guest_atmosphere_html` / `_GuestSiteCanvas` — not Grosir-only.
- Preserve **effects** z-order: backdrop → page bg image/overlay → preset → optional accent wash (`backdrop_id == none`) → **content** → `GuestSiteEffectStack` / `site-guest.effects.v1.js`.
- No new SiteDoc block types; behavior is **design + shell** only.
- UTF-8 sources; verify per [`verify-after-edit.mdc`](../../.cursor/rules/verify-after-edit.mdc).
- After Rust/CSS ship: `.\_\scripts\deploy\publish_server.ps1` + per-site **Publish** + hard refresh for live URL parity.

---

## Locked atmosphere contract (all sites)

Render order (bottom → top), fixed `inset: 0`, non-interactive:

| Layer | Web class / markup | Flutter widget (target) | When |
|-------|-------------------|-------------------------|------|
| Page fill | `.guest-backdrop-color` (`--page-bg`) | `ColoredBox(color: resolved.pageBackground)` | Always |
| Bg image | `.page-bg-image` inside `.guest-backdrop` | `_GuestSiteBackgroundImage` | `background.type == image` |
| Bg overlay | (existing overlay on image) | `ColoredBox` overlay on image | `overlay > 0` |
| Preset | `.guest-backdrop-preset--{id}` | `siteBackdropLayer` painters (`glow`…`aurora`) | `backdrop.id != none` |
| Accent wash | `.guest-backdrop-accent` | `GuestSiteAtmosphereAccent` (new, radial) | `backdrop.id == none` |
| Content | `<main>` / scroll column | `GuestSiteEffectStack` child | Always |
| Hub fade | `.block.hub-profile::after` | `GuestSiteHubProfileFade` (bottom gradient to `pageBackground`) | `hub_profile` block |
| **Forbidden** | Local `.guest-hub-hero` / `.block.hero` gradient fills | **Remove** `LinearGradient` on `GuestSiteHeroBlock` | Always |

**Tone:** `--guest-tone` / `body.guest-tone-{light|dark}` on web; Flutter uses `SiteResolvedDesign` / palette `dark` for fg/muted — parity tests assert both read the same theme fixture.

**Legacy:** `body.backdrop-*::before` stays **suppressed** when `.guest-backdrop` exists (web CSS already); Flutter must not duplicate preset on hero.

---

## Gap analysis (today)

| Concern | Web (c35) | Flutter preview | Target |
|---------|-----------|-----------------|--------|
| Full-page backdrop | `guest_atmosphere_html` + fixed stack | `_GuestSiteCanvas` + `siteBackdropLayer` (partial) | Same layer order + accent wash when preset `none` |
| Hub / hero gradient | Transparent `.guest-hub-hero` | `GuestSiteHeroBlock` **local** `LinearGradient` | Transparent hero; atmosphere only from stack |
| Hub profile fade | `.block.hub-profile::after` | None | Match 44px fade |
| Preset intensity | Fixed CSS mixes | `siteBackdropParamsResolve` | **Phase 2:** optional CSS vars from theme `backdrop.params` (both sides) |
| Detail / cart pages | Atmosphere in shell | Same canvas in preview shell | Same stack on all routes |
| Tests | `guest_design_test` backdrop markup | No assertion on hero gradient | Shared fixtures + both test suites |

---

## File map

| File | Responsibility |
|------|----------------|
| `clients/app/lib/guest_site/guest_site_view.dart` | `_GuestSiteCanvas`, new `GuestSiteAtmosphereStack`, wire accent wash |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | Remove hero gradient; hub fade wrapper on `GuestSiteHubProfileBlock` |
| `clients/app/lib/c/site/design/site_backdrop.dart` | Optional: export accent wash helper shared with canvas |
| `servers/crates/mod_site/src/render.rs` | Audit only unless Flutter finds web drift |
| `servers/crates/mod_site/src/guest_design.rs` | Optional: backdrop `params` → CSS custom properties |
| `clients/web/static/site-guest/site-guest.v1.css` | Preset vars if Track 2C; hub/hero comments |
| `servers/crates/mod_site/tests/guest_design_test.rs` | Full-page HTML atmosphere + hub no-gradient |
| `servers/crates/mod_site/tests/fixtures/guest_atmosphere_*.json` | Theme matrix (none + each preset, light/dark) |
| `clients/app/test/guest_site_design_test.dart` | Pump preview; `find.byKey(Key('guest-backdrop'))`; no `LinearGradient` in hero subtree |
| `clients/app/test/guest_site_atmosphere_test.dart` | **New** — preset matrix widget tests |
| `_/specs/site-guest-components.md` | “Atmosphere stack” table + canonical exception |
| `_/specs/plans/artifacts/2026-10-14-guest-atmosphere-parity-shipped.md` | Wave 7 deliverable |

---

## Multitask map

```
WAVE 0  Contract + fixtures (docs + JSON theme matrix)
WAVE 1  Flutter atmosphere (parallel: canvas stack, hero de-gradient, hub fade)
WAVE 2  Web hardening + optional backdrop params → CSS vars (parallel)
WAVE 3  Rust parity tests (full page + presets)
WAVE 4  Flutter parity tests (design + atmosphere matrix)
WAVE 5  Cross-check + manual visual checklist (hub + store samples)
WAVE 6  Docs artifact + publish note
```

Dispatch parallel tracks per wave ([`plan-execution.mdc`](../../.cursor/rules/plan-execution.mdc)). Parent does not implement all tracks inline.

---

## WAVE 0 — Contract & fixtures (parallel)

### Track 0A — Spec: atmosphere stack

- [ ] **0A.1** Add section **“Atmosphere stack (dual renderer)”** to [`_/specs/site-guest-components.md`](../site-guest-components.md) with the locked layer table above and note: atmosphere canonical = this stack (not hero-local gradients).
- [ ] **0A.2** Update [`2026-10-11-guest-csa-identity-gaps.md`](artifacts/2026-10-11-guest-csa-identity-gaps.md) row **Backdrop** — cite this plan; mark hero-local gradient **GAP → in progress** until Wave 4 green.

### Track 0B — Theme fixtures

- [ ] **0B.1** Add `servers/crates/mod_site/tests/fixtures/guest_atmosphere_none_light.json` — `backdrop.id: none`, light palette, store-ish meta optional.
- [ ] **0B.2** Add `guest_atmosphere_glow_dark.json` (or extend `guest_design_min.json` doc) — one file per preset id: `glow`, `mesh`, `grain`, `diamond`, `aurora` (can be single JSON array manifest listing paths).
- [ ] **0B.3** Add `guest_atmosphere_page_bg_image.json` — image background + overlay + preset `none` (accent wash case).

---

## WAVE 1 — Flutter atmosphere (parallel)

### Track 1A — `GuestSiteAtmosphereStack`

- [ ] **1A.1** In `guest_site_view.dart`, extract stack from `_GuestSiteCanvas`: color → image → overlay → preset (`siteBackdropLayer`) → **if** `backdropId == 'none'` insert accent radial (match `.guest-backdrop-accent` geometry: ellipse 130% × 62%, accent 20% at 50% -12%).
- [ ] **1A.2** Keep `GuestSiteBackdrop` / `Key('guest-backdrop')` on the stack root for tests.
- [ ] **1A.3** Ensure scrollable content sits **above** atmosphere (same as web `main` z-index); effects unchanged.

### Track 1B — Hero de-gradient (all sites)

- [ ] **1B.1** Remove `LinearGradient` `BoxDecoration` from `GuestSiteHeroBlock`; use transparent background + existing border-bottom only (match web `.guest-hub-hero`).
- [ ] **1B.2** Confirm standalone `hero` block and `hub_profile` (via embedded hero) both use the same transparent hero — no special case for Grosir.
- [ ] **1B.3** `guest_site_design_test.dart`: for default fixture, `GuestSiteHeroBlock` subtree has no `LinearGradient` (or golden: hero region does not paint accent fill above 5% opacity except CTA chip).

### Track 1C — Hub profile fade

- [ ] **1C.1** Wrap `GuestSiteHubProfileBlock` column in `Stack` with bottom `Positioned` gradient: transparent → `pageBackground`, height **44**, opacity **0.9** (match CSS).
- [ ] **1C.2** Do not reintroduce negative horizontal margins on hub (web keeps hub inside content wrap).

---

## WAVE 2 — Web hardening (parallel)

### Track 2A — Audit web vs contract

- [ ] **2A.1** Walk `guest_shell_html`, `page_html_render`, `guest_storefront_page_html` — confirm `{atmosphere}` on every guest body template; fix any path still injecting `{image}` only.
- [ ] **2A.2** Confirm `guest_root_css` emits `--theme-base`, `--surface`, `--outline`, `--guest-tone`, `--page-bg`, `--accent` for all themes (already Track A); add test if missing.

### Track 2B — Backdrop params (optional, same wave if quick)

- [ ] **2B.1** Parse `theme.backdrop.params` in `GuestDesign` (intensity, softness, scale).
- [ ] **2B.2** Emit CSS variables on `:root` (e.g. `--backdrop-intensity`) and multiply preset opacities in `site-guest.v1.css` via `color-mix` / `opacity`.
- [ ] **2B.3** Confirm Flutter `siteBackdropParamsResolve` uses the same keys — visual spot-check one custom intensity in Products → Design.

### Track 2C — Static build

- [ ] **2C.1** If CSS changes: `clients/web/static/site-guest/build.ps1`; commit `site-guest.v1.css` (+ `.js` if touched).

---

## WAVE 3 — Rust tests (parallel)

### Track 3A — Atmosphere markup

- [ ] **3A.1** `guest_design_test`: `guest_shell_html` / full page render includes `.guest-backdrop`, `.guest-backdrop-color`, and when preset ≠ none `.guest-backdrop-preset--{id}`.
- [ ] **3A.2** When preset == `none`, assert `.guest-backdrop-accent` present.
- [ ] **3A.3** `hub_profile` render: HTML does **not** contain inline hero gradient styles; `.guest-hub-hero` has no background gradient rule in inline styles (class-only).

### Track 3B — Fixture matrix

- [ ] **3B.1** Parametric test over `guest_atmosphere_*.json` fixtures: `GuestDesign::from_theme_json` + `guest_root_css` contains expected `--page-bg` and backdrop id.

---

## WAVE 4 — Flutter tests (parallel)

### Track 4A — Design regression

- [ ] **4A.1** Extend `guest_site_design_test.dart`: finds `Key('guest-backdrop')`; hub site paints without full-width accent box behind avatar (compare `RenderRepaintBoundary` pixel count or assert no gradient in hero `decoration`).
- [ ] **4A.2** Store layout fixture (`guest_layout: store`): catalog section still visible; atmosphere does not clip list.

### Track 4B — Atmosphere matrix (new file)

- [ ] **4B.1** Create `test/guest_site_atmosphere_test.dart` — pump `GuestSiteView` with boot JSON per preset (none, glow, aurora) + dark/light flag; expect stack present; for `none`, expect accent wash widget (semantics or key `guest-backdrop-accent`).
- [ ] **4B.2** Image background fixture: image layer + overlay do not double-stack preset on hero.

---

## WAVE 5 — Cross-renderer verification (parallel)

### Track 5A — Automated

- [ ] **5A.1** Run:

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site --test guest_design_test --test guest_parity_test --test render_test

cd D:\c35\clients\app
flutter test test/guest_site_design_test.dart test/guest_site_view_test.dart test/guest_site_atmosphere_test.dart

cd D:\c35\clients\web\static\site-guest
.\build.ps1

cd D:\c35
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

### Track 5B — Manual visual (all site shapes)

- [ ] **5B.1** **Hub** site: backdrop `none`, light — preview vs draft Visit URL: full-width accent wash, no hero box.
- [ ] **5B.2** **Store** site (9+ products or `guest_layout: store`): same + catalog search visible; atmosphere not clipped at hub bottom.
- [ ] **5B.3** **Dark + glow** preset: preview vs published after publish.
- [ ] **5B.4** **Product detail** route: backdrop visible behind detail chrome (not white void).
- [ ] **5B.5** Record pass/fail screenshots optional in artifact.

---

## WAVE 6 — Ship docs (parallel)

### Track 6A — Artifact

- [ ] **6A.1** Write [`_/specs/plans/artifacts/2026-10-14-guest-atmosphere-parity-shipped.md`](artifacts/2026-10-14-guest-atmosphere-parity-shipped.md) — waves completed, test counts, manual checklist results, publish summary if deployed.

### Track 6B — Index

- [ ] **6B.1** Link this plan from [`2026-10-14-guest-csa-modernize-shipped.md`](artifacts/2026-10-14-guest-csa-modernize-shipped.md) under “Follow-up plans”.

---

## Out of scope (separate plans)

- Link **placements** (`list` / `icon` / `icon_label`) — commerce parity plan §1A.
- Server-side catalog **`q`** search — client filter only today.
- Post **carousel**, reservation CSA markup — identity gaps doc.
- **`member_portal_enabled`** boot shape — member portal multitask plan.

---

## Subagent dispatch cheat sheet

| Wave | Tracks | Can run together |
|------|--------|------------------|
| 0 | 0A, 0B | Yes |
| 1 | 1A, 1B, 1C | Yes (touch different widgets; merge `guest_site_view` / `guest_site_blocks` carefully) |
| 2 | 2A, 2B, 2C | 2C after 2B if CSS changes |
| 3 | 3A, 3B | Yes |
| 4 | 4A, 4B | Yes |
| 5 | 5A, 5B | 5B after 1–4 |
| 6 | 6A, 6B | After 5A green |

**Suggested first dispatch (Wave 1):** three subagents — [1A Canvas stack], [1B Hero de-gradient], [1C Hub fade] — then parent resolves merge conflicts in `guest_site_view.dart` / `guest_site_blocks.dart`.

---

## Success criteria

1. For any site theme in the fixture matrix, **automated** Rust + Flutter tests pass.
2. Manual checklist **5B** passes for hub, store, dark+glow, and product detail.
3. No `LinearGradient` accent wash on `GuestSiteHeroBlock`; atmosphere comes only from the shared stack.
4. Live published URL matches preview after publish (ops step documented in artifact).
