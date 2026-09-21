# Stop running c_remote_windows agent processes.
param([switch]$Quiet)

$ErrorActionPreference = 'SilentlyContinue'

$procs = @(Get-Process -Name 'c_remote_windows' -ErrorAction SilentlyContinue)
foreach ($p in $procs) {
    if (-not $Quiet) { Write-Host "==> kill c_remote_windows pid $($p.Id)" }
    & taskkill /F /T /PID $p.Id 2>$null | Out-Null
}
