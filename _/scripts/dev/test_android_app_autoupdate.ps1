# E2E: Android APK OTA via mock GET /version/android (emulator + release APKs).
#
# Requires release cleartext for 10.0.2.2 (main network_security_config.xml).
# Test APKs use:
#   --dart-define=C35_SERVER=http://10.0.2.2:<MockPort>
#   --dart-define=C35_UPDATE_CHANNEL=apk
#
# Usage:
#   .\_\scripts\dev\test_android_app_autoupdate.ps1
#   .\_\scripts\dev\test_android_app_autoupdate.ps1 -OldBuild 999100 -NewBuild 999101

param(
    [int]$OldBuild = 999100,
    [int]$NewBuild = 999101,
    [int]$MockPort = 8879,
    [string]$AvdName = 'Pixel_10',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$fixtureRoot = Join-Path $repoRoot '.cache\android-autoupdate-test'
$appDir = Join-Path $repoRoot 'clients\app'
$mockBase = "http://10.0.2.2:${MockPort}"
$pkg = 'id.alienai'

if ($NewBuild -le $OldBuild) { throw 'NewBuild must be greater than OldBuild' }

$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
if (-not (Test-Path $adb)) { throw "adb not found: $adb" }

New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null

function Wait-Device {
    & $adb wait-for-device | Out-Null
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        $boot = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
        if ($boot -eq '1') { return }
        Start-Sleep -Seconds 2
    }
    throw 'emulator boot timeout'
}

function Build-Apk([int]$buildNumber, [string]$outPath) {
    Write-Host "==> flutter build apk --release --build-number=$buildNumber"
    Push-Location $appDir
    flutter build apk --release --build-number=$buildNumber `
        --dart-define="C35_SERVER=$mockBase" `
        --dart-define=C35_UPDATE_CHANNEL=apk
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed' }
    $built = Join-Path $appDir 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path $built)) { throw "missing $built" }
    Copy-Item $built $outPath -Force
    Pop-Location
}

$devices = (& $adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match 'device$' }
if (-not $devices) {
    if (-not (Test-Path $emulator)) { throw "emulator not found: $emulator" }
    Write-Host "==> starting AVD $AvdName"
    Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdName, '-no-snapshot-load') -WindowStyle Normal
    Wait-Device
} else {
    Write-Host '==> using connected device/emulator'
    Wait-Device
}

$hashTool = Join-Path $repoRoot '.cache\rust\hash_blake3\release\hash_blake3.exe'
if (-not (Test-Path $hashTool)) {
    $env:CARGO_TARGET_DIR = Join-Path $repoRoot '.cache\rust\hash_blake3'
    cargo build --release --manifest-path (Join-Path $repoRoot '_\scripts\deploy\tools\hash_blake3\Cargo.toml')
}

$oldApk = Join-Path $fixtureRoot "app-$OldBuild.apk"
$newApk = Join-Path $fixtureRoot "app-$NewBuild.apk"
if (-not $SkipBuild) {
    Build-Apk -buildNumber $NewBuild -outPath $newApk
    Build-Apk -buildNumber $OldBuild -outPath $oldApk
} else {
    if (-not (Test-Path $newApk)) { throw "missing $newApk (build or drop -SkipBuild)" }
    if (-not (Test-Path $oldApk)) { throw "missing $oldApk (build or drop -SkipBuild)" }
}

$hash = (& $hashTool $newApk).Trim().ToLower()
Write-Host "==> new=$NewBuild hash=$hash size=$((Get-Item $newApk).Length)"

$mockPy = Join-Path $PSScriptRoot 'android_apk_autoupdate_mock_server.py'
Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path } | ForEach-Object {
    try { Stop-Process -Id $_.Id -Force -ErrorAction Stop } catch {}
}
$mockProc = Start-Process -FilePath python -ArgumentList @($mockPy, $newApk, $hash, $MockPort, $NewBuild) -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 1
try {
    $probe = Invoke-RestMethod -Uri "http://127.0.0.1:${MockPort}/version/android" -Method Get
    if ([int]$probe.version -ne $NewBuild) { throw 'mock version mismatch' }
} catch {
    Stop-Process -Id $mockProc.Id -Force -ErrorAction SilentlyContinue
    throw "mock server failed: $_"
}
Write-Host "==> mock server OK on port $MockPort"

Write-Host "==> uninstall $pkg (signature / version conflicts)"
& $adb uninstall $pkg | Out-Null

Write-Host "==> installing old APK build $OldBuild"
& $adb install -r $oldApk
if ($LASTEXITCODE -ne 0) { throw 'adb install failed' }

$installed = (& $adb shell dumpsys package $pkg | Select-String 'versionCode=' | Select-Object -First 1).ToString()
Write-Host "==> installed $installed"

& $adb shell appops set $pkg REQUEST_INSTALL_PACKAGES allow | Out-Null
& $adb shell am force-stop $pkg
& $adb shell am start -n "$pkg/.MainActivity"

Write-Host @"

==> On emulator:
  1. Tap Update on the dialog (top banner shows download / Install when ready).
  2. Tap Install; confirm the system installer.
  3. Verify: adb shell dumpsys package $pkg | findstr versionCode=$NewBuild

Mock PID $($mockProc.Id). Stop: Stop-Process -Id $($mockProc.Id)

"@
