# Smoke: mint device egress lease + curl through CONNECT proxy (ipify).
# Requires: paired agent online, C35_EGRESS_PROXY_ENABLED=1 on server, invoke auth.
param(
    [long]$DeviceIid = 0,
    [string]$ServerUrl = $env:C35_SERVER_URL,
    [string]$Jwt = $env:C35_JWT
)

$ErrorActionPreference = 'Stop'
if (-not $ServerUrl) { throw 'Set C35_SERVER_URL (e.g. https://api.alienai.id)' }
if (-not $Jwt) { throw 'Set C35_JWT (session token for invoke)' }
if ($DeviceIid -le 0) { throw 'Pass -DeviceIid <paired device iid>' }

$base = $ServerUrl.TrimEnd('/')
$body = @{
    req_id = [guid]::NewGuid().ToString('N')
    body = @{
        device_egress_lease = @{
            device_iid = $DeviceIid
            req_id = 'egress-smoke'
            ttl_sec = 600
        }
    }
} | ConvertTo-Json -Depth 6

$invokeRes = Invoke-RestMethod -Method Post -Uri "$base/v1/invoke" `
    -Headers @{ Authorization = "Bearer $Jwt"; 'Content-Type' = 'application/json' } `
    -Body $body

if ($invokeRes.status_code -ne 200) {
    throw "invoke failed: $($invokeRes.error_message)"
}
$lease = $invokeRes.body.device_egress_lease
$user = $lease.username
$pass = $lease.password
$proxy = $lease.proxy_url
Write-Host "proxy=$proxy user=$user"

$direct = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 20).Trim()
Write-Host "direct ipify: $direct"

# Keep https:// for curl -x when ingress terminates TLS on :443 (plain http:// on 443 returns Traefik 404).
$proxyUri = $proxy

$via = curl.exe -sS --max-time 30 -x $proxyUri -U "${user}:${pass}" https://api.ipify.org
if ($LASTEXITCODE -ne 0) { throw "curl via proxy failed exit=$LASTEXITCODE" }
$via = $via.Trim()
Write-Host "via proxy ipify: $via"

if ($direct -ne $via) {
    throw "IP mismatch: direct=$direct via=$via (agent must be on same machine as direct curl for this check)"
}
Write-Host 'OK: proxied IP matches direct (same egress as agent PC)'
