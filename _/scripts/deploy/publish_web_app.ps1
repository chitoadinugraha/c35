# Publish Flutter web app: release build, S3 app/web/{N}/ + current/, ai.config web version.
# Public URL: https://alienai.id/app/
#
# Usage (repo root):
#   .\_\scripts\deploy\publish_web_app.ps1
#   .\_\scripts\deploy\publish_web_app.ps1 -SkipDartGet
#
# Env: repo-root .env.local (S3_*, YB_PASSWORD). Web upload does not need DEPLOY_AUTH_TOKEN.
# See _/specs/app-release.md (Flutter web publish).

param(
    [switch]$SkipDartGet
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$appRelease = Join-Path $repoRoot '_\scripts\deploy\publish_app_release.ps1'
if ($SkipDartGet) {
    & $appRelease -WebOnly -SkipDartGet
} else {
    & $appRelease -WebOnly
}
