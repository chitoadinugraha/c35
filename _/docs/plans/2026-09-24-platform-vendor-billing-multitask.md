# Platform vendor billing + P&L — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ingest infra vendor costs (OCI, GCP, CF, Wasabi) via `c35-fetcher`, store normalized line items in YB, reconcile with per-turn AI wholesale COGS, and expose a root-admin P&L report so we can see platform gross profit.

**Architecture:** New `ai.platform_vendor_cost` table + `c35_mod_platform` crate (vendor upsert, period windows, USD normalization). One `FetchTask` per vendor in fetcher (daily MTD + month-close re-pull). No NATS push — cold admin data. P&L is SQL aggregation over `billing_*` + `platform_vendor_cost` + `billing_usage_dedupe.cost_wholesale_usd`. Root console wire comes last.

**Tech Stack:** Rust / sqlx / reqwest / `mod_fetch` / OCI Usage API / GCP Cloud Billing API (or BigQuery export) / Cloudflare GraphQL + invoice CSV / Wasabi account API / Flutter root console (phase 2).

**Related specs:** [`_/docs/fetcher.md`](../../_/docs/fetcher.md), [`_/docs/billing.md`](../../_/docs/billing.md), [`_/docs/billing-pricing.md`](../../_/docs/billing-pricing.md), [`_/docs/plans/2026-09-22-platform-ops-multitask.md`](2026-09-22-platform-ops-multitask.md).

## Global Constraints

- Server workspace under `servers/`; build from `servers/` → `.cache/server` (see `.cursor/rules/rust-cache.mdc`).
- Verify Rust: `cd servers && cargo build -p server_fetcher` and `cargo build -p server_ai`; `cargo test -p CRATE` for edited crates.
- `mod_*` must not depend on `wire_ws`, `server_ai`, or `server_fetcher`.
- Fetcher singleton: `c35-fetcher` `replicas: 1`, `linux/arm64` → `hsg.ocir.io`.
- Platform vendor data is **root-only ops** — not client-syncable; no `owner_iid` on cost rows.
- Idempotent upsert on `(vendor, external_ref)` — daily runs must not duplicate.
- Tag GCP/CF AI lines `category = ai_api` — reconcile against wholesale, do not double-count in infra COGS.
- Snowflake IDs via `c35_store::snowflake_id()`; blake3 for content hashes where needed.
- Do not commit API keys — k8s secrets / env only.

---

## Fetch schedule (locked for this plan)

| Job | When | Window | `status` |
|-----|------|--------|----------|
| **MTD daily** | Every 24h @ 02:00 WIB (stagger vendors +15m) | `period_start` = 1st of month, `period_end` = **yesterday** | `estimated` |
| **Month-close** | Days **1, 3, 7, 14** of new month | Previous calendar month full | `estimated` → `finalized` when stable |

Env defaults:

```text
VENDOR_BILL_FETCH_INTERVAL_SECS=86400
VENDOR_BILL_MTD_ENABLED=1
VENDOR_BILL_FINALIZE_DAYS=1,3,7,14
VENDOR_BILL_STAGGER_MINS=0,15,30,45   # oci,gcp,cf,wasabi
```

No `fetch.proto` / NATS subject for vendor bills.

---

## Multitask map (6 waves)

| Wave | Track | Name | Depends on | Delivers |
|------|-------|------|------------|----------|
| **1** | **A** | Schema + migration | — | `platform.sql`, `cost_wholesale_usd` column |
| **1** | **B** | `mod_platform` core | — | upsert, period helpers, USD normalize |
| **2** | **C** | Fetch scheduler | A, B | `VendorBillFetchTask` base, MTD/finalize logic |
| **2** | **D** | AI wholesale on dedupe | A | write `cost_wholesale_usd` per turn |
| **3** | **E** | OCI adapter | C | OCI Usage / Cost Analysis → rows |
| **3** | **F** | GCP adapter | C | Cloud Billing API → rows |
| **3** | **G** | CF adapter | C | CF usage + CSV fallback → rows |
| **3** | **H** | Wasabi adapter | C | Wasabi account API → rows |
| **4** | **I** | Fetcher wire-up + deploy env | E–H | tasks in `fetcher/main.rs`, k8s secrets |
| **4** | **J** | CSV import script | A, B | manual month-close fallback |
| **5** | **K** | Admin P&L API | A, B, D | `admin_platform_pnl`, `wire.proto` |
| **6** | **L** | Root console P&L page | K | Flutter dashboard tab |
| **6** | **M** | Docs | all | `platform.md`, `fetcher.md` update |

