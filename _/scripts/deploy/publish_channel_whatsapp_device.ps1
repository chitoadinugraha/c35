# Build linux/arm64 channel-whatsapp-device on cluster buildkit, push OCIR, apply + rollout in c35.
# Usage:
#   .\_\scripts\deploy\publish_channel_whatsapp_device.ps1
#   .\_\scripts\deploy\publish_channel_whatsapp_device.ps1 -Tag v0.1.0 -SkipCleanup
#   .\_\scripts\deploy\publish_channel_whatsapp_device.ps1 -LocalBuild

param(
    [string]$Tag = "latest",
    [switch]$SkipBuild,
    [switch]$SkipDeploy,
    [switch]$SkipCleanup,
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
$dockerfile = Join-Path $deploymentsDir "Dockerfile.channel-whatsapp-device"
$manifestDir = Join-Path $deploymentsDir "channel-whatsapp-device"
$imageRepo = "hsg.ocir.io/axr8wqrrukgm/channel-whatsapp-device"
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
Write-Host " publish: channel-whatsapp-device -> $Namespace ($imageRef)"
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
                if ($LASTEXITCODE -ne 0) { throw "docker push $imageRef failed" }
                if ($Tag -ne "latest") {
                    docker push "${imageRepo}:latest"
                    if ($LASTEXITCODE -ne 0) { throw "docker push latest failed" }
                }
            } finally {
                Pop-Location
            }
        } else {
            Publish-C35ChannelWhatsappDeviceImage -Tag $Tag -RepoRoot $repoRoot -Platform $Platform
        }
    }

    if ($SkipDeploy) {
        Write-Host "==> skip deploy"
        return
    }

    Write-Host "==> apply namespace + manifests"
    kubectl apply -f (Join-Path $deploymentsDir "c35\namespace.yaml")
    kubectl apply -f $manifestDir
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed: $manifestDir" }

    Publish-Rollout -Deployment channel-whatsapp-device -Namespace $Namespace

    Write-Host "==> smoke test in-cluster /healthz"
    $pod = kubectl get pod -n $Namespace -l app.kubernetes.io/name=channel-whatsapp-device -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($pod) {
        $health = kubectl exec -n $Namespace $pod -- curl -fsS http://127.0.0.1:8080/healthz 2>$null
        Write-Host "    pod=$pod healthz=$health"
    } else {
        Write-Warning "no channel-whatsapp-device pod found for smoke test"
    }

    Write-Host "==> done"
    kubectl get deploy,svc -n $Namespace -l app.kubernetes.io/name=channel-whatsapp-device
} finally {
    Stop-Buildkit
}
