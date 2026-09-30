# Append a guarded dot-source of powershell_utf8.ps1 to Windows PowerShell + PowerShell 7 profiles (once per machine).
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$utf8Script = Join-Path $Root '_\scripts\dev\powershell_utf8.ps1'
if (-not (Test-Path $utf8Script)) { throw "Missing $utf8Script" }

$marker = '# c35 powershell_utf8 (UTF-8 defaults; see _/scripts/dev/powershell_utf8.ps1)'
$line = ". '$($utf8Script -replace "'", "''")'"
$block = "`n$marker`n$line`n"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Install-C35Utf8ProfileBlock([string]$profilePath) {
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    $existing = if (Test-Path $profilePath) { [IO.File]::ReadAllText($profilePath) } else { '' }
    if ($existing -match [regex]::Escape($marker)) {
        Write-Host "Already configured: $profilePath"
        return
    }
    [IO.File]::WriteAllText($profilePath, ($existing.TrimEnd() + $block), $utf8NoBom)
    Write-Host "Updated profile: $profilePath"
}

$homeDir = $env:USERPROFILE
$profiles = @(
    (Join-Path $homeDir 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
    (Join-Path $homeDir 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
)
foreach ($p in $profiles) { Install-C35Utf8ProfileBlock $p }

Write-Host 'Integrated terminals load UTF-8 defaults when profile runs (not git hooks -NoProfile).'
Write-Host 'Prefer pwsh (PS 7) as default shell so redirects use UTF-8 too.'