Wave 1: **A + B** parallel. Wave 2: **C + D** parallel. Wave 3: **E + F + G + H** parallel. Wave 4: **I + J** parallel. Wave 5: **K**. Wave 6: **L + M** parallel (L optional if SQL-only is enough initially).

---

## P&L formula (query contract)

All tracks must use the same definitions in SQL / admin report:

```
revenue_usd =
  SUM(billing_topup_request settled → USD equivalent)
+ SUM(billing_purchase settled → USD)
+ SUM(billing_usage_dedupe.cost_usd)          -- retail metered

ai_cogs_usd =
  SUM(billing_usage_dedupe.cost_wholesale_usd)

infra_cogs_usd =
  SUM(platform_vendor_cost.amount_usd
      WHERE category NOT IN ('ai_api'))       -- infra only

ai_api_vendor_usd =                            -- reconciliation only
  SUM(platform_vendor_cost.amount_usd
      WHERE category = 'ai_api')

gross_profit_usd = revenue_usd - ai_cogs_usd - infra_cogs_usd
```

Expose `ai_api_vendor_usd` vs `ai_cogs_usd` delta in admin report meta — flag when drift > 5%.

---

## Track A — Schema + migration

**Files:**
- Create: `_/schemas/platform.sql`
- Create: `_/schemas/migrations/platform_vendor_cost_v1.sql`
- Modify: `_/schemas/billing.sql` (add `cost_wholesale_usd` to `billing_usage_dedupe` DDL comment block)
- Modify: `_/docs/README.md` (index row when `platform.md` exists — Track M)

**DDL (`platform.sql`):**

```sql
CREATE TABLE IF NOT EXISTS ai.platform_vendor_cost (
    id                  BIGINT PRIMARY KEY,
    vendor              VARCHAR(32) NOT NULL,
    category            VARCHAR(32) NOT NULL,
    sku                 VARCHAR(128) NOT NULL DEFAULT '',
    description         TEXT NOT NULL DEFAULT '',

    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,

    amount_native       NUMERIC(20, 6) NOT NULL,
    currency            VARCHAR(3) NOT NULL DEFAULT 'USD',
    amount_usd          NUMERIC(12, 6) NOT NULL,

    source              VARCHAR(32) NOT NULL DEFAULT 'api',
    external_ref        VARCHAR(256) NOT NULL DEFAULT '',
    status              VARCHAR(16) NOT NULL DEFAULT 'estimated',

    fetched_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    meta                JSONB NOT NULL DEFAULT '{}',
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_platform_vendor CHECK (vendor IN ('oci','gcp','cf','wasabi')),
    CONSTRAINT chk_platform_vendor_cat CHECK (
        category IN ('compute','storage','network','dns','ai_api','other')
    ),
    CONSTRAINT chk_platform_vendor_status CHECK (status IN ('estimated','finalized')),
    CONSTRAINT chk_platform_vendor_source CHECK (source IN ('api','csv','manual'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_platform_vendor_cost_ref
    ON ai.platform_vendor_cost (vendor, external_ref)
    WHERE external_ref <> '' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_platform_vendor_cost_period
    ON ai.platform_vendor_cost (period_start, period_end, vendor)
    WHERE deleted_ts IS NULL;
```

**Alter `billing_usage_dedupe`:**

```sql
ALTER TABLE ai.billing_usage_dedupe
    ADD COLUMN IF NOT EXISTS cost_wholesale_usd NUMERIC(12, 6) NOT NULL DEFAULT 0;
```

- [x] **Step 1:** Add `platform.sql` + migration script
- [x] **Step 2:** Add `cost_wholesale_usd` to `billing.sql` + migration
- [ ] **Step 3:** Apply migration on cluster YB (`yb_execute` or deploy script)
- [ ] **Step 4:** Verify `\d ai.platform_vendor_cost` and dedupe column exist

---

## Track B — `mod_platform` core

**Files:**
- Create: `servers/crates/mod_platform/Cargo.toml`
- Create: `servers/crates/mod_platform/src/lib.rs`
- Create: `servers/crates/mod_platform/src/vendor_cost.rs`
- Create: `servers/crates/mod_platform/src/period.rs`
- Create: `servers/crates/mod_platform/src/fx_usd.rs`
- Create: `servers/crates/mod_platform/tests/vendor_cost_test.rs`
- Modify: `servers/Cargo.toml` (add `crates/mod_platform`)

