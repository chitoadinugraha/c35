# Shared publish helpers for c35-server cluster buildkit builds.
# Buildkit defaults to replicas=0; call Ensure-Buildkit before use, Stop-Buildkit when done.

. (Join-Path $PSScriptRoot 'publish_perf.ps1')

$script:PublishRegistry = "hsg.ocir.io/axr8wqrrukgm"
$script:PublishImage = "$script:PublishRegistry/c35-server"
$script:PublishChannelWhatsappDeviceImage = "$script:PublishRegistry/channel-whatsapp-device"
$script:PublishNodeStatsImage = "$script:PublishRegistry/c35-node-stats"
$script:PublishRustChefImage = "$script:PublishRegistry/c35-rust-chef"
$script:PublishRustChefTagDefault = '1.89-bookworm'
$script:PublishBuildkitNs = "build"
$script:PublishBuildkitSvc = "buildkit"
$script:PublishBuildkitPort = 1234
$script:PublishBuildkitCacheHostPath = "/var/lib/alienai/buildkit (boot disk)"
$script:PublishBuildkitDir = Join-Path $PSScriptRoot "..\buildkit"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) { throw "Required command not found: $Name" }
}

function Deny-LocalArmDockerBuild {
    throw @"
Local Docker arm64 builds are disabled for c35 cluster images.
Use cluster Buildkit instead (omit -LocalBuild):
  .\_\scripts\deploy\publish_server.ps1
See .cursor/rules/cluster-buildkit.mdc
"@
}

function Format-PublishDuration([TimeSpan]$Elapsed) {
    if ($Elapsed.TotalHours -ge 1) { return $Elapsed.ToString('h\:mm\:ss') }
    return $Elapsed.ToString('mm\:ss')
}

function Get-BuildkitPodName {
    $items = kubectl get pod -n $script:PublishBuildkitNs -l app=buildkit -o jsonpath='{.items[*].metadata.name}' 2>$null
    if (-not $items) { return $null }
    return ($items.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[0]).Trim()
}

function Get-BuildkitNodeName {
    $pod = Get-BuildkitPodName
    if (-not $pod) { return $null }
    $node = kubectl get pod -n $script:PublishBuildkitNs $pod -o jsonpath='{.spec.nodeName}' 2>$null
    if (-not $node) { return $null }
    return $node.Trim()
}

function Format-DfSummary([string]$DfText) {
    $text = ($DfText | Out-String) -replace "`r", ""
    foreach ($line in ($text -split "`n")) {
        $t = $line.Trim()
        if (-not $t -or $t -match '^Filesystem') { continue }
        if ($t -match '\s(\S+)\s+(\S+)\s+(\S+)\s+(\d+%)\s+') {
            return "$($Matches[1]) total, $($Matches[2]) used, $($Matches[3]) free ($($Matches[4]))"
        }
    }
    return $null
}

function Get-BuildkitDiskExec([string]$Pod, [string]$ShellCmd) {
    $raw = kubectl exec -n $script:PublishBuildkitNs $Pod -- sh -c $ShellCmd 2>$null
    return ($raw | Out-String).Trim()
}

function Show-PublishDiskStatus {
    param([string]$Label = "disk")
    Require-Command kubectl
    Write-Host ""
    Write-Host "==> $Label"
    $pod = Get-BuildkitPodName
    $node = Get-BuildkitNodeName
    if (-not $pod) {
        Write-Host "    buildkit: not running (skip disk stats)"
        Write-Host ""
        return
    }
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($node) { Write-Host "    node: $node" }
        $rootSummary = Format-DfSummary (Get-BuildkitDiskExec $pod "df -h / 2>/dev/null")
        if ($rootSummary) { Write-Host "    node boot (/): $rootSummary" }
        $cacheSummary = Format-DfSummary (Get-BuildkitDiskExec $pod "df -h /var/lib/buildkit 2>/dev/null")
        if ($cacheSummary) { Write-Host "    buildkit volume ($script:PublishBuildkitCacheHostPath): $cacheSummary" }
        $du = Get-BuildkitDiskExec $pod "du -sh /var/lib/buildkit 2>/dev/null"
        if ($du -match '^\S+') { Write-Host "    buildkit cache used: $du" }
    } finally {
        $ErrorActionPreference = $prevEap
    }
    Write-Host ""
}

