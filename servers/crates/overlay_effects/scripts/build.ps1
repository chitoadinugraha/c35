$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "..\..\..\clients\web\static\site-guest\effects"
New-Item -ItemType Directory -Force -Path $out | Out-Null

if (-not (Get-Command wasm-pack -ErrorAction SilentlyContinue)) {
    Write-Host "wasm-pack not found - skipping WASM build. Install: cargo install wasm-pack"
    exit 0
}

Push-Location $root
try {
    wasm-pack build --target web --out-dir pkg --release
    Copy-Item (Join-Path $root "pkg\overlay_effects_bg.wasm") (Join-Path $out "overlay_effects_bg.wasm") -Force
    Copy-Item (Join-Path $root "pkg\overlay_effects.js") (Join-Path $out "overlay_effects.js") -Force
    Write-Host "Built WASM to $out"
} finally {
    Pop-Location
}
