# Tester publish: optional git push, cluster server, Play internal AAB only (no production promote).
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

function Invoke-RepoGitPush {
    Push-Location $repoRoot
    try {
        $status = git status --porcelain
        if ($status) {
            throw @"
Working tree has uncommitted changes. Commit (or stash) before publish_tester, or pass -SkipGit.
$status
"@
        }
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "==> git push origin $branch"
        git push origin $branch
        if ($LASTEXITCODE -ne 0) { throw 'git push failed' }
    } finally {
        Pop-Location
    }
}

if (-not $SkipGit) {
    Invoke-RepoGitPush
}

if (-not $SkipServer) {
    Write-Host '==> publish server (cluster Buildkit)'
    & $serverScript
    if ($LASTEXITCODE -ne 0) { throw 'publish_server failed' }
}

$appExtra = @('-Tester')
if ($SkipDartGet) { $appExtra += '-SkipDartGet' }

Write-Host '==> Android: Play internal (tester) AAB only — no production promote, no /version/android'
& $appScript @appExtra
if ($LASTEXITCODE -ne 0) { throw 'Android tester publish failed' }

Write-Host '==> publish_tester done'
