# Build linux/amd64 static-IP CONNECT proxy, push OCIR (local buildx if Docker runs, else cluster buildkit).
# Do NOT docker build on c-personal — see .cursor/rules/docker-build-local.mdc
param(
    [string]$Tag = 'latest',
    [string]$Image = 'hsg.ocir.io/axr8wqrrukgm/c35-static-egress',
    [string]$RegistryUser = 'axr8wqrrukgm/chitoadinugraha@gmail.com',
    [string]$RegistryPass = '',
    [string]$Platform = 'linux/amd64',
    [switch]$ForceBuildkit
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$dockerfile = Join-Path $repoRoot 'servers\c35-proxy-cf-warp\Dockerfile'
$context = Join-Path $repoRoot 'servers\c35-proxy-cf-warp'
if (-not (Test-Path $dockerfile)) { throw "Missing $dockerfile" }

if (-not $RegistryPass) { $RegistryPass = $env:OCIR_PASSWORD }
if (-not $RegistryPass) {
    foreach ($envPath in @(
            (Join-Path $repoRoot '.env.local'),
            (Join-Path $repoRoot 'servers\server_ai\.env.local'),
            'D:\alienai_proto\cluster\.env.local'
        )) {
        if (-not (Test-Path $envPath)) { continue }
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^\s*OCIR_PASSWORD=(.*)$') { $RegistryPass = $matches[1].Trim().Trim('"').Trim("'") }
        }
        if ($RegistryPass) { break }
    }
}

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) { throw "Required: $Name" }
}

function Test-DockerDaemon {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $null = docker info 2>&1
    $ok = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $prev
    return $ok
}

$ref = "${Image}:$Tag"
$useBuildkit = $ForceBuildkit -or -not (Test-DockerDaemon)

if ($useBuildkit) {
    Require-Command kubectl
    . (Join-Path (Join-Path $repoRoot '_\deployments') '_lib\publish.ps1')
    Publish-GcpStaticEgressImage -Tag $Tag -RepoRoot $repoRoot -Platform $Platform
} else {
    if (-not $RegistryPass -and (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $b64 = kubectl get secret docker-registry-auth -n c35 -o jsonpath='{.data.\.dockerconfigjson}' 2>$null
        if ($b64) {
            $cfg = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64)) | ConvertFrom-Json
            $auth = $cfg.auths.'hsg.ocir.io'.auth
            if ($auth) {
                $pair = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($auth))
                $i = $pair.IndexOf(':')
                if ($i -ge 0) {
                    $RegistryUser = $pair.Substring(0, $i)
                    $RegistryPass = $pair.Substring($i + 1)
                }
            }
        }
    }
    if (-not $RegistryPass) { throw 'Set OCIR_PASSWORD or use cluster buildkit (Docker not running)' }

    Require-Command docker
    $dockerConfigDir = Join-Path $env:TEMP "docker-config-ocir-$([Guid]::NewGuid().ToString('n'))"
    New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
    $b64 = kubectl get secret docker-registry-auth -n c35 -o jsonpath='{.data.\.dockerconfigjson}' 2>$null
    if ($b64) {
        [IO.File]::WriteAllBytes((Join-Path $dockerConfigDir 'config.json'), [Convert]::FromBase64String($b64))
    } else {
        $auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${RegistryUser}:${RegistryPass}"))
        $json = @{ auths = @{ 'hsg.ocir.io' = @{ auth = $auth } } } | ConvertTo-Json -Compress
        Set-Content -Path (Join-Path $dockerConfigDir 'config.json') -Value $json -Encoding UTF8
    }
    $prevDockerConfig = $env:DOCKER_CONFIG
    $env:DOCKER_CONFIG = $dockerConfigDir
    try {
        Write-Host "==> buildx $Platform -> $ref (local)"
        docker buildx build --platform $Platform -f $dockerfile -t $ref --push $context
        if ($LASTEXITCODE -ne 0) { throw 'buildx failed' }
    } finally {
        if ($prevDockerConfig) { $env:DOCKER_CONFIG = $prevDockerConfig } else { Remove-Item Env:DOCKER_CONFIG -ErrorAction SilentlyContinue }
        Remove-Item -Recurse -Force $dockerConfigDir -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host '==> on c-personal: .\_\scripts\deploy\deploy_gcp_static_egress.ps1'
Write-Host "  image: $ref"
