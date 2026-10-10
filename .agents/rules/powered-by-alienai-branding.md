# Powered by alienai.id branding

Mirrored for Cursor: [`.cursor/rules/powered-by-alienai-branding.mdc`](../../.cursor/rules/powered-by-alienai-branding.mdc)

## Copy and icon

- **Never** use plain "Powered by AlienAI", "Alien AI", or "alien ai" in product attribution.
- **Always:** `Powered by` + **black alien icon** (`assets/icons/alien_receipt.svg`) + **`alienai.id`** (lowercase, no spaces).
- Flutter: reuse `UiPoweredByAlien` (`clients/app/lib/widgets/sites/ui_powered_by_alien.dart`).
- PDF / ESC-POS: `ReceiptBranding` + rasterized receipt icon.
- Server HTML: `html_powered_by_alienai_footer` in `servers/crates/mod_site/src/render.rs`.

## Links

- **Screen HTML / Flutter:** only **`alienai.id`** is tappable → `https://alienai.id`.
- **Print / thermal / PDF / static images:** no URLs — icon + `alienai.id` text only.

## Layout

Single horizontal row, centered in footers: muted "Powered by", ~14px icon, bold `alienai.id`.
