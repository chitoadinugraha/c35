# Site transaction chat prompts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cover warung/POS questions in Home chat (aggregates, period compare, transaction browse, single-nota detail, top products, multi-site) with the right tools, UI blocks, and **no full row grids in the LLM** — plus an automated **compose + prompt_run** test per user phrase.

**Architecture:** Extend the query catalog (`tx.sales_summary` family) with `yesterday` / compare queries and a capped `tx.sales_list` for browse. Mirror **`inst.site.stock_report`**: server prefetch + `site.tx_list` block + compact `llm` payload when `inst.site.tx_browse` matches. Aggregate and compare intents stay on **`site.query.run`** with small row sets. Steer with **`ai.inst`** (`general` topic where catalog already works). Regression: **`servers/crates/mod_chat/tests/site_tx_chat_prompt_test.rs`** (compose) and MCP **`prompt_run`** rows in the matrix below (integration).

**Tech Stack:** Rust (`c35_mod_site`, `c35_mod_tx`, `c35_mod_chat`, `c35_mod_file`), YSQL `site.tx*`, Flutter chat blocks, `ai.inst` seeds, MCP `prompt_compose` / `prompt_run` (`owner_iid` **33000**).

**Spec:** [`_/specs/site-ai.md`](../site-ai.md), [`_/specs/tx.md`](../tx.md), [`_/specs/inst.md`](../inst.md). Reference plan: [`2026-10-08-site-stock-report-multitask.md`](2026-10-08-site-stock-report-multitask.md).

## Global Constraints

- Readonly browse/report paths never call `site.tx.put`.
- No provider web grounding; exclude `web.search` / `web.visit` on commerce report insts (existing pattern).
- Grant check stays inside `site_query_run` / `tx_list` / `tx_get` (owner or staff).
- Money: **BIGINT** minor units in SQL and JSON; format for humans in reply text or PDF/xlsx only.
- Chat table preview **40** rows; export cap **20_000**; `truncated: true` when capped.
- LLM tool payload for closed browse: **no `rows` array** — only `row_count`, `total_revenue`, `truncated`, `preview` (≤5), `files[]`.
- Aggregate queries may return ≤1 row per `site_iid` (already true for summaries).
- Spoken steering in **`ai.inst`** + phrase lists; mechanical date/format parse in Rust (same class as `stock_report_parse`).
- After `inst.sql` edits: **`inst_put` live** on cluster (git seed alone is not live).
- Do not commit unless the user asks.
- Verify: `cargo test -p c35_mod_site`, `cargo test -p c35_mod_chat -- site_tx`, `cargo build -p server_ai`, `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`, `.\_\scripts\dev\verify_flutter_app.ps1` when Flutter changes.
- Subagent model: **`inherit`** only (`subagent-model.mdc`).

---

## Multitask Map

```
Track 0 (ranges + compare queries) ──┬──► Track 2 (tx.sales_list SQL)
Track 1 (inst phrases + topics)  ───┤
Track 3 (tx_browse parse) ───────────┼──► Track 4 (render + prefetch + compact tool)
Track 5 (site.tx.get + list compact) ─┘
Track 4 ──► Track 6 (Flutter site.tx_list card)
Tracks 0–6 ──► Track 7 (compose tests — every phrase)
Track 7 + fixtures ──► Track 8 (prompt_run matrix + site-ai.md)
```

| Track | Focus | Depends |
|-------|--------|---------|
| **0** | `yesterday`, `last_week` in `query_time_range`; `tx.sales_period_compare` query | — |
| **1** | Inst seeds: report phrases, `inst.site.tx_browse`, `inst.site.period_compare`, product qty, compare omzet; `general` on report/compare | — |
| **2** | `tx.sales_list` query + `TxBrowseReport` struct | 0 |
| **3** | `tx_browse_parse` (date, open_only, cancelled, last N) | — |
| **4** | Prefetch, `site_query` compact path, reuse `report_table` for xlsx/pdf | 2, 3 |
| **5** | `site.tx.get` tool; `site.tx.list` optional `compact: true` (headers only, no items in LLM) | — |
| **6** | `ui_tx_list_card.dart` + `ui_msg_blocks` | 4 |
| **7** | `site_tx_chat_prompt_test.rs` — **all phrases** | 1 |
| **8** | `prompt_run` per matrix row; update `site-ai.md`; live `inst_put` | 0–7 |