function Ensure-SingleBuilder {
    Require-Command kubectl
    Write-Host "==> disable legacy ci/buildkitd (single builder: build/buildkit)"
    kubectl scale deployment/buildkitd -n ci --replicas=0 2>$null | Out-Null
}

function Acquire-BuildLease {
    param([string]$Holder, [int]$DurationSec = 7200)
    Require-Command kubectl
    $ns = $script:PublishBuildkitNs
    $name = 'c35-build'
    $deadline = (Get-Date).AddSeconds($DurationSec)
    while ((Get-Date) -lt $deadline) {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $existing = (kubectl get lease $name -n $ns -o jsonpath='{.spec.holderIdentity}' 2>$null)
        $ErrorActionPreference = $prevEap
        if (-not $existing) {
            $yaml = @"
apiVersion: coordination.k8s.io/v1
kind: Lease
metadata:
  name: $name
  namespace: $ns
spec:
  holderIdentity: $Holder
  leaseDurationSeconds: 60
"@
            $prevApply = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            $yaml | kubectl apply -f - 2>$null | Out-Null
            $ErrorActionPreference = $prevApply
            $existing = (kubectl get lease $name -n $ns -o jsonpath='{.spec.holderIdentity}' 2>$null)
            if ($existing -eq $Holder) { return }
        } elseif ($existing -eq $Holder) {
            kubectl patch lease $name -n $ns --type=merge -p "{`"spec`":{`"holderIdentity`":`"$Holder`",`"leaseDurationSeconds`":60}}" 2>$null | Out-Null
            return
        }
        Write-Host "==> waiting for build lease (held by $existing)..."
        Start-Sleep -Seconds 5
        $ErrorActionPreference = 'SilentlyContinue'
        $existing = (kubectl get lease $name -n $ns -o jsonpath='{.spec.holderIdentity}' 2>$null)
        $renew = (kubectl get lease $name -n $ns -o jsonpath='{.spec.renewTime}' 2>$null)
        $ErrorActionPreference = $prevEap
        if ($existing -and $existing -ne $Holder -and -not $renew) {
            kubectl delete lease $name -n $ns 2>$null | Out-Null
        }
    }
    throw "timed out waiting for build lease"
}

function Release-BuildLease {
    param([string]$Holder)
    $ns = $script:PublishBuildkitNs
    $name = 'c35-build'
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $existing = kubectl get lease $name -n $ns -o jsonpath='{.spec.holderIdentity}' 2>$null
    if ($existing -eq $Holder) {
        kubectl delete lease $name -n $ns 2>$null | Out-Null
    }
    $ErrorActionPreference = $prevEap
}

function Ensure-Buildkit {
    Require-Command kubectl
    Ensure-SingleBuilder
    Write-Host "==> ensure buildkit ($script:PublishBuildkitNs)"
    kubectl apply -f $script:PublishBuildkitDir | Out-Null
    kubectl scale deployment/$script:PublishBuildkitSvc -n $script:PublishBuildkitNs --replicas=1 | Out-Null
    kubectl rollout status "deployment/$script:PublishBuildkitSvc" -n $script:PublishBuildkitNs --timeout=180s 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "buildkit rollout failed" }
    $pod = $null
    for ($i = 0; $i -lt 90; $i++) {
        $pod = Get-BuildkitPodName
        if ($pod) { break }
        Start-Sleep -Seconds 2
    }
    if (-not $pod) { throw "buildkit pod not scheduled" }
    Wait-BuildkitReady -Pod $pod
}

function Stop-Buildkit {
    Require-Command kubectl
    Write-Host "==> scale buildkit to 0 (idle)"
    kubectl scale deployment/$script:PublishBuildkitSvc -n $script:PublishBuildkitNs --replicas=0 | Out-Null
}

function Wait-BuildkitReady {
    param([string]$Pod, [int]$TimeoutSec = 120)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $live = kubectl get pod -n $script:PublishBuildkitNs $Pod -o jsonpath='{.status.containerStatuses[0].ready}' 2>$null
        if ($live -eq 'true') {
            kubectl exec -n $script:PublishBuildkitNs $Pod -- buildctl debug workers 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { return }
        }
        Start-Sleep -Seconds 2
    }
    throw "buildkit pod $Pod not ready within ${TimeoutSec}s"
}

function Copy-FileToBuildkit {
    param([string]$Pod, [string]$LocalFile, [string]$RemoteFile)
    if (-not (Test-Path $LocalFile)) { throw "missing local file: $LocalFile" }
    $remoteDir = ($RemoteFile -replace '/[^/]+$', '')
    kubectl exec -n $script:PublishBuildkitNs $Pod -- mkdir -p $remoteDir | Out-Null
    $local = (Resolve-Path $LocalFile).Path
    $dir = Split-Path -Parent $local
    $name = Split-Path -Leaf $local
    $prev = Get-Location
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        Set-Location $dir
        kubectl cp -n $script:PublishBuildkitNs "./$name" "${Pod}:${RemoteFile}" 2>&1 | Out-Host
        if ($LASTEXITCODE -eq 0) { return }
        $stage = "cat > $RemoteFile"
        cmd.exe /c "kubectl exec -n $($script:PublishBuildkitNs) $Pod -i -- sh -c `"$stage`" < `"$name`""
        if ($LASTEXITCODE -ne 0) { throw "upload $name -> ${Pod}:$RemoteFile failed" }
    } finally {
        Set-Location $prev
        $ErrorActionPreference = $prevEap
    }
}

function Sync-BuildkitRegistryAuth {
    param([string]$Pod, [string]$SecretNamespace = "c35")
    $b64 = kubectl get secret docker-registry-auth -n $SecretNamespace -o jsonpath='{.data.\.dockerconfigjson}'
    if (-not $b64) { throw "missing docker-registry-auth in $SecretNamespace" }
    $tmp = Join-Path $env:TEMP "docker-config-$([Guid]::NewGuid().ToString('n')).json"
    [IO.File]::WriteAllBytes($tmp, [Convert]::FromBase64String($b64))
    try {
        Copy-FileToBuildkit -Pod $Pod -LocalFile $tmp -RemoteFile "/root/.docker/config.json"
    } finally {
        Remove-Item $tmp -Force
    }
}

function Invoke-ClusterBuildkitBuild {
    param(
        [string]$RepoRoot,
        [string]$ImageRef,
        [string]$Platform = "linux/arm64",
        [string[]]$TarPaths,
        [string]$DockerfileRel = "_/deployments/Dockerfile",
        [string]$ContextRel = ""
    )
    Require-Command kubectl
    Require-Command tar
    $holder = "$env:COMPUTERNAME-$(Get-Date -Format 'HHmmss')"
    Acquire-BuildLease -Holder $holder
    try {
        Ensure-Buildkit
    $pod = Get-BuildkitPodName
    if (-not $pod) { throw "buildkit pod not found" }
    $ctxId = [Guid]::NewGuid().ToString('n')
    $remote = "/tmp/c35-build-$ctxId"
    $tarName = "c35-build-$ctxId.tar"
    $tarPath = Join-Path $RepoRoot $tarName
    Push-Location $RepoRoot
    try {
        $tarSw = [System.Diagnostics.Stopwatch]::StartNew()
        $excludes = Get-PublishTarExcludeArgs
        & tar -cf $tarName @excludes @TarPaths
        if ($LASTEXITCODE -ne 0) { throw "tar context failed" }
        $tarSw.Stop()
        $contextMb = [math]::Round((Get-Item $tarPath).Length / 1MB, 2)
        Set-PublishPerfMark -Name 'context_tar' -Seconds $tarSw.Elapsed.TotalSeconds -Extra @{ context_mb = $contextMb }
        Write-Host "==> stage context on buildkit pod=$pod ($contextMb MB)"
        $uploadSw = [System.Diagnostics.Stopwatch]::StartNew()
        Copy-FileToBuildkit -Pod $pod -LocalFile $tarPath -RemoteFile "$remote/context.tar"
        $uploadSw.Stop()
        Set-PublishPerfMark -Name 'context_upload' -Seconds $uploadSw.Elapsed.TotalSeconds
        $extractSw = [System.Diagnostics.Stopwatch]::StartNew()
        kubectl exec -n $script:PublishBuildkitNs $pod -- sh -c "tar -xf $remote/context.tar -C $remote"
        if ($LASTEXITCODE -ne 0) { throw "extract context tar failed" }
        $extractSw.Stop()
        Set-PublishPerfMark -Name 'context_extract' -Seconds $extractSw.Elapsed.TotalSeconds
    } finally {
        Pop-Location
        if (Test-Path $tarPath) { Remove-Item $tarPath -Force }
    }
    Sync-BuildkitRegistryAuth -Pod $pod
    $dfRel = ($DockerfileRel -replace '\\', '/')
    $dfName = ($dfRel -split '/')[-1]
    $dfDir = $dfRel -replace '/[^/]+$', ''
    $dockerfileLocal = if ($dfDir) { "$remote/$dfDir" } else { $remote }
    $ctxRel = ($ContextRel -replace '\\', '/').Trim('/')
    $contextLocal = if ($ctxRel) { "$remote/$ctxRel" } else { $remote }
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    kubectl exec -n $script:PublishBuildkitNs $pod -- buildctl --addr unix:///run/buildkit/buildkitd.sock build `
        --frontend dockerfile.v0 `
        --local "context=$contextLocal" `
        --local "dockerfile=$dockerfileLocal" `
        --opt "filename=$dfName" `
        --opt "platform=$Platform" `
        --output "type=image,name=$ImageRef,push=true" 2>&1 | ForEach-Object { Write-Host $_ }
    $buildOk = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $prevEap
    if (-not $buildOk) { throw "buildctl failed" }
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'buildctl' -Seconds $buildSw.Elapsed.TotalSeconds
    kubectl exec -n $script:PublishBuildkitNs $pod -- rm -rf $remote | Out-Null
    } finally {
        Release-BuildLease -Holder $holder
    }
}

function Publish-C35RustChefImage {
    param(
        [string]$Tag = $script:PublishRustChefTagDefault,
        [string]$RepoRoot,
        [string]$Platform = 'linux/arm64'
    )
    $imageRef = "$($script:PublishRustChefImage):$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Show-PublishDiskStatus -Label 'disk before build (c35-rust-chef)'
    Write-Host "==> build $imageRef via cluster buildkit ($Platform)"
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $tarPaths = @('_/deployments/Dockerfile.c35-rust-chef')
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths -DockerfileRel '_/deployments/Dockerfile.c35-rust-chef'
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'image_build' -Seconds $buildSw.Elapsed.TotalSeconds
    Write-Host "==> build finished in $(Format-PublishDuration $buildSw.Elapsed)"
    Show-PublishDiskStatus -Label 'disk after build (c35-rust-chef)'
}

function Publish-C35ChannelWhatsappDeviceImage {
    param(
        [string]$Tag = "latest",
        [string]$RepoRoot,
        [string]$Platform = "linux/arm64"
    )
    $imageRef = "$($script:PublishChannelWhatsappDeviceImage):$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Show-PublishDiskStatus -Label "disk before build (channel-whatsapp-device)"
    Write-Host "==> build $imageRef via cluster buildkit ($Platform) from $dir"
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $tarPaths = @(
        'servers/Cargo.toml', 'servers/Cargo.lock',
        'servers/crates', 'servers/channel_whatsapp_device',
        'servers/server_ai/Cargo.toml',
        'servers/fetcher/Cargo.toml',
        'servers/node_stats/Cargo.toml',
        '_/schemas', '_/deployments/Dockerfile.channel-whatsapp-device', '_/deployments/docker'
    )
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths -DockerfileRel '_/deployments/Dockerfile.channel-whatsapp-device'
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'image_build' -Seconds $buildSw.Elapsed.TotalSeconds
    Write-Host "==> build finished in $(Format-PublishDuration $buildSw.Elapsed)"
    Show-PublishDiskStatus -Label "disk after build (channel-whatsapp-device)"
}

function Publish-C35NodeStatsImage {
    param(
        [string]$Tag = "latest",
        [string]$RepoRoot,
        [string]$Platform = "linux/arm64"
    )
    $imageRef = "$($script:PublishNodeStatsImage):$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Show-PublishDiskStatus -Label "disk before build (c35-node-stats)"
    Write-Host "==> build $imageRef via cluster buildkit ($Platform) from $dir"
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $tarPaths = @(
        'servers/Cargo.toml', 'servers/Cargo.lock',
        'servers/node_stats', 'servers/crates/proto', '_/schemas',
        '_/deployments/Dockerfile.c35-node-stats', '_/deployments/docker'
    )
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths -DockerfileRel '_/deployments/Dockerfile.c35-node-stats'
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'image_build' -Seconds $buildSw.Elapsed.TotalSeconds
    Write-Host "==> build finished in $(Format-PublishDuration $buildSw.Elapsed)"
    Show-PublishDiskStatus -Label "disk after build (c35-node-stats)"
}

function Publish-C35FetcherImage {
    param(
        [string]$Tag = "latest",
        [string]$RepoRoot,
        [string]$Platform = "linux/arm64"
    )
    $imageRef = "hsg.ocir.io/axr8wqrrukgm/c35-fetcher:$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Show-PublishDiskStatus -Label "disk before build (c35-fetcher)"
    Write-Host "==> build $imageRef via cluster buildkit ($Platform) from $dir"
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $tarPaths = @(
        'servers/Cargo.toml', 'servers/Cargo.lock',
        'servers/crates', 'servers/fetcher',
        'servers/server_ai/Cargo.toml',
        'servers/node_stats/Cargo.toml',
        'servers/channel_whatsapp_device/Cargo.toml',
        '_/schemas', '_/deployments/Dockerfile.c35-fetcher', '_/deployments/docker'
    )
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths -DockerfileRel '_/deployments/Dockerfile.c35-fetcher'
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'image_build' -Seconds $buildSw.Elapsed.TotalSeconds
    Write-Host "==> build finished in $(Format-PublishDuration $buildSw.Elapsed)"
    Show-PublishDiskStatus -Label "disk after build (c35-fetcher)"
}

function Publish-GcpStaticEgressImage {
    param(
        [string]$Tag = 'latest',
        [string]$RepoRoot,
        [string]$Platform = 'linux/amd64'
    )
    $imageRef = "hsg.ocir.io/axr8wqrrukgm/c35-static-egress:$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Write-Host "==> build $imageRef via cluster buildkit ($Platform)"
    $tarPaths = @('servers/c35-proxy-cf-warp')
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths `
        -DockerfileRel 'servers/c35-proxy-cf-warp/Dockerfile' -ContextRel 'servers/c35-proxy-cf-warp'
}

function Publish-C35ServerImage {
    param(
        [string]$Tag = "latest",
        [string]$RepoRoot,
        [string]$Platform = "linux/arm64"
    )
    $imageRef = "$($script:PublishImage):$Tag"
    $dir = (Resolve-Path $RepoRoot).Path
    Show-PublishDiskStatus -Label "disk before build"
    Write-Host "==> build $imageRef via cluster buildkit ($Platform) from $dir"
    $buildSw = [System.Diagnostics.Stopwatch]::StartNew()
    $tarPaths = @(
        'servers/Cargo.toml', 'servers/Cargo.lock',
        'servers/crates', 'servers/server_ai',
        'servers/fetcher/Cargo.toml',
        'servers/node_stats/Cargo.toml',
        'servers/channel_whatsapp_device/Cargo.toml',
        'clients/web', 'scripts/presentation', '_/schemas',
        '_/deployments/Dockerfile', '_/deployments/docker'
    )
    Invoke-ClusterBuildkitBuild -RepoRoot $dir -ImageRef $imageRef -Platform $Platform -TarPaths $tarPaths
    $buildSw.Stop()
    Set-PublishPerfMark -Name 'image_build' -Seconds $buildSw.Elapsed.TotalSeconds
    Write-Host "==> build finished in $(Format-PublishDuration $buildSw.Elapsed)"
    Show-PublishDiskStatus -Label "disk after build"
}

function Publish-Rollout {
    param([string]$Deployment, [string]$Namespace = "c35")
    Require-Command kubectl
    $deploySw = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "==> rollout restart deployment/$Deployment namespace=$Namespace"
    kubectl rollout restart "deployment/$Deployment" -n $Namespace
    kubectl rollout status "deployment/$Deployment" -n $Namespace --timeout=300s
    if ($LASTEXITCODE -ne 0) { throw "rollout failed: deployment/$Deployment" }
    $deploySw.Stop()
    Set-PublishPerfMark -Name 'rollout' -Seconds $deploySw.Elapsed.TotalSeconds
    Write-Host "==> rollout finished in $(Format-PublishDuration $deploySw.Elapsed)"
}
