# Fail if source enables provider-native web grounding (Gemini googleSearch, OpenAI web_search tool, etc.).
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string[]]$Files = @(),
    [switch]$Staged,
    [switch]$Changed
)

$ErrorActionPreference = 'Stop'

$scanExtensions = @('.rs', '.dart', '.ts', '.tsx', '.js', '.ps1', '.md', '.mdc')
$excludeDirNames = @('.cache', '.git', 'node_modules', 'target', 'build', '.dart_tool', 'Pods')

$allowPathSuffixes = @(
    '\servers\crates\mod_llm\src\gemini_no_provider_grounding.rs',
    '\.cursor\rules\web-grounding-cluster-only.mdc',
    '\.agents\rules\web-grounding-cluster-only.md',
    '\_\scripts\dev\check_no_provider_grounding.ps1'
)

$patterns = @(
    @{ Name = 'googleSearch'; Regex = 'googleSearch' },
    @{ Name = 'groundingConfig'; Regex = 'groundingConfig' },
    @{ Name = 'enterpriseWebSearch'; Regex = 'enterpriseWebSearch' },
    @{ Name = 'google_search_retrieval'; Regex = 'google_search_retrieval' },
    @{ Name = 'dynamicRetrievalConfig'; Regex = 'dynamicRetrievalConfig' },
    @{ Name = 'web_search_options'; Regex = 'web_search_options' },
    @{ Name = 'openai_web_search_tool'; Regex = '"type"\s*:\s*"web_search(_preview)?"' }
)

function Test-PathUnderExcludedDir([string]$fullPath, [string]$rootPath) {
    $rel = $fullPath.Substring($rootPath.Length).TrimStart([char[]]"/\")
    foreach ($part in ($rel -split '[\\/]')) {
        if ([string]::IsNullOrEmpty($part)) { continue }
        if ($excludeDirNames -contains $part) { return $true }
    }
    return $false
}

function Test-AllowedFile([string]$fullPath) {
    foreach ($suffix in $allowPathSuffixes) {
        if ($fullPath.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-ScanRoots([string]$rootPath) {
    return @(
        (Join-Path $rootPath 'servers'),
        (Join-Path $rootPath 'clients'),
        (Join-Path $rootPath 'remotes')
    ) | Where-Object { Test-Path $_ }
}

function Get-FilesToScan([string]$rootPath) {
    if ($Files.Count -gt 0) {
        return $Files | ForEach-Object { Resolve-Path $_ -ErrorAction Stop }
    }
    if ($Staged) {
        Push-Location $rootPath
        try {
            $paths = git diff --cached --name-only --diff-filter=ACMR
            return $paths | ForEach-Object {
                $p = Join-Path $rootPath $_
                if (Test-Path $p -PathType Leaf) { $p }
            }
        } finally {
            Pop-Location
        }
    }
    if ($Changed) {
        Push-Location $rootPath
        try {
            $paths = git diff --name-only --diff-filter=ACMR
            $paths += git diff --name-only --cached --diff-filter=ACMR
            return $paths | Select-Object -Unique | ForEach-Object {
                $p = Join-Path $rootPath $_
                if (Test-Path $p -PathType Leaf) { $p }
            }
        } finally {
            Pop-Location
        }
    }
    $out = @()
    foreach ($scanRoot in Get-ScanRoots $rootPath) {
        foreach ($ext in $scanExtensions) {
            $out += Get-ChildItem -Path $scanRoot -Recurse -File -Filter "*$ext" -ErrorAction SilentlyContinue
        }
    }
    return $out | ForEach-Object { $_.FullName }
}

$hits = @()
foreach ($file in Get-FilesToScan $Root) {
    if (Test-PathUnderExcludedDir $file $Root) { continue }
    if (Test-AllowedFile $file) { continue }
    $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
    if ($scanExtensions -notcontains $ext) { continue }
    $text = [IO.File]::ReadAllText($file)
    foreach ($pat in $patterns) {
        if ($text -match $pat.Regex) {
            $hits += [pscustomobject]@{ File = $file; Pattern = $pat.Name }
            break
        }
    }
}

if ($hits.Count -eq 0) {
    Write-Host 'check_no_provider_grounding: OK'
    exit 0
}

Write-Host "check_no_provider_grounding: $($hits.Count) hit(s) - use cluster web.search instead:"
$hits | ForEach-Object { Write-Host "  $($_.Pattern): $($_.File)" }
exit 1
