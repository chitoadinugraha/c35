# Prune local Rust build artifacts under .cache/ (servers, remotes, tools).
# Usage:
#   .\_\scripts\dev\cleanup_rust_cache.ps1              # trim stale artifacts (default)
#   .\_\scripts\dev\cleanup_rust_cache.ps1 -Full       # cargo clean (full rebuild next time)
#   .\_\scripts\dev\cleanup_rust_cache.ps1 -Days 14    # keep artifacts newer than 14 days

param(
    [switch]$Full,
    [int]$Days = 30
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$CacheRoot = Join-Path $Root '.cache'

function Format-CacheSize([string]$Path) {
    if (-not (Test-Path $Path)) { return '0 MB (missing)' }
    $bytes = (Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if (-not $bytes) { return '0 MB' }
    return ('{0:N1} MB' -f ($bytes / 1MB))
}

function Show-CacheStatus([string]$Label) {
    Write-Host "    server : $(Format-CacheSize (Join-Path $CacheRoot 'server'))"
    Write-Host "    agent  : $(Format-CacheSize (Join-Path $CacheRoot 'agent'))"
    Write-Host "    rust   : $(Format-CacheSize (Join-Path $CacheRoot 'rust'))"
    Write-Host "    total  : $(Format-CacheSize $CacheRoot)"
}

function Invoke-CargoClean([string]$WorkDir, [string]$Label) {
    if (-not (Test-Path (Join-Path $WorkDir 'Cargo.toml'))) {
        Write-Host "==> skip $Label (no Cargo.toml at $WorkDir)"
        return
    }
    Write-Host "==> cargo clean ($Label)"
    Push-Location $WorkDir
    try {
        cargo clean 2>&1
        if ($LASTEXITCODE -ne 0) { throw "cargo clean failed for $Label (exit $LASTEXITCODE)" }
    } finally {
        Pop-Location
    }
}

function Test-CargoSweep {
    cargo sweep --version 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}

function Invoke-CargoSweep([string]$WorkDir, [string]$Label, [string]$TargetDir) {
    if (-not (Test-Path (Join-Path $WorkDir 'Cargo.toml'))) {
        Write-Host "==> skip $Label (no Cargo.toml at $WorkDir)"
        return
    }
    Write-Host "==> cargo sweep -t $Days ($Label)"
    Push-Location $WorkDir
    $prevTargetDir = $env:CARGO_TARGET_DIR
    try {
        if ($TargetDir) { $env:CARGO_TARGET_DIR = $TargetDir }
        cargo sweep -t $Days 2>&1
        if ($LASTEXITCODE -ne 0) { throw "cargo sweep failed for $Label (exit $LASTEXITCODE)" }
    } finally {
        if ($null -ne $prevTargetDir) { $env:CARGO_TARGET_DIR = $prevTargetDir }
        else { Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue }
        Pop-Location
    }
}

function Invoke-PruneOldFiles([string]$Dir, [int]$KeepDays) {
    if (-not (Test-Path $Dir)) { return 0 }
    $cutoff = (Get-Date).AddDays(-$KeepDays)
    $removed = 0
    Get-ChildItem $Dir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            $removed++
        }
    return $removed
}

function Invoke-PruneEmptyDirs([string]$Dir) {
    if (-not (Test-Path $Dir)) { return }
    Get-ChildItem $Dir -Recurse -Directory -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending |
        ForEach-Object {
            if ((Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
}

Write-Host '========================================'
Write-Host ' cleanup: rust cache (.cache/server, agent, rust)'
Write-Host '========================================'
Write-Host '==> before'
Show-CacheStatus

$hasSweep = Test-CargoSweep

if ($Full) {
    Write-Host '==> mode: full (cargo clean)'
    Invoke-CargoClean (Join-Path $Root 'servers') 'server'
    Invoke-CargoClean (Join-Path $Root 'remotes') 'agent'
    $hashTool = Join-Path $Root '_\scripts\deploy\tools\hash_blake3'
    if (Test-Path (Join-Path $hashTool 'Cargo.toml')) {
        $env:CARGO_TARGET_DIR = Join-Path $CacheRoot 'rust\hash_blake3'
        Invoke-CargoClean $hashTool 'hash_blake3'
        Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue
    }
} elseif ($hasSweep) {
    Write-Host "==> mode: trim (cargo sweep, keep last $Days days)"
    Invoke-CargoSweep (Join-Path $Root 'servers') 'server' ''
    Invoke-CargoSweep (Join-Path $Root 'remotes') 'agent' ''
    $hashTool = Join-Path $Root '_\scripts\deploy\tools\hash_blake3'
    if (Test-Path (Join-Path $hashTool 'Cargo.toml')) {
        Invoke-CargoSweep $hashTool 'hash_blake3' (Join-Path $CacheRoot 'rust\hash_blake3')
    }
} else {
    Write-Host "==> mode: trim (file age > $Days days; cargo-sweep not installed)"
    Write-Host '    tip: cargo install cargo-sweep  (better trim, keeps current deps)'
    $removed = 0
    $removed += Invoke-PruneOldFiles (Join-Path $CacheRoot 'server') $Days
    $removed += Invoke-PruneOldFiles (Join-Path $CacheRoot 'agent') $Days
    $removed += Invoke-PruneOldFiles (Join-Path $CacheRoot 'rust') $Days
    Invoke-PruneEmptyDirs $CacheRoot
    Write-Host "    removed $removed stale files"
}

Write-Host '==> after'
Show-CacheStatus
Write-Host '==> rust cache cleanup done'
