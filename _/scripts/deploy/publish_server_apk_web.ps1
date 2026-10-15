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
$webScript = Join-Path $PSScriptRoot 'publish_web_app.ps1'
$deployDir = Join-Path $repoRoot '_\scripts\deploy'
$logDir = Join-Path $repoRoot '.cache\publish-perf'

. (Join-Path $repoRoot '_\deployments\_lib\publish_perf.ps1')
. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')
. (Join-Path $PSScriptRoot 'publish_wave.ps1')

if (-not $SkipGit) {
    Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage 'chore: pre-publish server apk windows web'
}

if (-not $SkipServer) {
    Write-Host '==> publish server (cluster Buildkit)'
    & $serverScript
    if ($LASTEXITCODE -ne 0) { throw 'publish_server failed' }
}

$dartGot = $false
if (-not $SkipDartGet) {
    Push-Location $deployDir
    try {
        Write-Host '==> dart pub get (once for app wave)'
        dart pub get
        if ($LASTEXITCODE -ne 0) { throw 'dart pub get failed' }
        $dartGot = $true
    } finally {
        Pop-Location
    }
}

$env:DEPLOY_SKIP_VERSION_BUMP = '1'

$apkArgs = @('-AndroidApkOnly')
if ($SkipDartGet -or $dartGot) { $apkArgs += '-SkipDartGet' }

if ($SkipWindows) {
    Write-Host '==> Android: release APK + CAS + /version/android (no Play upload or promote)'
    & $appScript @apkArgs
    if ($LASTEXITCODE -ne 0) { throw 'Android APK publish failed' }
} else {
    Write-Host '==> Android + Windows in parallel (APK + zip, no pubspec bump yet)'
    $winArgs = @('-WindowsAppOnly', '-SkipDartGet')
    $wave = @(
        (Start-PublishWaveProcess -Name 'android-apk' -ScriptPath $appScript -RepoRoot $repoRoot -LogDir $logDir -ExtraArgs $apkArgs)
        (Start-PublishWaveProcess -Name 'windows-app' -ScriptPath $appScript -RepoRoot $repoRoot -LogDir $logDir -ExtraArgs $winArgs)
    )
    $parallelSw = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($entry in $wave) {
        Wait-PublishWaveProcess $entry
    }
    $parallelSw.Stop()
    Set-PublishPerfMark -Name 'apk_windows_parallel_wall' -Seconds $parallelSw.Elapsed.TotalSeconds
    foreach ($entry in $wave) {
        Merge-PublishPerfFromLogFile $entry.OutLog
    }
}

Remove-Item Env:DEPLOY_SKIP_VERSION_BUMP -ErrorAction SilentlyContinue

Write-Host '==> Flutter web (S3 + /version/web, single pubspec bump)'
& $webScript -SkipDartGet
if ($LASTEXITCODE -ne 0) { throw 'web publish failed' }

Write-Host '==> publish_server_apk_web done'
