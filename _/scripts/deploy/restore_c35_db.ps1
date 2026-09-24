# Bootstrap csa + c35 on YB, apply schemas, import backup, restart c35-server.
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$ClusterEnv = 'D:\alienai_proto\cluster\.env.local'
if (-not (Test-Path $ClusterEnv)) { throw "Missing $ClusterEnv" }

Get-Content $ClusterEnv | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $k = $matches[1].Trim(); $v = $matches[2].Trim().Trim('"').Trim("'")
        if ($k -and $v) { Set-Item -Path "Env:$k" -Value $v }
    }
}

$YbSock = '/tmp/.yb.0.0.0.0:5433'
$Pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
if (-not $Pod) { throw 'yb-tserver pod not found' }

function Invoke-YsqlSuper([string]$Sql) {
    $esc = $Sql.Replace("'", "'\''")
    kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c "/home/yugabyte/bin/ysqlsh -h $YbSock -U yugabyte -d yugabyte -v ON_ERROR_STOP=1 -c '$esc'"
    if ($LASTEXITCODE -ne 0) { throw "ysql failed: $Sql" }
}

function Invoke-YsqlSuperT([string]$Sql) {
    kubectl -n yugabyte exec $Pod -c yb-tserver -- /home/yugabyte/bin/ysqlsh -h $YbSock -U yugabyte -d yugabyte -tAc $Sql
    if ($LASTEXITCODE -ne 0) { throw "ysql failed: $Sql" }
}

Write-Host '==> create/update role csa'
$pwEsc = $env:YB_PASSWORD.Replace("'", "''")
$roleSql = ('DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = ''csa'') THEN CREATE ROLE csa WITH LOGIN PASSWORD ''{0}''; ELSE ALTER ROLE csa WITH LOGIN PASSWORD ''{0}''; END IF; END $$;' -f $pwEsc)
Invoke-YsqlSuper $roleSql

$dbExists = (Invoke-YsqlSuperT "SELECT 1 FROM pg_database WHERE datname='c35'").Trim()
if ($dbExists -eq '1') {
    Write-Host '==> database c35 exists'
} else {
    Write-Host '==> create database c35'
    Invoke-YsqlSuper 'CREATE DATABASE c35 OWNER csa;'
}
Invoke-YsqlSuper 'GRANT ALL ON DATABASE c35 TO csa;'

$env:YB_DATABASE = 'c35'
$env:YB_USER = 'csa'
$env:PGHOST = $env:YB_HOST
$env:PGPORT = $env:YB_PORT
$env:PGUSER = $env:YB_USER
$env:PGPASSWORD = $env:YB_PASSWORD
$env:PGDATABASE = 'c35'

Write-Host '==> scale down DB clients (avoid advisory-lock / index DDL contention)'
kubectl scale deployment/c35-server deployment/c35-fetcher deployment/channel-whatsapp-device -n c35 --replicas=0 2>$null | Out-Null
kubectl wait -n c35 --for=delete pod -l app.kubernetes.io/name=c35-server --timeout=120s 2>$null
Start-Sleep -Seconds 3
kubectl -n yugabyte exec $Pod -c yb-tserver -- /home/yugabyte/bin/ysqlsh -h $YbSock -U yugabyte -d c35 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='c35' AND pid <> pg_backend_pid();" 2>$null | Out-Null

Write-Host '==> apply schemas (c35_migrate)'
Push-Location (Join-Path $RepoRoot 'servers')
try {
    cargo run -p c35_store --bin c35_migrate -- apply
    if ($LASTEXITCODE -ne 0) { throw 'c35_migrate apply failed' }
} finally {
    Pop-Location
}

$backup = 'D:\alienai_proto\cluster\migrate-backup\yb-all-v2.sql'
if (Test-Path $backup) {
    Write-Host '==> import CSA backup (yb-all-v2.sql)'
    & (Join-Path $RepoRoot '_\scripts\migrate\run_import.ps1') -SkipAvatars
    if ($LASTEXITCODE -ne 0) { throw 'run_import failed' }
} else {
    Write-Host "==> skip import (no backup at $backup)"
}

Write-Host '==> verify csa login'
$check = kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c "export PGPASSWORD='$($env:YB_PASSWORD)'; /home/yugabyte/bin/ysqlsh -h 127.0.0.1 -U csa -d c35 -tAc 'SELECT count(*) FROM ai.identity'"
if ($LASTEXITCODE -ne 0) { throw "csa auth or ai.identity missing: $check" }
Write-Host "    ai.identity rows: $check"

Write-Host '==> scale c35 services back up'
kubectl scale deployment/c35-fetcher deployment/channel-whatsapp-device -n c35 --replicas=1 2>$null | Out-Null
kubectl scale deployment/c35-server -n c35 --replicas=2
kubectl rollout status deployment/c35-server -n c35 --timeout=300s
if ($LASTEXITCODE -ne 0) { throw 'c35-server rollout failed' }

Write-Host '==> smoke https://api.alienai.id/livez'
$r = Invoke-WebRequest -Uri 'https://api.alienai.id/livez' -UseBasicParsing -TimeoutSec 30
if ($r.StatusCode -ne 200) { throw "livez status $($r.StatusCode)" }
Write-Host "    livez: ok"
Write-Host '==> restore done'
