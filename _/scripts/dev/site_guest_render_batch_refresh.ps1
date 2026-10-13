# List published sites behind cluster guest_renderer_version; optionally HTTP GET to warm lazy regen.
# Requires YB_* in repo-root .env.local (same as other dev SQL helpers).
param(
    [switch]$ListOnly,
    [switch]$Ping,
    [string]$BaseUrl = 'https://alienai.id'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$envFile = Join-Path $repoRoot '.env.local'
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $val = $matches[2].Trim().Trim('"').Trim("'")
            if (-not [string]::IsNullOrWhiteSpace($name)) { Set-Item -Path "Env:$name" -Value $val }
        }
    }
}

if (-not $env:YB_PASSWORD) {
    throw 'YB_PASSWORD required (repo-root .env.local or shell).'
}

$YbHost = if ($env:YB_HOST) { $env:YB_HOST } else { '127.0.0.1' }
$YbPort = if ($env:YB_PORT) { $env:YB_PORT } else { '5433' }
$YbUser = if ($env:YB_USER) { $env:YB_USER } else { 'csa' }
$YbDb = if ($env:YB_DATABASE) { $env:YB_DATABASE } else { 'c35' }

$sql = @"
SELECT s.iid,
       COALESCE((s.config_json->>'guest_render_version')::int, 0) AS guest_render_version,
       COALESCE((SELECT (value_json->>'version')::int FROM ai.config WHERE key = 'site.guest_renderer_version'), 0) AS cluster_target,
       h.handle
FROM site.site s
LEFT JOIN site.handle h ON h.site_iid = s.iid AND h.is_primary = true
WHERE s.published = true
  AND COALESCE((s.config_json->>'guest_render_version')::int, 0) <
      COALESCE((SELECT (value_json->>'version')::int FROM ai.config WHERE key = 'site.guest_renderer_version'), 0)
ORDER BY s.iid;
"@

$pass = $env:YB_PASSWORD.Replace("'", "'\''")
$psqlCmd = "PGPASSWORD='$pass' psql -h $YbHost -p $YbPort -U $YbUser -d $YbDb -At -F '|' -c `"$($sql.Replace('"', '\"'))`""
$lines = Invoke-Expression $psqlCmd 2>&1
if ($LASTEXITCODE -ne 0) { throw "psql failed: $lines" }

if (-not $lines -or ($lines | Measure-Object).Count -eq 0) {
    Write-Host 'No published sites behind cluster guest_renderer_version.'
    exit 0
}

Write-Host "Stale guest render (site_iid|stored|target|handle):"
$lines | ForEach-Object { Write-Host $_ }

if ($ListOnly) { exit 0 }

if (-not $Ping) {
    Write-Host 'Add -Ping to HTTP GET each handle (lazy warm via site_guest_render_ensure_current on visit).'
    exit 0
}

foreach ($line in $lines) {
    $parts = $line -split '\|'
    if ($parts.Count -lt 4) { continue }
    $handle = $parts[3]
    if ([string]::IsNullOrWhiteSpace($handle)) { continue }
    $url = ($BaseUrl.TrimEnd('/')) + '/' + $handle.Trim()
    Write-Host "GET $url"
    try {
        Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 5 -TimeoutSec 60 | Out-Null
    } catch {
        Write-Warning "Ping failed for $url : $_"
    }
}
