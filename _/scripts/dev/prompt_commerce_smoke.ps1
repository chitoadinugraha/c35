# Smoke-check site commerce prompts via local server_ai MCP agent.
# Requires: dev_server on C35_SERVER_URL, C35_MCP_AGENT_KEY in env or servers/server_ai/.env.local
param(
    [int]$OwnerIid = 99000,
    [string]$SiteMention = 'iid:101836119014211584',
    [string]$BaseUrl = $(if ($env:C35_SERVER_URL) { $env:C35_SERVER_URL } else { 'http://127.0.0.1:8080' })
)

$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $root 'servers\server_ai\.env.local'
if (-not $env:C35_MCP_AGENT_KEY -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*C35_MCP_AGENT_KEY\s*=\s*(.+)\s*$') {
            $env:C35_MCP_AGENT_KEY = $Matches[1].Trim()
        }
    }
}
if (-not $env:C35_MCP_AGENT_KEY) {
    Write-Error 'Set C35_MCP_AGENT_KEY (or servers/server_ai/.env.local).'
}

$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $($env:C35_MCP_AGENT_KEY)"
}

function Invoke-AgentTool($name, $args) {
    $body = @{
        jsonrpc = '2.0'
        id = 1
        method = 'tools/call'
        params = @{
            name = $name
            arguments = $args
        }
    } | ConvertTo-Json -Depth 8 -Compress
    $resp = Invoke-RestMethod -Uri "$BaseUrl/v1/mcp/agent" -Method Post -Headers $headers -Body $body
    if ($resp.error) {
        throw ($resp.error | ConvertTo-Json -Compress)
    }
    $text = $resp.result.content[0].text
    return ($text | ConvertFrom-Json)
}

$phrases = @(
    'daftar transaksi hari ini',
    'berapa omzet hari ini',
    'berapa total transaksi hari ini',
    'berapa transaksi hari ini'
)

Write-Host "Owner $OwnerIid mention $SiteMention -> $BaseUrl"
foreach ($p in $phrases) {
    Write-Host "`n=== compose: $p ===" -ForegroundColor Cyan
    $c = Invoke-AgentTool 'prompt_compose' @{
        text = $p
        locale = 'id-ID'
        owner_iid = $OwnerIid
        mention_ids = @($SiteMention)
    }
    $fed = @($c.trace.candidates | Where-Object { $_.fed -and $_.tool_id -eq 'site.query.run' })
    if (-not $fed) {
        Write-Warning "site.query.run not fed"
    }
    Write-Host "inst: $($c.inst_ids -join ', ')"
}

Write-Host "`n=== prompt_run: berapa total transaksi hari ini ===" -ForegroundColor Cyan
$r = Invoke-AgentTool 'prompt_run' @{
    text = 'berapa total transaksi hari ini'
    locale = 'id-ID'
    owner_iid = $OwnerIid
    mention_ids = @($SiteMention)
}
$toolLine = @($r.trace.lines | Where-Object { $_ -match 'tool/tool_result' -and $_ -match 'site\.query' }) | Select-Object -First 1
if ($toolLine) {
    Write-Host "OK site.query.run in trace" -ForegroundColor Green
} else {
    Write-Warning "No site.query.run in trace; text: $($r.text.Substring(0, [Math]::Min(120, $r.text.Length)))"
}
Write-Host "blocks: $($r.blocks_json)"
