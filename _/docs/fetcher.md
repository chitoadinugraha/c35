# Fetcher service (LOCKED)

Status: **locked** 2026-09-23

Cluster singleton that periodically fetches external data, persists to YB, and publishes updates on NATS so `c35-server` pods keep hot in-memory caches without duplicate API calls.

Implementation plan: [`plans/2026-09-23-c35-fetcher-multitask.md`](plans/2026-09-23-c35-fetcher-multitask.md).

---

## Naming

| Layer | Name |
|-------|------|
| Workspace path | `servers/fetcher/` |
| Cargo package | `server_fetcher` |
| Binary | `c35_fetcher` |
| Framework crate | `servers/crates/mod_fetch` (`c35_mod_fetch`) |
| K8s Deployment | `c35-fetcher` (`replicas: 1`) |
| Docker image | `hsg.ocir.io/.../c35-fetcher:latest` |

Same pattern as `server_ai` → `c35-server` and `node_stats` → `c35-node-stats` (`servers/node_stats/`).

---

## Why a separate binary

| Today | Problem |
|-------|---------|
| `llm_catalog_spawn` in every `server_ai` pod | Duplicate Gemini API attempts; Postgres advisory lock to elect one winner |
| `MIDTRANS_USD_IDR` env var | Static; not tied to metered deduct; Midtrans is not an FX source |
| No shared fetch framework | Each new periodic job reinvents interval + retry + NATS |

**Fetcher** centralizes periodic external fetches. `server_ai` subscribes and reloads in-memory state; deduct hot path never hits YB for FX.

---

## Architecture

```
c35-fetcher (replicas: 1)
  mod_fetch runner
    ├─ fx_rate task       (mod_billing)   every 1h
    └─ llm_catalog task   (mod_llm)       every 30m

  each task on change:
    1. persist to YB (audit + cold start)
    2. NATS publish c35.fetch.{task}

c35-server (replicas: 2+)
  subscribe c35.fetch.>
    ├─ fx        → AtomicI64 micro_per_usd in mod_billing
    └─ llm_catalog → llm_catalog_reload(pool)
  on boot: load latest from YB if NATS not received yet
```

**Not in `c35-node-stats`.** Node stats is per-node host metrics (DaemonSet). Fetcher is a singleton external-data sync service.

---

## `mod_fetch` framework

Reusable for any future periodic fetch (app release metadata, BI sanity check, etc.).

```rust
pub struct FetchCtx {
    pool: PgPool,
    nats: Client,
    http: reqwest::Client,
}

pub trait FetchTask: Send + Sync + 'static {
    fn name(&self) -> &'static str;
    fn interval(&self) -> Duration;
    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome>;
}

pub struct FetchOutcome {
    pub changed: bool,
    pub nats_subject: Option<&'static str>,
    pub nats_payload: Option<Vec<u8>>,
}
```

Runner responsibilities (shared):

- per-task `tokio::time::interval` (staggered start)
- structured logging: `task`, `duration_ms`, `changed`
- publish NATS only when `changed == true`
- error backoff (do not hammer provider on failure)
- optional: skip publish when rate delta &lt; threshold (FX task)

Domain logic stays in `mod_billing` / `mod_llm` — they own API contracts and DB schema.

---

## Task registry (initial)

