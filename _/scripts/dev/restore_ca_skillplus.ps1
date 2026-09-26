# Restore ca_skillplus from yb-all-v2.sql (Aug 2026 backup section).
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Backup = 'D:\alienai_proto\cluster\migrate-backup\yb-all-v2.sql'
if (-not (Test-Path $Backup)) { throw "Missing $Backup" }

$ClusterEnv = 'D:\alienai_proto\cluster\.env.local'
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

Write-Host '==> scale down skillplus server'
kubectl scale deployment/server -n id-alienai-skillplus --replicas=0
kubectl wait -n id-alienai-skillplus --for=delete pod -l app.kubernetes.io/name=ca-skillplus --timeout=120s 2>$null

Write-Host '==> extract ca_skillplus section'
$extractPy = Join-Path $PSScriptRoot '_extract_ca_skillplus.py'
python $extractPy $Backup (Join-Path $env:TEMP 'ca_skillplus-restore.sql')
$sqlFile = Join-Path $env:TEMP 'ca_skillplus-restore.sql'
if (-not (Test-Path $sqlFile)) { throw 'extract failed' }
$mb = [math]::Round((Get-Item $sqlFile).Length / 1MB, 2)
Write-Host "    extracted ${mb} MiB -> $sqlFile"

$dbExists = Invoke-YsqlSuperT "SELECT 1 FROM pg_database WHERE datname='ca_skillplus'"
if ($null -eq $dbExists) { $dbExists = '' }
$dbExists = $dbExists.Trim()
if ($dbExists -eq '1') {
    Write-Host '==> drop existing ca_skillplus'
    Invoke-YsqlSuper "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='ca_skillplus' AND pid <> pg_backend_pid();"
    Invoke-YsqlSuper 'DROP DATABASE ca_skillplus;'
}

Write-Host '==> create database ca_skillplus'
Invoke-YsqlSuper 'CREATE DATABASE ca_skillplus OWNER csa;'
Invoke-YsqlSuper 'GRANT ALL ON DATABASE ca_skillplus TO csa;'

Write-Host '==> import SQL (may take a few minutes)'
$localSql = Join-Path $PSScriptRoot 'ca_skillplus-restore.sql'
Copy-Item $sqlFile $localSql -Force
Push-Location $PSScriptRoot
try {
    kubectl cp .\ca_skillplus-restore.sql "yugabyte/${Pod}:/tmp/ca_skillplus-restore.sql" -c yb-tserver -n yugabyte
    if ($LASTEXITCODE -ne 0) { throw 'kubectl cp failed' }
} finally {
    Pop-Location
}
kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c "/home/yugabyte/bin/ysqlsh -h $YbSock -U yugabyte -d ca_skillplus -v ON_ERROR_STOP=1 -f /tmp/ca_skillplus-restore.sql"
if ($LASTEXITCODE -ne 0) { throw 'import failed' }

Write-Host '==> verify csa login + table count'
$check = kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c "export PGPASSWORD='$($env:YB_PASSWORD)'; /home/yugabyte/bin/ysqlsh -h 127.0.0.1 -U csa -d ca_skillplus -tAc \"SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema','sys')\""
Write-Host "    tables: $check"

Write-Host '==> scale skillplus back up'
kubectl scale deployment/server -n id-alienai-skillplus --replicas=1
kubectl rollout status deployment/server -n id-alienai-skillplus --timeout=180s

Write-Host '==> done'
