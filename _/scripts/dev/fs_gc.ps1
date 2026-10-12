# CAS filesystem GC: inline Yugabyte blobs + S3-compatible large blobs.
# See _/specs/file.md (Orphan GC).
param(
    [int] $MinAgeDays = 0,
    [int] $InlineBatchLimit = 20000,
    [int] $S3BatchLimit = 50,
    [switch] $Execute,
    [switch] $InlineOnly,
    [switch] $S3Only
)

$ErrorActionPreference = 'Stop'
$Orphans = Join-Path $PSScriptRoot 'cleanup_cas_orphans.ps1'
$S3 = Join-Path $PSScriptRoot 'cleanup_cas_s3_orphans.ps1'

if (-not $S3Only) {
    Write-Host '=== Inline YB (small jpeg/webp orphans) ==='
    $inlineArgs = @('-MinAgeDays', $MinAgeDays, '-BatchLimit', $InlineBatchLimit)
    if ($Execute) { $inlineArgs += '-Execute' }
    & $Orphans @inlineArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $InlineOnly) {
    Write-Host '=== S3 (store=s3 orphans; OCI/Wasabi via S3_* in .env.local) ==='
    $s3Args = @('-BatchLimit', $S3BatchLimit)
    if ($Execute) { $s3Args += '-Execute' }
    & $S3 @s3Args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}