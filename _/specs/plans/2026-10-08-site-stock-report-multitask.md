# Site stock reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Answer stock list, stock card, and item in/out history from SQL, then attach a table, PDF, Excel file, summary slides, or a linked Google Sheet, without sending the row set through the model.

**Architecture:** Three new `site.query.run` ids return a capped `StockReport`. Renderers turn that struct into chat blocks and CAS files. Phrase matching stays in `ai.inst`. When `inst.site.stock_report` matches, Rust parses the date and format (mechanical, same class as the catalog web phase) and returns the blocks with no LLM hop. If the model calls the query anyway, the function result it sees is counts and file ids only.

**Tech Stack:** Rust (`c35_mod_site`, `c35_mod_file`, `c35_mod_chat`, `c35_mod_data_source`), YSQL `site.tx` / `site.tx_stock` / `site.product`, Flutter chat blocks, `ai.inst` seed.

**Spec:** [`_/specs/site-ai.md`](../site-ai.md), [`_/specs/tx.md`](../tx.md), [`_/specs/inst.md`](../inst.md).

## Global Constraints

- Readonly. These queries never `INSERT` / `UPDATE` / `DELETE` business rows.
- Every `site_iid` passes `site_grant_check` inside `site_query_run` before SQL runs.
- No user SQL. Only the three new `query_id` values below.
- Money stays `BIGINT` minor units in SQL and in the tool JSON. Format with thousands separators only inside PDF / xlsx / slide text.
- The model never receives `rows`. Compact result is `ok`, `query_id`, `kind`, `row_count`, `truncated`, `totals`, `files[]`.
- Chat table preview is **40** rows. Full export cap is **20_000** lines. Past that, `truncated: true` and the file footer says the cap was hit.
- Presentation is a **summary deck of at most 6 slides** (title, totals, top movers). One slide per transaction is forbidden.
- Google Sheet export writes one batch to a sheet the caller already linked. It does not create a spreadsheet and it does not call `gsheet.append` once per row. No linked sheet → `gsheet: "not_linked"` and the xlsx is still attached.
- `product.stock` (one product, limit 50) and `inst.site.report` (profit / sales) stay as they are. The new inst must not list `stok` or `untung` alone.
- Spoken steering lives in `ai.inst`. Rust branches on the inst id `inst.site.stock_report` plus date/format extraction. Do not add a new system-prompt paragraph in `prompt_turn.rs`.
- Personal `expense.*` and GL `site.tx_acc` are out of this plan.
- Do not commit unless the user asks.
- Verify from `servers/`: `cargo test -p c35_mod_site -- stock_report` and `cargo test -p c35_mod_chat -- stock_report`, then `cargo build -p server_ai`.

## Multitask Map

```
Track 1 (SQL + StockReport) ──┬──► Track 2 (pdf, xlsx, slides, gsheet, table block)
Track 3 (date/format parse) ──┤
Track 4 (inst seed) ──────────┴──► Track 5 (prefetch, skip LLM, compact tool result)
Track 2 ──► Track 6 (Flutter table card)
Track 5 + Track 6 ──► Track 7 (site-ai.md + prompt_compose)
```

| Track | Focus | Depends |
|-------|--------|---------|
| 1 | Three query ids, caps, index | — |
| 2 | Render the same struct to table / pdf / xlsx / slides / sheet | 1 |
| 3 | Pure date + format parser | — |
| 4 | `inst.site.stock_report` seed | — |
| 5 | Skip the model when that inst matches; strip rows if the model calls the tool | 1, 2, 3, 4 |
| 6 | Chat card for `site.stock_report` | 2 |
| 7 | Spec + `prompt_compose` on the closed phrases | 5, 6 |

Wave 1 is tracks 1, 3, and 4 in parallel. Wave 2 is track 2. Wave 3 is tracks 5 and 6. Wave 4 is track 7.

## File structure

