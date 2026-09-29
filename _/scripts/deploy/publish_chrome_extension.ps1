# Publish Chrome extension OTA zip (CAS, ai.config, optional NATS).
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$publish = Join-Path $repoRoot '_\scripts\deploy\publish_app_release.ps1'
. $publish -ChromeExtension @args
