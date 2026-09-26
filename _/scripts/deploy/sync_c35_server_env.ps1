# Sync selected keys from repo-root .env.local into k8s secret c35-server-env.
# Usage:
#   .\_\scripts\deploy\sync_c35_server_env.ps1
#   .\_\scripts\deploy\sync_c35_server_env.ps1 -Restart

param(
    [string]$Namespace = 'c35',
    [string]$SecretName = 'c35-server-env',
    [string]$EnvFile = '',
    [switch]$Restart,
    [string[]]$Keys = @('S3_ACCESS_KEY', 'S3_SECRET_KEY', 'S3_BUCKET', 'S3_ENDPOINT', 'S3_REGION', 'S3_SECURE')
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $EnvFile) { $EnvFile = Join-Path $repoRoot '.env.local' }
if (-not (Test-Path $EnvFile)) { throw "Env file not found: $EnvFile" }

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
$raw = kubectl get secret $SecretName -n $Namespace -o json | ConvertFrom-Json
foreach ($k in $Keys) {
    if (-not $envMap.ContainsKey($k)) { Write-Warning "skip $k (not in .env.local)"; continue }
    $bytes = [Text.Encoding]::UTF8.GetBytes($envMap[$k])
    $raw.data | Add-Member -NotePropertyName $k -NotePropertyValue ([Convert]::ToBase64String($bytes)) -Force
}
$json = $raw | ConvertTo-Json -Depth 10 -Compress
$json | kubectl apply -f -
Write-Host "==> patched secret $Namespace/$SecretName ($($Keys -join ', '))"

if ($Restart) {
    kubectl rollout restart "deployment/c35-server" -n $Namespace
    kubectl rollout status "deployment/c35-server" -n $Namespace --timeout=300s
}