**Wave 1:** Tracks 0, 1, 3, 5 (parallel).  
**Wave 2:** Tracks 2, 4.  
**Wave 3:** Track 6.  
**Wave 4:** Tracks 7, 8.

---

## Prompt test matrix (required)

Each row must pass **both** checks before the plan is done.

| ID | User phrase (ID) | `prompt_compose` expects | `prompt_run` expects |
|----|------------------|---------------------------|----------------------|
| R01 | `berapa omzet hari ini` | `inst.site.report`, `site.query.run` fed, no `web.search` | Hop 1: `site.query.run` `query_id=tx.sales_summary`, `params.range=today` |
| R02 | `berapa untung hari ini` | `inst.site.report` | `tx.profit_summary`, `range=today` |
| R03 | `laporan penjualan minggu ini` | `inst.site.report` | `tx.sales_summary`, `range=this_week` |
| R04 | `berapa transaksi hari ini` | `inst.site.report` (count via summary) | `tx.sales_summary`, `range=today`; reply mentions `tx_count` |
| R05 | `omzet kemarin` | `inst.site.report` | `tx.sales_summary`, `range=yesterday` |
| C01 | `berapa omzet hari ini dibanding kemarin` | `inst.site.period_compare` | `tx.sales_period_compare` **or** two summaries; reply has % or delta |
| C02 | `naik berapa persen penjualan vs kemarin` | `inst.site.period_compare` | same as C01 |
| B01 | `daftar transaksi hari ini` | `inst.site.tx_browse`, `site.query.run` | Block `site.tx_list` **or** `tokens_in+tokens_out==0` prefetch; **no** row dump in `text` |
| B02 | `apa saja transaksi hari ini` | same as B01 | same |
| B03 | `10 transaksi terakhir` | `inst.site.tx_browse` | `tx.sales_list` with `limit=10` |
| B04 | `transaksi yang belum lunas` | `inst.site.tx_browse` | `open_only=true` or filter in query |
| B05 | `transaksi batal hari ini` | `inst.site.tx_browse` | `state=cancelled`, `range=today` |
| T01 | `produk paling laku hari ini` | `inst.site.top_products` | `tx.top_products`, `range=today` |
| T02 | `indomie terjual berapa hari ini` | `inst.site.product_sales` (new) | `tx.product_compare` or `product_compare` with `q=indomie` |
| M01 | `@siteA @siteB mana lebih untung bulan ini` | `inst.site.compare` | `tx.profit_summary`, `range=this_month`, both site_iids |
| M02 | `bandingkan omzet warung A dan B` | `inst.site.compare` (extended phrases) | `tx.sales_summary`, multi-site rows |
| D01 | `detail transaksi 42` | `inst.site.tx_detail` | `site.tx.get` `tx_id=42` |
| D02 | `struk terakhir` | `inst.site.tx_detail` | `tx.sales_list` `limit=1` then get or list one row |
| G01 | `daftar transaksi hari ini` with **no** site grant | compose may match browse | Short reply: no site / no commerce — **no** web search |
| X01 | `berapa stok susu` | `inst.site.catalog.stock` | **not** `inst.site.tx_browse` |
| X02 | `kartu stok indomie` | `inst.site.stock_report` | **not** `inst.site.report` |

**Compose automation:** Track 7 encodes R01–X02 (except @-mention rows use synthetic `mention_ids` in test).  
**prompt_run automation:** Track 8 runs R01–B05, C01, T01, D01 against **`owner_iid=33000`** with seeded site + commerce (document fixture SQL in track 8). Rows M01–M02 manual or seed two sites on 33000.

---

## File structure

| File | Responsibility |
|------|----------------|
| `servers/crates/mod_site/src/query/params.rs` | `yesterday`, `last_week` in `named_utc_range` |
| `servers/crates/mod_site/src/query/tx.rs` | `tx.sales_period_compare`, `tx.sales_list` |
| `servers/crates/mod_site/src/query/tx_browse.rs` | `TxBrowseReport`, `tx_browse_from_query`, caps |
| `servers/crates/mod_chat/src/tx_browse.rs` | Intent parse |
| `servers/crates/mod_chat/src/tx_browse_run.rs` | Prefetch + `tx_browse_llm_payload` |
| `servers/crates/mod_chat/src/tx_browse_render.rs` | Blocks + files (reuse `report_table`) |
| `servers/crates/mod_chat/src/tools/builtin/site_tx.rs` | `site.tx.get`; list `compact` |
| `servers/crates/mod_chat/src/tools/builtin/site_query.rs` | Compact path for `tx.sales_list` |
| `servers/crates/mod_chat/src/prompt_turn.rs` | Prefetch hook (mirror `stock_report`) |
| `_/schemas/inst.sql` | New/updated inst rows |
| `clients/app/lib/widgets/ai/ui_tx_list_card.dart` | Preview table |
| `clients/app/lib/widgets/ai/ui_msg_blocks.dart` | `case 'site.tx_list'` |
| `servers/crates/mod_chat/tests/site_tx_chat_prompt_test.rs` | Compose matrix |
| `_/specs/site-ai.md` | Query ids + browse/compare sections |

