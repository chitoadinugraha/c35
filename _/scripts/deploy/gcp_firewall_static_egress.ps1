# Requires: gcloud auth login (once on this machine)
param(
    [string]$OciEgressIp = '168.110.203.3',
    [string]$RuleName = 'c35-btm-static-egress-8080'
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { throw 'gcloud not installed' }

$existing = gcloud compute firewall-rules describe $RuleName --format='value(name)' 2>$null
if ($existing) {
    Write-Host "==> firewall rule $RuleName already exists"
    exit 0
}

Write-Host "==> create $RuleName tcp:8080 from ${OciEgressIp}/32"
gcloud compute firewall-rules create $RuleName `
    --direction=INGRESS --priority=1000 --network=default `
    --action=ALLOW --rules=tcp:8080 --source-ranges="${OciEgressIp}/32" `
    --description='btm OKE worker -> c35 static egress (squid on c-personal)'
