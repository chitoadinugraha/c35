param(
    [Parameter(Mandatory = $true)][string]$StageDir,
    [Parameter(Mandatory = $true)][string]$OutputDir,
    [Parameter(Mandatory = $true)][string]$AppVersion,
    [Parameter(Mandatory = $true)][int]$AppBuild,
    [Parameter(Mandatory = $true)][string]$IssPath
)

$ErrorActionPreference = 'Stop'

$isccCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 5\ISCC.exe')
)
$iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $iscc) {
    $iexpressScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'build_remote_windows_setup_iexpress.ps1'
    & $iexpressScript -StageDir $StageDir -OutputDir $OutputDir
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $StageDir)) { throw "StageDir missing: $StageDir" }
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$defines = @(
    "/DStageDir=$StageDir",
    "/DMyAppVersion=$AppVersion",
    "/DMyAppBuild=$AppBuild"
)
Write-Host "==> ISCC $IssPath"
& $iscc $defines "/O$OutputDir" $IssPath
if ($LASTEXITCODE -ne 0) { throw "ISCC failed (exit $LASTEXITCODE)" }

$setup = Join-Path $OutputDir 'AlienAI_Remote_Windows_Setup.exe'
if (-not (Test-Path -LiteralPath $setup)) { throw "Setup exe not found: $setup" }
Write-Host "==> Setup ready: $setup"