| File | Responsibility |
|------|----------------|
| `servers/crates/mod_site/src/query/stock_report.rs` | SQL for list, card, movement. Builds `StockReport`. |
| `servers/crates/mod_site/src/query/mod.rs` | Register the three query ids. |
| `_/schemas/tx.sql` | Partial index on `site.tx_stock (site_iid, product_id)` |
| `servers/crates/mod_file/src/report_table.rs` | PDF (`lopdf`) and xlsx (OOXML via `zip`) from headers + string rows |
| `servers/crates/mod_chat/src/stock_report.rs` | Intent parse, block JSON, CAS put, prefetch decision |
| `servers/crates/mod_chat/src/tools/builtin/site_query.rs` | Compact payload for the three ids |
| `servers/crates/mod_chat/src/prompt/tool_loop.rs` | Return before `llm_stream_chain` when prefetch hits |
| `servers/crates/mod_data_source/src/google_sheet.rs` | One `values.batchUpdate` of the report grid |
| `_/schemas/inst.sql` | `inst.site.stock_report` |
| `clients/app/lib/widgets/ai/ui_stock_report_card.dart` | Preview table |
| `clients/app/lib/widgets/ai/ui_msg_blocks.dart` | `case 'site.stock_report'` |
| `_/specs/site-ai.md` | Document the three ids and the no-row LLM rule |

---

### Task 1: Stock report queries

**Files:**
- Create: `servers/crates/mod_site/src/query/stock_report.rs`
- Modify: `servers/crates/mod_site/src/query/mod.rs`
- Modify: `servers/crates/mod_site/src/query/registry_test.rs`
- Modify: `_/schemas/tx.sql` (append index after `site.tx_stock`)
- Test: `servers/crates/mod_site/src/query/stock_report.rs` (`#[cfg(test)]` module, no DB)

**Interfaces:**
- Consumes: `query_register!`, `query_time_range`, `query_param_str`, `site_query_rows_with_names`
- Produces:
  - `pub struct StockReport { pub kind: String, pub title: String, pub headers: Vec<String>, pub rows: Vec<Vec<String>>, pub row_count: i64, pub truncated: bool, pub qty_in: i64, pub qty_out: i64 }`
  - `pub fn stock_report_from_query(query_id: &str, rows: &[SiteQueryRow], result_json: &str) -> Option<StockReport>`
  - Query ids: `tx.stock_list`, `tx.stock_card`, `tx.stock_movement`
  - Caps: `STOCK_PREVIEW_ROWS = 40`, `STOCK_EXPORT_CAP = 20_000`

- [ ] **Step 1: Write the failing unit test**

```rust
#[test]
fn stock_report_kinds_are_closed() {
    assert!(stock_report_query_id("tx.stock_list"));
    assert!(stock_report_query_id("tx.stock_card"));
    assert!(stock_report_query_id("tx.stock_movement"));
    assert!(!stock_report_query_id("tx.sales_summary"));
    assert!(!stock_report_query_id("product.stock"));
}

#[test]
fn stock_report_preview_is_capped() {
    let rows = (0..50).map(|i| vec![format!("p{i}")]).collect::<Vec<_>>();
    let view = stock_report_preview(&rows, 40);
    assert_eq!(view.len(), 40);
}
```

- [ ] **Step 2: Run the test**

Run: `cargo test -p c35_mod_site -- stock_report_kinds -- --test-threads=8`

Expected: FAIL, `stock_report_query_id` not found.

- [ ] **Step 3: Implement the queries**

`stock_report_query_id` is the match above.

`tx.stock_list` reads `site.product` for the granted sites (`deleted_ts IS NULL`, `is_archived = false`, `track_stock = true`). Columns: site name, name, sku, stock_qty. Order by site_iid, name. `LIMIT 20001`. If the fetch returns 20001, drop the last row and set `truncated`. No `params.q` filter unless `q` is non-empty (then same `ILIKE` as `product.stock` on name/sku). This is the full list; it does not use the `product.stock` limit of 50.

