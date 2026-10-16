# Google Sheets — format on @device (eye + hand)

Use when **no** `gsheet.format_range` / `browser.sheets.format_range` tool applies (personal sheet on @device Windows Chrome).

## Prefer tools first

| Surface | Tool |
|---------|------|
| Bot-linked sheet (service account) | `gsheet.format_range` |
| Chrome extension browser + open tab | `browser.sheets.format_range` |
| @device PC only | This skill + `device.input` |

## Select the range

1. Close right panels (Themes/Tables) — X near top-right (~x 0.956, y 0.266).
2. Name box: `device.input` batch `[shortcut ctrl+g, type_text A1:C1, shortcut enter]` (adjust range).
3. Or click row/column headers to select.

## Borders

1. With range selected: toolbar **Borders** (grid icon, near Bold ~x 0.72, y 0.25) → **All borders**.
2. Outer only: Borders → **Outer borders**.
3. Verify in post-action screenshot: grid lines visible on selection.

## Number format

- **Currency**: Format → Number → Currency, or `Ctrl+Shift+4` (locale-dependent).
- **Percent**: `Ctrl+Shift+5`.
- **Plain number / thousands**: Format → Number → Number; or `Ctrl+Shift+1` (decimal).
- **Date**: `Ctrl+Shift+3`.

## Text align

- **Center**: Format → Alignment → Horizontal → Center (or toolbar align center).
- **Left / Right**: same menu.
- **Wrap**: Format → Wrapping → Wrap.

## Bold / style

- Select range first (entire header row — not only A1).
- Bold: toolbar **B** (~x 0.665, y 0.251) until active blue pill; toggle rule applies if mixed bold.

## Verification

Do not claim done until `device.screenshot` (som=true) shows borders, alignment, and number display for the target range.
