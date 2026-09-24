# Import platform vendor costs from CSV into ai.platform_vendor_cost.
# Loads DATABASE_URL from servers/server_ai/.env.local when present.
param(
    [Parameter(Mandatory)]
    [ValidateSet('oci', 'gcp', 'cf', 'wasabi')]
    [string]$Vendor,

    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$PeriodStart,

    [Parameter(Mandatory)]
    [string]$PeriodEnd,

    [string]$Category = 'other',

    [switch]$Finalize,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$envFile = Join-Path $root 'servers\server_ai\.env.local'
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $pair = $_ -split '=', 2
        if ($pair.Count -eq 2) {
            $name = $pair[0].Trim()
            $value = $pair[1].Trim().Trim('"').Trim("'")
            if ($name) { Set-Item -Path "Env:$name" -Value $value }
        }
    }
}

if (-not (Test-Path -LiteralPath $Path)) {
    throw "CSV not found: $Path"
}

$cargoArgs = @(
    'run', '-p', 'c35_mod_platform', '--example', 'import_csv', '--',
    '--vendor', $Vendor,
    '--path', (Resolve-Path -LiteralPath $Path),
    '--period-start', $PeriodStart,
    '--period-end', $PeriodEnd,
    '--category', $Category
)
if ($Finalize) { $cargoArgs += '--finalize' }
if ($DryRun) { $cargoArgs += '--dry-run' }

Push-Location (Join-Path $root 'servers')
try {
    & cargo @cargoArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
