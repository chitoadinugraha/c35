# Captcha vendor rates (fetcher) + metered-tool billing reservation — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review **Locked decisions** and **Prerequisites** before dispatch. **Track F (fetcher)** and **Track R0 (spec)** can start in parallel. **Track R1–R3** should land with or after **per-solve captcha billing** in `server_ai` (see Prerequisites). Publish **fetcher** and **server** when both tracks are green (`publish_fetcher.ps1` + `publish_server.ps1`).

**Goal:** (1) Stop hand-editing 2Captcha wholesale prices in Rust — **fetcher** periodically refreshes captcha SKU wholesale into YB, **server_ai** reads live rates for `captcha.solve` billing. (2) **Formalize metered-tool reservation** (hold → settle on a **child** `req_id`) so captcha, voice, and future prepaid tools share one path and do not fight the prompt-turn hold / `billing_usage_dedupe` idempotency.

**Architecture:** New fetcher task `captcha_vendor_rates` in `c35_mod_captcha` (or `mod_billing` if you prefer all SKUs in one crate — default **mod_captcha**). Persist JSON to `ai.config` key `captcha.2captcha_wholesale` (+ optional history table later). NATS `c35.fetch.captcha_rates` triggers in-memory reload on all `server_ai` pods. Billing: shared `billing_metered_tool_*` helpers in `mod_billing` (extracted from `mod_voice` + `mod_chat::captcha_billing`); prompt turns keep **parent** hold for LLM; **child** holds for async metered tools.

**Tech stack:** Rust (`server_fetcher`, `c35_mod_captcha`, `c35_mod_billing`, `c35_mod_chat`, `c35_mod_fetch`), YSQL (`ai.config`), protobuf (`fetch.proto`), NATS, specs [`fetcher.md`](../fetcher.md), [`captcha-solver.md`](../captcha-solver.md), [`billing.md`](../billing.md).

**Related:** [`2026-10-11-captcha-egress-ship-multitask.md`](2026-10-11-captcha-egress-ship-multitask.md), [`2026-09-23-c35-fetcher-multitask.md`](2026-09-23-c35-fetcher-multitask.md).

---

## Global constraints

- **No provider web grounding** on LLM bodies (`web-grounding-cluster-only.mdc`).
- **UTF-8** sources; `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix` after edits.
- **Fetcher / server:** `cd servers && cargo build -p server_fetcher && cargo build -p server_ai`.
- **Tests:** `cargo test -p c35_mod_captcha`, `cargo test -p c35_mod_billing`, `cargo test -p c35_mod_fetch`; add tests for new reservation helpers.
- **Cluster:** `publish_fetcher.ps1` + `publish_server.ps1` — no local arm64 Docker (`cluster-buildkit.mdc`). End ship with **Publish summary** from `.cache/publish-perf/latest.json`.
- **Do not commit** unless user asks.

---

## Prerequisites (repo state)

| Piece | Status / note |
|--------|----------------|
| `captcha.solve` + 2Captcha + egress | Shipped (see captcha egress plan) |
| Static wholesale in `mod_captcha::billing` | **Today** — compile-time constants |
| Per-solve captcha billing (child `req_id`, `billing_settled`) | **In progress / local** — `mod_chat::captcha_billing`; must be on cluster before R2 is meaningful |
| Fetcher task registry | `servers/fetcher/src/main.rs` — add task here only |
| `billing.md` deduct table | Lists parent-turn extras; **missing** child-req metered tools — fix in **R0** |

---

## Locked product decisions

