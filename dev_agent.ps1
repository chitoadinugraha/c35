# Run c_remote_windows: kill existing agent, build, then show pairing UI (or --Cli for console code).
param(
    [switch]$Cli,
    [string]$ServerUrl = '',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CargoArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$remotesDir = Join-Path $root 'remotes'
$port = if ($env:LISTEN) { [int](($env:LISTEN -split ':')[-1]) } else { 8080 }

if (-not $ServerUrl) {
    $ServerUrl = if ($env:C35_SERVER_URL) { $env:C35_SERVER_URL } else { "http://127.0.0.1:$port" }
}
$env:C35_SERVER_URL = $ServerUrl.TrimEnd('/')

$agentName = 'alienai_remote_windows'
$agentProcs = @(Get-Process -Name $agentName -ErrorAction SilentlyContinue)
if ($agentProcs.Count -eq 0) {
    $agentProcs = @(Get-Process -Name 'c_remote_windows' -ErrorAction SilentlyContinue)
}
foreach ($p in $agentProcs) {
    Write-Host "==> kill $agentName pid $($p.Id)"
    & taskkill /F /T /PID $p.Id 2>$null | Out-Null
}
if ($agentProcs.Count -gt 0) { Start-Sleep -Milliseconds 300 }

Write-Host "alienai_remote_windows -> $env:C35_SERVER_URL"
if ($Cli) { Write-Host 'pairing mode: CLI (--cli)' } else { Write-Host 'pairing mode: window (use -Cli for console code)' }
Write-Host ''

Push-Location $remotesDir
try {
    $runArgs = @('run', '-p', 'c_remote_windows')
    if ($CargoArgs) { $runArgs += $CargoArgs }
    if ($Cli) { $runArgs += '--', '--cli' }
    & cargo @runArgs
    $code = $LASTEXITCODE
    # Ctrl+C / broken pipe — exit cleanly without cargo error noise
    if ($code -eq 130 -or $code -eq -1073741510) { exit 0 }
    exit $code
} finally {
    Pop-Location
}
