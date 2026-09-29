# Post-publish smoke for chrome extension release on alienai.id.
# Usage: .\_\scripts\deploy\deploy_remote\smoke_chrome_extension_release.ps1

param(
    [string]$BaseUrl = 'https://alienai.id',
    [int]$MinVersion = 1
)

$ErrorActionPreference = 'Stop'
$base = $BaseUrl.Trim().TrimEnd('/')

Write-Host "==> smoke chrome-extension release base=$base minVersion=$MinVersion"

$ver = Invoke-RestMethod -Uri "$base/version/chrome-extension" -Method Get
if ($ver.version -lt $MinVersion) { throw "version $($ver.version) < min $MinVersion" }
if ([string]::IsNullOrWhiteSpace($ver.hash)) { throw 'version JSON missing hash (OTA zip)' }
if ($ver.size -le 0) { throw 'version JSON missing size (OTA zip)' }
Write-Host "  version=$($ver.version) min=$($ver.min) name=$($ver.versionName) otaSize=$($ver.size)"

if ($ver.url) {
    $cas = curl.exe -sI $ver.url 2>&1 | Out-String
    if ($cas -notmatch 'HTTP/\S+\s+(200|206)') { throw "CAS HEAD failed for version url: $cas" }
    Write-Host '  CAS artifact HEAD ok'
}

Write-Host '==> smoke chrome-extension release PASS'
