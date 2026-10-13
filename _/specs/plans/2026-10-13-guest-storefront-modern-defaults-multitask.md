# Guest storefront modern defaults — multitask plan

**Goal:** Published guest sites (web HTML + in-app preview) feel **2024+** — better defaults, editor presets, and tokens that reach CSA parity without re-scoping platform `index.html`.

**Related:** [2026-10-12-site-modern-design-csa-parity.md](2026-10-12-site-modern-design-csa-parity.md) (glass + platform landing). Dual renderer: [`site-guest-components.md`](../site-guest-components.md).

---

## Completed waves

| Wave | Track | Status | Notes |
|------|-------|--------|-------|
| Ship | Guest renderer v4 | done | `GUEST_RENDERER_VERSION = 4`; lazy regen on visit |
| Ship | `guest_theme_modernize.rs` | done | Render-time uplift + `default_modern_hub_theme` |
| Ship | Hours hub CTA, links heading | done | See commit `21a4f77` + v4 render |
| Ops | `site_guest_render_batch_refresh.ps1` | done | `-ListOnly` / `-Ping` |
| Docs | `refresh-look.md` en/id | done | Publish vs renderer bump |
| Docs | `site.md` + renderer rule v4 | done | Cluster generation **4** |
| CSA P1 | Platform landing | done | Starry + glass + platform grid in `clients/web/index.html` |
| CSA P3 | Cart / sheets CSS + Flutter bar | done | `site-guest.v1.css`, `guest_site_cart.dart` tests |

---

## Wave 2–5 (storefront polish — optional follow-up)

| Track | ID | Status |
|-------|-----|--------|
| Card CSS vars on web | W1 | open — ensure `--card-*` consumed everywhere |
| Flutter card parity | F1 | open — shadow/border vs web |
| Typography tokens | T1–T3 | partial — Inter/Outfit, section eyebrow |
| Hub layout tokens | H1–H3 | partial — sticky CTA doc in components spec |
| Dark glass preset | G1–G2 | partial — `guest-tone-dark` + `guest-card-glass` in CSS |

---

## Verification

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site
cargo build -p server_ai

cd D:\c35\clients\app
flutter test test/guest_site_cart_test.dart test/site_theme_modernize_test.dart

.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

---

## Locked rules

1. **Dual renderer:** App preview is canonical; fix web/CSS when parity drifts.
2. **Renderer bump:** Only when compile output changes; then `publish_site_guest_renderer_version.ps1`.
3. **Product titles:** Do not force `text-transform` on merchant product names in generic CSS.
