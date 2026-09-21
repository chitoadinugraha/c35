# Create YSQL database c35 on cluster (one-time). Requires kubectl + cluster .env.local.
$ErrorActionPreference = 'Stop'
$clusterEnv = 'D:\alienai_proto\cluster\.env.local'
if (-not (Test-Path $clusterEnv)) { throw "Missing $clusterEnv" }

Get-Content $clusterEnv | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $k = $matches[1].Trim(); $v = $matches[2].Trim()
        if ($k -and $v) { Set-Item -Path "Env:$k" -Value $v }
    }
}

$passCandidates = @($env:YB_YSQL_PASSWORD, 'yugabyte') | Where-Object { $_ } | Select-Object -Unique
if (-not $passCandidates) { throw 'YB_YSQL_PASSWORD missing in cluster .env.local' }

$pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
if (-not $pod) { throw 'yb-tserver pod not found' }

function Invoke-Ysql([string]$pass, [string]$sql) {
    kubectl -n yugabyte exec $pod -- sh -c "PGPASSWORD='$pass' ysqlsh -h 127.0.0.1 -U yugabyte -d yugabyte -tAc `"$sql`"" 2>&1
}

$pass = $null
foreach ($candidate in $passCandidates) {
    $probe = Invoke-Ysql $candidate 'SELECT 1'
    if ($LASTEXITCODE -eq 0 -and ($probe -match '1')) {
        $pass = $candidate
        break
    }
}
if (-not $pass) { throw 'yugabyte superuser auth failed (tried YB_YSQL_PASSWORD and default yugabyte)' }

$check = Invoke-Ysql $pass "SELECT 1 FROM pg_database WHERE datname='c35'"
if ($check -match '1') {
    Write-Host 'database c35 already exists'
    exit 0
}

Write-Host 'creating database c35...'
$out = kubectl -n yugabyte exec $pod -- sh -c "PGPASSWORD='$pass' ysqlsh -h 127.0.0.1 -U yugabyte -d yugabyte -c 'CREATE DATABASE c35 OWNER csa;'" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host $out
    throw 'failed to create database c35'
}
Write-Host 'done'
