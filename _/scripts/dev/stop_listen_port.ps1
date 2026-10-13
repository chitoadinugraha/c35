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

function Get-ListenPidsForPort([int]$ListenPort) {
    $found = @()
    try {
        $found = @(Get-NetTCPConnection -LocalPort $ListenPort -State Listen -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique |
            Where-Object { $_ -gt 0 })
    } catch {
        $found = @()
    }
    if ($found.Count -gt 0) { return $found }

    # NetTCPIP often fails to load on Windows PowerShell 5.1; netstat works everywhere.
    $portPat = ":$ListenPort\s"
    netstat -ano | ForEach-Object {
        $line = $_.Trim()
        if ($line -notmatch 'LISTENING') { return }
        if ($line -notmatch $portPat) { return }
        $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
        if ($parts.Count -lt 1) { return }
        $op = 0
        if ([int]::TryParse($parts[-1], [ref]$op) -and $op -gt 0) { $op }
    } | Select-Object -Unique
}

$pids = @(Get-ListenPidsForPort -ListenPort $Port)

foreach ($owningPid in $pids) {
    $p = Get-Process -Id $owningPid -ErrorAction SilentlyContinue
    if (-not $p) { continue }
    if (-not $Quiet) { Write-Host "==> kill $($p.ProcessName) pid $owningPid (port $Port)" }
    Stop-ProcessTree $owningPid
}

if ($pids.Count -gt 0) { Start-Sleep -Milliseconds 500 }