**Interfaces — produces:**

```rust
// vendor_cost.rs
pub struct VendorCostLine {
    pub vendor: &'static str,
    pub category: &'static str,
    pub sku: String,
    pub description: String,
    pub period_start: NaiveDate,
    pub period_end: NaiveDate,
    pub amount_native: f64,
    pub currency: String,
    pub source: &'static str,
    pub external_ref: String,
    pub status: &'static str,
    pub meta: serde_json::Value,
}

pub async fn vendor_cost_upsert_batch(pool: &PgPool, lines: &[VendorCostLine]) -> Result<usize>;
pub async fn vendor_cost_finalize_period(pool: &PgPool, vendor: &str, period_start: NaiveDate, period_end: NaiveDate) -> Result<u64>;

// period.rs
pub fn vendor_bill_mtd_window(now: DateTime<Utc>) -> (NaiveDate, NaiveDate);
pub fn vendor_bill_prev_month_window(now: DateTime<Utc>) -> (NaiveDate, NaiveDate);
pub fn vendor_bill_should_finalize_today(now: DateTime<Utc>, finalize_days: &[u32]) -> bool;

// fx_usd.rs — read latest billing_fx_rate for IDR; USD passthrough
pub async fn amount_to_usd(pool: &PgPool, amount_native: f64, currency: &str) -> Result<f64>;
```

- [x] **Step 1:** Create crate; deps: `sqlx`, `chrono`, `serde_json`, `c35_store`, `anyhow`
- [x] **Step 2:** Implement `vendor_cost_upsert_batch` — `ON CONFLICT (vendor, external_ref) DO UPDATE` via unique index lookup or explicit select+update
- [x] **Step 3:** Implement period helpers (yesterday = UTC+7 business day or env `VENDOR_BILL_TZ=Asia/Jakarta`)
- [x] **Step 4:** Implement `amount_to_usd` — USD=1.0, IDR via latest `billing_fx_rate.micro_per_usd`
- [x] **Step 5:** Unit tests: upsert idempotency (mock or `C35_TEST_DB=1`), MTD window boundaries, USD normalize
- [x] **Step 6:** `cd servers && cargo test -p c35_mod_platform && cargo build -p c35_mod_platform`

---

## Track C — Fetch scheduler

**Files:**
- Create: `servers/crates/mod_platform/src/fetch_vendor.rs`
- Create: `servers/crates/mod_platform/src/fetch/mod.rs`
- Create: `servers/crates/mod_platform/src/fetch/oci.rs` (stub)
- Create: `servers/crates/mod_platform/src/fetch/gcp.rs` (stub)
- Create: `servers/crates/mod_platform/src/fetch/cf.rs` (stub)
- Create: `servers/crates/mod_platform/src/fetch/wasabi.rs` (stub)
- Modify: `servers/crates/mod_platform/src/lib.rs`

**Trait:**

```rust
pub trait VendorBillSource: Send + Sync {
    fn vendor(&self) -> &'static str;
    async fn fetch_lines(&self, ctx: &FetchCtx, window: (NaiveDate, NaiveDate)) -> Result<Vec<VendorCostLine>>;
}

pub struct VendorBillFetchTask {
    pub source: Box<dyn VendorBillSource>,
    pub stagger_mins: u64,
}
```

`FetchTask` impl:
- `interval()` → `VENDOR_BILL_FETCH_INTERVAL_SECS` (86400)
- `run()`:
  1. If `vendor_bill_should_finalize_today` → fetch prev month + call `vendor_cost_finalize_period` when amounts stable (same total 2 runs in a row — store hash in `meta` or compare)
  2. If `VENDOR_BILL_MTD_ENABLED` → fetch MTD window
  3. Return `FetchOutcome { changed: rows_upserted > 0, nats_subject: None, ... }`

- [x] **Step 1:** Implement `VendorBillFetchTask` + env parsing
- [x] **Step 2:** Stub sources return empty vec (compile-only)
- [x] **Step 3:** Integration test with mock `VendorBillSource` behind `C35_TEST_DB=1`
- [x] **Step 4:** `cargo test -p c35_mod_platform`

---

## Track D — AI wholesale on `billing_usage_dedupe`

