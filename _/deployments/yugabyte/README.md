# YugabyteDB storage (k3s-btm)

Single-node YB uses one shared **`yb-data`** PVC (`oci-bv`, 50Gi) with Helm `subPath`:

| subPath | Pod | Mount |
|---------|-----|-------|
| `tserver` | `yb-tserver-0` | `/mnt/disk0` |
| `master` | `yb-master-0` | `/mnt/disk0` |

PV reclaim is patched to **Retain** after bind (default `oci-bv` is Delete).

## PVC `pg_data` symlink (required)

Helm mounts subPath `tserver` at `/mnt/disk0`. The image ships `pg_data` as an absolute symlink to `/mnt/disk0/pg_data_15`, which breaks on subPath mounts. After any restore or new PVC, fix **before** first YB start:

```bash
kubectl exec -n yugabyte yb-tserver-0 -c yb-tserver -- sh -c 'cd /mnt/disk0 && rm -f pg_data && ln -s pg_data_15 pg_data'
```

(Use a one-off inspect pod with the PVC mounted at `/data/tserver` if YB is scaled down.)

## Migrate from hostPath

```powershell
.\_\scripts\deploy\migrate_yb_to_pvc.ps1
```

Old hostPath dirs are renamed to `*.hostpath-bak` on the node after YSQL smoke test — not deleted automatically.

## Helm

```powershell
helm upgrade yb yugabyte/yugabyte --version 2026.1.1 -n yugabyte -f _/deployments/yugabyte/values-pvc.yaml
```
