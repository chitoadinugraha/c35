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
    param([int]$Port)
    $line = netstat -ano | Select-String "LISTENING" | Select-String ":$Port\s" | Select-Object -First 1
    if (-not $line) { return $null }
    $parts = ($line.ToString().Trim() -split '\s+')
    $procId = [int]$parts[-1]
    if ($procId -le 0) { return $null }
    return $procId
}

function Test-LocalPortListening {
    param([int]$Port)
    $null -ne (netstat -ano | Select-String "LISTENING" | Select-String ":$Port\s" | Select-Object -First 1)
}

function Set-ExtensionAgentServerUrlInConfig {
    param([string]$Url)
    $configPath = Join-Path $env:LOCALAPPDATA 'AlienAI\config.json'
    if (-not (Test-Path -LiteralPath $configPath)) { return }
    try {
        $raw = [IO.File]::ReadAllText($configPath)
        $j = $raw | ConvertFrom-Json
        $j | Add-Member -NotePropertyName server_url -NotePropertyValue $Url -Force
        $out = $j | ConvertTo-Json -Depth 12
        [IO.File]::WriteAllText($configPath, $out, [System.Text.UTF8Encoding]::new($false))
        Write-Host "    config server_url -> $Url"
    } catch {
        Write-Warning "config server_url patch failed: $_"
    }
}

$listenerPid = Get-ExtensionAgentListenerPid -Port $IpcPort
if ($listenerPid -and $env:C35_EXTENSION_AGENT_REUSE -eq '1') {
    Write-Host "==> extension agent already listening on $IpcPort (pid $listenerPid)"
    Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Id -ne $listenerPid) {
            Write-Host "    kill extra alienai_remote_browser pid $($_.Id)"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
    exit 0
}
if ($listenerPid) {
    Write-Host "==> restart extension agent on $IpcPort (pid $listenerPid)"
    Stop-Process -Id $listenerPid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 400
}

Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "==> kill stale alienai_remote_browser pid $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 400

$env:C35_BROWSER_ENGINE = 'extension'
$env:C35_SKIP_OTA = '1'
if (-not $env:C35_SERVER_URL) {
    $ports = @(8080, 8000)
    if ($env:LISTEN -match ':(\d+)\s*$') {
        $ports = @([int]$Matches[1]) + $ports | Select-Object -Unique
    }
    $localUrl = $null
    foreach ($port in $ports) {
        if (Test-LocalPortListening -Port $port) {
            $localUrl = "http://127.0.0.1:$port"
            break
        }
    }
    $env:C35_SERVER_URL = if ($localUrl) { $localUrl } else { 'https://alienai.id' }
}

Set-ExtensionAgentServerUrlInConfig -Url $env:C35_SERVER_URL

Write-Host "==> start extension agent -> $AgentExe"
Write-Host "    server: $env:C35_SERVER_URL"
Start-Process -FilePath $AgentExe -WindowStyle Hidden
Start-Sleep -Seconds 2

$listenerPid = Get-ExtensionAgentListenerPid -Port $IpcPort
if ($listenerPid) {
    Write-Host "==> OK ipc port $IpcPort pid $listenerPid"
} else {
    Write-Warning "Agent started but port $IpcPort not listening yet. Check AlienAI logs."
}
