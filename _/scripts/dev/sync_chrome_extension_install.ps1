# Copy repo extension dist + manifest to %LOCALAPPDATA% install (no native host kill).
# Pair with browser.extension.reload on the paired Chrome device to pick up JS changes.
param(
    [switch]$ReloadHint
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$extSrc = Join-Path $RepoRoot 'clients\chrome_extension\alienai_remote'
$installDir = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\install'
$extDst = Join-Path $installDir 'alienai_remote'
$distSrc = Join-Path $extSrc 'dist'
$distDst = Join-Path $extDst 'dist'

if (-not (Test-Path $distSrc)) { throw "missing dist: $distSrc" }
New-Item -ItemType Directory -Force -Path $extDst | Out-Null
New-Item -ItemType Directory -Force -Path $distDst | Out-Null

Copy-Item -Path (Join-Path $extSrc 'manifest.json') -Destination (Join-Path $extDst 'manifest.json') -Force
Copy-Item -Path (Join-Path $distSrc '*') -Destination $distDst -Recurse -Force
if (Test-Path (Join-Path $extSrc 'icons')) {
    Copy-Item -Path (Join-Path $extSrc 'icons') -Destination (Join-Path $extDst 'icons') -Recurse -Force
}

$configPath = Join-Path $extDst 'config.json'
$serverUrl = $env:C35_SERVER_URL
if (-not $serverUrl) { $serverUrl = 'http://127.0.0.1:8080' }
@{ server_url = $serverUrl } | ConvertTo-Json | Set-Content -Path $configPath -Encoding utf8

Write-Host "==> synced extension -> $extDst"
Write-Host "    manifest: $((Get-Content (Join-Path $extDst 'manifest.json') -Raw | ConvertFrom-Json).version)"
if ($ReloadHint) {
    Write-Host "==> call browser.extension op=reload on your Chrome extension device (or reload once manually)"
}