| Task | Interval | Source | Persist | NATS subject |
|------|----------|--------|---------|--------------|
| `fx_rate` | 1h (`:05` past hour) | [Open Exchange Rates](https://openexchangerates.org/) `latest.json?symbols=IDR` | `ai.billing_fx_rate` | `c35.fetch.fx` |
| `llm_catalog` | 30m | Google Gemini models API (existing `gemini_fetch`) | `ai.llm_model` upsert/prune | `c35.fetch.llm_catalog` |
| `context_idle` | 5m | `mod_chat` idle context sweep | `ai.chat_context` prune | — |
| `vendor_bill_oci` | 24h (stagger +0m) | OCI Usage API | `ai.platform_vendor_cost` | — |
| `vendor_bill_gcp` | 24h (stagger +15m) | GCP BigQuery billing export | `ai.platform_vendor_cost` | — |
| `vendor_bill_cf` | 24h (stagger +30m) | Cloudflare GraphQL (+ CSV import for close) | `ai.platform_vendor_cost` | — |
| `vendor_bill_wasabi` | 24h (stagger +45m) | Wasabi account billing API | `ai.platform_vendor_cost` | — |

Vendor bill tasks register only when `*_VENDOR_BILL_ENABLED=1` and required credentials are present (`mod_platform` factories in `fetcher/src/main.rs`). MTD daily + month-close finalize on days `1,3,7,14` — no NATS push (cold admin data). Canonical spec: [`platform.md`](platform.md). See `servers/fetcher/.env.example`.

Future tasks register in `servers/fetcher/src/main.rs` only — no changes to `server_ai` boot per task.

---

## FX rate task (`fx_rate`)

### Source

- **Primary:** Open Exchange Rates free tier — hourly refresh (~720 requests/month at 1 fetch/hour).
- **Not Midtrans** — payment gateway only; no FX API.
- **Optional later:** Bank Indonesia JISDOR weekly sanity check (alert if drift &gt; 2%).

### Markup

```
published_idr = raw_idr × (1 + FX_MARKUP_BPS / 10_000)
micro_per_usd = round(published_idr × 1_000_000)
```

Default `FX_MARKUP_BPS = 1000` (10%). Configurable via env; document in admin UI.

### Change threshold

Skip DB insert + NATS publish when `|new - last| / last < 0.0025` (0.25%).

### Deduct formula (unchanged)

```
deduct_native = cost_usd × (micro_per_usd / 1_000_000)
```

Store `fx_rate_id` on `billing_usage_dedupe` for audit.

### Top-up

Top-up amount pairing (USD ↔ IDR on the request record) uses the same published in-memory rate — remove `MIDTRANS_USD_IDR` from deduct path. Midtrans settlement still credits **IDR wallet only**; manual approval credits IDR or USD per `amount_idr > 0`.

---

## LLM catalog task (`llm_catalog`)

Moves execution from `llm_catalog_spawn()` in `server_ai` boot to fetcher.

- Reuse `llm_catalog_sync(pool)` in `mod_llm::catalog_sync`
- Drop Postgres advisory lock election (singleton fetcher replaces it)
- On NATS `c35.fetch.llm_catalog`: `server_ai` calls `llm_catalog_reload(pool)`
- `server_ai` boot: one-shot `llm_catalog_init` (seed + reload from DB); no background spawn when `EXTERNAL_FETCHER=1` (default in cluster)

---

## NATS subjects

```
c35.fetch.fx              # FetchFxPush (protobuf)
c35.fetch.llm_catalog     # FetchLlmCatalogPush (protobuf, sync_ts only)
```

Payload definitions: `_/schemas/proto/c35/fetch.proto`.

Optional later: JetStream on `c35.fetch.>` with `max_msgs_per_subject: 1` so late-joining pods get last rate without DB read.

---

## Environment

| Var | Used by | Default |
|-----|---------|---------|
| `OPENEXCHANGERATES_APP_ID` | fetcher | default `bbfbc56fd1ab494dbbc4531e325e6b8b` (hardcoded fallback in `fetch_fx.rs`) |
| `FX_MARKUP_BPS` | fetcher | `1000` |
| `FX_CHANGE_THRESHOLD_BPS` | fetcher | `25` |
| `GEMINI_API_KEY` | fetcher | required for catalog task |
| `LLM_CATALOG_SYNC` | fetcher | `1` (disable with `0`) |
| `VENDOR_BILL_FETCH_INTERVAL_SECS` | fetcher | `86400` |
| `VENDOR_BILL_MTD_ENABLED` | fetcher | `1` |
| `VENDOR_BILL_FINALIZE_DAYS` | fetcher | `1,3,7,14` |
| `VENDOR_BILL_STAGGER_MINS` | fetcher | `0,15,30,45` (oci,gcp,cf,wasabi) |
| `VENDOR_BILL_TZ` | fetcher | `Asia/Jakarta` |
| `OCI_VENDOR_BILL_ENABLED` + `OCI_*` | fetcher | OCI Usage API credentials — see `.env.example` |
| `GCP_VENDOR_BILL_ENABLED` + `GCP_BILLING_*`, `GOOGLE_APPLICATION_CREDENTIALS_JSON` | fetcher | BigQuery billing export |
| `CF_VENDOR_BILL_ENABLED` + `CLOUDFLARE_*` | fetcher | CF GraphQL estimated usage |
| `WASABI_VENDOR_BILL_ENABLED` + `WASABI_*` | fetcher | Wasabi billing API |
| `EXTERNAL_FETCHER` | server_ai | `1` in cluster — skip `llm_catalog_spawn` |
| `NATS_URL`, `NATS_USER`, `NATS_PASS` | both | same as `c35-server` |
| `YB_*` | fetcher | same as `c35-server` |

---

## Deploy

```
_/deployments/c35-fetcher/
  deployment.yaml    # replicas: 1, same secrets as c35-server
  Dockerfile         # linux/arm64, cargo build -p server_fetcher
```

Secrets: reuse `c35-server-env` or dedicated `c35-fetcher-env` with YB + NATS + API keys.

---

## Dependency direction

```
server_fetcher → mod_fetch → (mod_billing, mod_llm, mod_platform) → store, proto
server_ai      → mod_billing, mod_llm (NATS subscribers only; no fetch)
```

`mod_fetch` must not depend on `wire_ws` or `server_ai`.
