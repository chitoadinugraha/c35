# Local server_ai with auto-reload and crash restart.
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CargoArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
. (Join-Path $root '_\scripts\dev\c35_server_port.ps1')
$serverDir = Join-Path $root 'servers'
$schemasDir = Join-Path $root '_\schemas'
$port = if ($env:LISTEN) { [int](($env:LISTEN -split ':')[-1]) } else { $C35ServerHttpPort }
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
# Guest /{alien_id}: use current render.rs on localhost (still published doc snapshot; Publish for prod).
if (-not $env:C35_GUEST_DEV_LIVE_RENDER) { $env:C35_GUEST_DEV_LIVE_RENDER = '1' }
if (-not $env:C35_LIVE_ENABLED) { $env:C35_LIVE_ENABLED = '1' }
if (-not $env:C35_SERVER_URL) {
    $env:C35_SERVER_URL = "http://127.0.0.1:$port"
}
# Device egress CONNECT proxy (local listener; use http://127.0.0.1:8443 in lease smoke tests)
if (-not $env:C35_EGRESS_PROXY_ENABLED) { $env:C35_EGRESS_PROXY_ENABLED = '1' }
if (-not $env:C35_EGRESS_PROXY_PUBLIC_URL) { $env:C35_EGRESS_PROXY_PUBLIC_URL = 'http://127.0.0.1:8443' }
# Absolute CAS path so cwd (cargo-watch / loop) does not split cache dirs.
if (-not $env:CAS_DIR) {
    $env:CAS_DIR = (Join-Path $root '.cache/cas')
}

# Stale dev processes fight over the listen port and look like a crash loop.
foreach ($name in @('server_ai', 'cargo-watch')) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "==> stopping stale $($_.ProcessName) pid $($_.Id)"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
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