| Topic | Decision |
|--------|----------|
| Vendor source | **2Captcha** list prices only; no user-facing vendor name |
| Retail | `billing_to_retail_usd(wholesale)` → **× 1.50** (`RETAIL_MARKUP`) |
| Price storage (v1) | `ai.config` key `captcha.2captcha_wholesale` — JSON map `recaptcha_v2`, `recaptcha_v3`, `hcaptcha`, `image` → `wholesale_usd` + `source_url` + `fetched_ts_ms` |
| Fetcher interval | **24h** default (`CAPTCHA_RATES_SYNC_INTERVAL_SECS`); run once on fetcher boot if key missing or older than 7d |
| 2Captcha API | **No official pricing JSON** — v1: HTTP GET `https://2captcha.com/pricing` + HTML parse with **fixture tests**; on parse failure keep last DB/config values and log `captcha_rates_parse_failed` |
| Fallback | Compiled constants in `mod_captcha::billing` remain **last resort** if DB/config empty |
| Reservation model | **Child `req_id`** per metered invocation (`captcha_{tool_call_id}`, `voice_stt_{req_id}`, …); parent turn `req_id` unchanged for `billing_usage_report` |
| Double charge | Tool JSON `billing_settled: true` → dispatcher **must not** add retail to `tools_cost_usd` again |
| Freemium | `captcha.solve` blocked on free tier (same class as `img.generate`) |
| Future | Optional `ai.captcha_vendor_rate` history + admin diff alert if wholesale jumps &gt; 10% — **out of v1** |

---

## Parallel track map

```text
Track R0 (spec)              Track F (fetcher rates)
────────────────             ───────────────────────
R0 billing + captcha docs    F0 Proto + config schema
                             F1 Fetch + parse task
                             F2 server_ai reload (NATS + boot)
        \                   /
         v                 v
Track R (reservation)     Track P (publish + smoke)
─────────────────────     ─────────────────────────
R1 billing_metered_*      P1 publish_fetcher + server
R2 Migrate voice/captcha  P2 Prod: config row + one solve
R3 Tests + rate_card      P3 MCP billing log spot-check
R4 (optional) img hold
```

**Suggested dispatch:** **R0 + F0** parallel → **F1–F2** + **R1** parallel → **R2** → **P**.

---

# Track R0 — Spec alignment

- [ ] **R0.1** Update [`captcha-solver.md`](../captcha-solver.md) **Billing**: per-solve child `req_id`, `ai.log` `kind=tool` topic `captcha.solve:{kind}`, fetcher-owned wholesale, retail × 1.50.
- [ ] **R0.2** Update [`billing.md`](../billing.md) **Deduct rules** table — add rows:

| Event | `req_id` | Hold gate | Deduct path |
|-------|----------|-----------|-------------|
| Cloud STT/TTS | `voice_stt_*` / `voice_tts_*` | `voice_billing_gate` | `voice_billing_settle` → `billing_usage_dedupe` + wallet |
| Captcha solve | `captcha_{tool_call_id}` | `captcha_billing_gate` | `captcha_billing_settle` → dedupe + wallet; parent turn excludes via `billing_settled` |
| User prompt turn | parent `req_id` | `billing_gate_with_hold` | `billing_usage_report` (LLM + turn extras only) |

- [ ] **R0.3** Update [`fetcher.md`](../fetcher.md) task registry row for `captcha_vendor_rates`.
- [ ] **R0.4** Note in [`billing-pricing.md`](../billing-pricing.md) captcha SKUs point at live config (not hardcoded list).

**Review gate:** Specs consistent; no contradiction with `billing_usage_dedupe (owner_iid, req_id)` uniqueness.

---

# Track F — Fetcher: captcha vendor rates

### F0 — Contract

- [ ] **F0.1** Extend `_/schemas/proto/c35/fetch.proto`:

```protobuf
message FetchCaptchaRatesPush {
  int64 sync_ts_ms = 1;
  string config_key = 2;  // "captcha.2captcha_wholesale"
}
```

- [ ] **F0.2** Document JSON shape in `captcha-solver.md` (or `_/schemas/` comment block):

```json
{
  "vendor": "2captcha",
  "kinds": {
    "recaptcha_v2": { "wholesale_usd": 0.00299 },
    "recaptcha_v3": { "wholesale_usd": 0.00299 },
    "hcaptcha": { "wholesale_usd": 0.00299 },
    "image": { "wholesale_usd": 0.0005 }
  },
  "source_url": "https://2captcha.com/pricing",
  "fetched_ts_ms": 0
}
```

