# Publish c35.release.chrome-extension over NATS (cluster job).

param(
    [Parameter(Mandatory = $true)][int]$Version,
    [Parameter(Mandatory = $true)][string]$VersionName,
    [Parameter(Mandatory = $true)][string]$Hash,
    [Parameter(Mandatory = $true)][int]$Size
)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'nats_broadcast_remote_release.ps1') `
    -Version $Version `
    -VersionName $VersionName `
    -Hash $Hash `
    -Size $Size `
    -Subject 'c35.release.chrome-extension' `
    -Platform 'chrome-extension'
