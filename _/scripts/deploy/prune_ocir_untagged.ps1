# Delete untagged container images in OCIR (version=null). Keeps tagged images (e.g. :latest).
param(
    [switch]$Apply,
    [string]$CompartmentId = 'ocid1.tenancy.oc1..aaaaaaaaey3wfzt4f7jp72r74wtu4m24hx35pafnagjbajgwn6us2s6nwpba',
    [string[]]$RepositoryPrefix = @('c35-', 'channel-whatsapp')
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command oci -ErrorAction SilentlyContinue)) { throw 'Required command not found: oci' }

Write-Host "==> OCIR prune untagged images"
Write-Host "    repos: $($RepositoryPrefix -join ', ')*  apply=$Apply"

$repos = oci artifacts container repository list --compartment-id $CompartmentId --all --output json | ConvertFrom-Json
$selected = @($repos.data.items | Where-Object {
    $n = $_.'display-name'
    foreach ($p in $RepositoryPrefix) { if ($n -like "$p*") { return $true } }
    $false
})

$toDelete = @()
foreach ($repo in $selected) {
    $imgs = oci artifacts container image list --compartment-id $CompartmentId --repository-id $repo.id --all --output json | ConvertFrom-Json
    foreach ($img in $imgs.data.items) {
        if ($null -eq $img.version -or "$($img.version)".Trim() -eq '') {
            $toDelete += [PSCustomObject]@{
                repo = $repo.'display-name'
                id = $img.id
                digest = $img.digest
                created = $img.'time-created'
            }
        }
    }
}

Write-Host "==> untagged images to remove: $($toDelete.Count)"
$toDelete | Sort-Object repo, created | ForEach-Object { Write-Host "    $($_.repo) $($_.digest.Substring(0,19))... $($_.created)" }

if (-not $Apply) {
    Write-Host '==> dry-run only; pass -Apply to delete'
    return
}

$deleted = 0
foreach ($row in $toDelete) {
    Write-Host "==> delete $($row.repo) $($row.digest)"
    oci artifacts container image delete --image-id $row.id --force --wait-for-state DELETED | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "delete failed: $($row.id)" }
    $deleted++
}
Write-Host "==> deleted $deleted untagged image(s)"