- [ ] **F0.3** `cargo build -p c35_proto` (workspace build from `servers/`).

### F1 — Fetch task (`c35_mod_captcha`)

**Files (create / modify):**

- `servers/crates/mod_captcha/src/rates_fetch.rs` — HTTP fetch, HTML parse, validate sane bounds (e.g. `1e-6 .. 1.0` USD)
- `servers/crates/mod_captcha/src/rates_store.rs` — read/write `ai.config`, compare to last, skip if unchanged
- `servers/crates/mod_captcha/src/rates_cache.rs` — `OnceLock` / `RwLock` in-memory map for hot path
- `servers/crates/mod_captcha/src/fetch_task.rs` — `impl FetchTask` for `mod_fetch`
- `servers/crates/mod_captcha/Cargo.toml` — add `c35_mod_fetch`, `sqlx`, `scraper` or `regex` (prefer minimal deps; **fixture HTML tests** required)

- [ ] **F1.1** `CaptchaRatesFetchTask::run`:
  - Fetch pricing page (timeout 30s, no API key in URL).
  - Parse per-kind USD per 1000 or per solve — normalize to **per-solve wholesale_usd**.
  - If delta vs stored &lt; 0.1% for all kinds → `FetchOutcome { changed: false }`.
  - Else UPSERT `ai.config` + NATS publish `captcha.fetch.captcha_rates` (or `c35.fetch.captcha_rates` — **match `fetch.proto` subject naming in `sync.md`**).

- [ ] **F1.2** Unit tests: `tests/fixtures/2captcha_pricing_sample.html` — assert parsed kinds match expected floats.

- [ ] **F1.3** Replace `captcha_wholesale_usd(CaptchaKind)` implementation: **DB/cache first**, then compile-time constants.

- [ ] **F1.4** Env: `CAPTCHA_RATES_SYNC=1` (default on in fetcher), `CAPTCHA_RATES_SYNC_INTERVAL_SECS=86400`, `CAPTCHA_RATES_SOURCE_URL` override for tests.

**Review gate:** `cargo test -p c35_mod_captcha`; local `c35_fetcher` run inserts/updates `ai.config` row.

### F2 — Wire fetcher + server_ai

- [ ] **F2.1** Register `CaptchaRatesFetchTask` in `servers/fetcher/src/main.rs` (after `llm_catalog`).

- [ ] **F2.2** `server_ai` boot: `captcha_rates_init(pool)` — load from `ai.config` if present.

- [ ] **F2.3** NATS subscriber (same pattern as `llm_catalog_reload`): on push → reload cache only (no full pod restart).

- [ ] **F2.4** `servers/fetcher/.env.example` — document new env vars.

- [ ] **F2.5** Admin / rate card: extend `mod_billing::rate_card` or status endpoint to include captcha SKUs from cache (read-only).

**Review gate:** `cargo build -p server_fetcher -p server_ai`; manual NATS publish reloads rates without restart.

---

# Track R — Billing reservation (metered tools)

### R1 — Shared metered billing API (`mod_billing`)

Extract duplicate logic from `mod_voice::billing` and `mod_chat::captcha_billing` into:

- `servers/crates/mod_billing/src/billing_metered.rs`

**Public API (target):**

```rust
pub struct MeteredToolBill {
    pub billing_req_id: String,
    pub topic: String,
    pub model: &'static str,
}

pub async fn billing_metered_gate(
    pool, owner_iid, billing_req_id, hold_retail_usd, afford_retail_usd,
) -> Result<BillingRow>;

pub async fn billing_metered_abort(pool, billing_req_id) -> Result<()>;

pub async fn billing_metered_settle(
    pool, nats, owner_iid, row, billing_req_id, wholesale_usd,
    log: MeteredLogFields,
) -> Result<f64>;
```

- [ ] **R1.1** Implement helpers (dedupe insert, `billing_deduct_personal_profile`, `billing_reservation_settle`, `billing_notify_owner`).

- [ ] **R1.2** `billing_metered_req_id(prefix, parent_req_id, tool_call_id)` — single naming rule.

