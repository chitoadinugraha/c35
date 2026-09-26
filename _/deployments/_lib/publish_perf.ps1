# Publish timing + artifact size reporting (cluster images + app releases).
# Dot-sourced from publish.ps1 and publish_*.ps1 scripts.

$script:PublishPerfActive = $null

function Format-PublishPerfDuration([TimeSpan]$Elapsed) {
    if ($Elapsed.TotalHours -ge 1) { return $Elapsed.ToString('h\:mm\:ss') }
    return $Elapsed.ToString('mm\:ss')
}

function Get-PublishTarExcludeArgs {
    return @(
        '--exclude=.git', '--exclude=.cache', '--exclude=**/.cache',
        '--exclude=.cursor', '--exclude=.agents', '--exclude=agent-transcripts',
        '--exclude=terminals', '--exclude=**/*.md', '--exclude=_/docs',
        '--exclude=_/mcps', '--exclude=_/scripts', '--exclude=spec.md',
        '--exclude=**/.dart_tool', '--exclude=**/.cargo',
        '--exclude=**/target', '--exclude=**/build',
        '--exclude=**/node_modules', '--exclude=**/__pycache__',
        '--exclude=clients/app', '--exclude=remotes', '--exclude=*.tar'
    )
}

function Start-PublishPerfSession {
    param(
        [string]$Kind,
        [string]$Target,
        [string]$ImageRef = '',
        [string]$Tag = '',
        [string]$Version = '',
        [string]$VersionName = ''
    )
    $script:PublishPerfActive = @{
        kind         = $Kind
        target       = $Target
        image_ref    = $ImageRef
        tag          = $Tag
        version      = $Version
        version_name = $VersionName
        started_at   = (Get-Date).ToUniversalTime().ToString('o')
        marks        = @{}
        image_bytes  = $null
    }
    $script:PublishPerfActive['total_sw'] = [System.Diagnostics.Stopwatch]::StartNew()
}

function Set-PublishPerfMark {
    param(
        [string]$Name,
        [double]$Seconds,
        [hashtable]$Extra = @{}
    )
    if (-not $script:PublishPerfActive) { return }
    $entry = @{ sec = [math]::Round($Seconds, 1) }
    foreach ($k in $Extra.Keys) { $entry[$k] = $Extra[$k] }
    $script:PublishPerfActive.marks[$Name] = $entry
}

function Set-PublishPerfImageBytes([Nullable[long]]$Bytes) {
    if (-not $script:PublishPerfActive) { return }
    $script:PublishPerfActive.image_bytes = $Bytes
}

