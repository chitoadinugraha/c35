# Publish c35.release.remote-windows over NATS from inside the cluster (TLS + auth).
# Same DNS as c35-server: tls://nats-client.nats.svc.cluster.local:4222

param(
    [Parameter(Mandatory = $true)]
    [int]$Version,
    [Parameter(Mandatory = $true)]
    [string]$VersionName,
    [Parameter(Mandatory = $true)]
    [string]$Hash,
    [Parameter(Mandatory = $true)]
    [int]$Size,
    [string]$Namespace = 'c35',
    [string]$NatsUrl = 'tls://nats-client.nats.svc.cluster.local:4222',
    [string]$Subject = 'c35.release.remote-windows'
)

$ErrorActionPreference = 'Stop'

function Get-SecretEnv([string]$Name, [string]$Key) {
    $b64 = kubectl get secret $Name -n $Namespace -o "jsonpath={.data.$Key}" 2>$1
    if (-not $b64) { return $null }
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

$user = Get-SecretEnv 'c35-server-env' 'NATS_USER'
$pass = Get-SecretEnv 'c35-server-env' 'NATS_PASS'
if (-not $user -or -not $pass) { throw 'NATS_USER/NATS_PASS missing from c35-server-env (kubectl + c35 namespace)' }

$payloadObj = @{
    platform    = 'remote-windows'
    version     = $Version
    versionName = $VersionName
    hash        = $Hash.Trim().ToLower()
    size        = $Size
}
$payload = ($payloadObj | ConvertTo-Json -Compress)
$payloadB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))

$jobName = "nats-rel-$Version-$(Get-Random -Maximum 99999)"
Write-Host "==> NATS broadcast $Subject v$Version (pod $jobName)"

$podYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: $jobName
  namespace: $Namespace
spec:
  restartPolicy: Never
  containers:
    - name: nats-box
      image: natsio/nats-box:0.14.1
      imagePullPolicy: IfNotPresent
      env:
        - name: NATS_PAYLOAD_B64
          value: "$payloadB64"
        - name: NATS_USER
          valueFrom:
            secretKeyRef:
              name: c35-server-env
              key: NATS_USER
        - name: NATS_PASS
          valueFrom:
            secretKeyRef:
              name: c35-server-env
              key: NATS_PASS
        - name: NATS_URL
          value: "$NatsUrl"
        - name: NATS_SUBJECT
          value: "$Subject"
      command:
        - /bin/sh
        - -c
        - |
          set -e
          payload=`$(echo "`$NATS_PAYLOAD_B64" | base64 -d)
          nats pub "`$NATS_SUBJECT" "`$payload" -s "`$NATS_URL" --user "`$NATS_USER" --password "`$NATS_PASS" --tlsca /nats-ca/ca.crt
      volumeMounts:
        - name: nats-ca
          mountPath: /nats-ca
          readOnly: true
  volumes:
    - name: nats-ca
      secret:
        secretName: nats-ca
"@

$tmp = Join-Path $env:TEMP "nats-broadcast-$jobName.yaml"
$podYaml | Set-Content -Path $tmp -Encoding utf8
try {
    kubectl apply -f $tmp
    if ($LASTEXITCODE -ne 0) { throw 'kubectl apply failed' }
    $deadline = (Get-Date).AddSeconds(120)
    $phase = ''
    while ((Get-Date) -lt $deadline) {
        $phase = kubectl get pod $jobName -n $Namespace -o jsonpath='{.status.phase}' 2>$null
        if ($phase -eq 'Succeeded') { break }
        if ($phase -eq 'Failed') { break }
        Start-Sleep -Seconds 2
    }
    kubectl logs -n $Namespace "pod/$jobName" 2>&1 | Out-Host
    if ($phase -ne 'Succeeded') { throw "NATS broadcast pod phase=$phase" }
} finally {
    kubectl delete pod $jobName -n $Namespace --ignore-not-found --wait=false 2>$null | Out-Null
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host '==> NATS broadcast OK'
