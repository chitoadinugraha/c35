# Migrate Yugabyte hostPath -> shared PVC yb-data. Requires kubectl + helm.
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$YbDir = Join-Path $RepoRoot '_\deployments\yugabyte'
$Node = '10.0.91.240'

function Wait-YbPodsGone {
    kubectl wait -n yugabyte --for=delete pod/yb-tserver-0 --timeout=300s 2>$null
    kubectl wait -n yugabyte --for=delete pod/yb-master-0 --timeout=300s 2>$null
}

function Patch-YbPvRetain {
    $pv = kubectl get pvc yb-data -n yugabyte -o jsonpath='{.spec.volumeName}'
    if (-not $pv) { throw 'yb-data PVC not bound' }
    $patch = Join-Path $YbDir 'pv-retain-patch.json'
    kubectl patch pv $pv --type merge --patch-file $patch | Out-Null
    Write-Host "==> PV $pv reclaimPolicy=Retain"
}

Write-Host '==> apply yb-data PVC (binds on first consumer — migrate job)'
kubectl apply -f (Join-Path $YbDir 'pvc.yaml')

Write-Host '==> scale YB down (downtime)'
kubectl scale statefulset/yb-tserver -n yugabyte --replicas=0
kubectl scale statefulset/yb-master -n yugabyte --replicas=0
Wait-YbPodsGone

Write-Host '==> copy hostPath -> PVC'
kubectl delete job yb-data-migrate -n yugabyte --ignore-not-found
kubectl apply -f (Join-Path $YbDir 'migrate-job.yaml')
kubectl wait -n yugabyte --for=condition=complete job/yb-data-migrate --timeout=1200s
kubectl logs -n yugabyte job/yb-data-migrate
kubectl wait -n yugabyte --for=jsonpath='{.status.phase}'=Bound pvc/yb-data --timeout=180s
Patch-YbPvRetain

Write-Host '==> helm upgrade (PVC volumes) — master only; tserver patched separately'
helm upgrade yb yugabyte/yugabyte --version 2026.1.1 -n yugabyte -f (Join-Path $YbDir 'values-pvc.yaml') --set replicas.tserver=0 2>$null
kubectl patch statefulset yb-tserver -n yugabyte --patch-file (Join-Path $YbDir 'patch-tserver-pvc.yaml')
kubectl patch statefulset yb-tserver -n yugabyte --type=json --patch-file (Join-Path $YbDir 'patch-tserver-remove-hostpath.json')
kubectl scale statefulset/yb-tserver -n yugabyte --replicas=1
kubectl rollout status statefulset/yb-master -n yugabyte --timeout=300s
kubectl rollout status statefulset/yb-tserver -n yugabyte --timeout=300s

Write-Host '==> rename old hostPath (keep backup on node)'
kubectl delete job yb-hostpath-archive -n yugabyte --ignore-not-found
kubectl apply -f (Join-Path $YbDir 'archive-hostpath-job.yaml')
kubectl wait -n yugabyte --for=condition=complete job/yb-hostpath-archive --timeout=120s
kubectl logs -n yugabyte job/yb-hostpath-archive

Write-Host '==> YB migration done'
