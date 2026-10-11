# Delete spam: small image/jpeg|webp inline blobs in a created_ts window.
param(
    [Parameter(Mandatory)]
    [string] $FromDate,
    [Parameter(Mandatory)]
    [string] $ToDate,
    [int] $BatchLimit = 20000,
    [int] $MaxBatches = 0,
    [switch] $Safe,
    [switch] $Execute
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$EnvLocal = Join-Path $RepoRoot '.env.local'
if (Test-Path $EnvLocal) {
    Get-Content $EnvLocal | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim().Trim('"').Trim("'")
            if ($k -and $v) { Set-Item -Path "Env:$k" -Value $v }
        }
    }
}
if (-not $env:YB_PASSWORD) { throw 'YB_PASSWORD required' }

$YbUser = if ($env:YB_USER) { $env:YB_USER } else { 'csa' }
$YbDb = if ($env:YB_DATABASE) { $env:YB_DATABASE } else { 'c35' }
$Pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
if (-not $Pod) { throw 'yb-tserver pod not found' }

$CacheDir = Join-Path $RepoRoot '.cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$BuildSqlPath = Join-Path $RepoRoot '_\schemas\cas_gc_fast_build.sql'
$build = if ($Safe) { Get-Content -Raw -Encoding UTF8 $BuildSqlPath } else { '' }

$windowWhere = @"
m.store = 'inline'
  AND m.mime_type IN ('image/webp', 'image/jpeg')
  AND m.size_bytes < 65536
  AND m.created_ts >= '$FromDate'::date
  AND m.created_ts < '$ToDate'::date
"@

$keptFilter = if ($Safe) {
    'AND NOT EXISTS (SELECT 1 FROM cas_kept k WHERE k.hash = m.hash_blake3)'
} else { '' }

function Copy-SqlToPod([string]$LocalPath, [string]$RemotePath) {
    $full = (Resolve-Path -LiteralPath $LocalPath).Path
    $relFromRepo = $full.Substring($RepoRoot.Length).TrimStart('\', '/')
    Push-Location $RepoRoot
    try {
        kubectl cp -n yugabyte -c yb-tserver $relFromRepo "yugabyte/${Pod}:${RemotePath}" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'kubectl cp failed' }
    } finally { Pop-Location }
}

function Invoke-YsqlFile([string]$LocalSqlPath) {
    $remote = '/tmp/cas_spam_run.sql'
    Copy-SqlToPod $LocalSqlPath $remote
    $pass = $env:YB_PASSWORD.Replace("'", "'\''")
    $cmd = "export PGPASSWORD='$pass'; /home/yugabyte/bin/ysqlsh -h 127.0.0.1 -U $YbUser -d $YbDb -v ON_ERROR_STOP=1 -tAf $remote"
    kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c $cmd
    if ($LASTEXITCODE -ne 0) { throw 'ysqlsh failed' }
}

function Invoke-Ysql([string]$Sql) {
    $tmp = Join-Path $CacheDir ("cas_spam_{0}.sql" -f [guid]::NewGuid().ToString('n'))
    [IO.File]::WriteAllText($tmp, $Sql, [System.Text.UTF8Encoding]::new($false))
    try { Invoke-YsqlFile $tmp } finally { Remove-Item -Force $tmp -ErrorAction SilentlyContinue }
}

$auditSql = @"
$build
SELECT count(*)::text, coalesce(pg_size_pretty(sum(m.size_bytes)), '0 bytes')
FROM ai.file_blob_meta m
WHERE $windowWhere $keptFilter;
"@
Write-Host "==> Slice audit $FromDate .. $ToDate (Safe=$Safe)"
$auditLines = @(Invoke-Ysql $auditSql | Where-Object { $_ -and $_.Trim() })
Write-Host ("rows|bytes: {0}" -f ($auditLines -join ' '))

if (-not $Execute) { Write-Host 'Dry run. Pass -Execute to delete batches.'; exit 0 }

$deleteSql = @"
$build
WITH batch AS (
    SELECT m.hash_blake3
    FROM ai.file_blob_meta m
    WHERE $windowWhere $keptFilter
    LIMIT $BatchLimit
)
DELETE FROM ai.file_blob_meta m
USING batch b
WHERE m.hash_blake3 = b.hash_blake3
RETURNING 1;
"@
$deleteLocal = Join-Path $CacheDir 'cas_spam_delete_batch.sql'
[IO.File]::WriteAllText($deleteLocal, $deleteSql, [System.Text.UTF8Encoding]::new($false))
$deleteRemote = '/tmp/cas_spam_delete_batch.sql'
Copy-SqlToPod $deleteLocal $deleteRemote
$pass = $env:YB_PASSWORD.Replace("'", "'\''")
$ysqlCmd = "export PGPASSWORD='$pass'; /home/yugabyte/bin/ysqlsh -h 127.0.0.1 -U $YbUser -d $YbDb -v ON_ERROR_STOP=1 -tAf $deleteRemote"

$total = 0
$batch = 0
while ($true) {
    if ($MaxBatches -gt 0 -and $batch -ge $MaxBatches) { break }
    $out = @(kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c $ysqlCmd | Where-Object { $_ -and $_.Trim() })
    if ($LASTEXITCODE -ne 0) { throw 'ysqlsh failed' }
    $n = $out.Count
    $total += $n
    $batch++
    Write-Host ("batch {0}: deleted {1} (total {2})" -f $batch, $n, $total)
    if ($n -eq 0) { break }
}
Remove-Item -Force $deleteLocal -ErrorAction SilentlyContinue
Write-Host "Done. total_deleted=$total"