**Files:**
- Modify: `servers/crates/mod_billing/src/billing_turn.rs`
- Modify: `servers/crates/mod_voice/src/billing.rs` (voice dedupe path)
- Modify: `servers/crates/mod_billing/tests/` (extend if exists)
- Create: `servers/crates/mod_billing/tests/wholesale_dedupe_test.rs`

**Logic:**
- On `billing_usage_report`, compute `wholesale = billing_cost_wholesale_usd(model, tokens_in, tokens_out)` (or tool wholesale for image/voice)
- `UPDATE billing_usage_dedupe SET cost_wholesale_usd = $wholesale WHERE owner_iid AND req_id`
- Backfill not required — historical rows stay 0

- [x] **Step 1:** Thread wholesale through deduct insert/update
- [x] **Step 2:** Voice STT/TTS paths set wholesale separately
- [x] **Step 3:** Unit test: retail = wholesale × 1.5 for frontier model
- [x] **Step 4:** `cd servers && cargo test -p c35_mod_billing && cargo build -p server_ai`

---

## Track E — OCI adapter

**Files:**
- Modify: `servers/crates/mod_platform/src/fetch/oci.rs`
- Create: `servers/crates/mod_platform/tests/fetch_oci_test.rs` (mock HTTP)

**API:** OCI Usage API + Cost Analysis (`/usage/api/v1/usage` or SDK equivalent).

**Env:**

```text
OCI_VENDOR_BILL_ENABLED=1
OCI_CONFIG_PROFILE=DEFAULT          # or inline tenancy/user/key via existing OCI env
OCI_COMPARTMENT_OCID=...
```

**Mapping:**

| OCI service | `category` |
|-------------|------------|
| Compute / OKE | `compute` |
| Block Volume / Object Storage | `storage` |
| VCN / LB | `network` |
| Other | `other` |

`external_ref` = `{compartment}:{service}:{sku}:{date}` hash or API line id.

- [x] **Step 1:** HTTP client with OCI request signing (reuse pattern from existing OCI tooling if any in repo; else `oci-sdk` crate or manual sig)
- [x] **Step 2:** Parse response → `Vec<VendorCostLine>`
- [x] **Step 3:** Mock test with fixture JSON
- [ ] **Step 4:** Manual smoke: run fetcher locally against tenancy (read-only API key)

---

## Track F — GCP adapter

**Files:**
- Modify: `servers/crates/mod_platform/src/fetch/gcp.rs`
- Create: `servers/crates/mod_platform/tests/fetch_gcp_test.rs`

**API (pick one):**
- **Preferred:** BigQuery billing export table (daily partition) — service account JSON in secret
- **Fallback:** Cloud Billing Budgets / `cloudbilling.googleapis.com` SKU costs

**Env:**

```text
GCP_VENDOR_BILL_ENABLED=1
GCP_BILLING_PROJECT_ID=...
GCP_BILLING_DATASET=...             # if BigQuery
GCP_BILLING_TABLE=...
# or GOOGLE_APPLICATION_CREDENTIALS_JSON
```

**Mapping:**

| SKU pattern | `category` |
|-------------|------------|
| `Gemini`, `Vertex AI`, `Speech`, `Text-to-Speech` | `ai_api` |
| `Kubernetes Engine`, `Compute Engine` | `compute` |
| `Cloud Storage`, `Persistent Disk` | `storage` |
| `Networking`, `Load Balancing` | `network` |

- [x] **Step 1:** BigQuery query for date range → line items
- [x] **Step 2:** Category classifier from `sku.description` / `service.description`
- [x] **Step 3:** Mock test with fixture rows
- [ ] **Step 4:** Document required IAM: `bigquery.dataViewer` + billing account viewer

---

## Track G — CF adapter

**Files:**
- Modify: `servers/crates/mod_platform/src/fetch/cf.rs`
- Create: `servers/crates/mod_platform/tests/fetch_cf_test.rs`
- Create: `_/scripts/dev/import_cf_billing_csv.ps1` (thin wrapper calling Track J)

**API:**
- GraphQL Analytics for Workers / AI Gateway usage (estimated daily)
- Full invoice: **CSV import** via Track J for month-close (`source=csv`)

**Env:**

```text
CF_VENDOR_BILL_ENABLED=1
CLOUDFLARE_API_TOKEN=...            # Billing:Read
CLOUDFLARE_ACCOUNT_ID=...
```

**Mapping:**

