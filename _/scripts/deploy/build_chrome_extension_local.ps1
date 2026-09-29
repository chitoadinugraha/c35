# Build local Chrome extension install bundle (agent exe + CRX + one-click Install script).
# Usage: .\_\scripts\deploy\build_chrome_extension_local.ps1
#        Add -BuildAgent to force cargo build --release

param([switch]$BuildAgent)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$pem = Join-Path $repoRoot '_\deployments\chrome_extension\extension.pem'
if (-not (Test-Path $pem)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $pem) | Out-Null
    & openssl genrsa -out $pem 2048
    if ($LASTEXITCODE -ne 0) { throw 'openssl genrsa failed' }
}

Push-Location $repoRoot
try {
    $args = @()
    if ($BuildAgent) { $args += '--build-agent' }
    dart run '_\scripts\deploy\deploy_remote\chrome_extension_pack.dart' @args
} finally {
    Pop-Location
}

$install = Join-Path $repoRoot '.cache\chrome_extension\install\Install-AlienAI-Chrome-Remote.ps1'
if (Test-Path $install) {
    Write-Host ''
    Write-Host '==> Install (quit Chrome first):'
    Write-Host "    $install"
}