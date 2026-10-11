# Site guest dual renderer — app preview canonical

Mirrored from [`.cursor/rules/site-guest-dual-renderer-parity.mdc`](../../.cursor/rules/site-guest-dual-renderer-parity.mdc).

Plan: [`_/specs/plans/2026-10-11-site-preview-web-renderer-parity-multitask.md`](../../_/specs/plans/2026-10-11-site-preview-web-renderer-parity-multitask.md). Catalog: [`_/specs/site-guest-components.md`](../../_/specs/site-guest-components.md).

## Hard rule

c35 has **two** guest renderers: Flutter **`GuestSiteView`** (`clients/app/lib/guest_site/`) and published **HTML + `site-guest.v1.js/css`** (`mod_site::render`, static bundle). They must show the **same** blocks, chrome, and commerce UX from the **same boot JSON**.

**Canonical reference is the app preview.** If Flutter and web disagree, **fix web** (Rust render + guest static assets) unless boot assembly is wrong for both.

Do **not** “fix” preview with a WebView of the published page.

## When you change the app guest renderer

If you edit `clients/app/lib/guest_site/**` or guest preview design in `c/site/design/**`, in the **same change**:

1. Update the web counterpart (`render.rs`, `guest_design.rs`, `site-guest.v1.*`).
2. Extend parity tests (`guest_design_test.rs` / `guest_parity_test.rs` / `guest_site_*.dart`).
3. Update `site-guest-components.md` if block types or boot keys change.

## Counterpart map

| App | Web |
|-----|-----|
| `guest_site_blocks.dart` | `block_html_render` |
| `guest_site_view.dart` | `guest_shell_html`, `site-guest.v1.css` |
| `guest_site_boot.dart` | `site_boot.rs`, `__SITE_GUEST__` |
| cart / reservation Dart | `site-guest.v1.js` |
| `guest_site_effect_stack.dart` | `site-guest.effects.v1.js` |

## Verify

`cargo test -p mod_site guest_design`; `flutter test test/guest_site_design_test.dart test/guest_site_view_test.dart`; rebuild site-guest after JS/CSS edits.
