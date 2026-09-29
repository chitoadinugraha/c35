---
description: Keep repo text sources UTF-8 (never UTF-16) — agents and PowerShell on Windows
alwaysApply: true
---

# UTF-8 source files (no UTF-16 on disk)

Rust, Dart, markdown, SQL, proto, and most repo text **must be UTF-8** (BOM optional; prefer **no BOM**). **UTF-16 LE** (with or without BOM) breaks `rustc`, pollutes diffs, and shows as mojibake when read as UTF-8.

Mirrored for Cursor: [`.cursor/rules/utf8-source-files.mdc`](../../.cursor/rules/utf8-source-files.mdc)

## Agents — hard rules

1. **Prefer the editor / Write / ApplyPatch tools** to create or change `.rs`, `.md`, `.dart`, `.sql`, `.toml`, `.proto`, `.mdc`, `.ps1`. Do **not** write source via shell redirects (`>`, `>>`) or default `Set-Content` / `Out-File`.
2. **Never** use PowerShell `Set-Content` or `Out-File` on source files **without** `-Encoding utf8`. On Windows PowerShell 5.1, the default encoding is **UTF-16 LE**.
3. When PowerShell must write text, use UTF-8 without BOM:

```powershell
[IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
```

4. After editing any of the extensions above (or before claiming done), run:

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed
```

If it fails, run `-Fix` on the listed paths or re-save from git/UTF-8.

## Humans — optional git hook

One-time per clone (local only):

```powershell
.\_\scripts\dev\setup_githooks.ps1
```

That sets `core.hooksPath` to `_/githooks` so **pre-commit** blocks staged UTF-16 text.

## Detection

`check_utf8_sources.ps1` flags UTF-16 BOM and UTF-16 LE **without BOM** (null byte every other character in ASCII-heavy headers — typical agent/PowerShell accident).
