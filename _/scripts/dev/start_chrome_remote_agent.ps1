# Start exactly one Chrome extension background agent (extension IPC :37538).
param(
    [string]$AgentExe = '',
    [int]$IpcPort = 37538
)

$ErrorActionPreference = 'Stop'

if (-not $AgentExe) {
    $AgentExe = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\install\alienai_remote_browser.exe'
}
if (-not (Test-Path $AgentExe)) {
    throw "Agent not found: $AgentExe"
}

function Get-ExtensionAgentListenerPid {
    $conn = Get-NetTCPConnection -LocalPort $IpcPort -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $conn) { return $null }
    return [int]$conn.OwningProcess
}

$listenerPid = Get-ExtensionAgentListenerPid
if ($listenerPid) {
    Write-Host "==> extension agent already listening on $IpcPort (pid $listenerPid)"
    Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Id -ne $listenerPid) {
            Write-Host "    kill extra alienai_remote_browser pid $($_.Id)"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
    exit 0
}

Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "==> kill stale alienai_remote_browser pid $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 400

$env:C35_BROWSER_ENGINE = 'extension'
$env:C35_SKIP_OTA = '1'
if (-not $env:C35_SERVER_URL) {
    $env:C35_SERVER_URL = 'https://alienai.id'
}

Write-Host "==> start extension agent -> $AgentExe"
Write-Host "    server: $env:C35_SERVER_URL"
Start-Process -FilePath $AgentExe -WindowStyle Hidden
Start-Sleep -Seconds 2

$listenerPid = Get-ExtensionAgentListenerPid
if ($listenerPid) {
    Write-Host "==> OK ipc port $IpcPort pid $listenerPid"
} else {
    Write-Warning "Agent started but port $IpcPort not listening yet. Check AlienAI logs."
}