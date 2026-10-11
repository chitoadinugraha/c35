# Free a TCP listen port (default server_ai). Used by dev_server.ps1 before each run.
param(
    [int]$Port = 0,
    [switch]$Quiet
)

if ($Port -le 0) {
    $portScript = Join-Path $PSScriptRoot 'c35_server_port.ps1'
    if (Test-Path $portScript) { . $portScript }
    $Port = if ($script:C35ServerHttpPort) { $script:C35ServerHttpPort } else { 10000 }
}

$ErrorActionPreference = 'SilentlyContinue'

function Stop-ProcessTree([int]$ProcId) {
    if ($ProcId -le 0) { return }
    & taskkill /F /T /PID $ProcId 2>$null | Out-Null
}

$pids = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique |
    Where-Object { $_ -gt 0 })

foreach ($pid in $pids) {
    $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if (-not $p) { continue }
    if (-not $Quiet) { Write-Host "==> kill $($p.ProcessName) pid $pid (port $Port)" }
    Stop-ProcessTree $pid
}

if ($pids.Count -gt 0) { Start-Sleep -Milliseconds 300 }
