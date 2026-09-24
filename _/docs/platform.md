# Platform vendor billing + P&L (LOCKED)

Status: **locked** 2026-09-24

Canonical spec for infra vendor cost ingestion, wholesale AI COGS on usage dedupe, and root-admin platform P&L.

Implementation plan: [`plans/2026-09-24-platform-vendor-billing-multitask.md`](plans/2026-09-24-platform-vendor-billing-multitask.md).

Related: [`fetcher.md`](fetcher.md), [`billing.md`](billing.md), [`billing-pricing.md`](billing-pricing.md).

---

## Overview

| Layer | Store / API | Role |
|-------|-------------|------|
| **Vendor costs** | `ai.platform_vendor_cost` | Normalized OCI / GCP / CF / Wasabi line items (USD) |
| **AI wholesale** | `ai.billing_usage_dedupe.cost_wholesale_usd` | Per-turn provider cost at deduct time |
| **P&L query** | `c35_mod_platform::platform_pnl_query` | SQL aggregation for date range |
| **Admin wire** | `admin_platform_pnl` invoke | Root-only; returns metrics widgets + vendor table |
| **Flutter** | Root console → **P&L** page | Date range picker, metrics cards, vendor breakdown |

Platform vendor data is **root-only ops** — not client-syncable; no `owner_iid` on cost rows.

---

## Schema

DDL: [`../schemas/platform.sql`](../schemas/platform.sql). Migration: [`../schemas/migrations/platform_vendor_cost_v1.sql`](../schemas/migrations/platform_vendor_cost_v1.sql).

### `ai.platform_vendor_cost`

| Column | Type | Notes |
|--------|------|-------|
| `id` | BIGINT PK | Snowflake |
| `vendor` | VARCHAR(32) | `oci`, `gcp`, `cf`, `wasabi` |
| `category` | VARCHAR(32) | See categories below |
| `sku` | VARCHAR(128) | Provider SKU or product code |
| `description` | TEXT | Human label |
| `period_start` / `period_end` | DATE | Billing window (inclusive) |
| `amount_native` | NUMERIC | Raw amount in `currency` |
| `currency` | VARCHAR(3) | `USD` or `IDR` (normalized at upsert) |
| `amount_usd` | NUMERIC | USD equivalent at fetch time |
| `source` | VARCHAR(32) | `api`, `csv`, `manual` |
| `external_ref` | VARCHAR(256) | Idempotency key |
| `status` | VARCHAR(16) | `estimated`, `finalized` |
| `fetched_ts` | TIMESTAMPTZ | Last fetch |
| `meta` | JSONB | Provider-specific extras |

**Idempotency:** unique index on `(vendor, external_ref)` where `external_ref <> ''` and `deleted_ts IS NULL`.

### `ai.billing_usage_dedupe.cost_wholesale_usd`

Written on each `billing_usage_report` (LLM, tools, voice). Historical rows stay `0` — no backfill required.

---

## Categories

| `category` | Used for | P&L bucket |
|------------|----------|--------------|
| `compute` | OKE, VMs, GKE | Infra COGS |
| `storage` | Block/object storage, Wasabi | Infra COGS |
| `network` | VCN, LB, egress, CF Zero Trust | Infra COGS |
| `dns` | CF DNS / registrar | Infra COGS |
| `ai_api` | Gemini, Vertex AI, CF Workers AI / AI Gateway | **Reconciliation only** — excluded from infra COGS |
| `other` | Unclassified | Infra COGS |

**Double-count guard:** `ai_api` vendor lines are compared against `cost_wholesale_usd` sum; drift &gt; 5% surfaces a warning in the admin report.

---

## Fetch schedule

Handled by `VendorBillFetchTask` in `c35_mod_platform` (registered in `c35-fetcher`). No NATS publish — cold admin data.

| Job | When | Window | `status` |
|-----|------|--------|----------|
| **MTD daily** | Every 24h (staggered per vendor) | 1st of month → **yesterday** (WIB) | `estimated` |
| **Month-close** | Days **1, 3, 7, 14** of new month | Previous calendar month | `estimated` → `finalized` |

Business timezone: `VENDOR_BILL_TZ` (default `Asia/Jakarta`).

