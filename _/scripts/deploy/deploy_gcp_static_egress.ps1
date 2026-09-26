# Deploy static-IP egress on c-personal (pull public amd64 image OR OCIR c35-static-egress).
param(
    [string]$SshHost = 'chito@35.212.234.193',
    [string]$SshKey = "$env:USERPROFILE\.ssh\id_ed25519",
    [string]$Image = 'hsg.ocir.io/axr8wqrrukgm/c35-static-egress:latest',
    [string]$OciEgressIp = '168.110.203.3',
    [ValidateSet('squid', 'rust')]
    [string]$Mode = 'squid',
    [switch]$SkipFirewall
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$squidConf = Join-Path $repoRoot '_\deployments\gcp-static-egress\squid.conf'

function Get-OcirDockerConfigPath {
    $b64 = kubectl get secret docker-registry-auth -n c35 -o jsonpath='{.data.\.dockerconfigjson}'
    if (-not $b64) { throw 'missing docker-registry-auth in c35' }
    $tmp = Join-Path $env:TEMP "docker-config-gcp-$([Guid]::NewGuid().ToString('n')).json"
    [IO.File]::WriteAllBytes($tmp, [Convert]::FromBase64String($b64))
    return $tmp
}

if (-not $SkipFirewall -and (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    $rule = 'c35-btm-static-egress-8080'
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $existing = gcloud compute firewall-rules describe $rule --format='value(name)' 2>$null
    $ErrorActionPreference = $prev
    if (-not $existing) {
        Write-Host "==> gcloud firewall $rule (tcp:8080 from $OciEgressIp/32)"
        gcloud compute firewall-rules create $rule `
            --direction=INGRESS --priority=1000 --network=default `
            --action=ALLOW --rules=tcp:8080 --source-ranges="${OciEgressIp}/32" `
            --description='btm OKE worker -> static egress proxy'
        if ($LASTEXITCODE -ne 0) { Write-Warning 'gcloud firewall failed — open tcp:8080 manually' }
    }
}

if ($Mode -eq 'squid') {
    if (-not (Test-Path $squidConf)) { throw "Missing $squidConf" }
    $squidAcl = (Get-Content $squidConf -Raw) -replace '168\.110\.203\.3', $OciEgressIp
    $remoteConf = '/tmp/c35-squid.conf'
    $squidTmp = Join-Path $env:TEMP 'c35-squid.conf'
    [IO.File]::WriteAllText($squidTmp, $squidAcl.Replace("`r`n", "`n"))
    scp -i $SshKey -o StrictHostKeyChecking=accept-new $squidTmp "${SshHost}:$remoteConf"
    Remove-Item $squidTmp -Force

    $run = 'docker rm -f c35-static-egress 2>/dev/null || true; docker run -d --name c35-static-egress --restart unless-stopped -p 8080:8080 -v /tmp/c35-squid.conf:/etc/squid/squid.conf:ro ubuntu/squid:6.10-24.10_edge; sleep 2; docker exec c35-static-egress squid -k check'
} else {
    $cfg = Get-OcirDockerConfigPath
    $remoteCfg = '/tmp/ocir-docker-config.json'
    scp -i $SshKey -o StrictHostKeyChecking=accept-new $cfg "${SshHost}:$remoteCfg"
    Remove-Item $cfg -Force
    $run = "mkdir -p ~/.docker; cp $remoteCfg ~/.docker/config.json; chmod 600 ~/.docker/config.json; docker pull $Image; docker rm -f c35-static-egress 2>/dev/null || true; docker run -d --name c35-static-egress --restart unless-stopped -p 8080:8080 -e C35_PROXY_CF_ADDR=0.0.0.0:8080 $Image; curl -sf http://127.0.0.1:8080/health || true; rm -f $remoteCfg"
}

Write-Host "==> deploy static egress on c-personal (mode=$Mode)"
ssh -i $SshKey -o StrictHostKeyChecking=accept-new $SshHost $run
Write-Host '==> done'
