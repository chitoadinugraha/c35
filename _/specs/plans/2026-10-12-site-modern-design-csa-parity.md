# Modern Site Design & Dual-Renderer Parity Plan: c35 vs CSA

**Goal:** Transform `c35`'s storefront and platform landing UI from a rudimentary appearance into a polished, modern, glassmorphic design system matching `D:\csa_site_published`, ensuring that **Web HTML (`render.rs` + CSS/JS)** and **Flutter Widget Preview (`GuestSiteView` / `guest_site_blocks.dart`)** are visually and behaviorally **identical**.

---

## 1. Locked Decisions & Parity Architecture

| Principle | Locked Specification |
| :--- | :--- |
| **Dual Renderer Parity** | `site.boot_get` JSON is the **single source of truth** for both Flutter (`GuestSiteView`) and Web (`mod_site::render` prerender HTML + `site-guest.v1.js`). Every token and block spacing change must be applied to both. |
| **Design Language** | Dark glassmorphic aesthetic (`Outfit` / `Inter` typography, `-webkit-backdrop-filter: blur(20px)`, subtle 1px border glows, tabular figures for currency, micro-interactions on hover and tap). |
| **No Breakages** | Preserve WebSocket protobuf contracts (`ReqSite*`, `site.boot_get`, `site.draft`) and guest order submission protocols. |

---

## 2. Phase 1 — Platform Landing & Public Portal Modernization

Bring `clients/web/index.html` to direct parity with `D:\csa_site_published\public\index.html`.

- [x] **Track L1: Typography & Starry Backdrop**
  - Import `Outfit:wght@300;400;600;700` into `clients/web/index.html`.
  - Connect full-bleed 2D canvas stars (`starry-night.js`).
- [x] **Track L2: Main Glassmorphic Card & Floating Hero Logo**
  - Implement `.card` with `background: rgba(20, 21, 28, 0.45)`, `backdrop-filter: blur(20px)`, and `border: 1px solid rgba(255, 255, 255, 0.08)`.
  - Add floating keyframe animation for Alien logo (`float 6s ease-in-out infinite`).
- [x] **Track L3: Custom Release & Version Selector Dropdown**
  - Implement `#custom-dropdown` with chevron rotation, smooth popover, and option selection matching CSA `index.html`.
- [x] **Track L4: Platform Cards Grid (Windows, Android, Web)**
  - Implement responsive 3-column `.platform-grid` with `.card-win`, `.card-android`, and `.card-web`.
  - Add platform-specific glow hovers (`--glow-win`, `--glow-android`, `--glow-web`).

---

## 3. Phase 2 — Storefront Card & Product Tile Parity (Flutter & Web)

Make product cards, links, and profile headers look modern and identical across both renderers.

- [ ] **Track P1: Flutter Product Tile & Ink Micro-Interactions (`guest_site_blocks.dart`)**
  - Align `_productListRow` and `_productCard` with CSA's `_ProductTile` & `_productCardInk`:
    - Rounded corners (`12px`), subtle border (`1px solid var(--border)`), hover elevation.
    - Currency with tabular figures (`FontFeature.tabularFigures()`).
    - In-cart badge indicator with smooth scale transition.
- [ ] **Track P2: Web HTML Product Cards (`mod_site/src/render.rs` & `site-guest.v1.css`)**
  - Update `product_card_html` and `product_list_row_html` to output matching DOM structure with `.guest-product-tile`.
  - Style with CSS glass cards, hover lift (`transform: translateY(-2px)`), and badge highlights.
- [ ] **Track P3: Profile Block / Hero Banner**
  - In Flutter (`GuestSiteHeroBlock` / `GuestSiteHubProfileBlock`) and Web (`guest_hub_hero_inner_html`), support gradient avatar outline rings (`avatarOutlineWidth`, `avatarOutlineColor`) and clean typography hierarchy.

---

## 4. Phase 3 — Sticky Cart & Checkout Bar Polish

- [x] **Track C1: Modern Floating Cart Summary Bar**
  - **Flutter (`guest_site_cart.dart` - `GuestSiteCartChrome`)**: Update `guest-cart-bar` with floating elevation, `surfaceContainerHigh` or `#18181B` backdrop, tabular price text, item pill badge, and accent CTA button.
  - **Web (`site-guest.v1.css`)**: Style `.guest-cart-row` and `.guest-cart` with matching padding, rounded pill geometry (`16px`), glass shadow (`0 8px 28px rgba(0,0,0,0.25)`), and smooth slide-up animation.
- [x] **Track C2: Order & Reservation Sheets**
  - Ensure slide-in sheets (order note input, quantity counters, slot pickers) have matching rounded corners (`24px` top radius), scrim backdrop blur, and dark surfaces.

---

## 5. Phase 4 — Verification & Dual-Renderer Testing

- [ ] **Test V1: Flutter Widget Preview & Tests**
  - Run `flutter test clients/app/test/guest_site_view_test.dart` and `guest_site_design_test.dart`.
  - Run `flutter analyze clients/app`.
- [ ] **Test V2: Rust Server HTML Render Tests**
  - Run `cargo test -p mod_site` to verify `guest_design_test` and `site_db_test`.
- [ ] **Test V3: Visual Parity Check**
  - Compare rendered HTML on `localhost:10000/{alien_id}` with in-app phone preview (`UiSitePreviewStage`).
