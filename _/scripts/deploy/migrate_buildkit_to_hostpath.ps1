# Move buildkit cache to boot disk; delete oci-bv PVCs to stop billing.
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$BkDir = Join-Path $RepoRoot '_\deployments\buildkit'

Write-Host '==> ensure buildkit scaled down'
kubectl scale deployment/buildkit -n build --replicas=0 2>$null | Out-Null
kubectl scale deployment/buildkitd -n ci --replicas=0 2>$null | Out-Null
Start-Sleep -Seconds 3

Write-Host '==> apply buildkit deployment (hostPath cache)'
kubectl apply -f (Join-Path $BkDir 'deployment.yaml')

Write-Host '==> delete buildkit PVCs'
foreach ($claim in @(
        @{ ns = 'build'; name = 'buildkit-cache' }
        @{ ns = 'ci'; name = 'buildkitd-cache' }
    )) {
    kubectl delete pvc $claim.name -n $claim.ns --ignore-not-found --wait=true
}

Write-Host '==> remove orphaned PVs (oci-bv Delete should drop volumes)'
Start-Sleep -Seconds 5
kubectl get pv -o custom-columns='NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.namespace/.spec.claimRef.name' | Select-String 'buildkit'

$remaining = kubectl get pvc -A -o json | ConvertFrom-Json
$bk = @($remaining.items | Where-Object { $_.metadata.name -match 'buildkit' })
if ($bk.Count -gt 0) { throw "buildkit PVCs still present: $($bk | ForEach-Object { $_.metadata.namespace + '/' + $_.metadata.name })" }

Write-Host '==> buildkit PVC cleanup done (cache on /var/lib/alienai/buildkit)'
