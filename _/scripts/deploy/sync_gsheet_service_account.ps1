# Copy cs_bots Firebase service account into c35 and sync GOOGLE_APPLICATION_CREDENTIALS_JSON to cluster.
# Usage:
#   .\_\scripts\deploy\sync_gsheet_service_account.ps1
#   .\_\scripts\deploy\sync_gsheet_service_account.ps1 -Restart

param(
    [string]$Namespace = 'c35',
    [string]$SecretName = 'c35-server-env',
    [string]$SourcePath = 'D:\cs_bots\_\certs\firebase-service.json',
    [switch]$Restart
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$localPath = Join-Path $repoRoot '_\certs\firebase-service.json'

if (-not (Test-Path $SourcePath)) { throw "Source service account not found: $SourcePath" }
New-Item -ItemType Directory -Force -Path (Split-Path $localPath) | Out-Null
Copy-Item -Path $SourcePath -Destination $localPath -Force

$json = (Get-Content -Raw -Path $localPath).Trim()
if ($json.Length -lt 20) { throw "Invalid service account json at $localPath" }

$raw = kubectl get secret $SecretName -n $Namespace -o json | ConvertFrom-Json
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
$raw.data | Add-Member -NotePropertyName 'GOOGLE_APPLICATION_CREDENTIALS_JSON' -NotePropertyValue $b64 -Force
($raw | ConvertTo-Json -Depth 10 -Compress) | kubectl apply -f -
Write-Host "==> patched $Namespace/$SecretName (GOOGLE_APPLICATION_CREDENTIALS_JSON) + local $localPath"

if ($Restart) {
    kubectl rollout restart "deployment/c35-server" -n $Namespace
    kubectl rollout status "deployment/c35-server" -n $Namespace --timeout=300s
}
