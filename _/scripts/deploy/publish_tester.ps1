# Tester publish: optional git commit+push, cluster server, Play internal AAB only (no production promote).
# Usage (repo root):
#   .\_\scripts\deploy\publish_tester.ps1
#   .\_\scripts\deploy\publish_tester.ps1 -SkipGit
#   .\_\scripts\deploy\publish_tester.ps1 -SkipServer

param(
    [switch]$SkipGit,
    [switch]$SkipServer,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$serverScript = Join-Path $PSScriptRoot 'publish_server.ps1'
$appScript = Join-Path $PSScriptRoot 'publish_app_release.ps1'

. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')

if (-not $SkipGit) {
    Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage 'chore: pre-publish tester'
}

if (-not $SkipServer) {
    Write-Host '==> publish server (cluster Buildkit)'
    & $serverScript
    if ($LASTEXITCODE -ne 0) { throw 'publish_server failed' }
}

$appParams = @{ Tester = $true }
if ($SkipDartGet) { $appParams.SkipDartGet = $true }

Write-Host '==> Android: Play internal (tester) AAB only — no production promote, no /version/android'
& $appScript @appParams
if ($LASTEXITCODE -ne 0) { throw 'Android tester publish failed' }

Write-Host '==> publish_tester done'