`tx.stock_card` requires `params.q` or `params.product_id`. Empty both → `result_json` `{"error":"product_required"}` and zero rows (do not scan every movement). SQL joins `site.tx_stock` to `site.tx` on `(site_iid, tx_id)` and to `site.product` on `(site_iid, product_id)`:

```sql
SELECT t.time_ts, t.ty, t.tx_id, p.name, p.sku,
       s.direction, s.qty_signed, s.note
FROM site.tx_stock s
JOIN site.tx t
  ON t.site_iid = s.site_iid AND t.tx_id = s.tx_id
JOIN site.product p
  ON p.site_iid = s.site_iid AND p.product_id = s.product_id
WHERE s.site_iid = ANY($1)
  AND s.deleted_ts IS NULL
  AND t.deleted_ts IS NULL
  AND t.is_archived = false
  AND t.state = 'ok'
  AND ($2::bigint > 0 AND s.product_id = $2
       OR $2::bigint = 0 AND (p.name ILIKE ('%' || $3 || '%') OR p.sku ILIKE ('%' || $3 || '%')))
  AND ($4::timestamptz IS NULL OR t.time_ts >= $4)
  AND ($5::timestamptz IS NULL OR t.time_ts <= $5)
ORDER BY t.time_ts, t.tx_id, s.stock_id
LIMIT 20001
```

`tx.stock_movement` is the same filters grouped per product:

```sql
SELECT p.site_iid, p.product_id, p.name, p.sku,
       COALESCE(SUM(CASE WHEN s.qty_signed > 0 THEN s.qty_signed ELSE 0 END), 0) AS qty_in,
       COALESCE(SUM(CASE WHEN s.qty_signed < 0 THEN -s.qty_signed ELSE 0 END), 0) AS qty_out
FROM site.tx_stock s
JOIN site.tx t ON t.site_iid = s.site_iid AND t.tx_id = s.tx_id
JOIN site.product p ON p.site_iid = s.site_iid AND p.product_id = s.product_id
WHERE s.site_iid = ANY($1)
  AND s.deleted_ts IS NULL
  AND t.deleted_ts IS NULL
  AND t.is_archived = false
  AND t.state = 'ok'
  AND ($2::timestamptz IS NULL OR t.time_ts >= $2)
  AND ($3::timestamptz IS NULL OR t.time_ts <= $3)
  AND ($4 = '' OR p.name ILIKE ('%' || $4 || '%') OR p.sku ILIKE ('%' || $4 || '%'))
GROUP BY p.site_iid, p.product_id, p.name, p.sku
ORDER BY p.name
LIMIT 20001
```

Time window comes from `query_time_range`. Register all three in `query_registry()` and in `registry_test.rs` expected ids.

Append to `_/schemas/tx.sql` after the `site.tx_stock` table:

```sql
CREATE INDEX IF NOT EXISTS idx_tx_stock_site_product
    ON site.tx_stock (site_iid, product_id)
    WHERE deleted_ts IS NULL;
```

Apply that index on the live database with `yb_execute` when the track lands (same statement). Do not put the full grid in `result_json`. `result_json` is only:

```json
{"query_id":"tx.stock_movement","row_count":12,"truncated":false,"qty_in":40,"qty_out":15}
```

Row cells are strings. `qty_in` / `qty_out` on the list query are 0; `row_count` is the product count.

- [ ] **Step 4: Re-run**

Run: `cargo test -p c35_mod_site -- stock_report registry_test -- --test-threads=8`

Expected: PASS.

---

### Task 2: Renderers

**Files:**
- Create: `servers/crates/mod_file/src/report_table.rs`
- Modify: `servers/crates/mod_file/src/lib.rs` (pub use the two functions)
- Create: `servers/crates/mod_chat/src/stock_report_render.rs`
- Modify: `servers/crates/mod_data_source/src/google_sheet.rs`
- Test: unit tests in `report_table.rs` and `stock_report_render.rs`

