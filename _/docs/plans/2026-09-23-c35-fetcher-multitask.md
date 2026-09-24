# c35-fetcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `c35-fetcher` — a cluster singleton that periodically fetches external data (FX rates, LLM catalog), persists to YB, and publishes NATS updates so `c35-server` pods keep hot in-memory caches without duplicate API calls.

**Architecture:** `servers/fetcher/` thin binary + `mod_fetch` framework crate. Domain tasks live in `mod_billing` (FX) and `mod_llm` (catalog). `server_ai` drops `llm_catalog_spawn`, subscribes to `c35.fetch.>`, loads DB fallback on boot.

**Tech Stack:** Rust / tokio / async-nats / sqlx / prost / Open Exchange Rates API / existing Gemini catalog fetch.

**Spec:** [`_/docs/fetcher.md`](../../_/docs/fetcher.md) (locked 2026-09-23). Docs updated in this PR.

## Global Constraints

- Server workspace under `servers/`; build from `servers/` → `.cache/server` (see `.cursor/rules/rust-cache.mdc`).
- Verify Rust: `cd servers && cargo build -p server_ai` and `cargo build -p server_fetcher`; `cargo test -p c35_mod_fetch` / affected crates.
- `mod_*` must not depend on `wire_ws`, `server_ai`, or `server_fetcher`.
- NATS subjects: `c35.fetch.fx`, `c35.fetch.llm_catalog` (see `_/docs/sync.md`).
- FX markup default: `FX_MARKUP_BPS=1000` (10%). Change threshold: 25 bps (0.25%).
- K8s: `c35-fetcher` Deployment `replicas: 1`, `linux/arm64` image to `hsg.ocir.io`.
- Naming: package `server_fetcher`, binary `c35_fetcher`, framework `c35_mod_fetch`.

---

## Multitask map (5 waves)

| Wave | Track | Name | Depends on | Delivers |
|------|-------|------|------------|----------|
| **1** | **A** | Proto + `mod_fetch` framework | — | `fetch.proto`, `FetchTask` runner, unit tests |
| **1** | **B** | `server_fetcher` binary skeleton | A | boots, connects YB+NATS, runs empty task list |
| **2** | **C** | FX fetch task (`mod_billing`) | A | OER client, `billing_fx_rate` insert, `FetchFxPush` |
| **2** | **D** | LLM catalog task (`mod_llm`) | A | `LlmCatalogFetchTask`, export `llm_catalog_sync` |
| **3** | **E** | Wire tasks into fetcher binary | B, C, D | both tasks registered, local run works |
| **3** | **F** | `server_ai` NATS subscribers | A, C, D | in-memory FX, catalog reload, drop spawn |
| **4** | **G** | Billing deduct uses live FX | F | `fx_rate_id` on dedupe, top-up uses published rate |
| **5** | **H** | K8s deploy + publish script | E | `c35-fetcher` Deployment, Dockerfile, env |

Wave 1 tracks **A + B** parallel. Wave 2 tracks **C + D** parallel. Wave 3 **E + F** parallel. Wave 4 **G** after F. Wave 5 **H** after E.

---

## Track A — Proto + `mod_fetch` framework

**Files:**
- Create: `_/schemas/proto/c35/fetch.proto`
- Modify: `_/schemas/proto/c35/billing.proto` (if codegen needs include — prefer standalone `fetch.proto`)
- Create: `servers/crates/mod_fetch/Cargo.toml`
- Create: `servers/crates/mod_fetch/src/lib.rs`
- Create: `servers/crates/mod_fetch/src/runner.rs`
- Create: `servers/crates/mod_fetch/src/ctx.rs`
- Create: `servers/crates/mod_fetch/tests/runner_test.rs`
- Modify: `servers/crates/proto/build.rs` (add fetch.proto)
- Modify: `servers/Cargo.toml` (add `crates/mod_fetch`)

**Interfaces — produces:**
```rust
// servers/crates/mod_fetch/src/lib.rs
pub struct FetchCtx { pub pool: PgPool, pub nats: Client, pub http: reqwest::Client }
pub struct FetchOutcome { pub changed: bool, pub nats_subject: Option<&'static str>, pub nats_payload: Option<Vec<u8>> }
pub trait FetchTask: Send + Sync + 'static {
    fn name(&self) -> &'static str;
    fn interval(&self) -> Duration;
    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome>;
}
pub fn fetcher_run(ctx: FetchCtx, tasks: Vec<Box<dyn FetchTask>>) -> !;
```

