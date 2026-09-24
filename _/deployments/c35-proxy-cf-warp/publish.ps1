param(
    [string]$Namespace = "c35"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host " deploy: c35-proxy-cf-warp ($Namespace)"
Write-Host "========================================"

$manifests = @("service.yaml", "deployment.yaml")
foreach ($f in $manifests) {
    $path = Join-Path $PSScriptRoot $f
    Write-Host "==> apply $f"
    kubectl apply -f $path
}

Write-Host "==> waiting for deployment/c35-proxy-cf-warp rollout..."
kubectl rollout status deployment/c35-proxy-cf-warp -n $Namespace --timeout=180s

Write-Host "==> smoke test c35-proxy-cf-warp /health..."
kubectl run proxy-smoke --rm -i --restart=Never -n $Namespace --image=curlimages/curl:8.5.0 -- `
    curl -sf "http://c35-proxy-cf-warp.$Namespace.svc.cluster.local:8080/health" 2>$null

Write-Host "==> c35-proxy-cf-warp is healthy!"
