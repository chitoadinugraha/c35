# Copy CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID from csa_site_published .env.local
# into repo-root .env.local and servers/server_ai/.env.local (not committed).
param(
    [string]$CsaEnvFile = 'D:\csa_site_published\.env.local'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not (Test-Path $CsaEnvFile)) { throw "CSA env not found: $CsaEnvFile" }

function Read-DotEnv([string]$Path) {
    $map = [ordered]@{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $p = $line -split '=', 2
        if ($p.Length -ne 2) { return }
        $map[$p[0].Trim()] = $p[1].Trim().Trim('"').Trim("'")
    }
    return $map
}

function Set-EnvKey([string]$Path, [string]$Key, [string]$Value) {
    $lines = @(Get-Content $Path)
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^$Key=") {
            $lines[$i] = "$Key=$Value"
            $found = $true
            break
        }
    }
    if (-not $found) { $lines += "$Key=$Value" }
    [IO.File]::WriteAllText($Path, ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

$csa = Read-DotEnv $CsaEnvFile
foreach ($k in @('CLOUDFLARE_API_TOKEN', 'CLOUDFLARE_ACCOUNT_ID')) {
    if (-not $csa.Contains($k) -or [string]::IsNullOrWhiteSpace($csa[$k])) {
        throw "Missing $k in $CsaEnvFile"
    }
}

$targets = @(
    (Join-Path $repoRoot '.env.local'),
    (Join-Path $repoRoot 'servers\server_ai\.env.local')
)
foreach ($t in $targets) {
    if (-not (Test-Path $t)) { throw "Target env missing: $t" }
    foreach ($k in @('CLOUDFLARE_API_TOKEN', 'CLOUDFLARE_ACCOUNT_ID')) {
        Set-EnvKey $t $k $csa[$k]
    }
    Write-Host "==> updated $k in $t"
}

& (Join-Path $PSScriptRoot 'sync_c35_server_env.ps1') -Keys @('CLOUDFLARE_API_TOKEN', 'CLOUDFLARE_ACCOUNT_ID')
Write-Host '==> sync_cloudflare_from_csa done'
