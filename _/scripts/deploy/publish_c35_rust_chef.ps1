# Build and push c35-rust-chef base image (cargo-chef on rust:1.89-bookworm).
# Usage:
#   .\_\scripts\deploy\publish_c35_rust_chef.ps1
#   .\_\scripts\deploy\publish_c35_rust_chef.ps1 -Tag 1.89-bookworm -StopBuildkit

param(
    [string]$Tag = '1.89-bookworm',
    [switch]$StopBuildkit,
    [string]$Platform = 'linux/arm64',
    [string]$RegistryUser = 'axr8wqrrukgm/chitoadinugraha@gmail.com',
    [string]$RegistryPass = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot '..\..\deployments') '_lib\publish.ps1')

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$imageRef = "$($script:PublishRegistry)/c35-rust-chef:$Tag"

if (-not $RegistryPass) { $RegistryPass = $env:OCIR_PASSWORD }

Write-Host '========================================'
Write-Host " publish: c35-rust-chef ($imageRef)"
Write-Host '========================================'

Start-PublishPerfSession -Kind 'cluster' -Target 'c35-rust-chef' -ImageRef $imageRef -Tag $Tag

try {
    Publish-C35RustChefImage -Tag $Tag -RepoRoot $repoRoot -Platform $Platform
    if ($StopBuildkit) { Stop-Buildkit }
} finally {
    Write-PublishPerfReport -RepoRoot $repoRoot -RegistryUser $RegistryUser -RegistryPass $RegistryPass
}

Write-Host "==> done: $imageRef"
