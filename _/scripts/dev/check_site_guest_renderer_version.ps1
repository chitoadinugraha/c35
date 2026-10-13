# Verify guest renderer version bump when guest compile paths change.
param([switch]$Changed)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$rustFile = Join-Path $repoRoot 'servers\crates\mod_site\src\guest_renderer.rs'
if (-not (Test-Path $rustFile)) {
    Write-Error "Missing $rustFile"
    exit 1
}

$rustText = [IO.File]::ReadAllText($rustFile)
if ($rustText -notmatch 'pub const GUEST_RENDERER_VERSION:\s*i32\s*=\s*(\d+)\s*;') {
    Write-Error 'GUEST_RENDERER_VERSION not found in guest_renderer.rs'
    exit 1
}
$version = [int]$Matches[1]
if ($version -lt 1) {
    Write-Error "GUEST_RENDERER_VERSION must be >= 1 (got $version)"
    exit 1
}

$watchPatterns = @(
    'servers/crates/mod_site/src/render.rs',
    'servers/crates/mod_site/src/guest_renderer.rs',
    'servers/crates/mod_site/src/site_boot.rs',
    'servers/crates/mod_site/src/commerce_boot.rs',
    'servers/crates/mod_site/src/site_preview.rs',
    'servers/crates/mod_site/src/http.rs',
    'clients/web/static/site-guest/',
    'servers/crates/overlay_effects/'
)

function Test-PathTouched([string]$relPath, [string[]]$changedFiles) {
    foreach ($f in $changedFiles) {
        $n = $f -replace '\\', '/'
        $p = $relPath -replace '\\', '/'
        if ($n -eq $p -or $n.StartsWith($p)) { return $true }
    }
    return $false
}

if ($Changed) {
    $changed = @(git -C $repoRoot diff --name-only HEAD 2>$null)
    if ($changed.Count -eq 0) {
        Write-Host 'check_site_guest_renderer_version: no changed files'
        exit 0
    }
    $rendererTouched = $false
    foreach ($pat in $watchPatterns) {
        if (Test-PathTouched $pat $changed) {
            $rendererTouched = $true
            break
        }
    }
    if ($rendererTouched) {
        $bumped = Test-PathTouched 'servers/crates/mod_site/src/guest_renderer.rs' $changed
        if (-not $bumped) {
            Write-Error @(
                'Guest renderer compile paths changed but guest_renderer.rs was not updated.',
                'Bump GUEST_RENDERER_VERSION by 1 and run publish_site_guest_renderer_version.ps1 after cluster deploy.'
            )
            exit 1
        }
    }
}

Write-Host "check_site_guest_renderer_version: OK (GUEST_RENDERER_VERSION=$version)"
exit 0