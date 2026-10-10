# Run c35 Flutter client on Android: USB device or emulator, install, attach debugger.
param(
    [string]$AvdId = '',
    [string]$DeviceSerial = '',
    [switch]$Physical,
    [switch]$NoLaunch,
    [switch]$UninstallFirst,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$appDir = Join-Path $root 'clients\app'

function Resolve-AndroidSdkRoot {
    foreach ($name in @('ANDROID_SDK_ROOT', 'ANDROID_HOME')) {
        $p = (Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue).Value
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    $local = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    if (Test-Path -LiteralPath $local) { return $local }
    throw 'Android SDK not found. Set ANDROID_SDK_ROOT or install Android Studio SDK.'
}

function Invoke-Adb([string]$adb, [string[]]$AdbArgs, [string]$Serial = '') {
    $all = @()
    if ($Serial) { $all += '-s', $Serial }
    $all += $AdbArgs
    $out = & $adb @all 2>&1
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw ("adb failed: adb $($all -join ' ') -> $out")
    }
    return ($out | Out-String).Trim()
}

function Invoke-AdbAllowFail([string]$adb, [string[]]$AdbArgs, [string]$Serial = '') {
    $all = @()
    if ($Serial) { $all += '-s', $Serial }
    $all += $AdbArgs
    $lines = @(& $adb @all 2>&1 | ForEach-Object { "$_" })
    $code = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    return @{ ExitCode = $code; Output = ($lines -join [Environment]::NewLine) }
}

function Resolve-AndroidPackageId([string]$appDir) {
    $gradle = Join-Path $appDir 'android\app\build.gradle.kts'
    if (Test-Path -LiteralPath $gradle) {
        $text = Get-Content -Raw -LiteralPath $gradle
        if ($text -match 'applicationId\s*=\s*"([^"]+)"') { return $Matches[1] }
    }
    return 'id.alienai'
}

# Play Store / release builds use a different cert than debug; adb install then fails with UPDATE_INCOMPATIBLE.
function Ensure-AndroidDebugInstall([string]$adb, [string]$serial, [string]$appDir, [string]$packageId) {
    $paths = Invoke-AdbAllowFail $adb @('shell', 'pm', 'path', $packageId) $serial
    if ($paths.Output -notmatch 'package:') { return }

    $apk = Join-Path $appDir 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk)) {
        Write-Host "==> $packageId on device; building debug APK to verify signing before install"
        Push-Location $appDir
        try {
            $buildCode = Invoke-NativeCli { flutter build apk --debug }
            if ($buildCode -ne 0) { exit $buildCode }
        } finally {
            Pop-Location
        }
    }

    Write-Host "==> checking whether debug APK can replace installed $packageId"
    $attempt = Invoke-AdbAllowFail $adb @('install', '-r', $apk) $serial
    $text = $attempt.Output
    if ($text -match 'Success') {
        Write-Host '    same signing key as installed app'
        return
    }
    if ($text -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match') {
        Write-Host "==> uninstalling $packageId (installed cert != debug keystore)"
        Invoke-Adb $adb @('uninstall', $packageId) $serial | Out-Null
        return
    }
    if ($attempt.ExitCode -ne 0) {
        Write-Warning ('adb install probe: ' + $text)
    }
}

function Avd-List([string]$emulator) {
    $lines = @(& $emulator -list-avds 2>&1 | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
    return $lines
}

function Device-ListSerials([string]$adb) {
    $serial = @()
    foreach ($line in & $adb devices 2>&1 | ForEach-Object { "$_" }) {
        if ($line -match '^(\S+)\s+device(\s|$)') { $serial += $Matches[1] }
    }
    return $serial
}

function Device-FindForAvd([string]$adb, [string]$avdId) {
    $lines = & $adb devices 2>&1 | ForEach-Object { "$_" }
    foreach ($line in $lines) {
        if ($line -notmatch '^(\S+)\s+device(\s|$)') { continue }
        $serial = $Matches[1]
        if ($serial -notmatch '^emulator-') { continue }
        $name = (Invoke-Adb $adb @('emu', 'avd', 'name') $serial).Split("`n")[0].Trim()
        if ($name -eq $avdId) { return $serial }
    }
    return ''
}

function Emulator-WaitBoot([string]$adb, [string]$serial, [int]$TimeoutSec = 180) {
    Invoke-Adb $adb @('wait-for-device') $serial | Out-Null
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $boot = Invoke-Adb $adb @('shell', 'getprop', 'sys.boot_completed') $serial
        if ($boot -eq '1') { return }
        Start-Sleep -Seconds 2
    }
    throw "Emulator $serial did not finish boot within ${TimeoutSec}s."
}

# Flutter/Gradle write warnings to stderr; with $ErrorActionPreference Stop that becomes NativeCommandError.
function Invoke-NativeCli {
    param([Parameter(Mandatory)][scriptblock]$Command)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $exitCode = 0
    try {
        & $Command 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                Write-Host $_.ToString()
            } else {
                $_
            }
        }
        if ($null -ne $LASTEXITCODE) { $exitCode = [int]$LASTEXITCODE }
    } finally {
        $ErrorActionPreference = $prev
    }
    return , $exitCode
}

$sdk = Resolve-AndroidSdkRoot
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $emulator)) { throw "Missing emulator: $emulator" }
if (-not (Test-Path -LiteralPath $adb)) { throw "Missing adb: $adb" }

