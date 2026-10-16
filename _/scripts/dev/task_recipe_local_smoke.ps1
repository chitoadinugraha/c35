# Local dev smoke: data.shell_chunk + task.chunk_fanout via MCP agent HTTP.
# Requires: dev server on :10000, C35_MCP_AGENT_KEY in servers/server_ai/.env.local
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $root 'servers\server_ai\.env.local'
if (-not $env:C35_MCP_AGENT_KEY -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^C35_MCP_AGENT_KEY=(.+)$') { $env:C35_MCP_AGENT_KEY = $Matches[1].Trim() }
    }
}
if (-not $env:C35_MCP_AGENT_KEY) { throw 'C35_MCP_AGENT_KEY missing' }
$base = if ($env:C35_SERVER_URL) { $env:C35_SERVER_URL.TrimEnd('/') } else { 'http://127.0.0.1:10000' }
$headers = @{ Authorization = "Bearer $env:C35_MCP_AGENT_KEY"; 'Content-Type' = 'application/json' }
$deviceIid = $args[0]
if (-not $deviceIid) { throw 'Usage: task_recipe_local_smoke.ps1 <device_iid_string>' }

function Invoke-Tool($tool, $toolArgs) {
    $body = @{
        owner_iid = 99000
        tool_name = $tool
        arguments = $toolArgs
    } | ConvertTo-Json -Depth 10 -Compress
    $r = Invoke-RestMethod -Uri "$base/v1/mcp/agent" -Method Post -Headers $headers -Body $body
    if (-not $r.ok) { throw ($r | ConvertTo-Json -Depth 6) }
    return $r.result
}

Write-Host '==> data.shell_chunk'
$chunk = Invoke-Tool 'task.run_start' @{
    device_iid = $deviceIid
    prompt     = '{"recipe":"data.shell_chunk","offset":0,"limit":3}'
}
$chunkId = [string]$chunk.run_id
Write-Host "run_id=$chunkId status=$($chunk.status)"

Write-Host '==> task.chunk_fanout (6 rows x chunk 3)'
$fan = Invoke-Tool 'task.run_start' @{
    device_iid = $deviceIid
    prompt     = '{"recipe":"task.chunk_fanout","child_recipe":"data.shell_chunk","total":6,"chunk_size":3,"parallel_children":2,"stagger_ms":50,"child_params":{}}'
}
$runId = [string]$fan.run_id
Write-Host "parent_run_id=$runId"
Start-Sleep -Seconds 8
$st = Invoke-Tool 'task.run_status' @{ run_id = $runId }
Write-Host ($st | ConvertTo-Json -Depth 6 -Compress)
