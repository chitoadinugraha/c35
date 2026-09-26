# Tailscale on c-personal + Squid bound to tailnet IP only (no public :8080).
param(
    [string]$SshHost = 'chito@35.212.234.193',
    [string]$SshKey = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$TsHostname = 'c-personal-egress'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$squidConf = Join-Path $repoRoot '_\deployments\gcp-static-egress\squid.conf'

$authKey = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(
    (kubectl get secret tailscale-auth -n tailscale -o jsonpath='{.data.TS_AUTHKEY}')))
if (-not $authKey) { throw 'missing tailscale-auth TS_AUTHKEY in cluster' }

Write-Host '==> install tailscale on c-personal'
$installSh = Join-Path $env:TEMP 'c35-ts-install.sh'
$installBody = @(
    '#!/bin/bash'
    'set -e'
    'if ! command -v tailscale >/dev/null 2>&1; then curl -fsSL https://tailscale.com/install.sh | sh; fi'
    "sudo tailscale up --auth-key='$authKey' --hostname=$TsHostname --accept-routes=false --reset"
    'sleep 2'
    'tailscale ip -4'
) -join "`n"
[IO.File]::WriteAllText($installSh, $installBody + "`n")
scp -i $SshKey $installSh "${SshHost}:/tmp/c35-ts-install.sh"
$tsIp = (ssh -i $SshKey -o StrictHostKeyChecking=accept-new $SshHost 'bash /tmp/c35-ts-install.sh').Trim().Split("`n")[-1].Trim()
if (-not ($tsIp -match '^100\.')) { throw "unexpected tailscale IP: $tsIp" }
Write-Host "    tailscale IP: $tsIp"

$squidAcl = @"
acl tailnet src 100.64.0.0/10
acl cluster src 10.244.0.0/16 10.96.0.0/16 10.0.0.0/8
acl localnet src 127.0.0.1/32
acl SSL_ports port 443
acl CONNECT method CONNECT
http_port $tsIp`:8080
coredump_dir /var/spool/squid
cache_dir ufs /var/spool/squid 100 16 256
http_access allow CONNECT SSL_ports localnet
http_access allow CONNECT SSL_ports tailnet
http_access allow CONNECT SSL_ports cluster
http_access deny all
visible_hostname c35-static-egress
forwarded_for off
"@
$squidTmp = Join-Path $env:TEMP 'c35-squid-tailscale.conf'
[IO.File]::WriteAllText($squidTmp, $squidAcl.Replace("`r`n", "`n"))
scp -i $SshKey $squidTmp "${SshHost}:/tmp/c35-squid.conf"

$proxyUrl = "http://${tsIp}:8080"
$run = "docker rm -f c35-static-egress 2>/dev/null || true; docker run -d --name c35-static-egress --restart unless-stopped --network host -v /tmp/c35-squid.conf:/etc/squid/squid.conf:ro ubuntu/squid:6.10-24.10_edge; sleep 3; curl -sS --max-time 10 -x ${proxyUrl} https://api.ipify.org"
Write-Host "==> squid on tailnet only ($proxyUrl)"
ssh -i $SshKey $SshHost $run

Write-Host '==> patch c35-server-env ALIENAI_PROXY_STATIC_URL'
python -c @"
import base64, json, subprocess, tempfile, os
raw = subprocess.check_output(['kubectl','get','secret','c35-server-env','-n','c35','-o','json'])
sec = json.loads(raw)
data = {k: base64.b64decode(v).decode('utf-8') for k,v in sec['data'].items()}
data['ALIENAI_PROXY_STATIC_URL'] = '$proxyUrl'
sec['data'] = {k: base64.b64encode(v.encode()).decode() for k,v in data.items()}
fd, path = tempfile.mkstemp(suffix='.json'); os.close(fd)
open(path,'w',encoding='utf-8').write(json.dumps(sec))
subprocess.check_call(['kubectl','apply','-f',path])
os.remove(path)
"@

kubectl rollout restart deployment/c35-server -n c35 | Out-Null
Write-Host "==> test from cluster pod (may take ~30s after rollout)"
Start-Sleep 15
kubectl run ts-proxy-test --rm -i --restart=Never -n c35 --image=curlimages/curl:latest -- curl -sS --max-time 20 -x $proxyUrl https://api.ipify.org 2>&1
Write-Host "==> done proxy_url=$proxyUrl"
