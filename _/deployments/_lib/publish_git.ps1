# Commit (if needed) and push before cluster/app publish scripts run.

function Invoke-RepoGitCommitAndPush {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot,
        [string]$CommitMessage = 'chore: pre-publish commit'
    )

    Push-Location $RepoRoot
    try {
        $branch = (git rev-parse --abbrev-ref HEAD).Trim()
        if ($branch -eq 'HEAD') {
            throw 'Detached HEAD; checkout a branch before publish.'
        }

        $status = git status --porcelain
        if ($status) {
            Write-Host '==> git add -A (uncommitted changes)'
            git add -A
            if ($LASTEXITCODE -ne 0) { throw 'git add failed' }

            Write-Host "==> git commit: $CommitMessage"
            git commit -m $CommitMessage
            if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
        }

        Write-Host "==> git push origin $branch"
        git push origin $branch
        if ($LASTEXITCODE -ne 0) { throw 'git push failed' }
    } finally {
        Pop-Location
    }
}
