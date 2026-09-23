# Apply all _/schemas/*.sql to the configured YugabyteDB (see servers/server_ai/.env.local).
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location (Join-Path $root 'servers')
try {
    cargo run -p c35_store --bin c35_migrate -- apply
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
