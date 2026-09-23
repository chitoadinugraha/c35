# c35-node-stats DaemonSet

One pod per Kubernetes node publishes host CPU/RAM/network, OS disk mounts, and configured volume paths to NATS every 2 seconds.

## NATS subjects

| Subject | Payload |
|---------|---------|
| `c35.stats.node.{NODE_NAME}` | `StatsPush` with `node` body |
| `c35.stats.volume.{NODE_NAME}.{namespace}.{pvc_name}` | `StatsPush` with `volume` body |

## Configuration

| Env | Source | Description |
|-----|--------|-------------|
| `NODE_NAME` | downward API | Kubernetes node name |
| `NATS_URL` | daemonset env | `tls://nats-client.nats.svc.cluster.local:4222` |
| `NATS_USER` / `NATS_PASS` | `c35-server-env` secret | NATS credentials |
| `NATS_CA` | daemonset env + `nats-ca` secret mount | TLS CA |
| `C35_NODE_MOUNTS` | ConfigMap | Comma-separated host mounts (`/`, `/var/log`) |
| `C35_VOLUME_PATHS` | ConfigMap | `namespace:pvc:path[:storage_class][:label]` per entry |

Default volume entries monitor Yugabyte and NATS hostPath data:

```
yugabyte:yb-tserver:/host/var/lib/alienai/yb-tserver:oci-bv:yb-tserver
yugabyte:yb-master:/host/var/lib/alienai/yb-master:oci-bv:yb-master
nats:nats-data:/host/var/lib/alienai/nats:oci-bv:nats
```

> Before apply, verify host paths on cluster:
> `kubectl exec -n c35 -l app=c35-node-stats -- ls /host/var/lib/alienai/`
> Adjust `yb-master` and `nats` paths to match actual host layout.

Only the DaemonSet pod on a node with the path present will publish non-zero stats; other nodes skip missing paths.

## Host access

The container mounts the node root filesystem read-only at `/host`. `sysinfo` reads `/host/proc` and `/host/sys` for CPU, memory, network, and block I/O.

## Deploy

```powershell
.\_\scripts\deploy\publish_node_stats.ps1
kubectl apply -f _/deployments/c35-node-stats/
```

## Verify

```powershell
kubectl get pods -n c35 -l app=c35-node-stats
kubectl logs -n c35 -l app=c35-node-stats --tail=20
# From a pod with nats CLI:
nats sub 'c35.stats.>' --count=5
```

## Build locally

```powershell
cd node_stats
cargo build --release -p c_node_stats
```

## Publish image

```powershell
.\_\scripts\deploy\publish_node_stats.ps1
```

Builds `linux/arm64` via cluster buildkit and pushes `hsg.ocir.io/axr8wqrrukgm/c35-node-stats:latest`.