**Proto (`fetch.proto`):**
```protobuf
syntax = "proto3";
package c35;

message FetchFxPush {
  int64 fx_rate_id = 1;
  int64 micro_per_usd = 2;
  double raw_idr_per_usd = 3;
  double published_idr_per_usd = 4;
  int64 effective_ts_ms = 5;
}

message FetchLlmCatalogPush {
  int64 sync_ts_ms = 1;
  int32 model_count = 2;
}
```

- [ ] **Step 1:** Add `fetch.proto`, regenerate prost in `crates/proto`
- [ ] **Step 2:** Create `mod_fetch` with `FetchCtx`, `FetchOutcome`, `FetchTask` trait
- [ ] **Step 3:** Implement `fetcher_run` — spawn per-task interval loop, log `task`/`changed`/`duration_ms`, publish NATS when `changed && payload.is_some()`
- [ ] **Step 4:** Unit test: mock task returns `changed: true` once, then false; verify publish called once (inject mock nats or test outcome logic without network)
- [ ] **Step 5:** `cd servers && cargo test -p c35_mod_fetch && cargo build -p c35_mod_fetch`

---

## Track B — `server_fetcher` binary skeleton

**Files:**
- Create: `servers/fetcher/Cargo.toml`
- Create: `servers/fetcher/src/main.rs`
- Create: `servers/fetcher/.env.example`
- Modify: `servers/Cargo.toml` (add `"fetcher"` member)

**Interfaces — consumes:** `fetcher_run`, `FetchCtx` from Track A.

- [ ] **Step 1:** `fetcher/Cargo.toml` — package `server_fetcher`, bin `c35_fetcher`, deps: `mod_fetch`, `c35_store`, `c35_nats`, `c35_trace`, `tokio`, `dotenvy`
- [ ] **Step 2:** `main.rs` — load env, connect pool + NATS (copy pattern from `node_stats/c_node_stats/src/main.rs` + `server_ai/src/boot.rs`), build `FetchCtx`, call `fetcher_run(ctx, vec![])` 
- [ ] **Step 3:** `.env.example` — `YB_*`, `NATS_*`, `OPENEXCHANGERATES_APP_ID`, `FX_MARKUP_BPS=1000`, `GEMINI_API_KEY`, `RUST_LOG=info`
- [ ] **Step 4:** `cd servers && cargo build -p server_fetcher`

---

## Track C — FX fetch task (`mod_billing`)

**Files:**
- Create: `servers/crates/mod_billing/src/fetch_fx.rs`
- Create: `servers/crates/mod_billing/tests/fetch_fx_test.rs`
- Modify: `servers/crates/mod_billing/src/lib.rs` (export `FxRateFetchTask`)
- Modify: `servers/server_ai/.env.example` (document `OPENEXCHANGERATES_APP_ID`; note `MIDTRANS_USD_IDR` demoted to legacy fallback only until Track G removes it)

**Interfaces — produces:**
```rust
pub struct FxRateFetchTask { /* holds markup_bps, threshold_bps, app_id */ }
impl FetchTask for FxRateFetchTask { /* name = "fx_rate", interval = 1h */ }
// fetch_fx_run(pool, http, app_id) -> (raw_idr, published_micro, fx_rate_id)
pub fn fx_markup_apply(raw_idr: f64, markup_bps: i64) -> f64;
pub fn fx_micro_from_idr(idr: f64) -> i64;
```

**Logic:**
1. `GET https://openexchangerates.org/api/latest.json?app_id=...&symbols=IDR`
2. `raw = rates.IDR`
3. `published = raw * (1 + markup_bps/10000)`
4. Load last `billing_fx_rate` for IDR; if `|published-last|/last < threshold` → `FetchOutcome { changed: false }`
5. `INSERT ai.billing_fx_rate` → `fx_rate_id`
6. `FetchOutcome { changed: true, nats_subject: "c35.fetch.fx", nats_payload: FetchFxPush.encode() }`

- [ ] **Step 1:** Pure functions test: `fx_markup_apply(17630, 1000) ≈ 19393`, `fx_micro_from_idr` rounds correctly
- [ ] **Step 2:** Implement OER HTTP fetch with `reqwest`, parse JSON, handle missing key / HTTP errors (return Err, runner logs warn)
- [ ] **Step 3:** DB insert + threshold skip logic
- [ ] **Step 4:** `FxRateFetchTask` impl `FetchTask`
- [ ] **Step 5:** `cd servers && cargo test -p c35_mod_billing fetch_fx`

---

