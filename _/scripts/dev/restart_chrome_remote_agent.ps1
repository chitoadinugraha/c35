# Build (optional), deploy extension agent + popup dist, restart single IPC listener.
param(
    [switch]$SkipBuild,
    [switch]$StandaloneAgent,
    [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

$installDir = Join-Path $env:LOCALAPPDATA 'AlienAI\chrome_extension\install'
$agentDst = Join-Path $installDir 'alienai_remote_browser.exe'
$extSrc = Join-Path $RepoRoot 'clients\chrome_extension\alienai_remote'
$extDst = Join-Path $installDir 'alienai_remote'

if (-not $SkipBuild) {
    Write-Host '==> cargo build -p c_remote_browser'
    Push-Location (Join-Path $RepoRoot 'remotes')
    cargo build -p c_remote_browser
    Pop-Location
}

$agentSrc = Join-Path $RepoRoot '.cache\c_remote\debug\alienai_remote_browser.exe'
if (-not (Test-Path $agentSrc)) {
    throw "Built agent missing: $agentSrc"
}

Write-Host '==> stop alienai_remote_browser + native messaging host'
Get-Process alienai_remote_browser -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "    kill pid $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Get-Process alienai_remote_host -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "    kill native host pid $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 600

Write-Host "==> copy agent -> $agentDst"
Copy-Item -Path $agentSrc -Destination $agentDst -Force

Write-Host '==> sync extension dist (popup, service worker, ...)'
$distSrc = Join-Path $extSrc 'dist'
$distDst = Join-Path $extDst 'dist'
New-Item -ItemType Directory -Force -Path $distDst | Out-Null
Copy-Item -Path (Join-Path $distSrc '*') -Destination $distDst -Recurse -Force
Copy-Item -Path (Join-Path $extSrc 'manifest.json') -Destination (Join-Path $extDst 'manifest.json') -Force

if (-not $env:C35_SERVER_URL) { $env:C35_SERVER_URL = 'http://127.0.0.1:8080' }
$configPath = Join-Path $env:LOCALAPPDATA 'AlienAI\config.json'
if (Test-Path -LiteralPath $configPath) {
    try {
        $j = [IO.File]::ReadAllText($configPath) | ConvertFrom-Json
        $j | Add-Member -NotePropertyName server_url -NotePropertyValue $env:C35_SERVER_URL -Force
        [IO.File]::WriteAllText($configPath, ($j | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        Write-Host "    config server_url -> $($env:C35_SERVER_URL)"
    } catch {
        Write-Warning "config server_url patch failed: $_"
    }
}

if ($StandaloneAgent) {
    $startScript = Join-Path $RepoRoot '_\scripts\dev\start_chrome_remote_agent.ps1'
    & $startScript
} else {
    Write-Host '==> agent not started (Chrome extension embeds agent in native host). Use -StandaloneAgent for a separate listener on 37538.'
}

Write-Host '==> done - reload the Chrome extension (chrome://extensions)'