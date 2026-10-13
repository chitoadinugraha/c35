# Publish c35.release.windows over NATS (same cluster job as remote-windows).

param(
    [Parameter(Mandatory = $true)][int]$Version,
    [Parameter(Mandatory = $true)][string]$VersionName,
    [Parameter(Mandatory = $true)][string]$Hash,
    [Parameter(Mandatory = $true)][int]$Size
)

$ErrorActionPreference = 'Stop'
$remoteScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'deploy_remote\nats_broadcast_remote_release.ps1'
& $remoteScript `
    -Version $Version `
    -VersionName $VersionName `
    -Hash $Hash `
    -Size $Size `
    -Subject 'c35.release.windows' `
    -Platform 'windows'
