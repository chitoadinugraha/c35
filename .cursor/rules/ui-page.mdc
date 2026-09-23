---
description: Use UiPage for full-screen Flutter pages (consistent app bar chrome)
globs: clients/app/lib/pages/**/*.dart,clients/app/lib/widgets/**/ui_account_live_conns.dart
alwaysApply: false
---

# UiPage for full-screen pages

Use `UiPage` from `widgets/ui/ui_page.dart` for every full-screen page with a title bar.

Do **not** use raw `AppBar`, manual `Scaffold` + `UiPageBar`, or one-off top `Row` chrome in pages.

## Standard pattern

```dart
import 'package:alienai_c35/widgets/ui/ui_page.dart';

UiPage(
  title: 'Devices',
  subtitle: 'Coming soon', // optional
  onBack: () => Navigator.pop(context),
  trailing: myActions, // optional right-side actions
  onSearch: store.searchPut, // optional — adds search icon to actions
  searchHint: 'Search devices', // optional hint when onSearch is set
  body: ...,
)
```

## Search

Use built-in `onSearch` for list/filter search — do **not** embed a `TextField` in the page body or build a custom search bar in `titleWidget`.

When `onSearch` is set:
- A search icon appears in the page bar actions (before `trailing`)
- Tapping it replaces the title and actions with a compact search field + close button
- `onSearch` is called on every text change; clearing/closing resets the query via `onSearch('')`

```dart
UiPage(
  title: 'Devices',
  onBack: () => Navigator.pop(context),
  onSearch: _store.searchPut,
  searchHint: 'Search devices',
  trailing: UiDeviceAddMenu(store: _store),
  body: ...,
)
```

For advanced in-bar search (match navigation, extra controls inside the search field), use `titleWidget` — see `page_referral_tree.dart`.

## When to use what

| Need | Use |
|------|-----|
| Title + optional subtitle | `title`, `subtitle` |
| List/filter search | `onSearch`, `searchHint` |
| Custom title area (advanced search, etc.) | `titleWidget` |
| Right-side icon buttons / actions | `trailing` |
| Loading bar over page | `overlay` |
| Back navigation | `onBack: () => Navigator.pop(context)` |
| Master-detail owns its own header | `hideBar: true` — render `UiPageBar` inside master pane |

## Master-detail pages

When the master pane owns the page chrome (title, back, search, add):

```dart
UiPage(
  hideBar: true,
  title: 'Devices',
  body: UiMasterDetail(
    masterBar: _DeviceMasterBar(...),
    master: deviceList,
    detailBuilder: ...,
  ),
)
```

Put search and trailing actions in the master bar, not the global `UiPage` bar.

## Exceptions (do not use UiPage)

- **Home shell** — `page_ai_home.dart` (drawer / master-detail layout)
- **Auth flows** — sign-in / sign-up (`UiAuthShell`)
- **Session lock gate** — full-screen unlock, no back bar
- **Boot / error splash** — `main.dart` loading states
- **Bottom sheets / dialogs** — `showModalBottomSheet`, `AlertDialog`, etc.

## Examples in repo

- Settings, active connections, nav stubs (Bots / Devices / Sites), referral tree
