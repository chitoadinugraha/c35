# Detect (and optionally fix) UTF-16 text files that should be UTF-8 in the repo.
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [Alias('Path')]
    [string[]]$Files = @(),
    [switch]$Staged,
    [switch]$Changed,
    [switch]$Fix
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$textExtensions = @(
    '.rs', '.md', '.mdc', '.dart', '.sql', '.toml', '.yaml', '.yml', '.proto', '.ps1', '.json'
)

$excludeDirNames = @(
    '.cache', '.git', 'node_modules', 'target', 'build', '.dart_tool', 'Pods'
)

function Test-TextExtension([string]$filePath) {
    $ext = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
    return $textExtensions -contains $ext
}

function Test-PathUnderExcludedDir([string]$fullPath, [string]$rootPath) {
    $rel = $fullPath.Substring($rootPath.Length).TrimStart([char[]]"/\")
    foreach ($part in ($rel -split '[\\/]')) {
        if ([string]::IsNullOrEmpty($part)) { continue }
        if ($excludeDirNames -contains $part) { return $true }
    }
    return $false
}

function Test-IsUtf16Bytes([byte[]]$bytes) {
    if ($bytes.Length -lt 4) { return $false }
    if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { return $true }
    if ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) { return $true }

    $sample = [Math]::Min(800, $bytes.Length)
    if ($sample -lt 40) { return $false }

    $oddNulls = 0
    $pairs = 0
    for ($i = 1; $i -lt $sample; $i += 2) {
        $pairs++
        if ($bytes[$i] -eq 0) { $oddNulls++ }
    }
    if ($pairs -lt 20) { return $false }
    return ($oddNulls * 100 / $pairs) -ge 70
}

function Get-TargetPaths {
    if ($Files.Count -gt 0) {
        return $Files | ForEach-Object {
            if ([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $Root $_ }
        }
    }

    if ($Staged) {
        Push-Location $Root
        try {
            $names = @(git diff --cached --name-only --diff-filter=ACM 2>$null)
        } finally {
            Pop-Location
        }
        return $names | ForEach-Object { Join-Path $Root $_ }
    }

    if ($Changed) {
        Push-Location $Root
        try {
            # Include untracked paths — agent-created files are often UTF-16 and never appear in git diff alone.
            $names = @(
                git diff --name-only --diff-filter=ACM 2>$null
                git diff --cached --name-only --diff-filter=ACM 2>$null
                git ls-files --others --exclude-standard 2>$null
            ) | Select-Object -Unique
        } finally {
            Pop-Location
        }
        return $names | ForEach-Object { Join-Path $Root $_ }
    }

    $files = @()
    foreach ($ext in $textExtensions) {
        $files += Get-ChildItem -Path $Root -Recurse -File -Filter "*$ext" -ErrorAction SilentlyContinue
    }
    return $files.FullName
}

$targets = @(Get-TargetPaths | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) })
$bad = @()

foreach ($full in $targets) {
    if (Test-PathUnderExcludedDir $full $Root) { continue }
    if (-not (Test-TextExtension $full)) { continue }

    $bytes = [IO.File]::ReadAllBytes($full)
    if (-not (Test-IsUtf16Bytes $bytes)) { continue }

    if ($Fix) {
        $text = if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            [IO.File]::ReadAllText($full, [Text.Encoding]::Unicode)
        } elseif ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            [IO.File]::ReadAllText($full, [Text.Encoding]::BigEndianUnicode)
        } else {
            [IO.File]::ReadAllText($full, [Text.Encoding]::Unicode)
        }
        [IO.File]::WriteAllText($full, $text, $utf8NoBom)
        Write-Host "Fixed UTF-16 -> UTF-8: $full"
        $bytes = [IO.File]::ReadAllBytes($full)
        if (-not (Test-IsUtf16Bytes $bytes)) { continue }
    }

    $bad += $full
}

if ($bad.Count -eq 0) {
    Write-Host 'check_utf8_sources: OK'
    exit 0
}

Write-Host "check_utf8_sources: $($bad.Count) file(s) look UTF-16 (use -Fix to convert):"
$bad | ForEach-Object { Write-Host "  $_" }
exit 1
