# Guest atmosphere dual-renderer parity — shipped (2026-10-14)

Plan: [`2026-10-14-site-guest-atmosphere-dual-renderer-parity-multitask.md`](../2026-10-14-site-guest-atmosphere-dual-renderer-parity-multitask.md)

## Shipped

| Wave | What |
|------|------|
| **0–1** | Flutter full-page atmosphere stack, transparent hero, hub fade |
| **2B** | `backdrop.params` → `--backdrop-intensity/softness/scale` on web; Flutter accent wash uses intensity |
| **3–4** | Rust + Flutter atmosphere tests |
| **5–6** | Spec + this artifact |

## Wave 2B files

- `servers/crates/mod_site/src/guest_design.rs` — `backdrop_params`, `backdrop_params_resolve()`
- `servers/crates/mod_site/src/render.rs` — `guest_root_css` backdrop vars
- `clients/web/static/site-guest/site-guest.v1.css` — preset + accent use vars
- `clients/app/lib/c/site/design/site_backdrop.dart`, `guest_site_view.dart`

## Verify

```powershell
cd D:\c35\servers
cargo test -p c35_mod_site --test guest_design_test

cd D:\c35\clients\app
flutter test test/guest_site_atmosphere_test.dart test/guest_site_design_test.dart
```

## Publish (2026-10-14)

| Target | Result |
|--------|--------|
| **Flutter web** | v**297** (`20.297.0`), ~50.3 MiB |
| **c35-server** | `hsg.ocir.io/axr8wqrrukgm/c35-server:latest` pushed; `kubectl rollout status` **timed out** — verify pods |

Republish guest sites in the app after server rollout is healthy.
