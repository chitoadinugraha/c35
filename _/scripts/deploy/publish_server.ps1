# Build linux/arm64 c35-server on cluster buildkit, push OCIR, apply + rollout in c35.
# Usage:
#   .\_\scripts\deploy\publish_server.ps1
#   .\_\scripts\deploy\publish_server.ps1 -Tag v0.1.0
#   .\_\scripts\deploy\publish_server.ps1 -PruneBuildkit -StopBuildkit   # free disk; cold next build
#
# Prereq: kubectl, OCIR credentials for cluster buildkit (see publish.ps1)

param(
    [string]$Tag = "latest",
    [switch]$SkipBuild,
    [switch]$SkipDeploy,
    [switch]$PruneBuildkit,
    [switch]$StopBuildkit,
    [switch]$SkipCleanup,  # deprecated: no-op (prune is opt-in via -PruneBuildkit)
    [switch]$LocalBuild,
    [string]$Namespace = "c35",
    [string]$EnvFile = "",
    [string]$RegistryPass = "",
    [string]$RegistryUser = "axr8wqrrukgm/chitoadinugraha@gmail.com",
    [string]$Platform = "linux/arm64"
)

$ErrorActionPreference = "Stop"
. (Join-Path (Join-Path $PSScriptRoot "..\..\deployments") "_lib\publish.ps1")

function Read-DotEnv([string]$Path) {
    $map = @{}
    if (-not (Test-Path $Path)) { return $map }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $p = $line -split '=', 2
        if ($p.Length -ne 2) { return }
        $map[$p[0].Trim()] = $p[1].Trim().Trim('"').Trim("'")
    }
    return $map
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$deploymentsDir = Join-Path $repoRoot "_\deployments"
$dockerfile = Join-Path $deploymentsDir "Dockerfile"
$manifestDir = Join-Path $deploymentsDir "c35-server"
$imageRepo = "hsg.ocir.io/axr8wqrrukgm/c35-server"
$imageRef = "${imageRepo}:$Tag"

if (-not $EnvFile) {
    $candidates = @(
        (Join-Path $repoRoot ".env.local"),
        "D:\alienai_proto\cluster\.env.local",
        "D:\cs_bots\.env.local"
    )
    $EnvFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
$envMap = if ($EnvFile) { Read-DotEnv $EnvFile } else { @{} }
if (-not $RegistryPass) { $RegistryPass = $env:OCIR_PASSWORD }
if (-not $RegistryPass -and $envMap['OCIR_PASSWORD']) { $RegistryPass = $envMap['OCIR_PASSWORD'] }

Require-Command kubectl
if ($LocalBuild) { Deny-LocalArmDockerBuild }

Write-Host "========================================"
Write-Host " publish: c35-server -> $Namespace ($imageRef)"
Write-Host " host: https://api.alienai.id"
Write-Host "========================================"

Start-PublishPerfSession -Kind 'cluster' -Target 'c35-server' -ImageRef $imageRef -Tag $Tag

try {
    if ($PruneBuildkit) {
        & (Join-Path $PSScriptRoot "cleanup_buildkit.ps1")
    }

    if (-not $SkipBuild) {
        Publish-C35ServerImage -Tag $Tag -RepoRoot $repoRoot -Platform $Platform
    }

    if ($SkipDeploy) {
        Write-Host "==> skip deploy"
        return
    }

    Write-Host "==> apply namespace + manifests"
    kubectl apply -f (Join-Path $deploymentsDir "c35\namespace.yaml")
    kubectl apply -f $manifestDir
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed: $manifestDir" }

    Publish-Rollout -Deployment c35-server -Namespace $Namespace

    Write-Host "==> smoke test https://api.alienai.id/livez"
    try {
        $health = Invoke-RestMethod -Uri "https://api.alienai.id/livez" -TimeoutSec 20
        Write-Host "    api.alienai.id/livez: $health"
    } catch {
        Write-Warning "health check failed: $_"
    }

    Write-Host "==> smoke test https://api.alienai.id/a/auth/google (expect redirect)"
    try {
        $authOut = curl.exe -sS -D - -o NUL --max-redirs 0 --max-time 20 "https://api.alienai.id/a/auth/google" 2>&1 | Out-String
        $authStatus = if ($authOut -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
        $authLocation = if ($authOut -match '(?im)^location:\s*(.+)$') { $Matches[1].Trim() } else { '' }
        Write-Host "    auth/google status=$authStatus location=$authLocation"
    } catch {
        Write-Warning "auth smoke failed: $_"
    }

    Write-Host "==> done"
    kubectl get deploy,svc,ingress -n $Namespace -l app.kubernetes.io/name=c35-server
    if ($StopBuildkit) { Stop-Buildkit }
} catch {
    throw
} finally {
    Write-PublishPerfReport -RepoRoot $repoRoot -RegistryUser $RegistryUser -RegistryPass $RegistryPass
}
