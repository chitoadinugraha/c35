# NATS JetStream (ephemeral store)

NATS **2.15-alpine** with JetStream store directory `/data/jetstream` on `emptyDir` volume `nats-data`.

| Before | After |
|--------|-------|
| PVC `nats-data-nats-0` (`oci-bv`, 20–50Gi billed) | `emptyDir` (lost on pod delete) |
| JetStream survives pod reschedule | **YB is source of truth** — `c35-server` hydrates streams on boot / reconnect |

Kubernetes **cannot** swap `volumeClaimTemplates` for `emptyDir` in place. Recreate the StatefulSet (Services, ConfigMaps, Secrets stay). Runbook: `_/scripts/deploy/nats_ephemeral_upgrade.ps1`.

## Prerequisites

- `kubectl` context: `btm.alienai.id` (k3s-btm)
- Namespace `nats` with existing `nats-config`, `nats-credentials`, `nats-tls-certs`

## Upgrade (PVC to ephemeral emptyDir)

### 1. Scale down c35-server awareness

NATS downtime is expected. Scale consumers so they reconnect and hydrate from YB after NATS is back:

```powershell
kubectl scale deployment/c35-server -n c35 --replicas=0
kubectl scale deployment/c35-fetcher -n c35 --replicas=0
```

Or run the full script (includes these steps):

```powershell
.\_\scripts\deploy\nats_ephemeral_upgrade.ps1
```

### 2. Scale down and remove StatefulSet

```powershell
kubectl scale statefulset nats -n nats --replicas=0
kubectl wait -n nats --for=delete pod/nats-0 --timeout=120s
kubectl delete statefulset nats -n nats
```

### 3. Delete old PVC (stop oci-bv billing)

```powershell
kubectl delete pvc nats-data-nats-0 -n nats --ignore-not-found --wait=true
```

JetStream data on the PVC is **not** migrated. Queued work is replayed from YB (`ai.prompt_run`, `ai.task_run`, `ai.task_trigger`) when `c35-server` reconnects.

### 4. Apply repo StatefulSet

```powershell
kubectl apply -f _/deployments/nats/statefulset.yaml
kubectl wait -n nats --for=condition=ready pod/nats-0 --timeout=180s
```

### 5. Scale c35-server back up

```powershell
kubectl scale deployment/c35-fetcher -n c35 --replicas=1
kubectl scale deployment/c35-server -n c35 --replicas=1
kubectl rollout status deployment/c35-server -n c35 --timeout=300s
```

Watch server logs for hydrate: `[c35:nats] reconnected — hydrate scheduled` (or equivalent).

### 6. Verify

```powershell
kubectl exec -n nats nats-0 -c nats -- wget -qO- http://127.0.0.1:8222/varz | Select-String jetstream
kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream
kubectl delete pod nats-0 -n nats
kubectl wait -n nats --for=condition=ready pod/nats-0 --timeout=180s
kubectl exec -n nats nats-0 -c nats -- du -sh /data/jetstream
```

After pod delete, JetStream dir is empty until hydrate repopulates streams — expected with `emptyDir`.

## NATS 2.15

| Version | Status | Notes |
|---------|--------|-------|
| **2.15** | **Deploy target** | Latest maintained 2.x; recurring schedules (`@every`, cron) |
| 2.12 | EOL | Previous cluster image |

Image: `nats:2.15-alpine` in `statefulset.yaml`.

## JetStream streams

| Stream | Subject | Consumer / queue | Retention | Notes |
|--------|---------|------------------|-----------|-------|
| `C35_DEVICE_TASK` | task dispatch | — | — | See [server.md](../../docs/server.md) |
| `C35_CHAT_PROMPT` | `c35.prompt.run` | durable `c35-prompt-dispatch` (pull, `max_deliver=3`, `ack_wait=60s`) | WorkQueue | Prompt turn jobs; live fanout on core NATS `c35.user.{owner_iid}.chat.{chat_id}` |
| `C35_TASK_SCHEDULE` | `c35.schedule.task.*` | — | — | Cron schedules; requires NATS 2.14+ |

### Bootstrap streams

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

## Recovery model

1. **YB** holds durable state: queued prompts, task runs, cron triggers.
2. **NATS** holds runtime queues and schedules only.
3. On NATS loss or pod delete, one `c35-server` leader acquires a YB advisory lock and hydrates JetStream from YB.

Do **not** rely on NATS disk for durability. See [`storage.md`](../storage.md).

## Related

- Cluster storage layout: [`../storage.md`](../storage.md)
- Upgrade script: [`../../scripts/deploy/nats_ephemeral_upgrade.ps1`](../../scripts/deploy/nats_ephemeral_upgrade.ps1)
- Hydrate plan: [`../docs/plans/2026-09-23-nats-scheduler-hydrate-multitask.md`](../docs/plans/2026-09-23-nats-scheduler-hydrate-multitask.md)
