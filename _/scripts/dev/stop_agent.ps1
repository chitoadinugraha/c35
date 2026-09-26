# Stop running Alien AI remote Windows agent processes.
param([switch]$Quiet)

$ErrorActionPreference = 'SilentlyContinue'

foreach ($agentName in @('alienai_remote_windows', 'c_remote_windows')) {
    $procs = @(Get-Process -Name $agentName -ErrorAction SilentlyContinue)
    foreach ($p in $procs) {
        if (-not $Quiet) { Write-Host "==> kill $agentName pid $($p.Id)" }
        & taskkill /F /T /PID $p.Id 2>$null | Out-Null
    }
}
