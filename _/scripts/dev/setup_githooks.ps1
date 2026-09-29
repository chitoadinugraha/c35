# Point this clone at repo-managed git hooks (UTF-8 pre-commit, etc.).
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$hooksRel = '_/githooks'
$hooksAbs = Join-Path $Root $hooksRel
if (-not (Test-Path (Join-Path $hooksAbs 'pre-commit'))) {
    throw "Missing $hooksAbs\pre-commit"
}

Push-Location $Root
try {
    git config core.hooksPath $hooksRel
    Write-Host "core.hooksPath = $hooksRel (local clone only)"
    Write-Host 'Pre-commit will run check_utf8_sources.ps1 on staged text files.'
} finally {
    Pop-Location
}