| Product | `category` |
|---------|------------|
| AI Gateway / Workers AI | `ai_api` |
| DNS / Registrar | `dns` |
| Zero Trust / Tunnel | `network` |

- [x] **Step 1:** GraphQL daily usage → estimated rows
- [x] **Step 2:** CSV parser for account invoice export → `source=csv`, `status=finalized`
- [x] **Step 3:** Tests with redacted fixture files
- [ ] **Step 4:** Document CF token scopes in `_/docs/mcp-security.md` (billing read token)

---

## Track H — Wasabi adapter

**Files:**
- Modify: `servers/crates/mod_platform/src/fetch/wasabi.rs`
- Create: `servers/crates/mod_platform/tests/fetch_wasabi_test.rs`

**API:** Wasabi account billing / utilization API (S3-compatible control plane).

**Env:**

```text
WASABI_VENDOR_BILL_ENABLED=1
WASABI_ACCESS_KEY=...
WASABI_SECRET_KEY=...
WASABI_REGION=ap-southeast-1
```

**Mapping:** storage + egress → `category=storage` / `network`.

- [x] **Step 1:** Implement fetch for billing period
- [x] **Step 2:** Correlate optional: `meta.storage_gb` from API
- [x] **Step 3:** Mock test
- [ ] **Step 4:** Cross-check against `ai.file_blob_*` growth (manual note in README)

---

## Track I — Fetcher wire-up + deploy

**Files:**
- Modify: `servers/fetcher/Cargo.toml` (add `c35_mod_platform`)
- Modify: `servers/fetcher/src/main.rs`
- Modify: `servers/fetcher/.env.example`
- Modify: `_/deployments/c35-fetcher/deployment.yaml` (vendor env from secret)
- Modify: `_/deployments/c35-fetcher/README.md`
- Modify: `_/docs/fetcher.md` (task registry table)

**`main.rs` pattern:**

```rust
if env_enabled("OCI_VENDOR_BILL_ENABLED") {
    tasks.push(Box::new(VendorBillFetchTask::oci_from_env()));
}
// ... gcp, cf, wasabi
```

- [x] **Step 1:** Register enabled vendor tasks
- [x] **Step 2:** Update `.env.example` with all `VENDOR_BILL_*` vars
- [x] **Step 3:** `cd servers && cargo build -p server_fetcher`
- [ ] **Step 4:** Add k8s secret keys (reference only — do not commit values)
- [ ] **Step 5:** Deploy; verify logs: `vendor_bill_oci changed=true rows=N`

**Verify (cluster):**

```sql
SELECT vendor, category, period_start, period_end, amount_usd, status, fetched_ts
FROM ai.platform_vendor_cost
ORDER BY fetched_ts DESC LIMIT 20;
```

---

## Track J — CSV import script

**Files:**
- Create: `_/scripts/dev/platform_vendor_import_csv.ps1`
- Create: `_/scripts/dev/platform_vendor_import_csv.rs` (or dart — prefer small Rust bin under `servers/` if reuse upsert)

**Usage:**

```powershell
.\_\scripts\dev\platform_vendor_import_csv.ps1 -Vendor cf -Path .\invoice-sep.csv -PeriodStart 2026-09-01 -PeriodEnd 2026-09-30 -Finalize
```

Calls same `vendor_cost_upsert_batch` logic via `sqlx` CLI or one-off binary `server_tools`.

- [ ] **Step 1:** Define minimal CSV columns: `sku,description,amount,currency,category`
- [ ] **Step 2:** Parse → upsert with `source=csv`
- [ ] **Step 3:** `-Finalize` sets `status=finalized`
- [ ] **Step 4:** Test with sample redacted CSV in `servers/crates/mod_platform/tests/fixtures/`

---

## Track K — Admin P&L API

**Files:**
- Create: `servers/crates/mod_platform/src/pnl.rs`
- Modify: `servers/crates/mod_admin/src/lib.rs`
- Create: `servers/crates/mod_admin/src/platform_pnl.rs`
- Modify: `servers/crates/wire_http/src/invoke.rs`
- Modify: `_/schemas/proto/c35/report.proto`
- Modify: `_/schemas/proto/c35/wire.proto`
- Create: `servers/crates/mod_admin/tests/platform_pnl_test.rs`

**Proto (`report.proto`):**

