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

### Vendor billing (platform COGS)

After enabling a vendor (`*_VENDOR_BILL_ENABLED=1` in `c35-server-env`):

```powershell
kubectl logs -n c35 deploy/c35-fetcher --tail=120 | Select-String vendor_bill
```

Expect: `vendor bill task registered` at startup, then per-vendor runs (`vendor_bill_oci`, `vendor_bill_gcp`, `vendor_bill_cf`, `vendor_bill_wasabi`) with `changed=true` when rows upsert.

```sql
SELECT vendor, category, period_start, period_end, amount_usd, status, fetched_ts
FROM ai.platform_vendor_cost
ORDER BY fetched_ts DESC
LIMIT 20;
```

Env reference: `servers/fetcher/.env.example` (`VENDOR_BILL_*` + per-vendor keys).
