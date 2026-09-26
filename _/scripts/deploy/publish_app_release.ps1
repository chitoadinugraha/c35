# Coordinated c35 app release (Dart orchestrator) + optional remote agent publish.
#
# Usage:
#   .\_\scripts\deploy\publish_app_release.ps1
#   .\_\scripts\deploy\publish_app_release.ps1 -Tester
#   .\_\scripts\deploy\publish_app_release.ps1 -AndroidOnly
#   .\_\scripts\deploy\publish_app_release.ps1 -WindowsOnly
#   .\_\scripts\deploy\publish_app_release.ps1 -WebOnly
#   .\_\scripts\deploy\publish_app_release.ps1 -PromoteOnly 240
#   .\_\scripts\deploy\publish_app_release.ps1 -AndroidPromote
#   (if Play OK but CAS failed) dart run deploy_app/play_store_upload_promote_prod.dart --finish-cas-only <N>
#   .\_\scripts\deploy\publish_app_release.ps1 -RemoteAgent
#   .\_\scripts\deploy\publish_app_release.ps1 -MintToken
#
# Env: repo-root .env.local (YB_PASSWORD, DEPLOY_AUTH_TOKEN, Play JSON path, S3_*).
# MSIX / Microsoft Store: not wired yet (see _/docs/app-release.md).

param(
    [switch]$Tester,
    [switch]$AndroidOnly,
    [switch]$WindowsOnly,
    [switch]$WebOnly,
    [switch]$AndroidPromote,
    [int]$PromoteOnly = 0,
    [switch]$RemoteAgent,
    [switch]$MintToken,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$deployDir = Join-Path $repoRoot '_\scripts\deploy'
$envFile = Join-Path $repoRoot '.env.local'
. (Join-Path $repoRoot '_\deployments\_lib\publish_perf.ps1')

function Get-AppPubspecVersionInfo([string]$Root) {
    $pubspec = Join-Path $Root 'clients\app\pubspec.yaml'
    if (-not (Test-Path $pubspec)) { return @{ build = ''; name = '' } }
    $line = Get-Content $pubspec | Where-Object { $_ -match '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$' } | Select-Object -First 1
    if (-not $line) { return @{ build = ''; name = '' } }
    if ($line -notmatch '^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$') { return @{ build = ''; name = '' } }
    $major = $Matches[1]
    $build = $Matches[4]
    return @{ build = $build; name = "$major.$build.0" }
}

function Read-DotEnvLine([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $p = $line -split '=', 2
        if ($p.Length -ne 2) { return }
        $k = $p[0].Trim()
        $v = $p[1].Trim().Trim('"').Trim("'")
        if ($k -and -not (Test-Path Env:$k)) { Set-Item -Path "Env:$k" -Value $v }
    }
}

function Invoke-DeployDart {
    param([string[]]$DartArgs)
    $dartLines = @()
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & dart @DartArgs 2>&1 | ForEach-Object {
            $dartLines += $_
            Write-Host $_
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    if ($LASTEXITCODE -ne 0) { throw "dart failed: $($DartArgs -join ' ')" }
    foreach ($line in $dartLines) { Merge-PublishPerfFromJsonLine ([string]$line) }
}

function Resolve-AppPublishPerfTarget {
    if ($AndroidPromote) { return 'android-promote-prod' }
    if ($PromoteOnly -gt 0) { return 'android-promote-only' }
    if ($Tester) { return 'android-tester' }
    if ($WindowsOnly) { return 'windows-release' }
    if ($WebOnly) { return 'web-release' }
    if ($AndroidOnly) { return 'android-release' }
    if ($RemoteAgent) { return 'remote-windows-agent' }
    return 'app-release'
}

Read-DotEnvLine $envFile

if ($MintToken) {
    & (Join-Path $PSScriptRoot 'mint_deploy_auth_token.ps1') -EnvFile $envFile
    Read-DotEnvLine $envFile
}

if (-not $env:DEPLOY_AUTH_TOKEN -and -not $WebOnly) {
    Write-Warning 'DEPLOY_AUTH_TOKEN missing; run with -MintToken or set in .env.local'
}
if (-not $env:YB_PASSWORD) {
    throw 'YB_PASSWORD required (repo-root .env.local or shell).'
}

$pub = Get-AppPubspecVersionInfo $repoRoot
$perfTarget = Resolve-AppPublishPerfTarget
Start-PublishPerfSession -Kind 'app' -Target $perfTarget -Version $pub.build -VersionName $pub.name

Push-Location $deployDir
try {
    if (-not $SkipDartGet) {
        Write-Host '==> dart pub get'
        dart pub get
        if ($LASTEXITCODE -ne 0) { throw 'dart pub get failed' }
    }

    if ($RemoteAgent) {
        Write-Host '==> remote Windows agent (CAS + ai.config + NATS)'
        Remove-Item Env:C35_SERVER -ErrorAction SilentlyContinue
        Remove-Item Env:C35_SERVER_URL -ErrorAction SilentlyContinue
        $env:C35_SERVER = 'https://alienai.id'
        Invoke-DeployDart @('run', 'deploy_remote/remote_windows_upload_prod.dart')
        return
    }

    if ($PromoteOnly -gt 0) {
        Write-Host "==> Play promote-only versionCode=$PromoteOnly"
        Invoke-DeployDart @('run', 'deploy_app/play_store_upload_promote_prod.dart', '--promote-only', "$PromoteOnly")
        return
    }

    if ($AndroidPromote) {
        Write-Host '==> Android: internal upload, promote prod, APK + /version/android'
        Invoke-DeployDart @('run', 'deploy_app/play_store_upload_promote_prod.dart')
        return
    }

    $dartArgs = @('run', 'deploy_app/deploy_app_release.dart')
    if ($Tester) { $dartArgs += '--tester' }
    if ($AndroidOnly) { $dartArgs += '--android-only' }
    if ($WindowsOnly) { $dartArgs += '--windows-only' }
    if ($WebOnly) { $dartArgs += '--web-only' }

    if ($Tester -and ($AndroidOnly -or $WindowsOnly -or $WebOnly)) {
        throw 'Cannot combine -Tester with -AndroidOnly, -WindowsOnly, or -WebOnly'
    }
    if ($AndroidOnly -and $WindowsOnly) {
        throw 'Cannot use -AndroidOnly and -WindowsOnly together'
    }

    Write-Host ('==> ' + ($dartArgs -join ' '))
    Invoke-DeployDart $dartArgs
}
finally {
    Pop-Location
    Write-PublishPerfReport -RepoRoot $repoRoot
}

Write-Host '==> publish_app_release done'
