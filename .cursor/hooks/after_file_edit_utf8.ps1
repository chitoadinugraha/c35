# After Cursor agent/tab edits: force UTF-8 on repo text sources (no UTF-16 / BOM).
$ErrorActionPreference = 'Stop'
$root = if ($env:CURSOR_PROJECT_DIR) { $env:CURSOR_PROJECT_DIR } else { (git rev-parse --show-toplevel 2>$null) }
if (-not $root) { exit 0 }
$utf8Bootstrap = Join-Path $root '_\scripts\dev\powershell_utf8.ps1'
if (Test-Path -LiteralPath $utf8Bootstrap) { . $utf8Bootstrap }
$script = Join-Path $root '_\scripts\dev\check_utf8_sources.ps1'
if (-not (Test-Path -LiteralPath $script)) { exit 0 }
& $script -Root $root -Changed -Fix | Out-Null
exit 0