---

### Task 0: Time ranges and period compare query

**Files:**
- Modify: `servers/crates/mod_site/src/query/params.rs`
- Modify: `servers/crates/mod_site/src/query/params_test.rs`
- Modify: `servers/crates/mod_site/src/query/tx.rs`
- Modify: `servers/crates/mod_site/src/query/registry_test.rs`

**Interfaces:**
- Produces: `named_utc_range("yesterday")`, `named_utc_range("last_week")`
- Produces: `query_id` **`tx.sales_period_compare`** — params: `metric` (`revenue` \| `profit` \| `tx_count`, default `revenue`), optional `range` for period A (default `today`), period B fixed `yesterday` OR params `period_a` / `period_b` enum (`today`, `yesterday`, `this_week`, `last_week`, `this_month`)
- `result_json`: per site: `revenue_a`, `revenue_b`, `delta`, `delta_pct`, `tx_count_a`, `tx_count_b`

- [ ] **Step 1: Failing tests**

```rust
#[test]
fn named_range_yesterday_and_last_week() {
    let today = Utc.with_ymd_and_hms(2026, 3, 15, 12, 0, 0).unwrap();
    let (from, to) = named_utc_range_at("yesterday", today).unwrap();
    assert_eq!(from.date_naive(), NaiveDate::from_ymd_opt(2026, 3, 14).unwrap());
    // last_week: Mon–Sun before current week
    let (lw_from, _) = named_utc_range_at("last_week", today).unwrap();
    assert_eq!(lw_from.weekday(), chrono::Weekday::Mon);
}
```

- [ ] **Step 2:** Run `cargo test -p c35_mod_site -- query_time_range named_range` → FAIL.

- [ ] **Step 3:** Implement ranges + `SalesPeriodCompareQuery` (SQL: two aggregations on `site.tx` with same filters as `tx.sales_summary`).

- [ ] **Step 4:** Register id in `registry_test.rs`; run `cargo test -p c35_mod_site -- params_test registry_test`.

---

### Task 1: Inst seeds and topic coverage

**Files:**
- Modify: `_/schemas/inst.sql`
- Modify: `_/specs/site-ai.md` (inst table only — full doc in track 8)

**Interfaces:**
- Update **`inst.site.report`**: add topics **`general`**; phrases: `omzet`, `penjualan`, `pendapatan`, `revenue`, `minggu ini`, `bulan ini`, `berapa transaksi`, `transaksi hari ini` (when meaning **count** — inst body: use `tx.sales_summary`, not list).
- Create **`inst.site.period_compare`**: phrases `dibanding kemarin`, `vs kemarin`, `naik berapa`, `turun berapa`, `kemajuan`, `bandingkan hari ini`; `tool_include:site.query.run`; `query_id` hint `tx.sales_period_compare`.
- Create **`inst.site.tx_browse`**: topics `general`, `site.commerce`, `web.builder`; phrases `daftar transaksi`, `apa saja transaksi`, `list transaksi`, `transaksi terakhir`, `nota terakhir`, `belum lunas`, `transaksi batal`; exclude web; `tool_include:site.query.run` (not raw `site.tx.list` in inst body).
- Create **`inst.site.tx_detail`**: phrases `detail transaksi`, `struk`, `nota #`, `transaksi nomor`; `tool_include:site.tx.get`, `site.tx.list`.
- Create **`inst.site.product_sales`**: phrases `terjual berapa`, `qty`, `quantity sold`; `tx.product_compare`.
- Extend **`inst.site.compare`**: `omzet`, `penjualan`, `bandingkan omzet`.
- **`inst.site.report` inst body:** Revenue / omzet / penjualan → `tx.sales_summary`; explain `paid_total` vs `revenue` when user asks “sudah terkumpul”.

- [ ] **Step 1:** Apply SQL seed locally; **`inst_put`** each new/changed id on cluster.

