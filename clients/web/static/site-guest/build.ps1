$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$src = Join-Path $here 'src'
$names = @('site-guest.v1.js', 'site-guest.effects.v1.js')

foreach ($name in $names) {
    $in = Join-Path $src $name
    $out = Join-Path $here $name
    if (-not (Test-Path -LiteralPath $in)) {
        Write-Error ("missing " + $in)
    }
    & npx --yes esbuild $in --minify --outfile=$out
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
