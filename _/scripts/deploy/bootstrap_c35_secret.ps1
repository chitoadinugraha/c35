# Create c35 namespace secrets from cluster csa-env.
param(
    [string]$Namespace = "c35",
    [string]$SourceNs = "csa"
)

$ErrorActionPreference = "Stop"

function Secret-Get([string]$Ns, [string]$Name, [string]$Key) {
    $b64 = kubectl get secret $Name -n $Ns -o "jsonpath={.data.$Key}" 2>$null
    if (-not $b64) { return $null }
    return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

Write-Host "==> namespace $Namespace"
kubectl apply -f (Join-Path $PSScriptRoot "..\..\deployments\c35\namespace.yaml")

Write-Host "==> copy docker-registry-auth from $SourceNs"
kubectl get secret docker-registry-auth -n $SourceNs -o yaml |
    ForEach-Object { $_ -replace "namespace: $SourceNs", "namespace: $Namespace" } |
    ForEach-Object { $_ -replace '(^\s+resourceVersion:.*|^\s+uid:.*|^\s+creationTimestamp:.*)', '' } |
    kubectl apply -f -

Write-Host "==> copy alienai-id-tls from $SourceNs"
kubectl get secret alienai-id-tls -n $SourceNs -o yaml |
    ForEach-Object { $_ -replace "namespace: $SourceNs", "namespace: $Namespace" } |
    ForEach-Object { $_ -replace '(^\s+resourceVersion:.*|^\s+uid:.*|^\s+creationTimestamp:.*)', '' } |
    kubectl apply -f -

Write-Host "==> copy nats-ca from $SourceNs"
kubectl get secret nats-ca -n $SourceNs -o yaml |
    ForEach-Object { $_ -replace "namespace: $SourceNs", "namespace: $Namespace" } |
    ForEach-Object { $_ -replace '(^\s+resourceVersion:.*|^\s+uid:.*|^\s+creationTimestamp:.*)', '' } |
    kubectl apply -f -

$jwtSecret = Secret-Get $SourceNs csa-env JWT_SECRET
if (-not $jwtSecret) { throw "missing JWT_SECRET in ${SourceNs}/csa-env" }

$envMap = [ordered]@{
    C35_JWT_SECRET       = $jwtSecret
    CAS_HMAC_SECRET      = $jwtSecret
    GOOGLE_CLIENT_ID     = (Secret-Get $SourceNs csa-env GOOGLE_CLIENT_ID)
    GOOGLE_CLIENT_SECRET = (Secret-Get $SourceNs csa-env GOOGLE_CLIENT_SECRET)
    YB_HOST              = (Secret-Get $SourceNs csa-env PG_HOST)
    YB_PORT              = (Secret-Get $SourceNs csa-env PG_PORT)
    YB_USER              = (Secret-Get $SourceNs csa-env PG_USER)
    YB_PASSWORD          = (Secret-Get $SourceNs csa-env PG_PASSWORD)
    YB_DATABASE          = "c35"
    YB_SSLMODE           = "disable"
    NATS_URL             = "tls://nats-client.nats.svc.cluster.local:4222"
    NATS_USER            = (Secret-Get $SourceNs csa-env NATS_USER)
    NATS_PASS            = (Secret-Get $SourceNs csa-env NATS_PASS)
    NATS_CA              = "/nats-ca/ca.crt"
}

$lines = @()
foreach ($k in $envMap.Keys) {
    $v = $envMap[$k]
    if ([string]::IsNullOrWhiteSpace($v)) { continue }
    $lines += "$k=$v"
}

$tmp = Join-Path $env:TEMP "c35-server-env-$([Guid]::NewGuid().ToString('n')).env"
$lines | Set-Content -Path $tmp -Encoding utf8
Write-Host ("==> create secret c35-server-env ({0} keys)" -f $lines.Count)
kubectl create secret generic c35-server-env -n $Namespace --from-env-file=$tmp --dry-run=client -o yaml | kubectl apply -f -
Remove-Item $tmp -Force

Write-Host "==> done"
