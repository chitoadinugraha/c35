# NATS JetStream persistence (PVC)

JetStream store directory: `/data/jetstream` on volume `nats-data`.

| Before | After |
|--------|-------|
| `emptyDir` 10Gi (lost on pod restart) | PVC 20Gi `oci-bv` (survives reschedule) |

`volumeClaimTemplates` name `nats-data` produces PVC `nats-data-nats-0` for replica `nats-0`.

## Prerequisites

- `kubectl` context: `btm.alienai.id` (k3s-btm)
- Storage class `oci-bv` (OCI block volume, WaitForFirstConsumer)
- Namespace `nats` with existing `nats-config`, `nats-credentials`, `nats-tls-certs`

## Upgrade (emptyDir to PVC)

Kubernetes **cannot** add `volumeClaimTemplates` to a StatefulSet that was created without them. Recreate the StatefulSet (Services, ConfigMaps, Secrets stay).

### 1. Backup JetStream data (if any)

```powershell
kubectl exec -n nats nats-0 -c nats -- tar czf - -C /data jetstream > jetstream-backup.tgz
kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream
```

### 2. Scale down and remove StatefulSet

```powershell
kubectl scale statefulset nats -n nats --replicas=0
kubectl wait -n nats --for=delete pod/nats-0 --timeout=120s
kubectl delete statefulset nats -n nats
```

### 3. Export live StatefulSet, patch volumes, apply

```powershell
kubectl get statefulset nats -n nats -o yaml > nats-statefulset-live.yaml   # skip if already deleted
```

Edit `spec`:

1. Add `volumeClaimTemplates` from `pvc-patch.yaml`
2. Remove the `nats-data` `emptyDir` entry from `spec.template.spec.volumes`
3. Keep `volumeMounts` on the container (`mountPath: /data/jetstream`, `name: nats-data`)

Or apply the repo export (must match live env/credentials):

```powershell
kubectl apply -f _/deployments/nats/statefulset.yaml
```

### 4. Wait for PVC and pod

```powershell
kubectl get pvc -n nats
kubectl wait -n nats --for=jsonpath='{.status.phase}'=Bound pvc/nats-data-nats-0 --timeout=180s
kubectl wait -n nats --for=condition=ready pod/nats-0 --timeout=180s
```

### 5. Restore backup (optional)

Only if you backed up non-empty JetStream data in step 1:

```powershell
kubectl cp jetstream-backup.tgz nats/nats-0:/tmp/jetstream-backup.tgz -c nats
kubectl exec -n nats nats-0 -c nats -- sh -c 'rm -rf /data/jetstream && tar xzf /tmp/jetstream-backup.tgz -C /data'
kubectl rollout restart statefulset/nats -n nats
```

### 6. Verify persistence

```powershell
kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream
kubectl delete pod nats-0 -n nats
kubectl wait -n nats --for=condition=ready pod/nats-0 --timeout=180s
kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream
```

Sizes should match after pod delete (data on PVC, not emptyDir).

## Expand PVC

`oci-bv` allows volume expansion:

```powershell
kubectl patch pvc nats-data-nats-0 -n nats -p '{"spec":{"resources":{"requests":{"storage":"40Gi"}}}}'
```

## JetStream streams

| Stream | Subject | Consumer / queue | Retention | Notes |
|--------|---------|------------------|-----------|-------|
| `C35_DEVICE_TASK` | task dispatch | — | — | See [server.md](../../docs/server.md) |
| `C35_CHAT_PROMPT` | `c35.prompt.run` | durable `c35-prompt-dispatch` (pull, `max_deliver=3`, `ack_wait=60s`) | WorkQueue | Prompt turn jobs; live fanout on core NATS `c35.user.{owner_iid}.chat.{chat_id}` |

### Bootstrap `C35_CHAT_PROMPT`

The AI server calls `get_or_create_stream` on boot when NATS is connected. Optional manifest for ops visibility:

```yaml
# _/deployments/nats/prompt-stream.yaml (reference)
stream: C35_CHAT_PROMPT
subjects: [c35.prompt.run]
retention: workqueue
consumer: c35-prompt-dispatch
ack_wait: 60s
max_deliver: 3
```

Verify with NATS CLI (inside `nats-0`):

```powershell
kubectl exec -n nats nats-0 -c nats -- nats stream info C35_CHAT_PROMPT
kubectl exec -n nats nats-0 -c nats -- nats consumer info C35_CHAT_PROMPT c35-prompt-dispatch
```

## Related

- JetStream stream `C35_DEVICE_TASK` — task dispatch ([server.md](../../docs/server.md))
- Future: `c35.stats.*` node-stats monitors this mount ([platform ops plan](../../../docs/superpowers/plans/2026-09-22-platform-ops-multitask.md))
