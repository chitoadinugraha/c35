# Presentation theme catalog

**Status:** implemented 2026-10-03

## Delivered

- `ai.presentation_theme` + seeds in `_/schemas/presentation_theme.sql`
- `GET /v1/catalog/presentation-themes`
- PPTX export passes `theme_tokens` from DB resolve (`presentation_export_exec`)
- Flutter `SlideThemeCatalog` + menu/dialog UX
- Proto: `PresentationThemeItem` in `catalog.proto` (regen Dart pb when needed)

## Test

```powershell
cd servers; cargo test -p c35_mod_chat presentation_theme
cd clients/app; flutter test test/slide_theme_catalog_test.dart test/ui_slide_deck_card_test.dart
```

## Deploy

Run DB migrate so `presentation_theme` applies, then publish server.
