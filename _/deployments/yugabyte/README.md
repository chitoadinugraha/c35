# YugabyteDB storage (k3s-btm)

Single-node YB uses one shared **`yb-data`** PVC (`oci-bv`, 50Gi) with Helm `subPath`:

| subPath | Pod | Mount |
|---------|-----|-------|
| `tserver` | `yb-tserver-0` | `/mnt/disk0` |
| `master` | `yb-master-0` | `/mnt/disk0` |

PV reclaim is patched to **Retain** after bind (default `oci-bv` is Delete).

## Migrate from hostPath

```powershell
.\_\scripts\deploy\migrate_yb_to_pvc.ps1
```

Old hostPath dirs are renamed to `*.hostpath-bak` on the node after YSQL smoke test — not deleted automatically.

## Helm

```powershell
helm upgrade yb yugabyte/yugabyte --version 2026.1.1 -n yugabyte -f _/deployments/yugabyte/values-pvc.yaml
```