**Interfaces:**
- Consumes: `StockReport` from task 1
- Produces:
  - `pub fn report_pdf(title: &str, headers: &[String], rows: &[Vec<String>]) -> Vec<u8>`
  - `pub fn report_xlsx(headers: &[String], rows: &[Vec<String>]) -> Vec<u8>`
  - `pub fn stock_report_blocks(report: &StockReport, files: &[StockReportFile], slides: bool) -> Vec<Value>`
  - `pub struct StockReportFile { pub name: String, pub mime: String, pub bytes: Vec<u8> }`
  - `pub async fn gsheet_replace_grid(cfg: &GoogleSheetConfig, headers: &[String], rows: &[Vec<String>]) -> Result<()>`

- [ ] **Step 1: Write failing renderer tests**

```rust
#[test]
fn report_xlsx_is_a_zip() {
    let bytes = report_xlsx(&["Name".into(), "In".into()], &[vec!["Milk".into(), "3".into()]]);
    assert_eq!(&bytes[0..2], b"PK");
}

#[test]
fn report_pdf_starts_with_header() {
    let bytes = report_pdf("January", &["Name".into()], &[vec!["Milk".into()]]);
    assert!(bytes.starts_with(b"%PDF"));
}

#[test]
fn slides_are_summary_only() {
    let report = sample_movement_report(100);
    let slides = stock_report_slides(&report);
    assert!(slides.len() <= 6);
    assert!(slides.iter().all(|s| s.len() < 2000));
}
```

`sample_movement_report` builds a `StockReport` with `n` synthetic rows in the test module.

- [ ] **Step 2: Run**

Run: `cargo test -p c35_mod_file -- report_xlsx -- --test-threads=8`

Expected: FAIL, function missing.

- [ ] **Step 3: Implement**

PDF: `lopdf` already in `c35_mod_file`. One page per 28 body rows, Helvetica, title on page 1, footer `row i–j of N` and `truncated` when set. Escape `(`, `)`, `\` in text operands.

Xlsx: `zip` 2 is already in `c35_mod_file`. Write `[Content_Types].xml`, `xl/workbook.xml`, `xl/worksheets/sheet1.xml`, `xl/sharedStrings.xml`, and the two relationship parts. Shared strings for every cell. Sheet name `Report`. No third-party xlsx crate.

`stock_report_blocks`:
- Always one block `kind: "site.stock_report"` with `body.headers`, `body.rows` = first 40, `body.row_count`, `body.truncated`, `body.qty_in`, `body.qty_out`, `body.title`, `body.kind`.
- For each file, a `kind: "file"` block `{ hash, name, mime }` filled after CAS put (hash filled by task 5; this function takes already-uploaded `hash` values).
- When `slides` is true, one `kind: "presentation.deck"` block. Theme `emerald`. Slides, in order, only when there is data:
  1. `# {title}` plus period and row count
  2. Totals: qty in, qty out, net (`qty_in - qty_out`)
  3. Up to 8 rows with the largest `qty_out` (movement / card). List reports use the 8 lowest `stock_qty` instead.
- Formats the caller did not ask for produce no extra block.

`gsheet_replace_grid`: clear `A1:Z` then `spreadsheets.values.batchUpdate` with `valueInputOption=RAW` in chunks of 500 rows. Reuse the HTTP client and token path already in `google_sheet.rs`. On missing config, return `Err` with a message containing `not_linked`. Do not loop `values.append`.

- [ ] **Step 4: Re-run**

Run: `cargo test -p c35_mod_file -- report_ -- --test-threads=8` and `cargo test -p c35_mod_chat -- stock_report_slides -- --test-threads=8`

Expected: PASS.

---

### Task 3: Date and format parser

**Files:**
- Create: `servers/crates/mod_chat/src/stock_report.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` or `prompt/mod.rs` so the module is compiled (match how sibling modules are declared)
- Test: same file

