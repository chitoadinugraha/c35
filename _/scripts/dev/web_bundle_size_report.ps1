# Reports Flutter web build artifact sizes (run from repo root).
param(
    [switch]$Build,
    [string]$WebDir = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$clientApp = Join-Path $root 'clients\app'
$out = if ($WebDir) { $WebDir } else { Join-Path $clientApp 'build\web' }

if ($Build) {
    Push-Location $clientApp
    flutter build web --release --base-href /app/ --no-wasm-dry-run --web-resources-cdn
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
    Pop-Location
}

if (-not (Test-Path $out)) {
    Write-Error "Web build missing: $out (pass -Build or build first)"
}

function DirBytes($path) {
    if (-not (Test-Path $path)) { return 0 }
    $item = Get-Item $path
    if ($item.PSIsContainer) {
        return (Get-ChildItem $path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    }
    return $item.Length
}

$mainJs = Join-Path $out 'main.dart.js'
$canvaskit = Join-Path $out 'canvaskit'
$assets = Join-Path $out 'assets'
$symSum = (Get-ChildItem $out -Recurse -Filter '*.symbols' -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
if ($null -eq $symSum) { $symSum = 0 }
$parts = @(Get-ChildItem $out -Recurse -Filter '*.part.js' -File -ErrorAction SilentlyContinue)
$total = DirBytes($out)

$report = [ordered]@{
    total_mb      = [math]::Round($total / 1MB, 2)
    main_js_mb    = [math]::Round((DirBytes($mainJs)) / 1MB, 2)
    canvaskit_mb  = [math]::Round((DirBytes($canvaskit)) / 1MB, 2)
    assets_mb     = [math]::Round((DirBytes($assets)) / 1MB, 2)
    symbols_mb    = [math]::Round($symSum / 1MB, 2)
    part_js_count = $parts.Count
    web_dir       = $out
    generated_at  = (Get-Date).ToString('o')
}

Write-Host ('Flutter web bundle: {0} MB total' -f $report.total_mb)
Write-Host ('  main.dart.js: {0} MB' -f $report.main_js_mb)
Write-Host ('  canvaskit/:   {0} MB' -f $report.canvaskit_mb)
Write-Host ('  assets/:      {0} MB' -f $report.assets_mb)
Write-Host ('  .symbols:     {0} MB' -f $report.symbols_mb)
Write-Host ('  .part.js:     {0} files' -f $report.part_js_count)

$cacheDir = Join-Path $root '.cache'
if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir | Out-Null }
$jsonPath = Join-Path $cacheDir 'web-bundle-size.json'
$report | ConvertTo-Json | Set-Content -Path $jsonPath -Encoding utf8
Write-Host "Wrote $jsonPath"

if ($report.main_js_mb -gt 8) {
    Write-Warning "main.dart.js exceeds 8 MB soft gate ($($report.main_js_mb) MB)"
}
if ($report.total_mb -gt 18 -and $report.canvaskit_mb -lt 1) {
    Write-Warning "Total web dir exceeds 18 MB with CDN ($($report.total_mb) MB)"
}