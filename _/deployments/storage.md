# Cluster storage layout (k3s-btm)

## Summary

| Data | Backend | Survives pod restart | Survives node replace / CPU resize |
|------|---------|----------------------|-------------------------------------|
| **YugabyteDB** | PVC `yb-data` (`oci-bv`, 50Gi, Retain) | Yes | Yes (block volume reattaches) |
| **NATS JetStream** | `emptyDir` on `nats-0` (`/data/jetstream`) | **No** (pod delete wipes store) | **No** — hydrate from YB on recovery |
| **Buildkit cache** | `hostPath` `/var/lib/alienai/buildkit` | Yes | **No** — expendable |
| **c35-server CAS** | `emptyDir` | No | No |

OCI `oci-bv` **minimum provisioned size is 50Gi** regardless of PVC request.

## Yugabyte (`yb-data`)

One shared PVC, Helm `subPath`:

```text
yb-data/tserver  -> yb-tserver-0 /mnt/disk0
yb-data/master   -> yb-master-0 /mnt/disk0
```

Manifests: [`_/deployments/yugabyte/`](yugabyte/README.md). Migration: `_/scripts/deploy/migrate_yb_to_pvc.ps1`.

## NATS JetStream (ephemeral)

JetStream store is **`emptyDir`** in [`_/deployments/nats/statefulset.yaml`](nats/statefulset.yaml). No `oci-bv` PVC.

- **Source of truth:** YugabyteDB (`ai.prompt_run`, `ai.task_run`, `ai.task_trigger`, …)
- **Recovery:** `c35-server` hydrates JetStream streams and schedules after NATS reconnect
- **Upgrade runbook:** `_/scripts/deploy/nats_ephemeral_upgrade.ps1`

Delete legacy PVC `nats-data-nats-0` after migration to stop block-volume billing.

## PVC billing (current target)

| PVC | NS | Class | Size | Reclaim | Notes |
|-----|-----|-------|------|---------|-------|
| `yb-data` | yugabyte | oci-bv | 50Gi | **Retain** | Production DB |

Buildkit **no longer uses block storage** — cache on boot disk only.

NATS **no longer uses block storage** — JetStream on `emptyDir`; delete `nats-data-nats-0` if still present.

## Recommendations

1. **Backups** — YB backup to object storage before OKE node pool changes.
2. **Do not rely on swap** for YB — swap is for build/OOM safety only.
3. **Single buildkit** — `build/buildkit` only; `ci/buildkitd` deprecated.
4. **NATS outages** — expect brief queue loss; verify `c35-server` hydrate logs after NATS pod recycle.
