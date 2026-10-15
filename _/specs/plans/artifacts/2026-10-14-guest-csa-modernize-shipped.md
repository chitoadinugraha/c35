# Guest CSA modernize — Track E shipped (2026-10-14)

Multitask wave: web + Flutter guest renderer parity (Grosir / store layout).

## Shipped

| Area | What |
|------|------|
| **Atmosphere** | Full-page `guest-backdrop` stack; hero no longer uses a local gradient box (fixes cropped header wash). |
| **Catalog** | Store search input (`guest-catalog-search`) when `guest_layout: store` or 9+ products; category chips; 2-line title clamp; in-cart row highlight + qty badge. |
| **Hub chrome** | `guest-hub-actions`: Akun (`#c35-guest-hub-member`), share; sticky member control; orders chip gated by portal or local orders. |
| **Commerce** | CSA-style order sheet (handle, card, qty pill); tile tap opens `+ Pesan` / order flow. |
| **Composition** | Skip duplicate `hero` when `hub_profile` exists; hub Shop/Posts tabs (Flutter + web where catalog track landed). |
| **Boot** | `member_portal_enabled` on `__SITE_GUEST__`; `guest_layout` on published script. |

## Track E (tests / docs)

| Area | What |
|------|------|
| **Rust** | `guest_parity_test.rs` — store search markup, hub member/share actions, chrome HTML, hero dedup; fixture `guest_parity_product_grid_store.json` |
| **Flutter** | `guest_site_view_test.dart` — layout mode, member portal flag, hero dedup, hub tabs, category chips; design test sticky title tolerance |
| **Spec** | [`site-guest-components.md`](../../site-guest-components.md) — store catalog table, boot keys, hero dedup |

## Follow-up plans

- **Atmosphere (all sites):** [`2026-10-14-site-guest-atmosphere-dual-renderer-parity-multitask.md`](../2026-10-14-site-guest-atmosphere-dual-renderer-parity-multitask.md) — full-page backdrop + transparent hero on Flutter preview to match web.

## Gaps (remaining)

- **`member_portal_enabled`**: published inline `__SITE_GUEST__` only; Flutter preview reads `capabilities.member_portal` (same rule, different boot shape).
- **Server-side catalog `q`**: client filter on tiles only; no `guest-product/list` search param yet.
- **E2E**: hard-refresh published site after `publish_server` to pick up `site-guest.v1.js` + HTML.

## Verify

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site --test guest_parity_test --test guest_design_test --test render_test

cd D:\c35\clients\app
flutter test test/guest_site_view_test.dart test/guest_site_design_test.dart

clients\web\static\site-guest\build.ps1
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```
