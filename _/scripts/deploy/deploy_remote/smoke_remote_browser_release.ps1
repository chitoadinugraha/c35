# Post-publish smoke for remote browser agent release on alienai.id.
# Usage: .\_\scripts\deploy\deploy_remote\smoke_remote_browser_release.ps1

param(
    [string]$BaseUrl = 'https://alienai.id',
    [int]$MinVersion = 1
)

$ErrorActionPreference = 'Stop'
$base = $BaseUrl.Trim().TrimEnd('/')

Write-Host "==> smoke remote-browser release base=$base minVersion=$MinVersion"

$ver = Invoke-RestMethod -Uri "$base/version/remote-browser" -Method Get
if ($ver.version -lt $MinVersion) { throw "version $($ver.version) < min $MinVersion" }
if ([string]::IsNullOrWhiteSpace($ver.hash)) { throw 'version JSON missing hash (OTA zip)' }
if ($ver.size -le 0) { throw 'version JSON missing size (OTA zip)' }
Write-Host "  version=$($ver.version) min=$($ver.min) name=$($ver.versionName) otaSize=$($ver.size)"

$pair = Invoke-RestMethod -Uri "$base/v1/device/pair/register" -Method Post -ContentType 'application/json' -Body '{"device_name":"smoke-browser","device_type":"browser"}'
if ([string]::IsNullOrWhiteSpace($pair.code)) { throw 'pair/register missing code' }
Write-Host "  pair/register (browser) ok code=$($pair.code)"

if ($ver.url) {
    $cas = curl.exe -sI $ver.url 2>&1 | Out-String
    if ($cas -notmatch 'HTTP/\S+\s+(200|206)') { throw "CAS HEAD failed for version url: $cas" }
    Write-Host '  CAS artifact HEAD ok'
}

Write-Host '==> smoke remote-browser release PASS'
