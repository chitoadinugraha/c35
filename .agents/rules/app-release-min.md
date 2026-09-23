---
description: When to bump app release min build and C35AppId on breaking changes
alwaysApply: true
---

# App release `min` and `C35AppId`

## `min` (force-update floor)

Release JSON in `ai.config` (`app.release.c35.{platform}`) includes `min` — the **minimum supported build number**. Clients below `min` get a **non-dismissible** update (see `appReleaseForceUpdate`).

**Raise `min` when any of these ship:**

- Breaking wire/proto or auth/session contract (old clients must not connect)
- Breaking local storage / session shape (paired with `C35AppId` bump if needed)
- Major app generation cutover (e.g. csa → c35 takeover on same Play package)
- Security fix that must not run on older builds

**Do not raise `min` for:** routine features, UI-only changes, backward-compatible API additions.

**How to bump:**

1. Set `APP_RELEASE_MIN` (or `appReleaseMinBuild` in `_/scripts/deploy/deploy_app/publish_app_version.dart`) to the new floor — **never lower** `min` on publish (scripts use `GREATEST` with existing row).
2. Publish `/version/android` and `/version/windows` (not tester-only tracks).
3. Note the change in the release commit / deploy log.

Current floor constant: **235** (`appReleaseMinBuild`).

## `C35AppId` (local storage generation)

`C35AppId.id` (`c35`) namespaces prefs and triggers **local session wipe** when changed (`app_id_ensure.dart`).

**Bump `C35AppId.id` only when:**

- Session/token storage keys or format change and old data must not be reused
- Deliberate sign-out of all installs (same package name, new app generation)
- Install/device id prefix scheme changes (`c35-{uuid}`)

After bumping `id`, users re-login once; server sessions are unaffected unless you also invalidate tokens server-side.

**Pair with `min`:** major cutovers usually bump **both** so old builds are forced to update and new builds start clean.
