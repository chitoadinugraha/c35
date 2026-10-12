# Idempotent backfill of ai.blob_ref from existing CAS citation surfaces.
param(
    [switch] $DryRun,
    [int] $Limit = 0,
    [long] $OwnerIid = 0
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
$Pod = kubectl -n yugabyte get pods -l app=yb-tserver -o jsonpath='{.items[0].metadata.name}'
if (-not $Pod) { throw 'yb-tserver pod not found' }

$ownerFilter = ''
if ($OwnerIid -gt 0) {
    $ownerFilter = " AND billable_owner_iid = $OwnerIid"
}

$limitClause = ''
if ($Limit -gt 0) {
    $limitClause = " LIMIT $Limit"
}

$sql = @"
-- drive
INSERT INTO ai.blob_ref (billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key)
SELECT d.owner_iid, 'user', d.owner_iid, lower(d.hash_blake3), 'drive', 'drive:' || d.id::text
FROM ai.drive_file d
WHERE d.deleted_ts IS NULL AND d.hash_blake3 ~ '^[0-9a-f]{64}$'
  AND EXISTS (SELECT 1 FROM ai.file_blob_meta m WHERE m.hash_blake3 = lower(d.hash_blake3))
  $(if ($OwnerIid -gt 0) { "AND d.owner_iid = $OwnerIid" } else { '' })
ON CONFLICT (scope_kind, scope_iid, source_key) DO UPDATE SET
  hash_blake3 = EXCLUDED.hash_blake3,
  billable_owner_iid = EXCLUDED.billable_owner_iid,
  source = EXCLUDED.source;

-- tool artifacts
INSERT INTO ai.blob_ref (billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key)
SELECT t.owner_iid, 'user', t.owner_iid, lower(t.hash_blake3), 'tool_artifact', 'tool_artifact:' || t.id::text
FROM ai.tool_artifact t
WHERE t.deleted_ts IS NULL AND t.hash_blake3 ~ '^[0-9a-f]{64}$'
  AND EXISTS (SELECT 1 FROM ai.file_blob_meta m WHERE m.hash_blake3 = lower(t.hash_blake3))
  $(if ($OwnerIid -gt 0) { "AND t.owner_iid = $OwnerIid" } else { '' })
ON CONFLICT (scope_kind, scope_iid, source_key) DO UPDATE SET
  hash_blake3 = EXCLUDED.hash_blake3,
  billable_owner_iid = EXCLUDED.billable_owner_iid,
  source = EXCLUDED.source;

-- chat messages (user / bot_peer)
INSERT INTO ai.blob_ref (billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key)
SELECT
  CASE WHEN c.kind = 'bot_peer' AND c.bot_iid IS NOT NULL THEN COALESCE(b.owner_iid, c.owner_iid) ELSE cm.owner_iid END,
  CASE WHEN c.kind = 'bot_peer' AND c.bot_iid IS NOT NULL THEN 'bot' ELSE 'user' END,
  CASE WHEN c.kind = 'bot_peer' AND c.bot_iid IS NOT NULL THEN c.bot_iid ELSE cm.owner_iid END,
  lower(m[1]),
  'chat',
  'chat_msg:' || cm.id::text || ':' || lower(m[1])
FROM ai.chat_msg cm
JOIN ai.chat c ON c.id = cm.chat_id AND c.deleted_ts IS NULL
LEFT JOIN ai.identity b ON b.id = c.bot_iid AND b.kind = 'bot'
CROSS JOIN LATERAL regexp_matches(
  coalesce(cm.attachments::text, '') || ' ' || coalesce(cm.blocks_json::text, '') || ' ' || coalesce(cm.content, ''),
  '[0-9a-f]{64}', 'gi') AS m
WHERE cm.deleted_ts IS NULL AND m[1] ~ '^[0-9a-f]{64}$'
  AND EXISTS (SELECT 1 FROM ai.file_blob_meta meta WHERE meta.hash_blake3 = lower(m[1]))
  $(if ($OwnerIid -gt 0) { "AND cm.owner_iid = $OwnerIid" } else { '' })
ON CONFLICT (scope_kind, scope_iid, source_key) DO UPDATE SET
  hash_blake3 = EXCLUDED.hash_blake3,
  billable_owner_iid = EXCLUDED.billable_owner_iid,
  source = EXCLUDED.source;

-- identity avatars
INSERT INTO ai.blob_ref (billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key)
SELECT i.id, 'user', i.id, lower(m[1]), 'identity', 'identity.pic:' || i.id::text
FROM ai.identity i
CROSS JOIN LATERAL regexp_matches(coalesce(i.pic, ''), '[0-9a-f]{64}', 'gi') AS m
WHERE i.is_active AND m[1] ~ '^[0-9a-f]{64}$'
  AND EXISTS (SELECT 1 FROM ai.file_blob_meta meta WHERE meta.hash_blake3 = lower(m[1]))
  $(if ($OwnerIid -gt 0) { "AND i.id = $OwnerIid" } else { '' })
ON CONFLICT (scope_kind, scope_iid, source_key) DO UPDATE SET
  hash_blake3 = EXCLUDED.hash_blake3,
  billable_owner_iid = EXCLUDED.billable_owner_iid,
  source = EXCLUDED.source;

SELECT COUNT(*)::bigint AS blob_ref_rows FROM ai.blob_ref $(if ($OwnerIid -gt 0) { "WHERE billable_owner_iid = $OwnerIid" } else { '' });
"@

$CacheDir = Join-Path $RepoRoot '.cache'
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
$sqlPath = Join-Path $CacheDir 'backfill_blob_ref_run.sql'
[System.IO.File]::WriteAllText($sqlPath, $sql, [System.Text.UTF8Encoding]::new($false))

if ($DryRun) {
    Write-Host "DryRun: SQL written to $sqlPath"
    exit 0
}

$remote = '/tmp/backfill_blob_ref.sql'
kubectl -n yugabyte cp ((Resolve-Path -LiteralPath ).Path)$sqlPath "${Pod}:$remote" | Out-Null
$out = kubectl -n yugabyte exec $Pod -c yb-tserver -- bash -lc "ysqlsh -h 127.0.0.1 -U $YbUser -d $YbDb -f $remote" 2>&1
Write-Host $out
if ($out -match 'blob_ref_rows') {
    Write-Host "Backfill complete."
}
