# eturnal (removed)

The `eturnal` DaemonSet in namespace `eturnal` was part of legacy **cs-agent** WebRTC.

**Status:** Removed — superseded by **coturn** in `c35` namespace (`turn.alienai.id`, host port **3479**).

The eturnal pod was stuck for 3+ days because ConfigMap `eturnal-config` was never created. Running both would also conflict on host port 3478.

To remove from cluster:

```powershell
kubectl delete daemonset eturnal -n eturnal --ignore-not-found
kubectl delete namespace eturnal --ignore-not-found
```

See [`_/docs/remote.md`](../../_/docs/remote.md) and [`_/deployments/coturn/`](../../_/deployments/coturn/).
