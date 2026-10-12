# Repeat cleanup_cas_orphans.ps1 -Execute until a batch deletes 0 rows.
param(
    [int] $MinAgeDays = 0,
    [int] $BatchLimit = 20000,
    [int] $MaxBatches = 150
)

$ErrorActionPreference = 'Continue'
$script = Join-Path $PSScriptRoot 'cleanup_cas_orphans.ps1'
$total = 0
for ($i = 1; $i -le $MaxBatches; $i++) {
    Write-Host "==> batch $i"
    $lines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $script -MinAgeDays $MinAgeDays -Execute -BatchLimit $BatchLimit -SkipAudit 2>&1)
    $n = 0
    foreach ($line in $lines) {
        $s = "$line"
        if ($s -match 'deleted_rows:\s*(\d+)') { $n = [int]$matches[1] }
    }
    Write-Host "deleted_rows: $n"
    $total += $n
    if ($n -eq 0) { break }
}
Write-Host "Total deleted this run: $total"
