# Mint DEPLOY_AUTH_TOKEN (session JWT for CAS upload) and write repo-root .env.local.
# Uses cluster secret C35_JWT_SECRET + identity iid 99000 (chito) by default.
#
# Usage:
#   .\_\scripts\deploy\mint_deploy_auth_token.ps1
#   .\_\scripts\deploy\mint_deploy_auth_token.ps1 -OwnerIid 99000

param(
    [int]$OwnerIid = 99000,
    [string]$Namespace = 'c35',
    [string]$SecretName = 'c35-server-env',
    [string]$EnvFile = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $EnvFile) { $EnvFile = Join-Path $repoRoot '.env.local' }

$b64 = kubectl get secret $SecretName -n $Namespace -o jsonpath='{.data.C35_JWT_SECRET}' 2>$null
if (-not $b64) {
    throw "Could not read C35_JWT_SECRET from secret $Namespace/$SecretName (kubectl required)."
}
$secret = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64)).Trim()
if ($secret.Length -lt 8) { throw 'C35_JWT_SECRET from cluster is empty or too short.' }

$py = @"
import json, time, secrets, sys
import jwt

secret = sys.argv[1]
iid = int(sys.argv[2])
now = int(time.time())
claims = {
    'sub': str(iid),
    'name': 'Deploy',
    'handle': '@deploy',
    'pic': '',
    'iat': now,
    'exp': now + 30 * 86400,
    'jti': str(secrets.randbits(63)),
}
print(jwt.encode(claims, secret, algorithm='HS256'))
"@

$token = python -c $py $secret $OwnerIid
if (-not $token -or $token.Length -lt 20) { throw 'Failed to mint JWT.' }

$lines = @()
if (Test-Path $EnvFile) {
    $lines = Get-Content $EnvFile -Encoding UTF8
    $lines = $lines | Where-Object { $_ -notmatch '^\s*DEPLOY_AUTH_TOKEN\s*=' }
}
$lines += "DEPLOY_AUTH_TOKEN=$token"
Set-Content -Path $EnvFile -Value $lines -Encoding UTF8
Write-Host "Wrote DEPLOY_AUTH_TOKEN to $EnvFile (iid=$OwnerIid, expires ~30d)."