## Track D — LLM catalog task (`mod_llm`)

**Files:**
- Create: `servers/crates/mod_llm/src/fetch_catalog.rs`
- Modify: `servers/crates/mod_llm/src/catalog_sync.rs` (remove `llm_catalog_spawn` body into reusable export; keep `llm_catalog_sync`)
- Modify: `servers/crates/mod_llm/src/lib.rs`
- Modify: `servers/server_ai/src/boot.rs` (gate spawn behind `EXTERNAL_FETCHER`)

**Interfaces — produces:**
```rust
pub struct LlmCatalogFetchTask;
impl FetchTask for LlmCatalogFetchTask {
  // name = "llm_catalog", interval = SYNC_INTERVAL_SECS (30m)
  // run: llm_catalog_sync(pool) -> FetchLlmCatalogPush on success
}
```

**Changes to `catalog_sync.rs`:**
- Keep `llm_catalog_sync(pool)` public (already is via call from spawn)
- `llm_catalog_spawn`: only run when `std::env::var("EXTERNAL_FETCHER")` is not `1`/`true`
- Remove advisory lock **only after** fetcher is deployed — or keep lock as belt-and-suspenders during transition

- [ ] **Step 1:** `LlmCatalogFetchTask` wrapping `llm_catalog_sync`
- [ ] **Step 2:** On success, `FetchOutcome { changed: true, subject: "c35.fetch.llm_catalog", payload: FetchLlmCatalogPush { sync_ts_ms, model_count } }`
- [ ] **Step 3:** Gate `llm_catalog_spawn` with `EXTERNAL_FETCHER` env (default unset = legacy behavior for local dev)
- [ ] **Step 4:** `cd servers && cargo build -p c35_mod_llm`

---

## Track E — Wire tasks into fetcher binary

**Files:**
- Modify: `servers/fetcher/src/main.rs`
- Modify: `servers/fetcher/Cargo.toml` (add `c35_mod_billing`, `c35_mod_llm`)

- [ ] **Step 1:** Register `FxRateFetchTask::from_env()` + `LlmCatalogFetchTask` in task vec
- [ ] **Step 2:** Run one immediate tick per task on boot (before interval wait) so first fetch happens at start
- [ ] **Step 3:** `cd servers && cargo build -p server_fetcher`
- [ ] **Step 4:** Manual smoke: run fetcher locally with `.env.local`; confirm `billing_fx_rate` row + `llm_model` updated

---

## Track F — `server_ai` NATS subscribers

**Files:**
- Create: `servers/crates/mod_billing/src/fx_live.rs`
- Create: `servers/crates/mod_fetch/src/subscribe.rs` (optional shared subscribe helper)
- Modify: `servers/crates/mod_billing/src/lib.rs`
- Modify: `servers/crates/mod_llm/src/llm_catalog.rs` (add `llm_catalog_on_fetch_push(pool)`)
- Modify: `servers/server_ai/src/boot.rs` (subscribe `c35.fetch.>`, boot DB load)
- Modify: `servers/crates/mod_billing/src/billing_on_demand.rs` consumers (read live rate)

**Interfaces — produces:**
```rust
// mod_billing/fx_live.rs
pub fn fx_live_init(pool: &PgPool) -> Result<()>;  // load latest billing_fx_rate
pub fn fx_live_micro_per_usd() -> i64;
pub fn fx_live_subscribe(pool: PgPool, nats: Client);  // spawn task
```

**Subscribe handler:**
- `c35.fetch.fx` → decode `FetchFxPush`, set atomic micro, log
- `c35.fetch.llm_catalog` → `llm_catalog_reload(&pool)`

- [ ] **Step 1:** `fx_live.rs` with `AtomicI64` + `fx_live_init` from DB
- [ ] **Step 2:** NATS subscribe loop in `fx_live_subscribe` + catalog reload handler (can live in `boot.rs` or `mod_fetch::subscribe`)
- [ ] **Step 3:** Call `fx_live_init` + `fx_live_subscribe` + catalog handler from `server_ai` boot after NATS connect
- [ ] **Step 4:** Set `EXTERNAL_FETCHER=1` in `c35-server` deployment manifest
- [ ] **Step 5:** `cd servers && cargo build -p server_ai`

---

## Track G — Billing deduct + top-up use live FX

