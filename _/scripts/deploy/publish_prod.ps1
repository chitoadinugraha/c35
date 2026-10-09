# Full production publish: optional git commit+push, cluster server, Android (internal + promote + APK), Flutter web.
# Usage (repo root):
#   .\_\scripts\deploy\publish_prod.ps1
#   .\_\scripts\deploy\publish_prod.ps1 -SkipGit
#   .\_\scripts\deploy\publish_prod.ps1 -SkipServer

param(
    [switch]$SkipGit,
    [switch]$SkipServer,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$serverScript = Join-Path $PSScriptRoot 'publish_server.ps1'
$appScript = Join-Path $PSScriptRoot 'publish_app_release.ps1'

. (Join-Path $repoRoot '_\deployments\_lib\publish_perf.ps1')
. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')

if (-not $SkipGit) {
    Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage 'chore: pre-publish production'
}

if (-not $SkipServer) {
    Write-Host '==> publish server (cluster Buildkit)'
    & $serverScript
    if ($LASTEXITCODE -ne 0) { throw 'publish_server failed' }
}

$appExtra = @()
if ($SkipDartGet) { $appExtra += '-SkipDartGet' }

Write-Host '==> Android: internal upload, promote production, APK + /version/android (no pubspec bump yet)'
$env:DEPLOY_SKIP_VERSION_BUMP = '1'
& $appScript -AndroidPromote @appExtra
if ($LASTEXITCODE -ne 0) { throw 'Android promote publish failed' }

Remove-Item Env:DEPLOY_SKIP_VERSION_BUMP -ErrorAction SilentlyContinue

Write-Host '==> Flutter web (S3 + /version/web, single pubspec bump)'
& $appScript -WebOnly -SkipDartGet
if ($LASTEXITCODE -ne 0) { throw 'web publish failed' }

Write-Host '==> publish_prod done'
