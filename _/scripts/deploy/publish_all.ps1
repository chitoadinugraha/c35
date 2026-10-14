# Parallel server + app publish. Remote Windows agent is opt-in: pass -RemoteAgent only when needed.
param(
    [switch]$SkipGit,
    [switch]$SkipServer,
    [switch]$SkipApp,
    [switch]$RemoteAgent,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$deployDir = Join-Path $repoRoot '_\scripts\deploy'
$envFile = Join-Path $repoRoot '.env.local'
$logDir = Join-Path $repoRoot '.cache\publish-perf'
$serverScript = Join-Path $PSScriptRoot 'publish_server.ps1'
$appScript = Join-Path $PSScriptRoot 'publish_app_release.ps1'

. (Join-Path $repoRoot '_\deployments\_lib\publish_perf.ps1')
. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')

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

. (Join-Path $PSScriptRoot 'publish_wave.ps1')

Read-DotEnvLine $envFile

if (-not $SkipGit) {
    Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage 'chore: pre-publish all'
}

if (-not $SkipApp -and -not $env:YB_PASSWORD) {
    throw 'YB_PASSWORD required (repo-root .env.local or shell).'
}

$pub = Get-AppPubspecVersionInfo $repoRoot
Start-PublishPerfSession -Kind 'wave' -Target 'publish-all' -Version $pub.build -VersionName $pub.name -ImageRef 'hsg.ocir.io/axr8wqrrukgm/c35-server:latest'

if (-not $SkipApp -and -not $SkipDartGet) {
    Push-Location $deployDir
    try {
        Write-Host '==> dart pub get (once for app wave)'
        dart pub get
        if ($LASTEXITCODE -ne 0) { throw 'dart pub get failed' }
    } finally {
        Pop-Location
    }
}

$wave = @()
$parallelSw = [System.Diagnostics.Stopwatch]::StartNew()

if (-not $SkipServer) {
    $wave += Start-PublishWaveProcess -Name 'server' -ScriptPath $serverScript -RepoRoot $repoRoot -LogDir $logDir
}
if (-not $SkipApp) {
    $appArgs = @()
    if (-not $SkipDartGet) { $appArgs += '-SkipDartGet' }
    $wave += Start-PublishWaveProcess -Name 'app' -ScriptPath $appScript -RepoRoot $repoRoot -LogDir $logDir -ExtraArgs $appArgs
}

if ($wave.Count -eq 0) {
    throw 'Nothing to publish: pass -SkipServer or -SkipApp to skip one side, not both.'
}

foreach ($entry in $wave) {
    Wait-PublishWaveProcess $entry
}

$parallelSw.Stop()
Set-PublishPerfMark -Name 'parallel_wall' -Seconds $parallelSw.Elapsed.TotalSeconds

foreach ($entry in $wave) {
    Merge-PublishPerfFromLogFile $entry.OutLog
}

if ($RemoteAgent) {
    Write-Host '==> remote Windows agent (after server + app wave)'
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $appScript -RemoteAgent -SkipDartGet
    if ($LASTEXITCODE -ne 0) { throw 'remote agent publish failed' }
}

$regUser = if ($env:OCIR_USER) { $env:OCIR_USER } else { 'axr8wqrrukgm/chitoadinugraha@gmail.com' }
$regPass = if ($env:OCIR_PASSWORD) { $env:OCIR_PASSWORD } else { $env:REGISTRY_PASS }
Write-PublishPerfReport -RepoRoot $repoRoot -RegistryUser $regUser -RegistryPass $regPass

Write-Host '==> publish_all done'
