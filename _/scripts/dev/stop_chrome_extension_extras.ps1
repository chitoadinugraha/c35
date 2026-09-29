# Stop duplicate Chrome-remote processes and optional policy that fights your profile.
$ErrorActionPreference = 'Stop'

Write-Host '==> stop alienai_remote_browser (keeps daily Chrome open)'
Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "    kill pid $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host '==> stop Playwright automation Chrome (AlienAI\slots\*)'
Get-CimInstance Win32_Process -Filter "name='chrome.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
    $cl = $_.CommandLine
    if ($cl -and $cl -like '*AlienAI\slots\*') {
        Write-Host "    kill playwright chrome pid $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

$policy = 'HKCU:\Software\Policies\Google\Chrome\ExtensionInstallForcelist'
if (Test-Path $policy) {
    Write-Host '==> remove ExtensionInstallForcelist (file:// updates confuse Chrome)'
    Remove-Item -Path $policy -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Done. Run Start-ChromeRemoteAgent.cmd once (not dev_browser.ps1).'