# One-row or full extract using Cursor MCP credentials + production agent URL.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$mcpPath = Join-Path $repo '.cursor\mcp.json'
if (Test-Path -LiteralPath $mcpPath) {
    $mcp = Get-Content -LiteralPath $mcpPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $envBlock = $mcp.mcpServers.c35.env
    if ($envBlock.C35_MCP_AGENT_KEY) { $env:C35_MCP_AGENT_KEY = [string]$envBlock.C35_MCP_AGENT_KEY }
}
if (-not $env:C35_SERVER_URL) {
    try {
        $null = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/health' -UseBasicParsing -TimeoutSec 2
        $env:C35_SERVER_URL = 'http://127.0.0.1:8080'
    } catch {
        $env:C35_SERVER_URL = 'https://alienai.id'
    }
}
Set-Location $PSScriptRoot
python queue_build.py
python extract.py
