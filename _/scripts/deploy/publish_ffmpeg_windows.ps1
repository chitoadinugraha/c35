# Publish Windows ffmpeg sidecar (zip, CAS, ai.config, NATS c35.release.ffmpeg-windows).
# Usage: .\_\scripts\deploy\publish_ffmpeg_windows.ps1 -FfmpegDir D:/tools/ffmpeg-win64

param(
    [Parameter(Mandatory = $true)]
    [string]$FfmpegDir,
    [int]$Version = 0,
    [int]$MinAgentBuild = 0,
    [switch]$SkipNats,
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$deployDir = Join-Path $repoRoot '_\scripts\deploy'

Push-Location $deployDir
try {
    if (-not $SkipDartGet) {
        Write-Host '==> dart pub get'
        dart pub get
        if ($LASTEXITCODE -ne 0) { throw 'dart pub get failed' }
    }
    $dartArgs = @('run', 'deploy_ffmpeg/ffmpeg_windows_upload_prod.dart', '--ffmpeg-dir', $FfmpegDir)
    if ($Version -gt 0) { $dartArgs += @('--version', "$Version") }
    if ($MinAgentBuild -gt 0) { $dartArgs += @('--min-agent-build', "$MinAgentBuild") }
    if ($SkipNats) { $dartArgs += '--skip-nats' }
    Write-Host ('==> dart ' + ($dartArgs -join ' '))
    dart @dartArgs
    if ($LASTEXITCODE -ne 0) { throw 'ffmpeg publish failed' }
} finally {
    Pop-Location
}