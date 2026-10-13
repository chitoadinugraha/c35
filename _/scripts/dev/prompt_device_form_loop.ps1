# Retry VM1 Google Forms prompt until assistant text looks like success (or max attempts).
param(
    [int]$MaxAttempts = 8,
    [int]$TimeoutSec = 400,
    [string]$BaseUrl = 'http://127.0.0.1:10000',
    [int]$OwnerIid = 99000,
    [string]$DeviceIid = '98063412749627392'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$envPath = Join-Path $root 'servers\server_ai\.env.local'
if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Missing $envPath"
}

$key = $null
Get-Content -LiteralPath $envPath -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*C35_MCP_AGENT_KEY\s*=\s*(.+)\s*$') {
        $key = $Matches[1].Trim().Trim('"').Trim("'")
    }
}
if (-not $key) {
    throw 'C35_MCP_AGENT_KEY not found in .env.local'
}

$phrase = "@iid:$DeviceIid buka google form, buat form baru dengan judul Test Pendaftaran, dengan field nama, gender, alamat"
$mention = "iid:$DeviceIid"

function Test-FormSuccess([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $t = $Text.ToLowerInvariant()
    if ($t -notmatch 'test pendaftaran') { return $false }
    $bad = @(
        'please click', 'silakan klik', 'silakan lanjutkan', 'klik tombol', 'blank form',
        'no forms yet', 'could not', 'unable to', 'belum selesai',
        'timed out', 'connection failed', 'automation stopped',
        'mohon konfirmasi', 'beri tahu saya', 'lanjutkan pengisian', 'pilih tipe',
        'short answer', 'multiple choice', 'paragraph', 'ketik "', '1.', '2.', '3.'
    )
    foreach ($b in $bad) {
        if ($t.Contains($b)) { return $false }
    }
    return $true
}

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    Write-Host "=== Attempt $attempt / $MaxAttempts ==="
    $bodyObj = @{
        action      = 'prompt_run'
        owner_iid   = $OwnerIid
        text        = $phrase
        locale      = 'id-ID'
        mention_ids = @($mention)
    }
    $body = $bodyObj | ConvertTo-Json -Compress
    $headers = @{ 'X-C35-Mcp-Key' = $key }
    try {
        $resp = Invoke-RestMethod -Uri ($BaseUrl + '/v1/mcp/agent') -Method Post -Headers $headers -Body $body -ContentType 'application/json; charset=utf-8' -TimeoutSec $TimeoutSec
    }
    catch {
        Write-Warning $_.Exception.Message
        Start-Sleep -Seconds 5
        continue
    }

    $reqId = $resp.req_id
    $text = [string]$resp.text
    Write-Host "req_id=$reqId"
    if ($text.Length -gt 500) {
        Write-Host "text: $($text.Substring(0, 500))..."
    } else {
        Write-Host "text: $text"
    }

    if (Test-FormSuccess $text) {
        Write-Host 'SUCCESS'
        exit 0
    }

    Start-Sleep -Seconds 8
}

Write-Host 'Gave up after max attempts'
exit 1
