# Publish remote Linux agent (Rust OTA zip + CAS + ai.config + NATS).
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
& (Join-Path $repoRoot '_\scripts\deploy\publish_app_release.ps1') -RemoteLinux @args
