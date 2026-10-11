# Session root UI (client)

Cursor rule: [`.cursor/rules/session-root-ui.mdc`](../../.cursor/rules/session-root-ui.mdc)

## Two concepts — do not mix them up

| Getter | Meaning |
|--------|---------|
| **`Session.instance.hasRootRole`** | Server truth: `global_roles` contains `root`. Never changed by the dev toggle. |
| **`Session.instance.isRoot`** | **UI / tooling only**: `rootAccessEnabled` AND (`hasRootRole` OR dev viewer: uid 99000 / handle or name `chito`). |

**`sessionViewerIsRoot()`** in `chat_inbox.dart` is an alias for **`Session.instance.isRoot`** — do not reintroduce separate chito/99000 checks elsewhere.

Persisted toggle: **`Session.instance.rootAccessEnabled`** (`C35AppId.sessionRootAccessEnabled`). Updated via **`Session.instance.rootAccessPut`**, which bumps **`sessionTick`** (app shell rebuilds).

## What to use where

| Need | Use |
|------|-----|
| Hide root badges, console, root-only composer tools, trace/inst taps, referral root edits | **`Session.instance.isRoot`** or **`sessionViewerIsRoot()`** |
| Show **Root access** switch in API host menu | **`Session.instance.hasRootRole`** only |
| Keep API host picker visible when toggle is off | **`serverHostPickerVisible()`** uses **`hasRootRole`** (or debug / tester), not effective **`isRoot`** |
| Server authorization, MCP, Rust APIs | **Not** this toggle — server roles only |

## Forbidden vs allowed

```dart
// BAD — bypasses root access toggle and duplicates role logic
if (Session.instance.globalRoles.contains('root')) { ... }

// BAD — UI gate from server profile alone
if (profile.globalRoles.contains('root')) { ... }

// GOOD — shell / feature visibility
if (Session.instance.isRoot) { ... }
```

## Security note

Turning **Root access** off is **UI masking** for demos and “normal user” look. The account remains root on the server; do not treat the toggle as an auth boundary.
