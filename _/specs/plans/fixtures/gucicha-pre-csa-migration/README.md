# gucicha pre-CSA migration baseline

| Field | Value |
|-------|--------|
| `site_iid` | `101836119014211584` |
| `alien_id` | `gucicha` |
| `owner_iid` | `101254393898319872` |
| `product_count` | **10** (2026-10-15) |

Regression: `.\_\scripts\dev\site_gucicha_inventory.ps1` must report `product_count=10` after editor/renderer work.

Boot fixtures: capture via `site.boot_get` into `mod_site/tests/fixtures/gucicha_boot_*.json` (Wave G2).
