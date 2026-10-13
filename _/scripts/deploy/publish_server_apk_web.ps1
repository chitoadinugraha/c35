# Production publish without Play promote: optional git commit+push, cluster server,
# signed release APK (Play upload keystore) + CAS + /version/android,
# Flutter Windows zip + /version/windows, Flutter web.
# Usage (repo root):
#   .\_\scripts\deploy\publish_server_apk_web.ps1
#   .\_\scripts\deploy\publish_server_apk_web.ps1 -SkipGit
#   .\_\scripts\deploy\publish_server_apk_web.ps1 -SkipServer
#   .\_\scripts\deploy\publish_server_apk_web.ps1 -SkipGit -SkipServer -SkipWindows

param(
    [switch]$SkipGit,
    [switch]$SkipServer,
    [switch]$SkipWindows,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$serverScript = Join-Path $PSScriptRoot 'publish_server.ps1'
$appScript = Join-Path $PSScriptRoot 'publish_app_release.ps1'

. (Join-Path $repoRoot '_\deployments\_lib\publish_perf.ps1')
. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')

if (-not $SkipGit) {
    Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage 'chore: pre-publish server apk windows web'
}

if (-not $SkipServer) {
    Write-Host '==> publish server (cluster Buildkit)'
    & $serverScript
    if ($LASTEXITCODE -ne 0) { throw 'publish_server failed' }
}

$appExtra = @()
if ($SkipDartGet) { $appExtra += '-SkipDartGet' }

$env:DEPLOY_SKIP_VERSION_BUMP = '1'

Write-Host '==> Android: release APK + CAS + /version/android (no Play upload or promote)'
& $appScript -AndroidApkOnly @appExtra
if ($LASTEXITCODE -ne 0) { throw 'Android APK publish failed' }

if (-not $SkipWindows) {
    Write-Host '==> Windows: release zip + CAS + /version/windows (no pubspec bump yet)'
    & $appScript -WindowsAppOnly -SkipDartGet
    if ($LASTEXITCODE -ne 0) { throw 'Windows app publish failed' }
}

Remove-Item Env:DEPLOY_SKIP_VERSION_BUMP -ErrorAction SilentlyContinue

Write-Host '==> Flutter web (S3 + /version/web, single pubspec bump)'
& $appScript -WebOnly -SkipDartGet
if ($LASTEXITCODE -ne 0) { throw 'web publish failed' }

Write-Host '==> publish_server_apk_web done'
