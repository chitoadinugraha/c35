$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Push-Location (Join-Path $repoRoot '_\scripts\deploy')
try {
    dart pub get 2>$null | Out-Null
    dart run deploy_app/publish_site_guest_renderer_version.dart
    if ($LASTEXITCODE -ne 0) { throw 'publish_site_guest_renderer_version.dart failed' }
} finally {
    Pop-Location
}