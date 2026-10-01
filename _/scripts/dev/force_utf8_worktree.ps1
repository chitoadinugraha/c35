# Repair entire worktree: UTF-16 / UTF-8 BOM -> UTF-8 (no BOM) for repo text sources.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)
$ErrorActionPreference = 'Stop'
$check = Join-Path $Root '_\scripts\dev\check_utf8_sources.ps1'
& $check -Root $Root -Fix
exit $LASTEXITCODE