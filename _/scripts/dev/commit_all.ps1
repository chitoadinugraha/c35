# Commit all tracked/untracked changes and push the current branch.
# Usage (repo root):
#   .\_\scripts\dev\commit_all.ps1
#   .\_\scripts\dev\commit_all.ps1 -Message "feat: scope instructions for user and site"

param(
    [string]$Message = 'chore: commit all'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}
. (Join-Path $repoRoot '_\deployments\_lib\publish_git.ps1')

Invoke-RepoGitCommitAndPush -RepoRoot $repoRoot -CommitMessage $Message