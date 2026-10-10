# Commit all and push

Stage **all** changes (`git add -A`), commit if the working tree is dirty, and **push** the current branch to `origin`.

From the **repo root**:

```powershell
.\_\scripts\dev\commit_all.ps1
```

Custom commit message:

```powershell
.\_\scripts\dev\commit_all.ps1 -Message "feat: your summary here"
```

**Agent:** Run this when the user invokes `/commit-all`. Draft a clear one-line `-Message` from `git diff` (do not use the default unless the user wants a generic chore commit). Do not skip push unless the user says so. Fails on detached HEAD or hook rejection — fix and retry with a new commit (no amend unless amend rules apply).
