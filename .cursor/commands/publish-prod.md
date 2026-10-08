# Publish production

Run the full c35 **production** release from the **repo root** in order: git push (clean tree), cluster server, Android internal + Play production promote + APK/`/version/android`, then Flutter web (single pubspec bump on web step).

```powershell
.\_\scripts\deploy\publish_prod.ps1
```

If changes are already committed and pushed:

```powershell
.\_\scripts\deploy\publish_prod.ps1 -SkipGit
```

**Requirements**

- Clean working tree unless `-SkipGit` (commit first).
- Repo-root `.env.local`: `YB_PASSWORD`, Play JSON, `S3_*`, `DEPLOY_AUTH_TOKEN` (or `-MintToken` on app script), cluster/OCIR for server.
- Server builds on **cluster Buildkit** only (`publish_server.ps1`).

**Do not** use `publish_all.ps1` for this flow — prod Android and web are **sequential** so version bump happens once after web.

On failure see `_/docs/app-release.md` (`--finish-cas-only`, `-SkipServer`, etc.).

When finished, end with a **Publish summary** per `.cursor/rules/publish-perf-report.mdc` (server, `android-promote-prod`, `web-release`).
