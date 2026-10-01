# Point test_empus + Chrome extension agent at production cluster (not 127.0.0.1).
param(
    [string]$ServerUrl = 'https://alienai.id'
)

$ErrorActionPreference = 'Stop'
$env:C35_SERVER_URL = $ServerUrl

$alienCfg = Join-Path $env:LOCALAPPDATA 'AlienAI\config.json'
if (Test-Path -LiteralPath $alienCfg) {
    $j = [IO.File]::ReadAllText($alienCfg) | ConvertFrom-Json
    $j | Add-Member -NotePropertyName server_url -NotePropertyValue $ServerUrl -Force
    [IO.File]::WriteAllText($alienCfg, ($j | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    Write-Host "AlienAI config server_url -> $ServerUrl"
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
& (Join-Path $repo '_\scripts\dev\sync_chrome_extension_install.ps1')

Write-Host 'Reload Chrome extension (chrome://extensions) or browser.extension op=reload'
Write-Host 'Resume sync: cd _\scripts\test_empus; python sync_parallel.py --workers 3 --start-sheet-row 2 --wave-size 25'
