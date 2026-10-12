# Site reservation CSA gaps — multitask (2026-10-12)

**Goal:** Close functional gaps vs `D:\csa_site_published` while keeping c35 architecture (`site.object`, `guest-reservation/availability`, `tx_item_reservation.site_object_id`, no Alpine).

**Already shipped:** Tasks 1–9 in [`2026-10-08-site-reservation-objects-guest-sheet.md`](2026-10-08-site-reservation-objects-guest-sheet.md).

## Gaps

| ID | Gap | Status |
|----|-----|--------|
| G1 | Capacity without named units (`reservation_inventory_mode`, `reservation_capacity`) | **done** — `guest_reservation.rs` + `guest_product.rs` |
| G2 | Multi-unit guest picks (`assignments[]`) | **done** — [Multi-unit guest picks UI](d23eadf4-9f0f-4622-b0fd-a4718370dc22) (Flutter + JS) |
| G3 | Unpaid hold TTL (`reservation_hold_ttl_seconds`, default 3600) | **done** — overlap SQL ignores stale `waiting_payment` / `pending` / `draft` |
| G4 | Prompt-first setup | **done** — `inst.site.reservation` seed; live `inst_put` |
| G5 | Docs / plan hygiene | **done** — `site-guest-components.md` |

## Verify

```powershell
cd servers
cargo test -p c35_mod_site
cargo test -p c35_mod_tx
cd ..\clients\app
flutter test test/guest_site_reservation_cart_test.dart test/site_reservation_math_test.dart
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```
