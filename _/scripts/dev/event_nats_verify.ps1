param(
    [int]$OwnerIid = 33000,
    [int]$TimeoutSec = 45
)
$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envLocal = Join-Path $repo ".env.local"
if (Test-Path $envLocal) {
    Get-Content $envLocal | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim().Trim('"')
            [Environment]::SetEnvironmentVariable($k, $v, "Process")
        }
    }
}
if (-not $env:NATS_URL) { throw "NATS_URL missing" }
if (-not $env:DATABASE_URL) { throw "DATABASE_URL missing" }
$specific = "c35.user.$OwnerIid.ev.>"
$countFile = Join-Path $env:TEMP "c35_event_smoke_count_$OwnerIid.txt"
Remove-Item $countFile -ErrorAction SilentlyContinue
$natsCli = Get-Command nats -ErrorAction SilentlyContinue
$listenJob = $null
if ($natsCli) {
    $listenJob = Start-Job -ScriptBlock {
        param($Url, $Sub, $OutFile, $Timeout)
        $env:NATS_URL = $Url
        $deadline = (Get-Date).AddSeconds($Timeout)
        $n = 0
        while ((Get-Date) -lt $deadline) {
            $msg = nats sub $Sub --count=1 --timeout=5s 2>$null
            if ($LASTEXITCODE -eq 0 -and $msg) { $n = 1; break }
        }
        Set-Content -Path $OutFile -Value $n -Encoding ASCII
    } -ArgumentList $env:NATS_URL, $specific, $countFile, $TimeoutSec
    Start-Sleep -Seconds 2
}
$env:C35_EVENT_SMOKE_OWNER = "$OwnerIid"
Push-Location (Join-Path $repo "servers")
try { cargo run -q -p c35_mod_event --example emit_smoke } finally { Pop-Location }
if ($listenJob) {
    Wait-Job $listenJob -Timeout ($TimeoutSec + 10) | Out-Null
    Remove-Job $listenJob -Force -ErrorAction SilentlyContinue
    $heard = 0
    if (Test-Path $countFile) { $heard = [int](Get-Content $countFile -Raw) }
    if ($heard -ne 1) { throw "Expected 1 NATS message on $specific, got $heard" }
    Write-Host "OK: one publish -> one message on $specific"
} else {
    Write-Host "emit_smoke ok (no nats CLI for listen verify)"
}