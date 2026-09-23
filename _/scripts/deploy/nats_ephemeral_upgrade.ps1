# Migrate NATS JetStream from oci-bv PVC to ephemeral emptyDir + NATS 2.15.
# YB is source of truth; c35-server hydrates JetStream after NATS is back.
#
# Steps:
#   1. Scale c35-server + c35-fetcher to 0 (NATS consumers stop cleanly)
#   2. Scale NATS StatefulSet to 0 and delete it (cannot swap PVC -> emptyDir in place)
#   3. Delete PVC nats-data-nats-0 if present (stop oci-bv billing)
#   4. Apply repo StatefulSet (nats:2.15-alpine, emptyDir nats-data)
#   5. Wait for nats-0 ready
#   6. Scale c35-fetcher + c35-server back up (hydrate from YB on reconnect)
#
# Requires: kubectl context btm.alienai.id (k3s-btm)
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$NatsDir = Join-Path $RepoRoot '_\deployments\nats'
$Context = if ($env:KUBE_CONTEXT) { $env:KUBE_CONTEXT } else { 'context-btm-oke-cvvaxr6wvrq' }

function Invoke-Kubectl {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & kubectl --context $Context @Args
    if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $($Args -join ' ')" }
}

Write-Host "==> kubectl context: $Context"
$current = kubectl config current-context 2>$null
if ($current -ne $Context) {
    Write-Host "    switching context from '$current'"
    kubectl config use-context $Context | Out-Null
}

Write-Host '==> scale c35-server awareness (stop NATS consumers)'
Invoke-Kubectl scale deployment/c35-server -n c35 --replicas=0
Invoke-Kubectl scale deployment/c35-fetcher -n c35 --replicas=0
Start-Sleep -Seconds 5

Write-Host '==> scale NATS down'
Invoke-Kubectl scale statefulset/nats -n nats --replicas=0
Invoke-Kubectl wait -n nats --for=delete pod/nats-0 --timeout=120s 2>$null

Write-Host '==> delete NATS StatefulSet (PVC templates cannot be removed in place)'
Invoke-Kubectl delete statefulset nats -n nats --ignore-not-found --wait=true

Write-Host '==> delete legacy PVC nats-data-nats-0'
Invoke-Kubectl delete pvc nats-data-nats-0 -n nats --ignore-not-found --wait=true

Write-Host '==> apply NATS StatefulSet (2.15-alpine, emptyDir jetstream)'
Invoke-Kubectl apply -f (Join-Path $NatsDir 'statefulset.yaml')

Write-Host '==> wait for nats-0 ready'
Invoke-Kubectl wait -n nats --for=condition=ready pod/nats-0 --timeout=180s

Write-Host '==> scale c35-server back up (hydrate from YB on reconnect)'
Invoke-Kubectl scale deployment/c35-fetcher -n c35 --replicas=1
Invoke-Kubectl scale deployment/c35-server -n c35 --replicas=1
Invoke-Kubectl rollout status deployment/c35-fetcher -n c35 --timeout=300s
Invoke-Kubectl rollout status deployment/c35-server -n c35 --timeout=300s

Write-Host '==> NATS ephemeral upgrade done'
Write-Host '    verify: kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream'
Write-Host '    verify: kubectl get pvc -n nats (no nats-data-nats-0)'