$connected = @(Device-ListSerials $adb)
$serial = ''
$targetLabel = ''

if ($DeviceSerial) {
    if ($connected -notcontains $DeviceSerial) {
        throw "adb device '$DeviceSerial' not found (connected: $($connected -join ', '))"
    }
    $serial = $DeviceSerial
    $targetLabel = $serial
} elseif ($Physical) {
    $usb = @($connected | Where-Object { $_ -notmatch '^emulator-' })
    if ($usb.Count -eq 0) { throw 'No USB Android device in adb devices.' }
    if ($usb.Count -gt 1) { throw "Multiple USB devices; pass -DeviceSerial. Found: $($usb -join ', ')" }
    $serial = $usb[0]
    $targetLabel = "USB $serial"
    Write-Host "==> using USB device: $serial"
} elseif ($connected.Count -eq 1 -and $connected[0] -notmatch '^emulator-') {
    $serial = $connected[0]
    $targetLabel = "USB $serial"
    Write-Host "==> using sole adb device (USB): $serial"
}

if (-not $serial) {
    $avds = @(Avd-List $emulator)
    if ($avds.Count -eq 0) {
        throw 'No adb device and no AVD. Connect a phone (USB debugging) or create an AVD in Android Studio.'
    }

    Write-Host '==> Android emulators (AVD)'
    foreach ($id in $avds) { Write-Host "    $id" }

    if (-not $AvdId) {
        if ($avds.Count -eq 1) {
            $AvdId = $avds[0]
            Write-Host "==> using sole AVD: $AvdId"
        } else {
            throw "Multiple AVDs; pass -AvdId <name>. Example: .\dev_app_android.ps1 -AvdId $($avds[0])"
        }
    } elseif ($avds -notcontains $AvdId) {
        throw "AVD '$AvdId' not in list: $($avds -join ', ')"
    }

    $serial = Device-FindForAvd $adb $AvdId
    if (-not $serial -and -not $NoLaunch) {
        Write-Host "==> starting emulator: $AvdId"
        Start-Process -FilePath $emulator -ArgumentList @('-avd', $AvdId) | Out-Null
        $deadline = (Get-Date).AddMinutes(3)
        while ((Get-Date) -lt $deadline) {
            $serial = Device-FindForAvd $adb $AvdId
            if ($serial) { break }
            Start-Sleep -Seconds 2
        }
        if (-not $serial) { throw "Emulator for AVD '$AvdId' did not appear in adb within 3 minutes." }
    } elseif (-not $serial) {
        throw "AVD '$AvdId' is not running (adb). Start it or omit -NoLaunch."
    }
    $targetLabel = "$serial ($AvdId)"
}

Write-Host "==> waiting for boot: $targetLabel"
Emulator-WaitBoot $adb $serial

$port = if ($env:LISTEN) { [int](($env:LISTEN -split ':')[-1]) } else { 8080 }
$serverUrl = if ($env:C35_SERVER_URL) { $env:C35_SERVER_URL.Trim().TrimEnd('/') } else { "http://127.0.0.1:$port" }
Write-Host "==> adb reverse tcp:$port (device 127.0.0.1:$port -> host PC)"
Invoke-Adb $adb @('reverse', "tcp:$port", "tcp:$port") $serial | Out-Null
Write-Host "==> API base: $serverUrl"
Write-Host '    (cluster: set C35_SERVER_URL=https://api.alienai.id; tailscale dev: http://100.100.1.10:8080)'
try {
    $healthHost = if ($serverUrl -match '^https?://([^/:]+)') { $Matches[1] } else { '127.0.0.1' }
    $healthUrl = if ($healthHost -in @('10.0.2.2', '127.0.0.1')) { "http://127.0.0.1:$port/health" } else { "$serverUrl/health" }
    $null = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3
} catch {
    Write-Warning ('Dev server not reachable at ' + $serverUrl + '; start .\dev_server.ps1 in another terminal (or set C35_SERVER_URL).')
}

$packageId = Resolve-AndroidPackageId $appDir

if ($UninstallFirst) {
    Write-Host '==> flutter install --uninstall-only (-UninstallFirst)'
    Push-Location $appDir
    try {
        $unCode = Invoke-NativeCli { flutter install -d $serial --debug --uninstall-only }
        if ($unCode -ne 0) { exit $unCode }
    } finally {
        Pop-Location
    }
} else {
    Ensure-AndroidDebugInstall $adb $serial $appDir $packageId
}

if (-not (Test-Path (Join-Path $appDir 'android\app\build.gradle.kts'))) {
    if (-not (Test-Path (Join-Path $appDir 'android'))) {
        Push-Location $appDir
        try {
            Write-Host '==> flutter create --platforms=android .'
            $createCode = Invoke-NativeCli { flutter create --platforms=android . }
            if ($createCode -ne 0) { exit $createCode }
        } finally {
            Pop-Location
        }
    }
}

Write-Host "==> flutter run -d $serial (debug)"
Push-Location $appDir
try {
    $runArgs = @(
        'run', '-d', $serial,
        '--dart-define', ('C35_SERVER=' + $serverUrl)
    )
    if ($FlutterArgs) { $runArgs += $FlutterArgs }
    $code = Invoke-NativeCli { flutter @runArgs }
    if ($code -eq 130 -or $code -eq -1073741510) { $code = 0 }
    exit $code
} finally {
    Pop-Location
}