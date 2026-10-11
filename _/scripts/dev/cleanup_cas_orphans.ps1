# Audit or delete unreferenced inline CAS blobs (ai.file_blob_meta store=inline).
param(
    [int] $MinAgeDays = 14,
    [int] $BatchLimit = 5000,
    [switch] $Execute,
    [switch] $SkipAudit
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

if (-not $env:YB_PASSWORD) {
    throw 'YB_PASSWORD required (repo-root .env.local or shell).'
}

$YbUser = if ($env:YB_USER) { $env:YB_USER } else { 'csa' }
$YbDb = if ($env:YB_DATABASE) { $env:YB_DATABASE } else { 'c35' }
$YbHost = '127.0.0.1'
$Pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
if (-not $Pod) { throw 'yb-tserver pod not found' }

$CacheDir = Join-Path $RepoRoot '.cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$BuildSqlPath = Join-Path $RepoRoot '_\schemas\cas_gc_fast_build.sql'
if (-not (Test-Path $BuildSqlPath)) { throw "Missing $BuildSqlPath" }

$build = Get-Content -Raw -Encoding UTF8 $BuildSqlPath

$orphanWhere = @"
m.store = 'inline'
  AND m.created_ts < NOW() - ($MinAgeDays::text || ' days')::interval
  AND m.mime_type IN ('image/webp', 'image/jpeg')
  AND m.size_bytes < 65536
  AND NOT EXISTS (SELECT 1 FROM cas_kept k WHERE k.hash = m.hash_blake3)
"@

function Invoke-YsqlFile([string]$LocalSqlPath) {
    $remote = '/tmp/cas_gc_run.sql'
    $full = (Resolve-Path -LiteralPath $LocalSqlPath).Path
    $relFromRepo = $full.Substring($RepoRoot.Length).TrimStart('\', '/')
    Push-Location $RepoRoot
    try {
        kubectl cp -n yugabyte -c yb-tserver $relFromRepo "yugabyte/${Pod}:${remote}" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'kubectl cp failed' }
    } finally {
        Pop-Location
    }
    $pass = $env:YB_PASSWORD.Replace("'", "'\''")
    $cmd = "export PGPASSWORD='$pass'; /home/yugabyte/bin/ysqlsh -h $YbHost -U $YbUser -d $YbDb -v ON_ERROR_STOP=1 -tAf $remote"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $raw = kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c $cmd 2>&1
    } finally {
        $ErrorActionPreference = $prevEap
    }
    $raw = @($raw | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { "$_" }
    })
    $text = ($raw | Out-String)
    if ($text -match '(?i)ERROR:|FATAL:') { throw "ysqlsh failed: $text" }
    if ($LASTEXITCODE -ne 0 -and $text -notmatch 'INSERT|DROP TABLE|CREATE TABLE|^\d') {
        throw "ysqlsh failed: $text"
    }
    return @($raw | Where-Object { $_ -and ($_ -notmatch 'NOTICE:') })
}

if (-not $SkipAudit) {
    $auditSql = @"
$build
SELECT count(*)::text || '|' || coalesce(pg_size_pretty(sum(m.size_bytes)), '0 bytes')
FROM ai.file_blob_meta m
WHERE $orphanWhere;
"@
    $tmpAudit = Join-Path $CacheDir ("cas_gc_audit_{0}.sql" -f [guid]::NewGuid().ToString('n'))
    [IO.File]::WriteAllText($tmpAudit, $auditSql, [System.Text.UTF8Encoding]::new($false))
    Write-Host "==> CAS orphan audit (small images, older than $MinAgeDays days)"
    $summary = Invoke-YsqlFile $tmpAudit
    Remove-Item -Force $tmpAudit
    Write-Host "orphan_count|orphan_bytes: $summary"
}

if (-not $Execute) {
    if (-not $SkipAudit) {
        Write-Host 'Dry run only. Pass -Execute to delete one batch (re-run until count is 0).'
    }
    exit 0
}

$deleteSql = @"
$build
WITH batch AS (
    SELECT m.hash_blake3
    FROM ai.file_blob_meta m
    WHERE $orphanWhere
    ORDER BY m.created_ts ASC
    LIMIT $BatchLimit
),
del AS (
    DELETE FROM ai.file_blob_meta m
    USING batch b
    WHERE m.hash_blake3 = b.hash_blake3
    RETURNING 1
)
SELECT count(*)::text FROM del;
"@

$tmpDelete = Join-Path $CacheDir ("cas_gc_delete_{0}.sql" -f [guid]::NewGuid().ToString('n'))
[IO.File]::WriteAllText($tmpDelete, $deleteSql, [System.Text.UTF8Encoding]::new($false))

Write-Host "==> Deleting up to $BatchLimit orphan inline blobs..."
$deleted = Invoke-YsqlFile $tmpDelete
Remove-Item -Force $tmpDelete
$countLine = @($deleted | Where-Object { $_ -match '^\d+$' } | Select-Object -Last 1)
$deletedCount = if ($countLine.Count -gt 0) { [int]$countLine[-1] } else { 0 }
Write-Host ("deleted_rows: {0}" -f $deletedCount)
