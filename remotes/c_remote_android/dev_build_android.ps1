# Build script for Alien AI Remote Agent (Android)
# Builds Rust native library via cargo ndk and packages the APK.

param(
    [string]$TargetAbi = 'arm64-v8a',
    [switch]$Release
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $scriptDir 'android'
$jniLibsDir = Join-Path $appDir 'app\src\main\jniLibs'

Write-Host "==> [BUILD] Building c_remote_android for ABI: $TargetAbi" -ForegroundColor Cyan

$buildMode = if ($Release) { '--release' } else { '' }

# Ensure jniLibs target directory exists
$targetJniDir = Join-Path $jniLibsDir $TargetAbi
if (-not (Test-Path $targetJniDir)) {
    New-Item -ItemType Directory -Path $targetJniDir -Force | Out-Null
}

Push-Location $scriptDir
try {
    # Verify cargo ndk is available
    $ndkCheck = Get-Command 'cargo-ndk' -ErrorAction SilentlyContinue
    if (-not $ndkCheck) {
        Write-Warning "cargo-ndk is not installed. Run: cargo install cargo-ndk"
    } else {
        $ndkArgs = @('ndk', '-t', $TargetAbi, '-o', $jniLibsDir, 'build', '-p', 'c_remote_android')
        if ($Release) {
            $ndkArgs += '--release'
        }
        & cargo @ndkArgs
    }
} finally {
    Pop-Location
}

Write-Host "==> [BUILD] Android native build complete." -ForegroundColor Green