- [ ] **R1.3** Unit tests: idempotent settle (second call no double deduct); abort releases hold.

- [ ] **R1.4** Document: **do not** use parent turn `req_id` for metered dedupe (conflicts with turn-end `billing_usage_report`).

**Review gate:** `cargo test -p c35_mod_billing` new tests green.

### R2 — Migrate call sites

- [ ] **R2.1** Refactor `mod_voice::billing` to call `billing_metered_*` (behavior unchanged).

- [ ] **R2.2** Refactor `mod_chat::captcha_billing` to call `billing_metered_*`.

- [ ] **R2.3** Ensure `ToolDispatcher` honors `billing_settled` for **all** metered tools (already for captcha; add test case).

- [ ] **R2.4** `billing_tool_cost_usd("captcha.solve")` — read max retail from cache for gate fallbacks / compose estimates (optional `prompt_compose` cost hint).

**Review gate:** `cargo test -p c35_mod_voice`, `cargo test -p c35_mod_chat`; voice + captcha smoke on 33000.

### R3 — Concurrency + wallet math tests

- [ ] **R3.1** Integration test (DB optional `C35_TEST_DB=1`): two parallel child holds same owner — `billing_held_totals` sums both; second gate fails when wallet insufficient.

- [ ] **R3.2** Test: parent turn held + child captcha hold — settle child does not refund parent hold.

- [ ] **R3.3** Test: failed captcha solve → child hold `refunded`, wallet unchanged.

**Review gate:** Tests documented in `billing.md` or `billing-implementation.md`.

### R4 — (Optional, phase 2) Image / video / music

- [ ] **R4.1** Spike: move `img.generate` from “afford check only” to child `billing_metered_gate` + settle on CAS success (larger hold = tier retail).

- [ ] **R4.2** Product decision: keep turn rollup vs immediate deduct — **default defer** until captcha + voice path stable.

---

# Track P — Publish + smoke

- [ ] **P1.1** `.\_\scripts\deploy\publish_fetcher.ps1` then `publish_server.ps1`.

- [ ] **P1.2** Verify `ai.config` row after fetcher boot:

```sql
SELECT key, value->'fetched_ts_ms', value->'kinds' FROM ai.config WHERE key = 'captcha.2captcha_wholesale';
```

- [ ] **P1.3** One `captcha.solve` on 99000 (active prompt run): `ai.log` row `kind=tool`, topic `captcha.solve:recaptcha_v2`, matching retail from config.

- [ ] **P1.4** `trace_get` / `log_tail`: parent turn `cost_usd` does **not** include captcha retail twice.

- [ ] **P1.5** Temporarily break HTML parse in staging — confirm last good rates still used (no zero charge).

---

## Subagent split (recommended)

| Subagent | Tracks | Deliverable |
|----------|--------|-------------|
| **Spec** | R0 | Docs only PR |
| **Fetcher** | F0–F2 | `captcha_vendor_rates` task + NATS + reload |
| **Billing** | R1–R3 | `billing_metered.rs` + refactors + tests |
| **Ship** | P | Publish + SQL/log verification |

---

## Risks

| Risk | Mitigation |
|------|------------|
| 2Captcha redesigns pricing HTML | Fixture tests fail in CI; keep constants fallback; alert on parse failure |
| Wholesale drop below retail markup floor | Clamp alert only; never charge below configured wholesale × 1.50 |
| Stale rates on long-running pods | NATS push + boot init; optional periodic reload tick in `server_ai` (15m) if NATS missed |
| Double billing regression | `billing_settled` + dedupe tests; parent/child `req_id` documented |
| Fetcher-only deploy without server | Server keeps constants until reload path exists — deploy **pair** for rate changes |

---

## Out of scope (follow-up plans)

- Per-tenant BYO 2Captcha key (`ai.identity.meta_json`)
- Historical `ai.captcha_vendor_rate` table + admin graph
- AI OCR captcha fallback pricing
- `billing_reservation` **increment** on parent `req_id` (prefer child-req pattern instead)
