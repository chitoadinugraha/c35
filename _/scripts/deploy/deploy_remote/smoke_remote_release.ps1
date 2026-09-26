# Post-publish smoke for remote Windows agent release on alienai.id.
# Usage: .\_\scripts\deploy\deploy_remote\smoke_remote_release.ps1
#        .\_\scripts\deploy\deploy_remote\smoke_remote_release.ps1 -BaseUrl https://alienai.id -MinVersion 2

param(
    [string]$BaseUrl = 'https://alienai.id',
    [int]$MinVersion = 1
)

$ErrorActionPreference = 'Stop'
$base = $BaseUrl.Trim().TrimEnd('/')

Write-Host "==> smoke remote release base=$base minVersion=$MinVersion"

$ver = Invoke-RestMethod -Uri "$base/version/remote-windows" -Method Get
if ($ver.version -lt $MinVersion) { throw "version $($ver.version) < min $MinVersion" }
if ([string]::IsNullOrWhiteSpace($ver.hash)) { throw 'version JSON missing hash' }
if ($ver.size -le 0) { throw 'version JSON missing size' }
Write-Host "  version=$($ver.version) name=$($ver.versionName) size=$($ver.size)"

$pair = Invoke-RestMethod -Uri "$base/v1/device/pair/register" -Method Post -ContentType 'application/json' -Body '{"device_name":"smoke-test","device_type":"windows"}'
if ([string]::IsNullOrWhiteSpace($pair.code)) { throw 'pair/register missing code' }
Write-Host "  pair/register ok code=$($pair.code)"

$dlHeaders = curl.exe -sI "$base/download/agent.exe" 2>&1 | Out-String
if ($dlHeaders -notmatch 'HTTP/\S+\s+307') { throw "download/agent.exe expected 307, got: $dlHeaders" }
if ($dlHeaders -notmatch 'Location:\s*\S+/fs/') { throw "download/agent.exe missing /fs/ Location" }
Write-Host '  download/agent.exe -> 307 CAS redirect ok'

if ($ver.url) {
    $cas = curl.exe -sI $ver.url 2>&1 | Out-String
    if ($cas -notmatch 'HTTP/\S+\s+(200|206)') { throw "CAS HEAD failed for version url: $cas" }
    Write-Host '  CAS artifact HEAD ok'
}

Write-Host '==> smoke remote release PASS'
