# Run server_ai.exe in a loop. cargo-watch kills this script on file changes.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string]$Port = '10000'
)

$ErrorActionPreference = 'Continue'
$exe = Join-Path $Root ".cache\server\debug\server_ai.exe"
$stopScript = Join-Path $Root "_\scripts\dev\stop_listen_port.ps1"
$restartDelaySec = 2
$lockFile = Join-Path $Root ".cache\dev-server-loop.lock"

function Wait-ListenPortFree([int]$ListenPort, [int]$MaxWaitMs = 8000) {
    $deadline = [DateTime]::UtcNow.AddMilliseconds($MaxWaitMs)
    while ([DateTime]::UtcNow -lt $deadline) {
        $busy = $false
        $portPat = ":$ListenPort\s"
        netstat -ano | ForEach-Object {
            $line = $_.Trim()
            if ($line -match 'LISTENING' -and $line -match $portPat) { $busy = $true }
        }
        if (-not $busy) { return }
        Start-Sleep -Milliseconds 250
    }
}

function Test-DevServerLoopOwner {
    if (-not (Test-Path $lockFile)) { return $true }
    try {
        $raw = Get-Content -LiteralPath $lockFile -Raw -ErrorAction Stop
        $pid = [int]($raw.Trim())
        if ($pid -le 0) { return $true }
        $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if (-not $p) { return $true }
        if ($pid -eq $PID) { return $true }
        Write-Host "==> another dev server loop is running (pid $pid). Stop extra dev_server / cargo-watch windows."
        return $false
    } catch {
        return $true
    }
}

if (-not (Test-DevServerLoopOwner)) {
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $lockFile) | Out-Null
Set-Content -LiteralPath $lockFile -Value $PID -Encoding ascii

try {
    while ($true) {
        & $stopScript -Port $Port -Quiet
        Wait-ListenPortFree -ListenPort $Port
        if (-not (Test-Path $exe)) {
            Write-Host "==> waiting for $exe"
            Start-Sleep -Seconds $restartDelaySec
            continue
        }
        Write-Host '==> starting server_ai'
        $t0 = [DateTime]::UtcNow
        $p = Start-Process -FilePath $exe -WorkingDirectory $Root -Wait -PassThru -NoNewWindow
        $code = if ($null -ne $p.ExitCode) { $p.ExitCode } else { 1 }
        $ranSec = ([DateTime]::UtcNow - $t0).TotalSeconds
        if ($code -eq 0) {
            Write-Host '==> server exited cleanly'
            break
        }
        if ($ranSec -lt 3) {
            Write-Host "==> server exited ($code) after $([int]$ranSec)s (check for a second dev_server/cargo-watch on port $Port)"
        } else {
            Write-Host "==> server exited ($code), restarting in ${restartDelaySec}s..."
        }
        & $stopScript -Port $Port -Quiet
        Start-Sleep -Seconds $restartDelaySec
    }
} finally {
    Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
}
