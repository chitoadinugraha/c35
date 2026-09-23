---
description: Always add leading icons to dropdown and popup menu items
globs: clients/app/lib/**/*.dart
alwaysApply: false
---

# Dropdown and popup menu icons

Every dropdown, popup menu, and context menu item must include a leading icon.

## Pattern

Use a compact `Row` with a fixed-width icon column:

```dart
PopupMenuItem(
  value: 'archive',
  child: Row(
    children: [
      Icon(Icons.archive_outlined, size: 18, color: Color(0xFFA1A1AA)),
      SizedBox(width: 10),
      Text('Archive'),
    ],
  ),
),
```

For `showMenu`, use the same `Row` pattern inside each `PopupMenuItem`.

## Icon choices

- Pin / unpin: `Icons.push_pin_outlined` / `Icons.push_pin`
- Archive: `Icons.archive_outlined`
- Delete: `Icons.delete_outline`
- Edit: `Icons.edit_outlined`
- Add / create: `Icons.add`
- Settings: `Icons.settings_outlined`
- Copy: `Icons.content_copy_outlined`

Use `_muted` (`0xFFA1A1AA`) or project accent for icon color. Keep icon size 16–18.

## Do not

- Text-only menu items without icons
- `ListTile` with `leading` omitted (always set `leading: Icon(...)`)
