# Shared VC++ 2015-2022 x64 runtime helpers for remote agent install scripts.

function Test-VcRuntime140Installed {
    if (-not (Test-Path -LiteralPath "$env:SystemRoot\System32\vcruntime140.dll")) {
        return $false
    }
    try {
        $key = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction Stop
        if ($null -ne $key.Installed -and [int]$key.Installed -ne 1) { return $false }
    }
    catch {
        # DLL present is enough for most stripped Windows images.
    }
    return $true
}

function Install-VcRedistIfNeeded {
    param(
        [Parameter(Mandatory = $true)][string]$VcRedistPath,
        [switch]$Quiet
    )
    if (Test-VcRuntime140Installed) {
        if (-not $Quiet) { Write-Host '==> Visual C++ runtime already installed; skipping vcredist.' }
        return
    }
    if (-not (Test-Path -LiteralPath $VcRedistPath)) {
        throw "VC++ runtime missing and redist not bundled: $VcRedistPath"
    }
    if (-not $Quiet) { Write-Host '==> Installing Visual C++ runtime (quiet)...' }
    $p = Start-Process -FilePath $VcRedistPath -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 1638) {
        throw "vc_redist.x64.exe failed with exit $($p.ExitCode)"
    }
}

function Test-WinFspInstalled {
    $paths = @(
        "${env:ProgramFiles(x86)}\WinFsp\bin\winfsp-x64.dll",
        "$env:ProgramFiles\WinFsp\bin\winfsp-x64.dll"
    )
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) { return $true }
    }
    return $false
}

function Install-WinFspIfNeeded {
    param(
        [Parameter(Mandatory = $true)][string]$MsiPath,
        [switch]$Quiet
    )
    if (Test-WinFspInstalled) {
        if (-not $Quiet) { Write-Host '==> WinFsp already installed; skipping MSI.' }
        return
    }
    if (-not (Test-Path -LiteralPath $MsiPath)) {
        if (-not $Quiet) { Write-Host "==> WinFsp MSI not bundled ($MsiPath); virtual drive may use fallback until WinFsp is installed." }
        return
    }
    if (-not $Quiet) { Write-Host '==> Installing WinFsp (UAC may appear)...' }
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', $MsiPath, '/quiet', '/norestart', 'ADDLOCAL=ALL') -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) {
        throw "WinFsp MSI failed with exit $($p.ExitCode)"
    }
}

function Install-RemoteAgentTo {
    param(
        [Parameter(Mandatory = $true)][string]$SourceExe,
        [Parameter(Mandatory = $true)][string]$InstallDir,
        [string]$WinfspDllPath = '',
        [switch]$Quiet
    )
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $dest = Join-Path $InstallDir 'alienai_remote_windows.exe'
    Copy-Item -LiteralPath $SourceExe -Destination $dest -Force
    if ($WinfspDllPath -and (Test-Path -LiteralPath $WinfspDllPath)) {
        Copy-Item -LiteralPath $WinfspDllPath -Destination (Join-Path $InstallDir 'winfsp-x64.dll') -Force
    }
    $legacy = Join-Path $InstallDir 'c_remote_windows.exe'
    if (Test-Path -LiteralPath $legacy) {
        Remove-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue
    }
    if (-not $Quiet) { Write-Host "==> Installed to $dest" }
    return $dest
}
