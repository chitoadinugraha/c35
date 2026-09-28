# YugabyteDB storage (k3s-btm)

Single-node YB uses one shared **`yb-data`** PVC (`oci-bv`, 50Gi) with Helm `subPath`:

| subPath | Pod | Mount |
|---------|-----|-------|
| `tserver` | `yb-tserver-0` | `/mnt/disk0` |
| `master` | `yb-master-0` | `/mnt/disk0` |

PV reclaim is patched to **Retain** after bind (default `oci-bv` is Delete).

## `yb-data` is sacred (Retain)

The **`yb-data` PVC and its bound PV are production data.** OCI `oci-bv` minimum is 50Gi; deleting the PVC (or a `Delete` reclaim PV) destroys the block volume.

| Rule | Why |
|------|-----|
| **Never** `kubectl delete pvc yb-data` unless you have a **tested** volume backup restore plan | Empty or new PVC = empty cluster |
| **Never** swap PVC/PV names (`yb-data-restored`, `restored2`, new CSI id) without confirming **YSQL smoke** on the target volume first | Wrong volume looks “healthy” with zero `c35` data |
| **Always** patch PV reclaim to **Retain** after first bind | Survives accidental PVC delete; volume stays in OCI for reattach |
| **Always** backup to object storage before node pool resize, Helm subPath changes, or `migrate_yb_to_pvc.ps1` | Boot disk / eviction does not wipe PVC, but migrate mistakes do |
| Keep **one** active `yb-data` claim; delete only **orphan** OCI volumes after verifying they are not the live PV `volumeHandle` | Extra 50Gi volumes eat Always Free quota (200Gi boot+block) |

Confirm live volume:

```powershell
kubectl get pvc -n yugabyte yb-data -o jsonpath='{.spec.volumeName}{"\n"}'
kubectl get pv yb-data-restored2 -o jsonpath='{.spec.csi.volumeHandle}{"\n"}'
```

## Migrate / restore checklist

Run in order; do not skip steps.

1. **Backup** — YB backup or OCI volume backup of the **current** `yb-data` PV; note `volumeHandle` OCID in the run log.
2. **Freeze writes** (optional but safer) — scale `c35-server` to 0 or stop traffic during cutover.
3. **PVC only** — if creating a new PVC, restore **into** `yb-data` subPaths (`master`, `tserver`) via `migrate-job-from-backup.yaml` / `migrate_yb_to_pvc.ps1`; do not start YB on an empty PVC “to see if it works”.
4. **`pg_data` symlink** — fix on `tserver` subPath **before** first start after restore (see below).
5. **`fs_data_dirs` gflags** — run `patch-gflags-fs-data-dirs.ps1` so tserver uses PVC, not overlay empty dir.
6. **Start YB** — `kubectl rollout status statefulset/yb-master -n yugabyte`; same for `yb-tserver`.
7. **Smoke** — `ysqlsh` against `c35`: `SELECT count(*) FROM information_schema.tables WHERE table_schema = 'ai';` (expect dozens of tables, not 0).
8. **Retain** — `kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'`
9. **App** — rollout `c35-server`; tail logs for `connect yugabyte` / NATS hydrate.
10. **Orphans** — in OCI console, terminate only block volumes **not** matching step 1’s live `volumeHandle`.

### Common “data lost” causes (this cluster)

- Tserver **gflags** pointed at ephemeral `/var/yugabyte` while data sat on PVC subPath.
- New **empty** PVC or wrong **restore** volume attached; pods started anyway.
- **DiskPressure** evicted YB pods (data on PVC is fine) — looks like “DB down”, not wipe; fix disk, restart pods.
- Deleted **orphan-looking** volume that was still the active PV name in Kubernetes.

## PVC `pg_data` symlink (required)

Helm mounts subPath `tserver` at `/mnt/disk0`. The chart still sets `--fs_data_dirs=/var/yugabyte` (ephemeral overlay) unless patched — **tserver then starts empty while real data stays on the PVC**. After PVC migration run:

```powershell
.\_\deployments\yugabyte\patch-gflags-fs-data-dirs.ps1
kubectl delete pod -n yugabyte yb-master-0 yb-tserver-0
```

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
