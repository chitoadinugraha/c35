# E2E (mock): Windows desktop app OTA staging via GET /version/windows + zip download.
# Does not launch alienai.exe (release-only checkNow); uses Flutter tests for download/hash/staging.
#
# Fixture zip: minimal alienai.exe at zip root (built under .cache\windows-autoupdate-test\).
# Optional: copy a real Release\alienai.exe into the bundle for a larger stub.
#
# Usage:
#   .\_\scripts\dev\test_windows_app_autoupdate.ps1
#   .\_\scripts\dev\test_windows_app_autoupdate.ps1 -TargetVersion 999002 -MockPort 8878

param(
    [string]$Zip = '',
    [int]$TargetVersion = 999001,
    [int]$MockPort = 8878,
    [string]$ProdBaseUrl = 'https://api.alienai.id'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixtureRoot = Join-Path $repoRoot '.cache\windows-autoupdate-test'
$testLocalAppData = Join-Path $fixtureRoot 'localappdata'

if ($TargetVersion -le 0) { throw 'TargetVersion must be > 0' }

if (-not $Zip) {
    $Zip = Join-Path $fixtureRoot "alienai-windows-$TargetVersion.zip"
}

if (-not (Test-Path $Zip)) {
    Write-Host "==> building fixture zip $Zip"
    $bundleDir = Join-Path $fixtureRoot 'bundle'
    if (Test-Path $bundleDir) { Remove-Item -Recurse -Force $bundleDir }
    New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null
    $stubDest = Join-Path $bundleDir 'alienai.exe'
    $releaseExe = Join-Path $repoRoot 'clients\app\build\windows\x64\runner\Release\alienai.exe'
    if (Test-Path $releaseExe) {
        Copy-Item $releaseExe $stubDest -Force
    } else {
        [IO.File]::WriteAllBytes($stubDest, [byte[]](0x4D, 0x5A, 0x90, 0x00))
    }
    if (Test-Path $Zip) { Remove-Item -Force $Zip }
    Compress-Archive -Path $stubDest -DestinationPath $Zip -CompressionLevel Fastest
}

$hashTool = Join-Path $repoRoot '.cache\rust\hash_blake3\release\hash_blake3.exe'
if (-not (Test-Path $hashTool)) {
    $env:CARGO_TARGET_DIR = Join-Path $repoRoot '.cache\rust\hash_blake3'
    cargo build --release --manifest-path (Join-Path $repoRoot '_\scripts\deploy\tools\hash_blake3\Cargo.toml')
}
$hash = (& $hashTool $Zip).Trim().ToLower()
Write-Host "==> target=$TargetVersion hash=$hash size=$((Get-Item $Zip).Length)"

$updatesRoot = Join-Path $testLocalAppData 'AlienAI\updates'
if (Test-Path $updatesRoot) {
    Remove-Item -Recurse -Force $updatesRoot
}
New-Item -ItemType Directory -Force -Path $testLocalAppData | Out-Null

$mockPy = Join-Path $PSScriptRoot 'windows_app_autoupdate_mock_server.py'
$mockProc = Start-Process -FilePath python -ArgumentList @($mockPy, $Zip, $hash, $MockPort, $TargetVersion) -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 1

try {
    $probe = Invoke-RestMethod -Uri "http://127.0.0.1:${MockPort}/version/windows" -Method Get
    if ([int]$probe.version -ne $TargetVersion) {
        throw "mock version mismatch: $($probe.version) != $TargetVersion"
    }
} catch {
    Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue
    throw "mock server failed to start on port ${MockPort}: $_"
}

$mockBase = "http://127.0.0.1:${MockPort}"
Write-Host "==> mock $mockBase/version/windows OK; running Flutter staging tests"

$prevLocalAppData = $env:LOCALAPPDATA
$env:LOCALAPPDATA = $testLocalAppData
$env:C35_WINDOWS_UPDATE_MOCK_BASE = $mockBase
try {
    Push-Location (Join-Path $repoRoot 'clients\app')
    flutter test test/app_update_windows_staging_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed' }
} finally {
    if ($null -ne $prevLocalAppData) { $env:LOCALAPPDATA = $prevLocalAppData } else { Remove-Item Env:LOCALAPPDATA -ErrorAction SilentlyContinue }
    Remove-Item Env:C35_WINDOWS_UPDATE_MOCK_BASE -ErrorAction SilentlyContinue
    Pop-Location
}

$stagedExe = Join-Path $updatesRoot "$TargetVersion\staging\alienai.exe"
if (-not (Test-Path $stagedExe)) {
    Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue
    throw "Expected staged exe missing: $stagedExe"
}

Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue

try {
    $live = Invoke-RestMethod -Uri "$ProdBaseUrl/version/windows" -Method Get -TimeoutSec 10
    Write-Host "==> prod /version/windows version=$($live.version) (reference only)"
} catch {
    Write-Warning "prod /version/windows probe skipped: $_"
}

Write-Host "==> windows app autoupdate mock E2E: PASS (staged v$TargetVersion)"