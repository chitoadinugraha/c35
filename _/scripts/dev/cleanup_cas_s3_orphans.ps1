# Delete unreferenced CAS blobs on S3-compatible storage (store=s3 in ai.file_blob_meta).
param(
    [int] $BatchLimit = 50,
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
if (-not $env:YB_PASSWORD) { throw 'YB_PASSWORD required' }
if (-not $env:S3_BUCKET) { throw 'S3_BUCKET required' }

$YbUser = if ($env:YB_USER) { $env:YB_USER } else { 'csa' }
$YbDb = if ($env:YB_DATABASE) { $env:YB_DATABASE } else { 'c35' }
$Pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
$build = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot '_\schemas\cas_gc_fast_build.sql')
$orphanWhere = "m.store = 's3' AND NOT EXISTS (SELECT 1 FROM cas_kept k WHERE k.hash = m.hash_blake3)"
$CacheDir = Join-Path $RepoRoot '.cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

function Invoke-YsqlFile([string]$SqlBody) {
    $tmp = Join-Path $CacheDir ("cas_s3_{0}.sql" -f [guid]::NewGuid().ToString('n'))
    [IO.File]::WriteAllText($tmp, $SqlBody, [System.Text.UTF8Encoding]::new($false))
    $rel = $tmp.Substring($RepoRoot.Length).TrimStart('\', '/')
    Push-Location $RepoRoot
    try { kubectl cp -n yugabyte -c yb-tserver $rel "yugabyte/${Pod}:/tmp/cas_s3_run.sql" | Out-Null } finally { Pop-Location }
    $pass = $env:YB_PASSWORD.Replace("'", "'\''")
    $cmd = "export PGPASSWORD='$pass'; /home/yugabyte/bin/ysqlsh -h 127.0.0.1 -U $YbUser -d $YbDb -v ON_ERROR_STOP=1 -tAF'|' -f /tmp/cas_s3_run.sql"
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $raw = kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -c $cmd 2>&1 } finally { $ErrorActionPreference = $prev }
    $raw = @($raw | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { "$_" } })
    if (($raw | Out-String) -match '(?i)ERROR:|FATAL:') { throw "ysqlsh failed: $raw" }
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    return @($raw | Where-Object { $_ -and $_ -notmatch 'NOTICE:' -and $_ -notmatch '^(DROP|CREATE|INSERT)' })
}

function Remove-S3Object([string]$ObjectKey) {
    $bucket = $env:S3_BUCKET
    if ($env:S3_ENDPOINT -match 'oraclecloud\.com') {
        $out = oci os object delete --bucket-name $bucket --name $ObjectKey --force 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -and $out -notmatch 'ObjectNotFound|does not exist') { throw "oci delete failed: $ObjectKey $out" }
        return
    }
    $aws = Get-Command aws -ErrorAction SilentlyContinue
    if (-not $aws) { throw 'Need oci or aws CLI' }
    $args = @('s3api','delete-object','--bucket',$bucket,'--key',$ObjectKey)
    if ($env:S3_ENDPOINT) { $args += @('--endpoint-url',$env:S3_ENDPOINT) }
    & aws @args 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "aws delete failed: $ObjectKey" }
}

if (-not $SkipAudit) {
    $auditSql = "$build`nSELECT count(*)::text || '|' || coalesce(pg_size_pretty(sum(m.size_bytes)), '0 bytes') FROM ai.file_blob_meta m WHERE $orphanWhere;"
    Write-Host '==> S3 CAS orphan audit'
    $lines = @(Invoke-YsqlFile $auditSql)
    $summary = @($lines | Where-Object { $_ -match '^\d+\|' } | Select-Object -Last 1)
    Write-Host "orphan_count|bytes: $summary"
    if (-not $Execute) { Write-Host 'Dry run. Pass -Execute.'; exit 0 }
}

$fetchSql = @"
$build
SELECT m.hash_blake3 || ',' || coalesce(m.loc->>'key', 'fs/' || m.hash_blake3)
FROM ai.file_blob_meta m WHERE $orphanWhere ORDER BY m.size_bytes DESC LIMIT $BatchLimit;
"@
Write-Host "==> S3 delete batch up to $BatchLimit"
$deleted = 0
foreach ($line in @(Invoke-YsqlFile $fetchSql)) {
    if ($line -notmatch '^[0-9a-f]{64},') { continue }
    $hash, $key = $line.Split(',', 2)
    Write-Host "  $key"
    Remove-S3Object $key
    Invoke-YsqlFile "DELETE FROM ai.file_blob_meta WHERE hash_blake3 = '$hash';" | Out-Null
    $deleted++
}
Write-Host "deleted_objects: $deleted"