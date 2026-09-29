# Dev install: copy unpacked extension + register native messaging host (current user).
# Usage: .\_\scripts\deploy\install_chrome_extension_chito.ps1
# Optional: set $HostExe to alienai_remote_browser.exe; set $ExtensionId after first load for NM allowed_origins.

param(
    [string]$HostExe = '',
    [string]$ExtensionId = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$srcPkg = Join-Path $repoRoot 'clients\chrome_extension\alienai_remote'
$destRoot = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\alienai_remote'
$nmName = 'com.alienai.c35.remote'
$nmReg = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$nmName"

if (-not (Test-Path (Join-Path $srcPkg 'manifest.json'))) {
    throw "Extension package missing: $srcPkg"
}

function Resolve-HostExe {
    param([string]$Hint)
    if ($Hint -and (Test-Path $Hint)) { return (Resolve-Path $Hint).Path }
    $candidates = @(
        (Join-Path $repoRoot '.cache\c_remote\release\alienai_remote_browser.exe'),
        (Join-Path $env:LOCALAPPDATA 'AlienAI\remote\alienai_remote_browser.exe'),
        (Join-Path $env:ProgramFiles 'AlienAI\alienai_remote_browser.exe')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return (Resolve-Path $c).Path }
    }
    throw 'alienai_remote_browser.exe not found - build remote browser or pass -HostExe'
}

function Assert-ChromeExtensionHostExe {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "missing host exe: $Path" }
    $ascii = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Path))
    if ($ascii -like '*==> [AGENT READY] Windows Remote Agent*') {
        throw @"
Wrong executable for Chrome native messaging (desktop Windows agent).
Build: cd remotes; cargo build --release -p c_remote_browser
Then pass -HostExe to this script or copy .cache\c_remote\release\alienai_remote_browser.exe
"@
    }
}

$hostPath = Resolve-HostExe $HostExe
Assert-ChromeExtensionHostExe $hostPath
Write-Host "==> copy extension -> $destRoot"
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
robocopy $srcPkg $destRoot /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }

$nmDir = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\native_host'
New-Item -ItemType Directory -Force -Path $nmDir | Out-Null
$nmFile = Join-Path $nmDir "$nmName.json"
$origins = @('chrome-extension://*/')
if ($ExtensionId) {
    $origins = @("chrome-extension://$ExtensionId/")
}
$nm = @{
    name            = $nmName
    description     = 'Alien AI Remote native host'
    path            = $hostPath
    type            = 'stdio'
    allowed_origins = $origins
    args            = @('--chrome-native-host')
} | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText($nmFile, $nm, [System.Text.UTF8Encoding]::new($false))
New-Item -Path $nmReg -Force | Out-Null
Set-ItemProperty -Path $nmReg -Name '(default)' -Value $nmFile
Write-Host "==> native host registered -> $nmFile"

Write-Host 'Next steps:'
Write-Host '  1. Open chrome://extensions (Developer mode ON).'
Write-Host '  2. Load unpacked -> select folder:'
Write-Host "     $destRoot"
Write-Host '  3. Copy extension ID from chrome://extensions; re-run with -ExtensionId (required for native messaging).'
Write-Host ''
Write-Host '  4. Start the WebRTC agent (separate from Chrome NM process):'
$agentCmd = '$env:C35_BROWSER_ENGINE=''extension''; Start-Process ' + ('"' + $hostPath + '"')
Write-Host "     $agentCmd"
Write-Host ''
Write-Host 'Optional (enterprise policy, default profile): ExtensionInstallForcelist'
Write-Host '  HKCU:\Software\Policies\Google\Chrome\ExtensionInstallForcelist'
Write-Host '  Value: extension_id;https://alienai.id/chrome-extension/updates.xml'
Write-Host '  Chrome must be fully closed before first policy apply.'

Start-Process 'chrome://extensions'