- [ ] **Step 2:** `prompt_compose` manual spot-check R01, B01, C01 (33000) before track 7 lands.

---

### Task 2: `tx.sales_list` query

**Files:**
- Create: `servers/crates/mod_site/src/query/tx_browse.rs`
- Modify: `servers/crates/mod_site/src/query/mod.rs`

**Interfaces:**
- `query_id`: **`tx.sales_list`**
- Params: `range`, `time_from_ms`, `time_to_ms`, `limit` (default 50, max 200), `open_only`, `state`, `q` (desc ILIKE), `after_tx_id`
- Columns per row (cells): `tx_id`, `time_ts`, `total`, `total_paid`, `desc`, `cashier_name`, `subject_name`, `state`, `ty`
- Footer aggregates in `result_json`: `row_count`, `total_revenue`, `truncated`
- SQL: header-only from `site.tx` (no line items); `LIMIT export_cap+1` pattern from stock report

- [ ] **Step 1:** Unit test `tx_browse_query_id("tx.sales_list")` true; preview cap 40.

- [ ] **Step 2:** `cargo test -p c35_mod_site -- tx_browse` → implement.

---

### Task 3: Browse intent parser

**Files:**
- Create: `servers/crates/mod_chat/src/tx_browse.rs`
- Test: `#[cfg(test)]` in same file

**Interfaces:**
- `pub struct TxBrowseIntent { pub query_id: String, pub range: String, pub limit: i32, pub open_only: bool, pub state: Option<String>, pub formats: Vec<TxBrowseFormat> }`
- `pub fn tx_browse_parse(text: &str, now: DateTime<Utc>) -> Option<TxBrowseIntent>`

Parse rules (tests required):
- `hari ini` → `range=today`
- `10 transaksi terakhir` → `limit=10`
- `belum lunas` / `open` → `open_only=true`
- `batal` → `state=cancelled`
- `excel` / `pdf` → formats (reuse `StockReportFormat` enum or parallel)

- [ ] Run `cargo test -p c35_mod_chat -- tx_browse_parse`.

---

### Task 4: Prefetch, blocks, compact tool result

**Files:**
- Create: `servers/crates/mod_chat/src/tx_browse_render.rs`, `tx_browse_run.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`, `prompt_turn.rs`, `tools/builtin/site_query.rs`, `prompt/tool_loop.rs` (only if needed for zero-token path)

**Interfaces:**
- `pub fn tx_browse_llm_payload(report: &TxBrowseReport, files: &[Value]) -> Value` — **no `rows`**, `preview` max 5
- `pub fn tx_browse_blocks(...) -> Vec<Value>` — `kind: "site.tx_list"`
- `pub async fn tx_browse_prefetch(ctx, user_text) -> Option<ChatRes>` when `inst.site.tx_browse` matched
- `site_query_run_exec`: if `query_id == "tx.sales_list"`, return compact payload + `block` (same pattern as stock report)

- [ ] **Step 1:** Test `llm_payload_has_no_rows` (copy stock_report test).

- [ ] **Step 2:** Wire prefetch in `prompt_turn` (flag `tx_browse: composed.inst_ids contains inst.site.tx_browse`).

- [ ] **Step 3:** `cargo test -p c35_mod_chat -- tx_browse` && `cargo build -p server_ai`.

---

