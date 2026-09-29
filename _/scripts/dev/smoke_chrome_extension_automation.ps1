# Smoke: Chrome extension automation stack (extension IPC + native host pair.status).
param(
    [string]$AgentExe = '',
    [int]$IpcPort = 37538
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$NmTest = Join-Path $RepoRoot '_\scripts\dev\test_chrome_native_host.py'

if (-not $AgentExe) {
    $AgentExe = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\install\alienai_remote_browser.exe'
}

function Test-ExtensionIpcListening {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $conn) { return $null }
    return [int]$conn.OwningProcess
}

Write-Host "==> smoke chrome extension automation (ipc port $IpcPort)"

$listenerPid = Test-ExtensionIpcListening -Port $IpcPort
if (-not $listenerPid) {
    Write-Error "Extension agent not listening on port ${IpcPort}. Run: .\_\scripts\dev\start_chrome_remote_agent.ps1"
}
Write-Host "  OK ipc listen pid=$listenerPid port=$IpcPort"

if (-not (Test-Path $AgentExe)) {
    Write-Error "Agent exe not found: $AgentExe"
}
if (-not (Test-Path $NmTest)) {
    Write-Error "Missing NM test helper: $NmTest"
}

Write-Host "==> native messaging pair.status"
$nmOut = python $NmTest $AgentExe
$nmExit = $LASTEXITCODE
if ($nmExit -ne 0) {
    Write-Error "pair.status failed (exit $nmExit): $nmOut"
}
Write-Host $nmOut
try {
    $pairJson = $nmOut | ConvertFrom-Json
} catch {
    Write-Error "pair.status response is not JSON: $nmOut"
}
if ($pairJson.ok -ne $true) {
    Write-Error "pair.status ok=false: $($pairJson.error)"
}

Write-Host '==> smoke chrome extension automation PASS'