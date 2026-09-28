# Install Alien AI remote Windows agent from setup payload (same folder as this script).
param(
    [switch]$SkipVcRedist,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $root 'remote_runtime.ps1')

$sourceExe = Join-Path $root 'alienai_remote_windows.exe'
if (-not (Test-Path -LiteralPath $sourceExe)) {
    throw "Missing alienai_remote_windows.exe in $root"
}

$installDir = Join-Path $env:LOCALAPPDATA 'AlienAI'
$vc = Join-Path $root 'vc_redist.x64.exe'
if (-not $SkipVcRedist) {
    Install-VcRedistIfNeeded -VcRedistPath $vc -Quiet:$Quiet
}

$winfspMsi = Join-Path $root 'winfsp-2.1.25156.msi'
Install-WinFspIfNeeded -MsiPath $winfspMsi -Quiet:$Quiet

$winfspDll = Join-Path $root 'winfsp-x64.dll'
$destExe = Install-RemoteAgentTo -SourceExe $sourceExe -InstallDir $installDir -WinfspDllPath $winfspDll -Quiet:$Quiet

if (-not $Quiet) { Write-Host "==> Starting $destExe" }
Start-Process -FilePath $destExe
