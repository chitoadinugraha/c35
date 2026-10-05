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
$firebaseJson = Join-Path $root '_\certs\firebase-service.json'
if (Test-Path $firebaseJson) {
    if (-not $env:FIREBASE_SERVICE_ACCOUNT_PATH) { $env:FIREBASE_SERVICE_ACCOUNT_PATH = $firebaseJson }
} else {
    Write-Host "WARNING: missing $firebaseJson - Google Sheets write disabled locally (copy cs_bots _/certs/firebase-service.json)"
}

$env:DEV_SERVER_PORT = $port
$env:C35_ICE_LOCAL_DEV = '1'
if (-not $env:C35_LIVE_ENABLED) { $env:C35_LIVE_ENABLED = '1' }
if (-not $env:C35_SERVER_URL) {
    $env:C35_SERVER_URL = "http://127.0.0.1:$port"
}

& $stopScript -Port $port

if (-not (Test-Path $envFile)) {
    Write-Host "Missing $envFile - copy from servers/server_ai/.env.example"
    exit 1
}

if (-not (Get-Command cargo-watch -ErrorAction SilentlyContinue)) {
    Write-Host 'install cargo-watch: cargo install cargo-watch'
    exit 1
}

Write-Host 'server_ai (watch)'
Write-Host ''

$cargoWatchArgs = @(
    'watch',
    '-C', $serverDir,
    '-c', '-d', '1',
    '-w', 'server_ai',
    '-w', 'crates',
    '-w', $schemasDir,
    '-x', 'build -p server_ai',
    '-s', $loopCmd
)
if ($CargoArgs) { $cargoWatchArgs += $CargoArgs }
& cargo @cargoWatchArgs
