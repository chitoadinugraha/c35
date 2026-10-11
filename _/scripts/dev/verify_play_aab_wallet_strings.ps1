# Fail if a Play-distribution AAB still contains wallet checkout strings (Play policy scan).
param(
    [string]$AabPath = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$AppDir = Join-Path $RepoRoot 'clients\app'

if (-not $AabPath) {
    $AabPath = Join-Path $AppDir 'build\app\outputs\bundle\release\app-release.aab'
}

if (-not (Test-Path $AabPath)) {
    Write-Error "AAB not found: $AabPath (run flutter build appbundle with C35_BILLING_DISTRIBUTION=play)"
}

$patterns = @('midtrans', 'Midtrans', 'Manual bank transfer', 'upload bukti transfer', 'stripe')
$hits = @()

foreach ($pat in $patterns) {
    $found = Select-String -Path $AabPath -Pattern $pat -SimpleMatch -Quiet -ErrorAction SilentlyContinue
    if ($found) { $hits += $pat }
}

if ($hits.Count -gt 0) {
    Write-Error "Play AAB contains forbidden wallet strings: $($hits -join ', ')"
}

Write-Host "OK: no wallet checkout strings in $AabPath"
