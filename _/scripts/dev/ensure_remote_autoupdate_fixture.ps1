# Build prior-build agent exe for mock OTA tests (e.g. build 2 when prod is 3).
# Usage: .\_\scripts\dev\ensure_remote_autoupdate_fixture.ps1 -Build 2

param(
    [Parameter(Mandatory = $true)]
    [int]$Build
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$verFile = Join-Path $repoRoot 'remotes\VERSION'
$saved = Get-Content $verFile -Raw
$name = "1.$Build.0"
Set-Content $verFile -Value "$name+$Build" -NoNewline
Push-Location (Join-Path $repoRoot 'remotes')
try {
    cargo build --release -p c_remote_windows
    if ($LASTEXITCODE -ne 0) { throw 'cargo build failed' }
    $outDir = Join-Path $repoRoot ".cache\remote-autoupdate-test\v$Build"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    Copy-Item (Join-Path $repoRoot '.cache\c_remote\release\c_remote_windows.exe') (Join-Path $outDir 'c_remote_windows.exe') -Force
    Write-Host "==> fixture ready: build $Build at $outDir\c_remote_windows.exe"
    Set-Content $verFile -Value $saved.TrimEnd() -NoNewline
    cargo build --release -p c_remote_windows
    if ($LASTEXITCODE -ne 0) { throw 'cargo restore build failed' }
} catch {
    Set-Content $verFile -Value $saved.TrimEnd() -NoNewline
    throw
} finally {
    Pop-Location
}
