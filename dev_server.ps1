# Local server_ai with auto-reload and crash restart.
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CargoArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$serverDir = Join-Path $root 'servers'
$schemasDir = Join-Path $root '_\schemas'
$port = if ($env:LISTEN) { [int](($env:LISTEN -split ':')[-1]) } else { 8080 }
$loopCmd = Join-Path $root '_\scripts\dev\run_server_loop.cmd'
$stopScript = Join-Path $root '_\scripts\dev\stop_listen_port.ps1'
$envFile = Join-Path $root 'servers\server_ai\.env.local'

$env:DEV_SERVER_PORT = $port

& $stopScript -Port $port

if (-not (Test-Path $envFile)) {
    Write-Host "Missing $envFile - copy from servers/server_ai/.env.example"
    exit 1
}

if (-not (Get-Command cargo-watch -ErrorAction SilentlyContinue)) {
    Write-Host 'install cargo-watch: cargo install cargo-watch'
    exit 1
}

$listen = if ($env:LISTEN) { $env:LISTEN } else { "0.0.0.0:$port" }
Write-Host "server_ai (watch) -> http://$listen"
Write-Host ''

$cargoWatchArgs = @(
    'watch',
    '-C', $serverDir,
    '-c', '-d', '1',
    '-w', 'server_ai',
    '-w', 'crates',
    '-w', $schemasDir,
    '-x', 'build -p server_ai',
    '-s', ('"' + $loopCmd + '"')
)
if ($CargoArgs) { $cargoWatchArgs += $CargoArgs }
& cargo @cargoWatchArgs