**Interfaces:**
- Consumes: nothing from other tracks
- Produces:
  - `pub struct StockReportIntent { pub query_id: &'static str, pub q: String, pub time_from_ms: i64, pub time_to_ms: i64, pub formats: Vec<StockReportFormat> }`
  - `pub enum StockReportFormat { Table, Pdf, Xlsx, Slides, Gsheet }`
  - `pub fn stock_report_parse(text: &str, now: DateTime<Utc>) -> Option<StockReportIntent>`

- [ ] **Step 1: Write failing tests**

```rust
#[test]
fn january_movement_pdf_parses() {
    let now = Utc.with_ymd_and_hms(2026, 10, 8, 12, 0, 0).unwrap();
    let intent = stock_report_parse(
        "generate pdf report of all item in and out from january",
        now,
    ).unwrap();
    assert_eq!(intent.query_id, "tx.stock_movement");
    assert!(intent.formats.contains(&StockReportFormat::Pdf));
    assert!(intent.formats.contains(&StockReportFormat::Table));
    let from = Utc.timestamp_millis_opt(intent.time_from_ms).unwrap();
    assert_eq!((from.year(), from.month(), from.day()), (2026, 1, 1));
}

#[test]
fn bare_stok_is_not_a_report() {
    let now = Utc.with_ymd_and_hms(2026, 10, 8, 0, 0, 0).unwrap();
    assert!(stock_report_parse("berapa stok susu", now).is_none());
}

#[test]
fn stock_card_needs_the_phrase() {
    let now = Utc.with_ymd_and_hms(2026, 10, 8, 0, 0, 0).unwrap();
    let intent = stock_report_parse("kartu stok indomie dari januari excel", now).unwrap();
    assert_eq!(intent.query_id, "tx.stock_card");
    assert_eq!(intent.q, "indomie");
    assert!(intent.formats.contains(&StockReportFormat::Xlsx));
}
```

- [ ] **Step 2: Run**

Run: `cargo test -p c35_mod_chat -- stock_report_parse january_movement -- --test-threads=8`

Expected: FAIL.

- [ ] **Step 3: Implement the parser**

Lowercase the text. Return `None` unless one of these needles hits: `kartu stok`, `stock card`, `daftar stok`, `stock list`, `list stok`, `semua stok`, `mutasi`, `masuk keluar`, `in and out`, `barang masuk`, `barang keluar`, `stock movement`, `laporan stok`.

Kind:
- card needles (`kartu stok`, `stock card`) → `tx.stock_card`
- list needles (`daftar stok`, `stock list`, `list stok`, `semua stok`) → `tx.stock_list`
- otherwise the movement needles → `tx.stock_movement`

`q`: for a card, the leftover tokens after removing the needles, format words, and date words, joined by space. If that leftover is empty, still return the intent with `q: ""` (task 5 answers `product_required` without a model).

Formats: `pdf` → Pdf, `excel` / `xlsx` / `spreadsheet` → Xlsx, `google sheet` / `gsheet` → Gsheet, `presentasi` / `slide` / `presentation` → Slides. Always include `Table`.

Dates, UTC:
- `dari januari` / `from january` / `since january` → 1 Jan of `now.year()` through `now` (end of today).
- `januari 2025` / `january 2025` → that calendar month.
- `bulan ini` / `this month` → `query` range `this_month`, computed here with the same Monday/month rules as `named_utc_range` (copy the three-arm match; do not import `mod_site` private fn).
- Movement and card with no date → `this_month`.
- List ignores the window (`time_from_ms = 0`, `time_to_ms = 0`).

Month names: Indonesian and English, January–December.

- [ ] **Step 4: Re-run**

Run: `cargo test -p c35_mod_chat -- stock_report_parse -- --test-threads=8`

Expected: PASS. Add one test each for `this month`, `januari 2025`, and `presentasi`.

---

### Task 4: Inst seed

**Files:**
- Modify: `_/schemas/inst.sql` (insert after `inst.site.report`)
- Test: `servers/crates/mod_chat/tests/compose_test.rs` if an inst-phrase fixture already loads SQL; otherwise a pure test is not required here. Confirm with `inst_get` after `inst_put`.

