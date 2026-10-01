# Flutter app verify: UTF-8 worktree check (with auto-fix) then flutter analyze.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$utf8 = Join-Path $Root '_\scripts\dev\check_utf8_sources.ps1'
& $utf8 -Root $Root -Changed -Fix
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Push-Location (Join-Path $Root 'clients\app')
try {
    flutter analyze
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
