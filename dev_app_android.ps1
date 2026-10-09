# Run c35 Flutter client on Android: USB device or emulator, install, attach debugger.
param(
    [string]$AvdId = '',
    [string]$DeviceSerial = '',
    [switch]$Physical,
    [switch]$NoLaunch,
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

if (-not (Test-Path (Join-Path $appDir 'android\app\build.gradle.kts'))) {
    if (-not (Test-Path (Join-Path $appDir 'android'))) {
        Push-Location $appDir
        try {
            Write-Host '==> flutter create --platforms=android .'
            flutter create --platforms=android .
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
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
    flutter @runArgs
    $code = $LASTEXITCODE
    if ($code -eq 130 -or $code -eq -1073741510) { $code = 0 }
    exit $code
} finally {
    Pop-Location
}