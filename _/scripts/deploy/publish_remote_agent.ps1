# Publish remote Windows agent (Rust OTA zip + Inno Setup + CAS + ai.config + NATS).
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
& (Join-Path $repoRoot '_\scripts\deploy\publish_app_release.ps1') -RemoteAgent @args
