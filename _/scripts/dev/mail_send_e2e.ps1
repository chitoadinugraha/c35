# Live mail smoke (YSQL + Cloudflare SMTP). Loads repo .env.local for YB_* and CLOUDFLARE_API_TOKEN.
param(
    [string]$EnvFile = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $EnvFile) { $EnvFile = Join-Path $repoRoot '.env.local' }
if (-not (Test-Path $EnvFile)) { throw "Missing $EnvFile" }

function Read-DotEnv([string]$Path) {
    $map = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $p = $line -split '=', 2
        if ($p.Length -ne 2) { return }
        $map[$p[0].Trim()] = $p[1].Trim().Trim('"').Trim("'")
    }
    return $map
}

$envMap = Read-DotEnv $EnvFile
foreach ($k in @('YB_HOST', 'YB_PORT', 'YB_DATABASE', 'YB_USER', 'YB_PASSWORD', 'CLOUDFLARE_API_TOKEN', 'C35_JWT_SECRET', 'CAS_HMAC_SECRET')) {
    if ($envMap.ContainsKey($k)) { Set-Item -Path "env:$k" -Value $envMap[$k] }
}
if (-not $env:MAIL_INBOUND_SECRET -and $envMap.ContainsKey('MAIL_INBOUND_SECRET')) {
    Set-Item -Path 'env:MAIL_INBOUND_SECRET' -Value $envMap['MAIL_INBOUND_SECRET']
}
if (-not $env:MAIL_INBOUND_SECRET) {
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $secret = [Convert]::ToBase64String($bytes)
    Set-Item -Path 'env:MAIL_INBOUND_SECRET' -Value $secret
    Write-Host '==> generated ephemeral MAIL_INBOUND_SECRET for this run (add to .env.local + c35-server-env for inbound)'
}

$env:C35_TEST_DB = '1'
$env:MAIL_SMTP_HOST = 'smtp.mx.cloudflare.net'
$env:MAIL_SMTP_PORT = '465'
$env:MAIL_SMTP_USER = 'api_token'
$env:MAIL_SMTP_TLS = 'wrapper'
if (-not $env:MAIL_SMTP_PASS) { $env:MAIL_SMTP_PASS = $env:CLOUDFLARE_API_TOKEN }

Push-Location (Join-Path $repoRoot 'servers')
try {
    cargo run --example mail_send_live -p c35_mod_mail
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}
