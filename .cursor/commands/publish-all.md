# Publish all (server + app)

Run the full c35 release wave from the **repo root**. Do not publish the remote agent unless the user adds `-RemoteAgent`.

```powershell
.\_\scripts\deploy\publish_all.ps1
```

Run from the workspace / repo root (where `_\scripts\deploy` exists).

- **Parallel:** `publish_server.ps1` (cluster Buildkit) and default `publish_app_release.ps1` (Play promote, APK/CAS, Windows, web).
- **Env:** repo-root `.env.local` (`YB_PASSWORD`, Play JSON, `S3_*`, cluster/OCIR as usual).
- **On failure:** see `_/specs/app-release.md` recovery (`--finish-cas-only`, `-SkipServer`, etc.).

When the script finishes, end with a **Publish summary** per `.cursor/rules/publish-perf-report.mdc` (target `publish-all`, plus merged marks from server and app logs under `.cache/publish-perf/publish-all-*.log` if needed).
