# c35-fetcher

Singleton Deployment that periodically fetches external data (FX rates, LLM catalog), persists to YB, and publishes NATS updates for `c35-server` pods.

Spec: [`_/docs/fetcher.md`](../../docs/fetcher.md)

## Publish

```powershell
.\_\scripts\deploy\publish_fetcher.ps1
```

## Verify

```powershell
kubectl logs -n c35 deploy/c35-fetcher --tail=80
kubectl get deploy -n c35 c35-fetcher
```

Expect log lines: `fx_rate` publish, `llm_catalog synced`.
