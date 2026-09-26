# CSA -> c35 user + referral import (handles, badges, profile pics, @chito uid 99000).
param(
    [switch]$SkipAvatars
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$clusterEnv = 'D:\alienai_proto\cluster\.env.local'
if (-not (Test-Path $clusterEnv)) { throw "Missing $clusterEnv" }

Get-Content $clusterEnv | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $k = $matches[1].Trim(); $v = $matches[2].Trim().Trim('"').Trim("'")
        if ($k -and $v) { Set-Item -Path "Env:$k" -Value $v }
    }
}

$env:YB_HOST = if ($env:YB_HOST) { $env:YB_HOST } else { 'yb-tservers.yugabyte.svc.cluster.local' }
$env:YB_PORT = if ($env:YB_PORT) { $env:YB_PORT } else { '5433' }
$env:YB_USER = if ($env:YB_USER) { $env:YB_USER } else { 'csa' }
$env:YB_PASSWORD = if ($env:YB_PASSWORD) { $env:YB_PASSWORD } elseif ($env:PGPASSWORD) { $env:PGPASSWORD } else { 'yugabyte' }
$env:YB_DATABASE = 'c35'
$env:CSA_DATABASE = 'csa'

if (-not $env:CAS_HMAC_SECRET) {
    $secretB64 = kubectl get secret c35-server-env -n c35 -o jsonpath='{.data.CAS_HMAC_SECRET}' 2>$null
    if ($secretB64) {
        $env:CAS_HMAC_SECRET = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($secretB64))
    }
}
if (-not $env:CAS_HMAC_SECRET) {
    $c35Env = Join-Path $root 'servers\server_ai\.env.local'
    if (Test-Path $c35Env) {
        Get-Content $c35Env | ForEach-Object {
            if ($_ -match '^\s*([^#=]+)=(.*)$') {
                $k = $matches[1].Trim(); $v = $matches[2].Trim()
                if ($k -eq 'CAS_HMAC_SECRET' -and $v) { $env:CAS_HMAC_SECRET = $v }
            }
        }
    }
}

Write-Host '==> pip install migrate deps'
python -m pip install -q psycopg2-binary blake3 2>$null
if ($LASTEXITCODE -ne 0) { throw 'pip install failed' }

$migrateDir = $PSScriptRoot
Write-Host '==> import_from_backup.py (yb-all-v2.sql -> c35)'
python (Join-Path $migrateDir 'import_from_backup.py')
if ($LASTEXITCODE -ne 0) { throw 'import_from_backup failed' }

Write-Host '==> migrate_csa_passwords.py (CSA pass_hash -> ai.identity_provider)'
python (Join-Path $migrateDir 'migrate_csa_passwords.py')
if ($LASTEXITCODE -ne 0) { throw 'migrate_csa_passwords failed' }

Write-Host '==> migrate_csa_google.py (CSA Google -> ai.identity_provider; zero old balances)'
python (Join-Path $migrateDir 'migrate_csa_google.py')
if ($LASTEXITCODE -ne 0) { throw 'migrate_csa_google failed' }

if (-not $SkipAvatars) {
    Write-Host '==> migrate_avatars_to_fs.py (http avatars -> CAS)'
    python (Join-Path $migrateDir 'migrate_avatars_to_fs.py')
    if ($LASTEXITCODE -ne 0) { throw 'migrate_avatars_to_fs failed' }
}

Write-Host '==> verify @chito'
python -c @"
import os, psycopg2
conn = psycopg2.connect(
    host=os.environ['YB_HOST'], port=os.environ['YB_PORT'],
    user=os.environ['YB_USER'], password=os.environ['YB_PASSWORD'], dbname='c35')
cur = conn.cursor()
cur.execute(\"SELECT id, alien_id, name, left(pic, 60), meta->'global_roles' FROM ai.identity WHERE id = 99000\")
print('chito:', cur.fetchone())
cur.execute('SELECT COUNT(*) FROM ai.identity WHERE kind=%s', ('user',))
print('users:', cur.fetchone()[0])
cur.execute('SELECT COUNT(*) FROM ai.referral_share')
print('shares:', cur.fetchone()[0])
cur.execute('SELECT COUNT(*) FROM ai.file_blob_inline')
print('blobs:', cur.fetchone()[0])
cur.execute("SELECT COUNT(*) FROM ai.identity_provider WHERE kind='password' AND deleted_ts IS NULL")
print('password_providers:', cur.fetchone()[0])
cur.execute("SELECT COUNT(*) FROM ai.identity_provider WHERE kind='google' AND deleted_ts IS NULL")
print('google_providers:', cur.fetchone()[0])
conn.close()
"@

Write-Host '==> done'