Task registry: [`fetcher.md`](fetcher.md#vendor-bill-tasks).

---

## P&L formula

All admin SQL / reports use the same definitions:

```
revenue_usd =
  SUM(billing_topup_request settled → amount_usd)
+ SUM(billing_purchase settled → USD equivalent)
+ SUM(billing_usage_dedupe.cost_usd)          -- retail metered

ai_cogs_usd =
  SUM(billing_usage_dedupe.cost_wholesale_usd)

infra_cogs_usd =
  SUM(platform_vendor_cost.amount_usd
      WHERE category NOT IN ('ai_api'))

ai_api_vendor_usd =                            -- reconciliation only
  SUM(platform_vendor_cost.amount_usd
      WHERE category = 'ai_api')

gross_profit_usd = revenue_usd - ai_cogs_usd - infra_cogs_usd
```

**Drift:** `ai_cogs_drift_pct = |ai_api_vendor_usd - ai_cogs_usd| / max(ai_cogs, ai_api_vendor) × 100` (0 when both zero).

Vendor costs filter by period overlap: `period_end >= since_date AND period_start <= until_date`.

Usage / revenue filter by `created_ts` / `settled_ts` in the ms range from the client.

---

## Admin wire

Proto: [`../schemas/proto/c35/report.proto`](../schemas/proto/c35/report.proto).

```
admin_platform_pnl { since_ms, until_ms } → ResAdminPlatformPnl
```

Response includes scalar totals plus `UiWidget` list (metrics cards + vendor table). Root-only (`require_root`).

Flutter: `AdminPnlApi.platformPnl` → `PageRootPnl` (Root console → **P&L**).

---

## Environment variables

### Scheduler (all vendors)

| Var | Default | Purpose |
|-----|---------|---------|
| `VENDOR_BILL_FETCH_INTERVAL_SECS` | `86400` | Task interval |
| `VENDOR_BILL_MTD_ENABLED` | `1` | Enable MTD window fetch |
| `VENDOR_BILL_FINALIZE_DAYS` | `1,3,7,14` | Month-close run days |
| `VENDOR_BILL_STAGGER_MINS` | `0,15,30,45` | Stagger oci,gcp,cf,wasabi |
| `VENDOR_BILL_TZ` | `Asia/Jakarta` | MTD / finalize calendar |

### OCI (`vendor_bill_oci`)

| Var | Required |
|-----|----------|
| `OCI_VENDOR_BILL_ENABLED` | `1` to enable |
| `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT` | yes |
| `OCI_COMPARTMENT_OCID` | yes |
| `OCI_REGION` | default `ap-southeast-1` |
| OCI API key PEM | `OCI_PRIVATE_KEY` or `~/.oci/config` profile |

### GCP (`vendor_bill_gcp`)

| Var | Required |
|-----|----------|
| `GCP_VENDOR_BILL_ENABLED` | `1` to enable |
| `GCP_BILLING_PROJECT_ID` | yes |
| `GCP_BILLING_DATASET`, `GCP_BILLING_TABLE` | BigQuery export |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | service account |

### Cloudflare (`vendor_bill_cf`)

| Var | Required |
|-----|----------|
| `CF_VENDOR_BILL_ENABLED` | `1` to enable |
| `CLOUDFLARE_API_TOKEN` | Billing:Read |
| `CLOUDFLARE_ACCOUNT_ID` | yes |

Month-close invoice: CSV import (`source=csv`, `status=finalized`) — see plan Track J.

### Wasabi (`vendor_bill_wasabi`)

| Var | Required |
|-----|----------|
| `WASABI_VENDOR_BILL_ENABLED` | `1` to enable |
| `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY` | yes |
| `WASABI_REGION` | e.g. `ap-southeast-1` |

---

## Code layout

```
servers/crates/mod_platform/     # vendor upsert, period, FX, fetch adapters, pnl.rs
servers/crates/mod_admin/        # admin_platform_pnl wire handler
servers/fetcher/                 # registers enabled vendor tasks
clients/app/lib/c/admin/         # admin_pnl_api.dart
clients/app/lib/pages/           # page_root_pnl.dart
```

Regenerate Dart pb after proto changes: `_/scripts/protoc.ps1`.