**Interfaces:**
- Consumes: query ids from task 1
- Produces: inst id `inst.site.stock_report`, priority **146**

- [ ] **Step 1: Add the seed row**

```sql
INSERT INTO ai.inst (
    id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, def_hash, updated_ts
) VALUES (
    'inst.site.stock_report',
    'global',
    'task',
    '',
    ARRAY['web.builder', 'site.commerce'],
    '[SITE.STOCK.REPORT] Closed stock report. The server runs site.query.run and attaches the file. query_id tx.stock_list for a full stock list, tx.stock_card for one product card, tx.stock_movement for item in and out. Do not paste rows. Do not call web.search or site.tx.put.',
    ARRAY[
        'kartu stok', 'stock card', 'daftar stok', 'stock list', 'list stok', 'semua stok',
        'mutasi stok', 'masuk keluar', 'barang masuk', 'barang keluar', 'stock movement',
        'laporan stok', 'item in and out', 'in and out'
    ],
    ARRAY['tool_include:site.query.run', 'tool_exclude:web.search', 'tool_exclude:web.visit'],
    ARRAY['site.query.run'],
    ARRAY['web.search', 'web.visit', 'site.tx.put'],
    146,
    'seed',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    inst = EXCLUDED.inst,
    phrases = EXCLUDED.phrases,
    triggers = EXCLUDED.triggers,
    include_tools = EXCLUDED.include_tools,
    exclude_tools = EXCLUDED.exclude_tools,
    topics = EXCLUDED.topics,
    kind = EXCLUDED.kind,
    priority = EXCLUDED.priority,
    updated_ts = NOW();
```

Do not add `stok`, `stock`, `laporan`, or `report` as their own phrases.

- [ ] **Step 2: Push the live row**

`inst_put` with the same id, phrases, include/exclude, and body. Git seed alone is not live.

- [ ] **Step 3: Check compose**

`prompt_compose` owner `33000`, text `kartu stok indomie dari januari`.

Expected: `inst.site.stock_report` in `inst_ids`, `site.query.run` in `selected_tools`, `web.search` absent.

`prompt_compose` text `berapa stok susu`.

Expected: `inst.site.catalog.stock` still matches, and `inst.site.stock_report` does not.

---

### Task 5: Skip the model

**Files:**
- Modify: `servers/crates/mod_chat/src/stock_report.rs`
- Modify: `servers/crates/mod_chat/src/prompt/tool_loop.rs` (before the first `llm_stream_chain` when tools are non-empty)
- Modify: `servers/crates/mod_chat/src/tools/builtin/site_query.rs`
- Test: `servers/crates/mod_chat/src/stock_report.rs`

**Interfaces:**
- Consumes: `stock_report_parse`, `site_query_run`, `stock_report_from_query`, `report_pdf`, `report_xlsx`, `stock_report_blocks`, `cas_put`, `gsheet_replace_grid`
- Produces:
  - `pub async fn stock_report_prefetch(...) -> Option<ChatRes>`
  - `pub fn stock_report_llm_payload(report: &StockReport, files: &[Value]) -> Value`

- [ ] **Step 1: Write the payload test**

```rust
#[test]
fn llm_payload_has_no_rows() {
    let report = sample_movement_report(100);
    let v = stock_report_llm_payload(&report, &[]);
    assert!(v.get("rows").is_none());
    assert_eq!(v["row_count"], 100);
    let s = v.to_string();
    assert!(s.len() < 2000);
}
```

- [ ] **Step 2: Run it** so it fails, then implement.

- [ ] **Step 3: Prefetch**

In `tool_loop`, after tools are known and before hop 1, if `req` matched inst ids contain `inst.site.stock_report`:

