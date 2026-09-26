# Mirror of servers/crates/wire_http/scripts/agent_ota_rescue.ps1 (embedded in server_ai).
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File agent_ota_rescue.ps1
# Or:  https://alienai.id/download/agent-update.ps1

param(
    [string]$BaseUrl = 'https://alienai.id'
)

$ErrorActionPreference = 'Stop'

function Get-AgentDestExe {
    foreach ($name in @('alienai_remote_windows', 'c_remote_windows')) {
        $p = Get-Process -Name $name -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty Path
        if ($p) { return $p }
    }
    return Join-Path (Join-Path $env:LOCALAPPDATA 'AlienAI') 'alienai_remote_windows.exe'
}

function Stop-AgentProcesses {
    foreach ($name in @('alienai_remote_windows', 'c_remote_windows')) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 400
}

$ver = Invoke-RestMethod -Uri "$BaseUrl/version/remote-windows"
if (-not $ver.version -or -not $ver.url) { throw 'Invalid version response from server' }

$updatesRoot = Join-Path (Join-Path $env:LOCALAPPDATA 'AlienAI\updates') 'remote'
$staging = Join-Path $updatesRoot ([string]$ver.version)
New-Item -ItemType Directory -Force -Path $staging | Out-Null

$zipPath = Join-Path $staging 'bundle.zip'
Write-Host "==> Downloading remote agent build $($ver.version) ($($ver.versionName))..."
Invoke-WebRequest -Uri $ver.url -OutFile $zipPath -UseBasicParsing

if ($ver.size -and [int64]$ver.size -gt 0) {
    $len = (Get-Item -LiteralPath $zipPath).Length
    if ($len -ne [int64]$ver.size) {
        throw "Download size mismatch: got $len expected $($ver.size)"
    }
}

Expand-Archive -LiteralPath $zipPath -DestinationPath $staging -Force
Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue

$src = Join-Path $staging 'alienai_remote_windows.exe'
if (-not (Test-Path -LiteralPath $src)) {
    $src = Join-Path $staging 'c_remote_windows.exe'
}
if (-not (Test-Path -LiteralPath $src)) { throw 'OTA zip missing agent executable' }

$destExe = Get-AgentDestExe
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destExe) | Out-Null

Write-Host "==> Installing to $destExe"
Stop-AgentProcesses
Copy-Item -LiteralPath $src -Destination $destExe -Force

$legacy = Join-Path (Split-Path -Parent $destExe) 'c_remote_windows.exe'
if ($legacy -ne $destExe -and (Test-Path -LiteralPath $legacy)) {
    Remove-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue
}

Set-Content -LiteralPath (Join-Path $staging '.ready') -Value 'ok' -NoNewline

Write-Host '==> Starting agent'
Start-Process -FilePath $destExe
Write-Host '==> Done. Tray should show the new build after a few seconds.'
