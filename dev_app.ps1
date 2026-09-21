# Run c35 Flutter client (Windows desktop by default).
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$appDir = Join-Path $root 'clients\app'

if (-not (Test-Path (Join-Path $appDir 'windows\CMakeLists.txt'))) {
    Push-Location $appDir
    try {
        flutter create --platforms=windows,android .
    } finally {
        Pop-Location
    }
}

Push-Location $appDir
try {
    if ($FlutterArgs) {
        flutter run @FlutterArgs
    } else {
        flutter run -d windows
    }
} finally {
    Pop-Location
}
