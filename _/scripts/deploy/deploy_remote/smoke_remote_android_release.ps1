# Smoke: remote-android version + download after publish.
$ErrorActionPreference = 'Stop'
$base = if ($env:C35_SERVER) { $env:C35_SERVER.TrimEnd('/') } else { 'https://alienai.id' }

Write-Host "==> smoke remote-android @ $base"

$ver = Invoke-RestMethod -Uri "$base/version/remote-android" -Method Get
if ($ver.version -le 0) { throw "remote-android version expected > 0, got $($ver | ConvertTo-Json -Compress)" }
$apkHash = "$($ver.apkHash)"
if ([string]::IsNullOrWhiteSpace($apkHash)) { $apkHash = "$($ver.hash)" }
if ([string]::IsNullOrWhiteSpace($apkHash)) { throw 'remote-android missing apkHash/hash' }
Write-Host "  version/remote-android -> $($ver.version) ($($ver.versionName))"

$setupHeaders = curl.exe -sI "$base/download/remote.apk" 2>&1 | Out-String
if ($setupHeaders -notmatch 'HTTP/\S+\s+200') { throw "download/remote.apk expected 200, got: $setupHeaders" }
Write-Host '  download/remote.apk -> 200 ok'
