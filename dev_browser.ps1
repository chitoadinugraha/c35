# Local remote browser agent: pair against dev_server (or cluster), verbose logs, dev browser_engine path.
param(
    [switch]$Cli,
    [switch]$Watch,
    [switch]$EngineWatch,
    [switch]$SctpScreen,
    [switch]$RtpVideo,
    [switch]$Unpair,
    [string]$ServerUrl = '',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CargoArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$remotesDir = Join-Path $root 'remotes'
$engineDir = Join-Path $remotesDir 'browser_engine'
$workerJs = Join-Path $engineDir 'dist\worker.js'
$port = if ($env:LISTEN) { [int](($env:LISTEN -split ':')[-1]) } else { 8080 }

if (-not $ServerUrl) {
    $ServerUrl = if ($env:C35_SERVER_URL) { $env:C35_SERVER_URL } else { "http://127.0.0.1:$port" }
}
$env:C35_SERVER_URL = $ServerUrl.TrimEnd('/')
# Isolated from Chrome extension agent (`AlienAI\config.json`) and prod browser OTA (`browser\`).
$env:C35_AGENT_STORAGE = 'browser-dev'
Remove-Item Env:C35_BROWSER_ENGINE -ErrorAction SilentlyContinue
$env:C35_BROWSER_ENGINE_WORKER = $workerJs
if ($Unpair) {
    foreach ($cfg in @(
            (Join-Path $env:LOCALAPPDATA 'AlienAI\browser\config.json'),
            (Join-Path $env:LOCALAPPDATA 'AlienAI\browser-dev\config.json')
        )) {
        if (Test-Path $cfg) {
            Write-Host "==> unpair: remove $cfg"
            Remove-Item -LiteralPath $cfg -Force
        }
    }
}
# Dev: visible Chromium + pairing window (not console-only unless -Cli).
$env:C35_BROWSER_HEADLESS = '0'

if (-not $env:RUST_LOG) {
    $env:RUST_LOG = 'info,c_remote_browser=debug,c_remote_core::engine=debug,c_remote_core::task_run=debug,c_remote_core::webrtc=info'
}
if ($RtpVideo) {
    $env:C35_BROWSER_SCTP_SCREEN = '0'
} elseif ($SctpScreen -or -not $env:C35_BROWSER_SCTP_SCREEN) {
    $env:C35_BROWSER_SCTP_SCREEN = '1'
}

$agentName = 'alienai_remote_browser'
foreach ($p in @(Get-Process -Name $agentName -ErrorAction SilentlyContinue)) {
    Write-Host "==> kill $agentName pid $($p.Id)"
    & taskkill /F /T /PID $p.Id 2>$null | Out-Null
}
Start-Sleep -Milliseconds 200

Write-Host '==> remote browser dev'
Write-Host "    server:     $env:C35_SERVER_URL"
Write-Host "    config:     %LOCALAPPDATA%\AlienAI\browser-dev\"
Write-Host "    engine:     $workerJs"
Write-Host "    RUST_LOG:   $env:RUST_LOG"
if ($Cli) { Write-Host '    pair:       console only (-Cli)' } else { Write-Host '    pair:       GUI window with code + refresh timer (default)' }
Write-Host '    chromium:   headed (C35_BROWSER_HEADLESS=0)'
if ($Watch) { Write-Host '    rust:       cargo-watch' }
if ($EngineWatch) { Write-Host '    engine:     tsc -w (restart agent after TS changes)' }
Write-Host ''
try {
    $null = Invoke-WebRequest -Uri "$($env:C35_SERVER_URL)/health" -UseBasicParsing -TimeoutSec 3
} catch {
    Write-Warning "Dev server not reachable at $($env:C35_SERVER_URL) — start .\dev_server.ps1 in another terminal."
}
Write-Host 'Tip: run .\dev_server.ps1 in another terminal; pair device_type=browser; use MCP tool_exec browser.page.screenshot / browser.page.observe.'
Write-Host '      Re-pair locally: .\dev_browser.ps1 -Unpair'
Write-Host '      Dev JPEG: node _\scripts\dev\browser_page_screenshot_ipc_test.mjs  (worker IPC smoke)'
Write-Host ''

Push-Location $engineDir
try {
    if (-not (Test-Path (Join-Path $engineDir 'node_modules'))) {
        Write-Host '==> npm install (browser_engine)'
        & npm install
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    Write-Host '==> npm run build (browser_engine)'
    & npm run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

$engineWatchProc = $null
if ($EngineWatch) {
    Write-Host '==> npm run watch (background)'
    $engineWatchProc = Start-Process -FilePath 'npm' -ArgumentList @('run', 'watch') -WorkingDirectory $engineDir -PassThru -WindowStyle Minimized
}

Push-Location $remotesDir
try {
    if ($Watch) {
        if (-not (Get-Command cargo-watch -ErrorAction SilentlyContinue)) {
            Write-Host 'install cargo-watch: cargo install cargo-watch'
            exit 1
        }
        $runLine = if ($Cli) { 'run -p c_remote_browser -- --cli' } else { 'run -p c_remote_browser' }
        $watchArgs = @(
            'watch', '-c', '-d', '1',
            '-w', 'c_remote_browser',
            '-w', 'c_remote_core',
            '-x', $runLine
        )
        if ($CargoArgs) { $watchArgs += $CargoArgs }
        & cargo @watchArgs
        $code = $LASTEXITCODE
    } else {
        $runArgs = @('run', '-p', 'c_remote_browser')
        if ($CargoArgs) { $runArgs += $CargoArgs }
        if ($Cli) { $runArgs += '--', '--cli' }
        & cargo @runArgs
        $code = $LASTEXITCODE
    }
    if ($code -eq 130 -or $code -eq -1073741510) { $code = 0 }
    exit $code
} finally {
    Pop-Location
    if ($engineWatchProc -and -not $engineWatchProc.HasExited) {
        Stop-Process -Id $engineWatchProc.Id -Force -ErrorAction SilentlyContinue
    }
}
