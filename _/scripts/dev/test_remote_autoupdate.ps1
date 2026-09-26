# E2E: run prior-build remote agent against mock /version + zip (no prod CAS).
# Defaults: prod /version for target; agent build = target-1 (minimum 2).
# Usage:
#   .\_\scripts\dev\test_remote_autoupdate.ps1
#   .\_\scripts\dev\test_remote_autoupdate.ps1 -AgentBuild 2 -TargetVersion 3

param(
    [string]$AgentExe = '',
    [string]$Zip = '',
    [int]$AgentBuild = 0,
    [int]$TargetVersion = 0,
    [int]$WaitSeconds = 180,
    [int]$MockPort = 8877,
    [string]$ProdBaseUrl = 'https://alienai.id'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

if ($TargetVersion -le 0) {
    $live = Invoke-RestMethod -Uri "$ProdBaseUrl/version/remote-windows" -Method Get
    $TargetVersion = [int]$live.version
}
if ($TargetVersion -lt 2) { throw "TargetVersion must be >= 2 (prod is $TargetVersion)" }

if ($AgentBuild -le 0) {
    $AgentBuild = [Math]::Max(2, $TargetVersion - 1)
}
if ($AgentBuild -ge $TargetVersion) {
    throw "AgentBuild ($AgentBuild) must be < TargetVersion ($TargetVersion)"
}

if (-not $AgentExe) {
    $AgentExe = Join-Path $repoRoot ".cache\remote-autoupdate-test\v$AgentBuild\c_remote_windows.exe"
}
if (-not (Test-Path $AgentExe)) {
    Write-Host "==> building fixture for build $AgentBuild"
    & (Join-Path $PSScriptRoot 'ensure_remote_autoupdate_fixture.ps1') -Build $AgentBuild
}
if (-not $Zip) {
    $Zip = Join-Path $repoRoot ".cache\c_remote\remote-windows\c_remote_windows-$TargetVersion.zip"
}
if (-not (Test-Path $Zip)) {
    throw "Zip not found: $Zip (run remote publish or copy prod bundle)"
}

$hashTool = Join-Path $repoRoot '.cache\rust\hash_blake3\release\hash_blake3.exe'
if (-not (Test-Path $hashTool)) {
    $env:CARGO_TARGET_DIR = Join-Path $repoRoot '.cache\rust\hash_blake3'
    cargo build --release --manifest-path (Join-Path $repoRoot '_\scripts\deploy\tools\hash_blake3\Cargo.toml')
}
$hash = (& $hashTool $Zip).Trim().ToLower()
Write-Host "==> agent build=$AgentBuild -> target=$TargetVersion hash=$hash size=$((Get-Item $Zip).Length)"

$updatesRoot = Join-Path $env:LOCALAPPDATA 'AlienAI\updates\remote'
if (Test-Path $updatesRoot) {
    Remove-Item -Recurse -Force $updatesRoot
}

$mockPy = Join-Path $PSScriptRoot 'remote_autoupdate_mock_server.py'
$mockProc = Start-Process -FilePath python -ArgumentList @($mockPy, $Zip, $hash, $MockPort, $TargetVersion) -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 1

$agentDir = Split-Path $AgentExe -Parent
Remove-Item Env:C35_DEV -ErrorAction SilentlyContinue

Write-Host "==> starting agent build $AgentBuild from $AgentExe (mock http://127.0.0.1:$MockPort)"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $AgentExe
$psi.WorkingDirectory = $agentDir
$psi.UseShellExecute = $false
foreach ($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
    $k = [string]$entry.Key
    if ($k -eq 'C35_SERVER' -or $k -eq 'C35_SERVER_URL') { continue }
    $psi.EnvironmentVariables[$k] = [string]$entry.Value
}
$psi.EnvironmentVariables['C35_DEV'] = '1'
$psi.EnvironmentVariables['C35_SERVER'] = "http://127.0.0.1:$MockPort"
$agentProc = [System.Diagnostics.Process]::Start($psi)

$ready = Join-Path $updatesRoot "$TargetVersion\.ready"
$deadline = (Get-Date).AddSeconds($WaitSeconds)
$ok = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    if (Test-Path $ready) {
        $ok = $true
        break
    }
    if ($agentProc.HasExited) {
        Write-Host "agent exited (pid $($agentProc.Id)) exit=$($agentProc.ExitCode)"
        break
    }
}

if (-not $ok) {
    Stop-Process -Id $agentProc.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue
    throw "Timed out waiting for staged update (.ready). Check $env:LOCALAPPDATA\AlienAI\logs"
}

Write-Host "==> staged .ready present; waiting for apply/restart"
Start-Sleep -Seconds 12

$running = Get-Process -Name c_remote_windows -ErrorAction SilentlyContinue
Write-Host "==> running c_remote_windows processes: $($running.Count)"
foreach ($p in $running) { Write-Host "   pid=$($p.Id) path=$($p.Path)" }

Stop-Process -Name c_remote_windows -Force -ErrorAction SilentlyContinue
Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $ready)) { throw 'Update staging lost before completion' }

$logDir = Join-Path $env:LOCALAPPDATA 'AlienAI\logs'
$cutoff = (Get-Date).AddMinutes(-10)
$logText = ''
if (Test-Path $logDir) {
    $logText = (Get-ChildItem $logDir -Filter 'agent-*.log' | Where-Object { $_.LastWriteTime -ge $cutoff } | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
}
if ($logText -notmatch 'AUTO-UPDATE STAGED') {
    throw 'Expected AUTO-UPDATE STAGED in agent log'
}
if ($logText -notmatch 'AUTO-UPDATE APPLYING') {
    Write-Warning 'AUTO-UPDATE APPLYING not found in log (apply skipped in C35_DEV mock test)'
}

Write-Host "==> remote autoupdate E2E: PASS (build $AgentBuild -> $TargetVersion)"
