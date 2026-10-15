# Product/catalog inventory for gucicha regression (CSA migration).
# Usage: .\_\scripts\dev\site_gucicha_inventory.ps1
# Requires YB MCP or psql; defaults to known site_iid from 2026-10-15 baseline.

param(
    [int64]$SiteIid = 101836119014211584
)

$ErrorActionPreference = 'Stop'
Write-Host "site_iid=$SiteIid"

# Prefer MCP yb_query via agent; standalone uses env if psql configured.
$sql = @"
SELECT
  (SELECT COUNT(*) FROM site.product WHERE site_iid = $SiteIid AND deleted_ts IS NULL) AS product_count,
  (SELECT COALESCE(MAX(product_id), 0) FROM site.product WHERE site_iid = $SiteIid AND deleted_ts IS NULL) AS max_product_id,
  (SELECT COUNT(*) FROM site.link WHERE site_iid = $SiteIid AND deleted_ts IS NULL) AS link_count
"@

Write-Host "Run on YB (database c35):"
Write-Host $sql
Write-Host ""
Write-Host "Baseline (2026-10-15): product_count=10, alien_id=gucicha"