**Files:**
- Modify: `servers/crates/mod_billing/src/billing_turn.rs`
- Modify: `servers/crates/mod_billing/src/billing_reservation.rs`
- Modify: `servers/crates/mod_billing/src/billing_pool.rs` (if still reads per-account `fx_micro_per_usd`)
- Modify: `servers/crates/mod_billing/src/billing_midtrans.rs` (`resolve_topup_amounts` takes live rate, not `rt.midtrans_usd_idr`)
- Modify: `servers/crates/mod_billing/src/billing_topup.rs`
- Modify: `servers/crates/mod_voice/src/billing.rs` (if uses fx_micro_per_usd)

**Logic:**
- Replace per-account `fx_micro_per_usd` reads with `fx_live_micro_per_usd()` for metered deduct
- `resolve_topup_amounts(amount_usd, amount_idr, fx_live_rate_as_f64())`
- Store `fx_rate_id` from live state on `billing_usage_dedupe` inserts
- Keep `billing_account.fx_micro_per_usd` column for now (write-only on signup = snapshot); deprecate reads

- [ ] **Step 1:** Centralize `fx_rate_id` + `micro` accessor in `fx_live.rs`
- [ ] **Step 2:** Update deduct paths (`billing_turn`, `billing_reservation`, `billing_pool`)
- [ ] **Step 3:** Update top-up `resolve_topup_amounts` call sites
- [ ] **Step 4:** `cd servers && cargo test -p c35_mod_billing && cargo test -p c35_mod_voice`
- [ ] **Step 5:** `cd servers && cargo build -p server_ai`

---

## Track H — K8s deploy + publish

**Files:**
- Create: `_/deployments/c35-fetcher/deployment.yaml`
- Create: `_/deployments/c35-fetcher/Dockerfile` (or `_/deployments/Dockerfile.c35-fetcher`)
- Create: `_/deployments/c35-fetcher/README.md`
- Create: `_/scripts/deploy/publish_fetcher.ps1` (mirror `publish_node_stats.ps1`)
- Modify: `_/deployments/c35-server/deployment.yaml` (`EXTERNAL_FETCHER=1`)
- Modify: `servers/server_ai/.env.example`

- [ ] **Step 1:** Dockerfile — `cargo build --release -p server_fetcher`, `linux/arm64`
- [ ] **Step 2:** Deployment — `replicas: 1`, env from `c35-server-env` + `OPENEXCHANGERATES_APP_ID`, `FX_MARKUP_BPS`
- [ ] **Step 3:** `publish_fetcher.ps1` — build, push `hsg.ocir.io/.../c35-fetcher:latest`, `kubectl apply`
- [ ] **Step 4:** Deploy to cluster; verify logs show `fx_rate` + `llm_catalog` tasks; confirm `c35-server` logs show NATS subscribe + rate update
- [ ] **Step 5:** Update `_/deployments/c35-fetcher/README.md` with verify commands

**Verify (cluster):**
```powershell
kubectl logs -n c35 deploy/c35-fetcher --tail=50
# expect: fx_rate changed=true, llm_catalog synced

kubectl exec -n c35 deploy/c35-server -- ... 
# or query YB: SELECT * FROM ai.billing_fx_rate ORDER BY effective_from DESC LIMIT 3;
```

---

## Acceptance checklist

- [ ] `c35_fetcher` binary builds in `servers/` workspace
- [ ] FX task fetches OER hourly, applies 10% markup, skips noise &lt; 0.25%
- [ ] LLM catalog sync runs from fetcher, not `server_ai` background loop (when `EXTERNAL_FETCHER=1`)
- [ ] `c35-server` holds in-memory FX; deduct does not read `MIDTRANS_USD_IDR`
- [ ] NATS `c35.fetch.fx` + `c35.fetch.llm_catalog` documented in `sync.md`
- [ ] `c35-fetcher` Deployment `replicas: 1` on cluster
- [ ] Top-up credits IDR→IDR / USD→USD unchanged; only pairing rate is live

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Fetcher down | Servers keep last in-memory rate; boot loads DB; OER outage = no new row |
| OER free tier quota | 1 fetch/hour ≈ 720/mo; stay under 1000 |
| 10% markup user surprise | Document in billing UI; `FX_MARKUP_BPS` tunable |
| Transition period (both spawn + fetcher) | `EXTERNAL_FETCHER` gate; advisory lock kept until fetcher proven |
| Bad API tick | Threshold skip + optional daily cap (add in Track C if time permits) |

---

## Doc status

- [x] `_/docs/fetcher.md` — canonical spec
- [x] `_/docs/server.md`, `sync.md`, `billing.md`, `structure.md`, `architecture.md`, `billing-implementation.md`, `README.md` — updated 2026-09-23
