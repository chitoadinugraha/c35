param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [Parameter(Mandatory = $true)][string]$OutputDir
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$vendor = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'vendor'
Copy-Item (Join-Path $vendor 'remote_runtime.ps1') (Join-Path $StageDir 'remote_runtime.ps1') -Force
Copy-Item (Join-Path $vendor 'install_remote_windows.ps1') (Join-Path $StageDir 'install_remote_windows.ps1') -Force

$launcher = Join-Path $StageDir '_setup_launch.cmd'
@'
@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_remote_windows.ps1"
'@ | Set-Content -LiteralPath $launcher -Encoding ASCII

$work = Join-Path $OutputDir 'iexpress_work'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Force -Path $work | Out-Null

$targetExe = Join-Path $OutputDir 'AlienAI_Remote_Windows_Setup.exe'
if (Test-Path -LiteralPath $targetExe) { Remove-Item -LiteralPath $targetExe -Force }

$sedPath = Join-Path $work 'remote_agent.sed'
$fileEntries = @()
$idx = 0
Get-ChildItem -LiteralPath $StageDir -File | Sort-Object Name | ForEach-Object {
    $fileEntries += "%FILE$idx%=$($_.Name)"
    $idx++
}
$filesBlock = ($fileEntries -join "`r`n")

$sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CompressionType=LZX
CompressionMemorySize=21
RebootMode=N
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=Alien AI Remote Agent is installed. The agent window should open for pairing.
TargetName=$targetExe
FriendlyName=Alien AI Remote Agent Setup
AppLaunched=_setup_launch.cmd
PostInstallCmd=<None>
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$StageDir
[SourceFiles0]
$filesBlock
"@

Set-Content -LiteralPath $sedPath -Value $sed -Encoding ASCII

$iexpress = Join-Path $env:SystemRoot 'System32\iexpress.exe'
if (-not (Test-Path -LiteralPath $iexpress)) {
    throw 'iexpress.exe not found (Windows component missing)'
}

Write-Host '==> IExpress (Inno Setup not found; using built-in IExpress)'
$proc = Start-Process -FilePath $iexpress -ArgumentList @('/N', $sedPath) -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "IExpress failed (exit $($proc.ExitCode))" }
if (-not (Test-Path -LiteralPath $targetExe)) { throw "Setup exe not found: $targetExe" }
Write-Host "==> Setup ready: $targetExe"