1. `stock_report_parse(&req.user, Utc::now())`.
2. `None` → fall through to the normal hop (the inst matched a phrase but the parser rejected it).
3. Resolve site ids the same way as `site_query_run_exec` (`site_scope_pick`). Empty scope → return text `No site to report on.` and empty blocks. No model call.
4. Card with empty `q` and no product id → text `Which product?` and no model call.
5. `site_query_run` with params `{ q, time_from_ms, time_to_ms }`.
6. Build `StockReport`. Render only the requested formats. `cas_put` pdf (`application/pdf`, name `{kind}-{yyyymm}.pdf`) and xlsx (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).
7. Gsheet format: call `gsheet_replace_grid` when a sheet is bound for this caller; on `not_linked`, add that word to the text and still attach xlsx.
8. Return `ChatRes` with a fixed sentence: title, `row_count`, `qty_in`, `qty_out`, and `truncated` when set. `tokens_in` and `tokens_out` stay 0. `blocks_json` is the array from `stock_report_blocks`.

Do not push the row JSON into `contents`.

`site_query_run_exec`: when `stock_report_query_id(query_id)`, build the report, upload requested files from `params.formats` (default table only), return `stock_report_llm_payload` plus `block` keys the tool loop already appends. The `rows` field is omitted.

- [ ] **Step 4: Re-run**

Run: `cargo test -p c35_mod_chat -- stock_report -- --test-threads=8` then `cargo build -p server_ai`.

Expected: tests PASS, build succeeds.

---

### Task 6: Flutter preview card

**Files:**
- Create: `clients/app/lib/widgets/ai/ui_stock_report_card.dart`
- Modify: `clients/app/lib/widgets/ai/ui_msg_blocks.dart` (switch next to `presentation.deck`)
- Test: widget test only if a nearby block already has one; otherwise `flutter analyze` via the verify script is the check

**Interfaces:**
- Consumes: block `kind == site.stock_report` and body fields from task 2
- Produces: a card with title, `row_count`, in/out totals, and up to 40 rows. File and slide blocks keep their existing widgets.

- [ ] **Step 1: Render the card**

Read `body['headers']` and `body['rows']` as `List`. Show a horizontal `SingleChildScrollView` + `DataTable` or a column of rows. If `truncated == true`, a line under the table: `Showing 40 of {row_count}. Full rows are in the file.`

`default` in the switch must still return `SizedBox.shrink()` for unknown kinds.

- [ ] **Step 2: Verify**

Run: `.\_\scripts\dev\verify_flutter_app.ps1`

Expected: analyze clean for the new file.

---

### Task 7: Spec and a live compose check

**Files:**
- Modify: `_/specs/site-ai.md` query catalog table and a short “Stock reports” section
- Modify: `_/docs/site-ai.md` the same way (docs mirror)

- [ ] **Step 1: Document**

Add rows `tx.stock_list`, `tx.stock_card`, `tx.stock_movement`. State the caps, the compact LLM payload, the inst id, and that PDF / xlsx / slides / linked sheet are renderers of one report. State that `inst.site.report` remains profit and sales.

- [ ] **Step 2: prompt_compose**

Owner `33000`:

| Text | Expect |
|------|--------|
| `generate pdf report of all item in and out from january` | `inst.site.stock_report`, tool `site.query.run` |
| `berapa untung hari ini` | `inst.site.report`, not `inst.site.stock_report` |
| `berapa stok susu` | `inst.site.catalog.stock`, not `inst.site.stock_report` |

`prompt_run` on the January sentence is required before calling the feature fixed. Expect `tokens_in + tokens_out == 0` when the caller has no granted site (the no-site reply) or, with a seeded site, a `site.stock_report` block and no row dump in `text`.

- [ ] **Step 3: Encoding**

Run: `.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`

---

## Self-review

- Stock list, stock card, long in/out history, PDF, Excel, slides, and linked Google Sheet each have a task.
- Profit/sales reports and single-product `berapa stok` stay on their current insts (task 4 phrases, task 7 checks).
- Row bodies never enter the model (task 5).
- Grant check stays inside `site_query_run` (task 1 uses that entry).
- GL and personal expense are named as out of scope.
