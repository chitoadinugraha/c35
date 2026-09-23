# Build linux/arm64 c35-fetcher, push OCIR, apply manifests in c35.
# Usage:
#   .\_\scripts\deploy\publish_fetcher.ps1
#   .\_\scripts\deploy\publish_fetcher.ps1 -Tag v0.1.0 -SkipBuild
#   .\_\scripts\deploy\publish_fetcher.ps1 -LocalBuild

param(
    [string]$Tag = "latest",
    [switch]$SkipBuild,
    [switch]$SkipDeploy,
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
$dockerfile = Join-Path $deploymentsDir "Dockerfile.c35-fetcher"
$manifestDir = Join-Path $deploymentsDir "c35-fetcher"
$imageRepo = "hsg.ocir.io/axr8wqrrukgm/c35-fetcher"
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

Write-Host "========================================"
Write-Host " publish: c35-fetcher -> $Namespace ($imageRef)"
Write-Host "========================================"

try {
    if (-not $SkipCleanup) {
        & (Join-Path $PSScriptRoot "cleanup_buildkit.ps1")
    }

    if (-not $SkipBuild) {
        if ($LocalBuild) {
            Require-Command docker
            if (-not $RegistryPass) { throw "Set -RegistryPass or OCIR_PASSWORD to push $imageRef" }
            Write-Host "==> docker login hsg.ocir.io"
            $RegistryPass | docker login hsg.ocir.io -u $RegistryUser --password-stdin
            if ($LASTEXITCODE -ne 0) { throw "docker login failed" }
            Write-Host "==> docker build $imageRef ($Platform)"
            Push-Location $repoRoot
            try {
                docker build --platform $Platform -f $dockerfile -t $imageRef -t "${imageRepo}:latest" .
                if ($LASTEXITCODE -ne 0) { throw "docker build failed" }
                docker push $imageRef
                if ($LASTEXITCODE -ne 0) { throw "docker push failed" }
                if ($Tag -ne "latest") {
                    docker push "${imageRepo}:latest"
                    if ($LASTEXITCODE -ne 0) { throw "docker push latest failed" }
                }
            } finally {
                Pop-Location
            }
        } else {
            Publish-C35FetcherImage -Tag $Tag -RepoRoot $repoRoot -Platform $Platform
        }
    }

    if (-not $SkipDeploy) {
        Write-Host "==> kubectl apply -f $manifestDir"
        kubectl apply -f $manifestDir
        if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed" }
        Write-Host "==> rollout status deployment/c35-fetcher -n $Namespace"
        kubectl rollout status "deployment/c35-fetcher" -n $Namespace --timeout=180s
        if ($LASTEXITCODE -ne 0) { throw "deployment rollout failed" }
        kubectl get pods -n $Namespace -l app.kubernetes.io/name=c35-fetcher
    }
} finally {
    if (-not $SkipCleanup) {
        Stop-Buildkit
    }
}

Write-Host "==> done: $imageRef"
