# Live prod OTA on isolated profile: release agent, https://alienai.id, download + apply restart.
# Does not touch your real %LOCALAPPDATA%\AlienAI (uses a temp sandbox).
# Usage:
#   .\_\scripts\dev\test_remote_ota_prod_agent.ps1
#   .\_\scripts\dev\test_remote_ota_prod_agent.ps1 -AgentBuild 2 -WaitSeconds 240

param(
    [int]$AgentBuild = 0,
    [int]$TargetVersion = 0,
    [int]$WaitSeconds = 240,
    [string]$ProdBaseUrl = 'https://alienai.id'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

if ($TargetVersion -le 0) {
    $live = Invoke-RestMethod -Uri "$ProdBaseUrl/version/remote-windows" -Method Get
    $TargetVersion = [int]$live.version
}
if ($AgentBuild -le 0) {
    $AgentBuild = [Math]::Max(2, $TargetVersion - 1)
}
if ($AgentBuild -ge $TargetVersion) { throw "AgentBuild must be < TargetVersion ($AgentBuild >= $TargetVersion)" }

$agentExe = Join-Path $repoRoot ".cache\remote-autoupdate-test\v$AgentBuild\c_remote_windows.exe"
if (-not (Test-Path $agentExe)) {
    & (Join-Path $PSScriptRoot 'ensure_remote_autoupdate_fixture.ps1') -Build $AgentBuild
}

$sandbox = Join-Path $env:TEMP "c35-ota-sandbox-$([Guid]::NewGuid().ToString('n'))"
New-Item -ItemType Directory -Force -Path $sandbox | Out-Null
Write-Host "==> prod agent OTA sandbox LOCALAPPDATA=$sandbox"
Write-Host "==> agent build $AgentBuild -> target $TargetVersion (release mode, server $ProdBaseUrl)"

Remove-Item Env:C35_DEV -ErrorAction SilentlyContinue
Remove-Item Env:C35_SERVER -ErrorAction SilentlyContinue
Remove-Item Env:C35_SERVER_URL -ErrorAction SilentlyContinue

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $agentExe
$psi.WorkingDirectory = (Split-Path $agentExe -Parent)
$psi.UseShellExecute = $false
foreach ($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
    $k = [string]$entry.Key
    if ($k -eq 'LOCALAPPDATA' -or $k -eq 'C35_DEV' -or $k -eq 'C35_SERVER' -or $k -eq 'C35_SERVER_URL') { continue }
    $psi.EnvironmentVariables[$k] = [string]$entry.Value
}
$psi.EnvironmentVariables['LOCALAPPDATA'] = $sandbox

$proc = [System.Diagnostics.Process]::Start($psi)
$startPid = $proc.Id
$updatesRoot = Join-Path $sandbox 'AlienAI\updates\remote'
$ready = Join-Path $updatesRoot "$TargetVersion\.ready"
$configPath = Join-Path $sandbox 'AlienAI\config.json'

$deadline = (Get-Date).AddSeconds($WaitSeconds)
$readyOk = $false
$applied = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    if (Test-Path $ready) { $readyOk = $true }
    if ($proc.HasExited -and $readyOk) { $applied = $true; break }
    if ($proc.HasExited -and -not $readyOk) {
        Write-Host "agent exited early pid=$startPid exit=$($proc.ExitCode)"
        break
    }
}

Stop-Process -Name c_remote_windows -Force -ErrorAction SilentlyContinue

if (-not $readyOk) {
    Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
    throw "Timed out: .ready for v$TargetVersion not found under sandbox"
}
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw
    if ($cfg -match 'session_key') {
        Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
        throw 'Sandbox config unexpectedly contains session_key'
    }
}

$logDir = Join-Path $sandbox 'AlienAI\logs'
$logText = ''
if (Test-Path $logDir) {
    $logText = (Get-ChildItem $logDir -Filter 'agent-*.log' -ErrorAction SilentlyContinue | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
}
if ($logText -notmatch 'AUTO-UPDATE STAGED') {
    Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
    throw 'Expected AUTO-UPDATE STAGED in sandbox logs'
}
$stagedExe = Join-Path $updatesRoot "$TargetVersion\c_remote_windows.exe"
if (-not (Test-Path $stagedExe)) {
    Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
    throw "Staged exe missing before apply: $stagedExe"
}
if ($logText -notmatch 'AUTO-UPDATE APPLYING') {
    Write-Warning 'AUTO-UPDATE APPLYING not found in sandbox log'
} elseif (-not $applied) {
    Write-Warning 'Agent still running after apply log (expected exit for restart)'
} else {
    Write-Host '  apply triggered agent restart (exit after apply.ps1)'
}

Start-Sleep -Seconds 8
Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
Write-Host '==> prod agent OTA sandbox PASS (live alienai.id download; isolated profile)'