### Task 5: `site.tx.get` and compact list

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/site_tx.rs`
- Modify: `servers/crates/mod_tx` only if `tx_get` needs lighter JSON helper

**Interfaces:**
- New tool **`site.tx.get`**: `site_iid`, `tx_id` required; readonly; returns **`llm`** object: header + items (one nota — acceptable size).
- **`site.tx.list`**: param `compact: true` (default false for backward compat) → map with slim JSON (no items/payments/accs); used only when model explicitly lists; inst steers browse to `tx.sales_list` instead.

- [ ] **Step 1:** Register tool in `tools/mod.rs`.

- [ ] **Step 2:** Unit test slim JSON length &lt; full `tx_to_json` for sample tx.

---

### Task 6: Flutter `site.tx_list` block

**Files:**
- Create: `clients/app/lib/widgets/ai/ui_tx_list_card.dart`
- Modify: `clients/app/lib/widgets/ai/ui_msg_blocks.dart`

- [ ] Mirror `ui_stock_report_card.dart`: title, `row_count`, `total_revenue`, 40-row table, truncated footer.

- [ ] `.\_\scripts\dev\verify_flutter_app.ps1`

---

### Task 7: Compose tests (every phrase)

**Files:**
- Create: `servers/crates/mod_chat/tests/site_tx_chat_prompt_test.rs`

**Interfaces:**
- Helper: `async fn compose(owner, text, mention_ids) -> ComposeOutput` — use same internals as `compose_test.rs` or call `compose_tools_and_inst_async` with fixture inst rows loaded from DB **or** in-memory `InstRow` slice for phrase tests (prefer DB integration test gated by `C35_TEST_YB=1` if existing pattern; else pure `inst_pick` tests for phrase + topic).

Minimum **pure Rust** tests (no DB):
- `inst_pick` with `active_topics: ["general"]` + text R01 → `inst.site.report`
- B01 → `inst.site.tx_browse` and **not** `inst.consumption_coach`
- C01 → `inst.site.period_compare`
- X01/X02 cross-talk guards

**DB integration** (if `compose_test` already uses pool):
- Table-driven loop over matrix IDs R01–B05, C01, T01, T02, X01, X02 with `assert!(selected_tools.contains("site.query.run"))` etc.

- [ ] **Step 1:** Write failing tests for full matrix.

- [ ] **Step 2:** `cargo test -p c35_mod_chat -- site_tx_chat_prompt` → implement missing inst/topics until green.

---

### Task 8: `prompt_run` matrix and docs

**Files:**
- Modify: `_/specs/site-ai.md`
- Optional: `_/docs/en/sites/pos-reports.md`, `_/docs/id/sites/pos-reports.md` (`path: prompt`)

**Fixture (33000):**
- Document in this plan appendix: one site with `commerce: true`, ≥3 `site.tx` rows today, ≥1 yesterday (seed script or SQL snippet in `servers/crates/mod_chat/tests/fixtures/site_tx_prompt_seed.sql`).

**For each automated `prompt_run` row:**

```text
prompt_run owner_iid=33000 text="<phrase>" tool_mode=ask
```

Assert:
- `trace` hop 1 tool name `site.query.run` (or prefetch with `model_used=tx_browse` / `stock_report`-style)
- `blocks_json` contains `site.tx_list` for B01–B05
- `text` does not contain a 20+ line enumerated receipt list
- C01: `text` matches `\d+%` or contains `kemarin`
- R04: `text` mentions integer count

- [ ] Run MCP checks from dev machine with `C35_MCP_AGENT_ENABLED=1`.

- [ ] `inst_put` all changed inst rows.

- [ ] `check_utf8_sources.ps1 -Changed -Fix`

---

## Appendix A: Seed SQL sketch (33000)

```sql
-- Run once on test DB; site_iid and ids are examples — adjust to 33000 grants.
-- 1) site with commerce capability
-- 2) INSERT INTO site.tx (...) for 2026-03-15 and 2026-03-14 with state ok, ty sale
```

Implementers replace with real `site_iid` from `identity_grant` for `automated-tester`.

---

## Appendix B: Commerce topic without @mention (optional hardening)

If `prompt_compose` still shows `active_topics: ["general"]` but inst rows include `general`, **no change**. If reports fail in app because `inst.site.report` lacks `general`, task 1 fixes it. Optional follow-up: promote `site.commerce` when `inst.site.report` / `inst.site.tx_browse` phrase hits and caller has ≥1 `commerce_site_iids` (extend `mention_active_topics` in `mention_registry.rs`) — **only if** task 7 tests still fail after task 1.

---

## Self-review

| Requirement | Task |
|-------------|------|
| P0 omzet/untung/count today | 0, 1, 7–8 (R01–R04) |
| Yesterday + compare | 0, 1, 7–8 (R05, C01–C02) |
| Transaction list without LLM rows | 2, 3, 4, 6, 7–8 (B01–B05) |
| Top / product qty | 1, 7–8 (T01–T02) |
| Multi-site compare | 1, 8 (M01–M02) |
| Single nota detail | 5, 1, 8 (D01–D02) |
| Guards vs stock/consumption | 7 (X01–X02, B01 vs consumption) |
| Per-prompt test | 7 compose + 8 prompt_run matrix |
| No placeholder steps | All tasks have concrete files and commands |

---

## Execution handoff

Wave 1: dispatch **Track 0, 1, 3, 5** as parallel subagents.  
After wave 1 green tests: **Track 2 → 4 → 6 → 7 → 8**.

Do not mark the feature done until **every matrix row** R01–X02 passes compose (track 7) and automated `prompt_run` rows R01–B05, C01, T01, D01 pass (track 8).
