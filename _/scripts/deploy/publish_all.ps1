param(
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

function Start-PublishWaveProcess {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$ExtraArgs = @()
    )
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $outLog = Join-Path $logDir "publish-all-$Name.log"
    $errLog = Join-Path $logDir "publish-all-$Name.err"
    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $ExtraArgs
    Write-Host ('==> start parallel wave: ' + $Name + ' ' + $ScriptPath)
    $proc = Start-Process -FilePath 'powershell.exe' -PassThru -WorkingDirectory $repoRoot -ArgumentList $argList -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    return @{ Name = $Name; Proc = $proc; OutLog = $outLog; ErrLog = $errLog }
}

function Wait-PublishWaveProcess {
    param($Entry)
    $proc = $Entry.Proc
    $null = $proc.WaitForExit()
    $proc.Refresh(); $code = $proc.ExitCode; if ($null -eq $code) { $code = 0 }
    Write-Host ('==> wave ' + $Entry.Name + ' finished with code ' + $code + ' log ' + $Entry.OutLog)
    if ($code -ne 0) {
        if (Test-Path $Entry.OutLog) { Get-Content $Entry.OutLog -Tail 40 | ForEach-Object { Write-Host $_ } }
        if (Test-Path $Entry.ErrLog) { Get-Content $Entry.ErrLog -Tail 20 | ForEach-Object { Write-Host $_ } }
        throw ('publish wave failed: ' + $Entry.Name + ' code ' + $code)
    }
}

function Merge-PublishPerfFromLogFile([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path) {
        if ($line -notmatch 'C35_PUBLISH_PERF') { continue }
        Merge-PublishPerfFromJsonLine $line
    }
}

Read-DotEnvLine $envFile

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
    $wave += Start-PublishWaveProcess -Name 'server' -ScriptPath $serverScript
}
if (-not $SkipApp) {
    $appArgs = @()
    if (-not $SkipDartGet) { $appArgs += '-SkipDartGet' }
    $wave += Start-PublishWaveProcess -Name 'app' -ScriptPath $appScript -ExtraArgs $appArgs
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