function Format-PublishBytes([long]$Bytes) {
    if ($Bytes -ge 1GB) { return '{0:N2} GiB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2} MiB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N2} KiB' -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-RegistryImageSizeBytes {
    param(
        [string]$ImageRef,
        [string]$RegistryUser,
        [string]$RegistryPass
    )
    if (-not $ImageRef -or -not $RegistryUser -or -not $RegistryPass) { return $null }
    if ($ImageRef -notmatch '^([^/]+)/(.+):([^:]+)$') { return $null }
    $registryHost = $Matches[1]
    $repository = $Matches[2]
    $tag = $Matches[3]
    $pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${RegistryUser}:${RegistryPass}"))
    $headers = @{
        Authorization  = "Basic $pair"
        Accept         = 'application/vnd.docker.distribution.manifest.v2+json'
    }
    $manifestUrl = "https://${registryHost}/v2/${repository}/manifests/${tag}"
    try {
        $resp = Invoke-WebRequest -Uri $manifestUrl -Headers $headers -Method Get -UseBasicParsing -TimeoutSec 60
    } catch {
        return $null
    }
    $manifest = $resp.Content | ConvertFrom-Json
    $total = [long]0
    if ($manifest.config -and $manifest.config.size) {
        $total += [long]$manifest.config.size
    }
    foreach ($layer in $manifest.layers) {
        if ($layer.size) { $total += [long]$layer.size }
    }
    if ($total -le 0) { return $null }
    return $total
}

function Merge-PublishPerfFromJsonLine {
    param([string]$Line)
    if ($Line -notmatch 'C35_PUBLISH_PERF') { return }
    $jsonStart = $Line.IndexOf('{')
    if ($jsonStart -lt 0) { return }
    try {
        $obj = $Line.Substring($jsonStart) | ConvertFrom-Json
        if (-not $script:PublishPerfActive) {
            Start-PublishPerfSession -Kind $obj.kind -Target $obj.target -Version ([string]$obj.version) -VersionName ([string]$obj.version_name)
        }
        if ($obj.duration_sec) { Set-PublishPerfMark -Name 'total' -Seconds ([double]$obj.duration_sec) }
        if ($obj.marks) {
            foreach ($prop in $obj.marks.PSObject.Properties) {
                Set-PublishPerfMark -Name $prop.Name -Seconds ([double]$prop.Value)
            }
        }
        if ($obj.image_bytes) { Set-PublishPerfImageBytes ([long]$obj.image_bytes) }
        if ($obj.detail) { $script:PublishPerfActive.detail = [string]$obj.detail }
        if ($obj.target) { $script:PublishPerfActive.target = [string]$obj.target }
        if ($obj.artifacts_bytes) {
            $script:PublishPerfActive.artifacts_bytes = @{}
            foreach ($prop in $obj.artifacts_bytes.PSObject.Properties) {
                $script:PublishPerfActive.artifacts_bytes[$prop.Name] = [long]$prop.Value
            }
        }
    } catch {
        Write-Warning "C35_PUBLISH_PERF parse failed: $_"
    }
}

function Write-PublishPerfReport {
    param(
        [string]$RepoRoot,
        [string]$RegistryUser = '',
        [string]$RegistryPass = ''
    )
    if (-not $script:PublishPerfActive) { return }
    $session = $script:PublishPerfActive
    $session.total_sw.Stop()
    $totalSec = [math]::Round($session.total_sw.Elapsed.TotalSeconds, 1)
    Set-PublishPerfMark -Name 'wall_total' -Seconds $totalSec

    if ($session.image_ref -and -not $session.image_bytes) {
        $bytes = Get-RegistryImageSizeBytes -ImageRef $session.image_ref -RegistryUser $RegistryUser -RegistryPass $RegistryPass
        if ($bytes) { Set-PublishPerfImageBytes $bytes }
    }

    $payload = @{
        kind         = $session.kind
        target       = $session.target
        image_ref    = $session.image_ref
        tag          = $session.tag
        version      = $session.version
        version_name = $session.version_name
        detail       = $session.detail
        duration_sec = $totalSec
        image_bytes  = $session.image_bytes
        marks            = $session.marks
        artifacts_bytes  = $session.artifacts_bytes
        finished_at      = (Get-Date).ToUniversalTime().ToString('o')
    }

    $perfDir = Join-Path $RepoRoot '.cache\publish-perf'
    New-Item -ItemType Directory -Force -Path $perfDir | Out-Null
    $latestPath = Join-Path $perfDir 'latest.json'
    $payload | ConvertTo-Json -Depth 6 | Set-Content -Path $latestPath -Encoding utf8

    $jsonLine = "C35_PUBLISH_PERF $($payload | ConvertTo-Json -Compress -Depth 6)"
    Write-Host ''
    Write-Host '========================================'
    Write-Host ' C35 publish perf'
    Write-Host '========================================'
    Write-Host " target:       $($session.target)"
    if ($session.image_ref) { Write-Host " image:        $($session.image_ref)" }
    if ($session.version) { Write-Host " version:      $($session.version)" }
    if ($session.version_name) { Write-Host " version_name: $($session.version_name)" }
    if ($session.detail) { Write-Host " detail:       $($session.detail)" }
    if ($session.image_bytes) {
        Write-Host " image_size:   $(Format-PublishBytes ([long]$session.image_bytes)) ($($session.image_bytes) bytes)"
    }
    Write-Host " wall_time:    $(Format-PublishPerfDuration $session.total_sw.Elapsed)"
    foreach ($name in ($session.marks.Keys | Sort-Object)) {
        $m = $session.marks[$name]
        $extra = ''
        if ($m.context_mb) { $extra = " ($($m.context_mb) MB context)" }
        Write-Host "   - ${name}: $($m.sec)s$extra"
    }
    if ($session.artifacts_bytes) {
        foreach ($name in ($session.artifacts_bytes.Keys | Sort-Object)) {
            $b = [long]$session.artifacts_bytes[$name]
            Write-Host "   - artifact ${name}: $(Format-PublishBytes $b)"
        }
    }
    Write-Host " saved:        $latestPath"
    Write-Host $jsonLine
    Write-Host '========================================'
    Write-Host ''

    $script:PublishPerfActive = $null
}
