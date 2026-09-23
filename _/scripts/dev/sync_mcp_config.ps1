# Sync Antigravity MCP config -> Cursor .cursor/mcp.json (path transforms only).
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)

$ErrorActionPreference = 'Stop'
$src = Join-Path $Root '.agents\plugins\c35\mcp_config.json'
$dst = Join-Path $Root '.cursor\mcp.json'

if (-not (Test-Path $src)) { throw "Missing $src" }

$raw = Get-Content $src -Raw -Encoding UTF8
$raw = $raw -replace 'D:/c35', '${workspaceFolder}'
$raw = $raw -replace 'D:\\c35', '${workspaceFolder}'

$null = New-Item -ItemType Directory -Force -Path (Split-Path $dst)
Set-Content -Path $dst -Value $raw -Encoding UTF8 -NoNewline
Write-Host "Synced $src -> $dst"
