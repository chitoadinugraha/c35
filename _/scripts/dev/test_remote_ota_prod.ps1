# Live prod OTA gate: fetch /version/remote-windows, download signed CAS zip, verify Blake3.
# Usage:
#   .\_\scripts\dev\test_remote_ota_prod.ps1
#   .\_\scripts\dev\test_remote_ota_prod.ps1 -MinVersion 3 -MinBuild 2

param(
    [string]$BaseUrl = 'https://alienai.id',
    [int]$MinVersion = 1,
    [int]$MinBuild = 0
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$base = $BaseUrl.Trim().TrimEnd('/')

Write-Host "==> prod OTA dry-run base=$base minVersion=$MinVersion minBuild=$MinBuild"

$ver = Invoke-RestMethod -Uri "$base/version/remote-windows" -Method Get
if ($ver.version -lt $MinVersion) { throw "version $($ver.version) < minVersion $MinVersion" }
if ($MinBuild -gt 0 -and $ver.min -lt $MinBuild) { throw "release min $($ver.min) < minBuild $MinBuild" }
if ([string]::IsNullOrWhiteSpace($ver.hash)) { throw 'version JSON missing hash' }
if ($ver.size -le 0) { throw 'version JSON missing size' }
if ($ver.url -notmatch '^https://([^/]+)/fs/') { throw "unexpected CAS url host: $($ver.url)" }
$hostName = $Matches[1]
if ($hostName -notmatch 'alienai\.id$') { throw "CAS url must be on alienai.id, got $hostName" }

Write-Host "  version=$($ver.version) min=$($ver.min) hash=$($ver.hash.Substring(0,16))..."

$hashTool = Join-Path $repoRoot '.cache\rust\hash_blake3\release\hash_blake3.exe'
if (-not (Test-Path $hashTool)) {
    $env:CARGO_TARGET_DIR = Join-Path $repoRoot '.cache\rust\hash_blake3'
    cargo build --release --manifest-path (Join-Path $repoRoot '_\scripts\deploy\tools\hash_blake3\Cargo.toml')
}

$tmp = Join-Path $env:TEMP "c35-remote-ota-$($ver.version).zip"
Write-Host "==> downloading $($ver.url.Substring(0, [Math]::Min(80, $ver.url.Length)))..."
Invoke-WebRequest -Uri $ver.url -OutFile $tmp -UseBasicParsing
$dlSize = (Get-Item $tmp).Length
if ($dlSize -ne $ver.size) { throw "size mismatch: got $dlSize expected $($ver.size)" }

$hash = (& $hashTool $tmp).Trim().ToLower()
if ($hash -ne $ver.hash.ToLower()) { throw "blake3 mismatch: got $hash expected $($ver.hash)" }

Remove-Item $tmp -Force -ErrorAction SilentlyContinue
Write-Host '==> prod OTA dry-run PASS (version JSON, CAS download, size, blake3)'
