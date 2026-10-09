# Publish tester

Run **tester** release from the **repo root**: git commit (if needed) and push, then cluster server, Play **internal** AAB only — **no** production promote and **no** `/version/android` publish.

```powershell
.\_\scripts\deploy\publish_tester.ps1
```

If git should be left unchanged (already pushed):

```powershell
.\_\scripts\deploy\publish_tester.ps1 -SkipGit
```

**Requirements**

- Uncommitted work is auto-committed (`git add -A`) unless `-SkipGit`.
- Repo-root `.env.local`: `YB_PASSWORD`, Play JSON, cluster/OCIR for server.

Does **not** deploy Flutter web or Windows. For full prod including web, use `/publish-prod`.

When finished, end with a **Publish summary** per `.cursor/rules/publish-perf-report.mdc` (server, `android-tester`).