```protobuf
message ReqAdminPlatformPnl {
  int64 since_ms = 1;
  int64 until_ms = 2;
}

message ResAdminPlatformPnl {
  repeated UiWidget widgets = 1;
  double revenue_usd = 2;
  double ai_cogs_usd = 3;
  double infra_cogs_usd = 4;
  double gross_profit_usd = 5;
  double ai_api_vendor_usd = 6;
  double ai_cogs_drift_pct = 7;
}
```

Follow `admin_log_report` widget pattern (`UiMetricsCard` + `UiReportTable` by vendor).

- [x] **Step 1:** Implement `platform_pnl_query(pool, since, until)` in `mod_platform`
- [x] **Step 2:** `admin_platform_pnl` with `require_root`
- [x] **Step 3:** Wire invoke + proto codegen
- [x] **Step 4:** Tests with seeded rows (`owner_iid` irrelevant; use test billing + vendor fixtures)
- [x] **Step 5:** `cd servers && cargo test -p c35_mod_admin && cargo build -p server_ai`

---

## Track L — Root console P&L page (optional)

**Files:**
- Create: `clients/app/lib/pages/page_root_pnl.dart`
- Create: `clients/app/lib/c/admin/admin_pnl_api.dart`
- Modify: `clients/app/lib/pages/page_root_console.dart` (P&L button)
- Modify: `clients/app/lib/c/pb/` (regenerate)

- [x] **Step 1:** Date range picker (default: current month MTD)
- [x] **Step 2:** Call `admin_platform_pnl` invoke
- [x] **Step 3:** Render metrics cards + vendor breakdown table
- [x] **Step 4:** `cd clients/app && flutter analyze`

---

## Track M — Docs

**Files:**
- Create: `_/docs/platform.md` (canonical: tables, fetch schedule, P&L formula, categories)
- Modify: `_/docs/fetcher.md` (vendor task registry)
- Modify: `_/docs/README.md` (index)
- Modify: `_/docs/billing-pricing.md` (cross-link wholesale dedupe)

- [x] **Step 1:** Write `platform.md` — locked decisions mirror this plan
- [x] **Step 2:** Update fetcher.md task table
- [x] **Step 3:** Archive or check off this plan when done

---

## Acceptance checklist

- [ ] `ai.platform_vendor_cost` populated for OCI + at least one other vendor
- [ ] Daily MTD fetch runs without duplicate rows (`uq_platform_vendor_cost_ref`)
- [ ] Month-close re-pull on days 1/3/7/14 updates previous month
- [x] `billing_usage_dedupe.cost_wholesale_usd` written on new turns
- [x] `admin_platform_pnl` returns revenue, ai_cogs, infra_cogs, gross_profit for date range
- [x] AI API vendor lines tagged `ai_api`; not summed into infra_cogs
- [ ] CSV import works for CF month-close invoice
- [ ] `cargo build -p server_fetcher` + `cargo build -p server_ai` pass
- [ ] No secrets in git

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Vendor API lag (24–48h) | `period_end = yesterday`; `status=estimated` |
| OCI/GCP auth complexity | Start OCI (existing creds); GCP via BigQuery SA |
| CF no granular billing API | CSV import Track J for finalized month |
| Double-count AI costs | `category=ai_api` excluded from infra; drift metric in P&L |
| FX on IDR vendor bills | `amount_to_usd` via `billing_fx_rate` at fetch time |
| Fetcher down | Stale costs OK for ops; manual CSV import |
| 50Gi OCI PVC minimum | Tag `sku` so storage line visible in breakdown |

---

## Suggested dispatch order (subagents)

**Wave 1** — spawn 2 agents in parallel:
1. Track A (schema)
2. Track B (`mod_platform` core)

**Wave 2** — after A+B:
3. Track C (scheduler)
4. Track D (wholesale dedupe)

**Wave 3** — after C:
5. Track E (OCI) — **start here** (biggest cost, creds exist)
6. Track F (GCP)
7. Track G (CF)
8. Track H (Wasabi)

**Wave 4** — after E–H:
9. Track I (fetcher deploy)
10. Track J (CSV import)

**Wave 5** — after I+J+D:
11. Track K (admin P&L API)

**Wave 6** — optional:
12. Track L (Flutter)
13. Track M (docs)

---

## Doc status

- [x] `_/docs/platform.md` — Track M
- [x] `_/docs/fetcher.md` — vendor task rows
- [x] This plan — `2026-09-24-platform-vendor-billing-multitask.md`
