---
description: Verify scripts and code compile after edits before claiming done
alwaysApply: true
---

# Verify after edit

Before finishing any task that changed files, run checks for the areas touched. Fix failures before reporting success.

## PowerShell (`*.ps1`, `dev_*.ps1`)

Parse every edited script (no execution required):

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('PATH.ps1', [ref]$null, [ref]$errors)
if ($errors) { $errors | Format-List; exit 1 }
```

Rules:
- Use ASCII quotes `'` / `"` only — no smart quotes or em dashes inside strings
- Prefer `('-s', ('"' + $path + '"'))` over nested backtick-escaped quotes

## Rust (`servers/**/*.rs`)

```powershell
cd servers
cargo build -p server_ai
```

Run `cargo test -p CRATE` when the edited crate has tests.

## Dart / Flutter (`clients/app/**`)

```powershell
cd clients/app
flutter analyze
```

Run `flutter test` when tests exist for changed code.

## Text encoding (all platforms)

After creating or editing `.rs`, `.md`, `.dart`, `.sql`, `.toml`, `.proto`, `.mdc`, or `.ps1`:

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed
```

See `utf8-source-files.md` — never write those files with default PowerShell `Set-Content` (UTF-16 on Windows).

## General

- Do not claim "fixed" or "ready to test" without running the relevant check above
- If a check cannot run (missing tool, blocked network), say so explicitly
