# Prune cluster buildkit cache (Docker layer cache on k3s), then scale builder to 0.
# Usage:
#   .\_\scripts\deploy\cleanup_buildkit.ps1

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\..\deployments\_lib\publish.ps1')

Require-Command kubectl
Ensure-Buildkit

$pod = Get-BuildkitPodName
if (-not $pod) { throw 'buildkit pod not found after scale-up' }

Write-Host '========================================'
Write-Host ' cleanup: buildkit (cluster Docker cache)'
Write-Host '========================================'

Write-Host "==> prune buildkit cache (pod $pod)"
kubectl exec -n build $pod -- buildctl prune --all --keep-duration 0s 2>&1

Show-PublishDiskStatus -Label 'disk after buildkit cleanup'
Stop-Buildkit
Write-Host '==> buildkit cleanup done'
