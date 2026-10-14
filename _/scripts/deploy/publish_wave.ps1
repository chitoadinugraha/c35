# Shared helpers for parallel publish waves (server+app, apk+windows, etc.).

function Start-PublishWaveProcess {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$ExtraArgs = @(),
        [string]$RepoRoot,
        [string]$LogDir
    )
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $outLog = Join-Path $LogDir "publish-wave-$Name.log"
    $errLog = Join-Path $LogDir "publish-wave-$Name.err"
    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $ExtraArgs
    Write-Host ('==> start parallel wave: ' + $Name)
    $proc = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru -WorkingDirectory $RepoRoot -ArgumentList $argList -RedirectStandardOutput $outLog -RedirectStandardError $errLog
    return @{ Name = $Name; Proc = $proc; OutLog = $outLog; ErrLog = $errLog }
}

function Wait-PublishWaveProcess {
    param($Entry)
    $proc = $Entry.Proc
    $null = $proc.WaitForExit()
    $proc.Refresh(); $code = $proc.ExitCode; if ($null -eq $code) { $code = 0 }
    Write-Host ('==> wave ' + $Entry.Name + ' finished with code ' + $code + ' log ' + $Entry.OutLog)
    if ($code -ne 0) {
        if (Test-Path $Entry.OutLog) { Get-Content $Entry.OutLog -Tail 40 | ForEach-Object { Write-Host $_ } }
        if (Test-Path $Entry.ErrLog) { Get-Content $Entry.ErrLog -Tail 20 | ForEach-Object { Write-Host $_ } }
        throw ('publish wave failed: ' + $Entry.Name + ' code ' + $code)
    }
}

function Merge-PublishPerfFromLogFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path) {
        if ($line -notmatch 'C35_PUBLISH_PERF') { continue }
        Merge-PublishPerfFromJsonLine $line
    }
}
