# Cleanup unused build caches (local Rust + cluster buildkit).
# Usage:
#   .\cleanup.ps1                  # both
#   .\cleanup.ps1 -SkipBuildkit    # local rust only
#   .\cleanup.ps1 -SkipRust        # cluster buildkit only
#   .\cleanup.ps1 -Full            # full cargo clean (rust)

param(
    [switch]$SkipRust,
    [switch]$SkipBuildkit,
    [switch]$Full,
    [int]$Days = 1
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

Write-Host '========================================'
Write-Host ' cleanup: all build caches'
Write-Host '========================================'

if (-not $SkipRust) {
    $rustArgs = @{ Days = $Days }
    if ($Full) { $rustArgs['Full'] = $true }
    & (Join-Path $Root '_\scripts\dev\cleanup_rust_cache.ps1') @rustArgs
    Write-Host ''
}

if (-not $SkipBuildkit) {
    & (Join-Path $Root '_\scripts\deploy\cleanup_buildkit.ps1')
}

Write-Host '==> all cleanup done'
