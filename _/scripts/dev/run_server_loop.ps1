# Run server_ai.exe in a loop. cargo-watch kills this script on file changes.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string]$Port = '8080'
)

$ErrorActionPreference = 'Continue'
$exe = Join-Path $Root ".cache\server\debug\server_ai.exe"
$stopScript = Join-Path $Root "_\scripts\dev\stop_listen_port.ps1"
$restartDelaySec = 1

while ($true) {
    & $stopScript -Port $Port -Quiet
    if (-not (Test-Path $exe)) {
        Write-Host "==> waiting for $exe"
        Start-Sleep -Seconds $restartDelaySec
        continue
    }
    Write-Host "==> starting server_ai (port $Port)"
    Push-Location $Root
    try {
        & $exe
        $code = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    if ($code -eq 0) { Write-Host "==> server exited cleanly"; break }
    Write-Host "==> server exited ($code), restarting in ${restartDelaySec}s..."
    Start-Sleep -Seconds $restartDelaySec
}
