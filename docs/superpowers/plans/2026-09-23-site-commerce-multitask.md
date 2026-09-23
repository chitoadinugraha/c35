# Site Commerce — POS, Multi-Site Context, Query Catalog

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Subagent model: **inherit** (not fast).

**Goal:** Close Phase 9 gaps — `mod_tx` server, id.alienai POS UI in Sites, multi-site `MentionContext`, readonly query catalog (`site.query.run`), commerce tools + `inst` seeds.

**Architecture:** Writes stay single-site per tool call. Reads/compare/reports use `QueryDef` registry + one LLM tool `site.query.run`. POS staff UI ports id.alienai `transaksi/` (not CSA staff board). Guest checkout borrows CSA HTTP glue on id.alienai schema.

**Docs (locked):** `_/docs/site-ai.md`, `_/docs/tx.md`, `_/docs/site.md`, `_/docs/chat.md`

**References:**

| Area | Path |
|------|------|
| POS UI + receipt | `E:\Project Archive\id.alienai\client_app\lib\page_project\bisnis\transaksi\` |
| Query defs | `E:\Project Archive\id.alienai\server\lib\project\bisnis\query\` |
| Guest order HTTP | `D:\csa_site_published\crates\mod_site_tx\` |

**Verify:** `cargo build -p server_ai`; `cargo test -p mod_chat` / `mod_site` / `mod_tx` when added; `flutter analyze` in `clients/app`.

---

## Multitask map

```
Wave 1 (parallel)
  Track 0  Proto + schema stubs (query wire, tool metadata)
  Track 1  MentionContext (server prompt + tool ctx)

Wave 2 (parallel, after Wave 1)
  Track 2  Tool compose filter (requires_kinds, capability)
  Track 3  mod_tx crate (ReqTxGet/List/Put/Preview/DebtPay)
  Track 4  mod_site_query + QueryDef registry + site.query.run RPC

Wave 3 (parallel, after Wave 2)
  Track 5  Query catalog seeds (product.*, tx.* summaries)
  Track 6  Commerce chat tools (site.tx.*) + wire_ws handlers
  Track 7  inst.sql seeds (commerce, compare, report)

Wave 4 (parallel, after Wave 3 wire stable)
  Track 8  Flutter POS — Orders tab + id.alienai transaksi editor port
  Track 9  Flutter receipt (pdf preview + print) port

Wave 5
  Track 10 Guest order HTTP (CSA patterns on tx.proto)
  Track 11 Tests + docs sync + full verify
```

| Track | Owner focus | Key files | Depends |
|-------|-------------|-----------|---------|
| **0** | Proto | `_/schemas/proto/c35/query.proto` or `site.proto` extend; `ToolDefinition` fields in Rust | — |
| **1** | MentionContext | `mention_registry.rs`, `site_resolve.rs`, `prompt_turn.rs`, `tools/context.rs` | — |
| **2** | Compose gating | `compose/mod.rs`, `tools/definition.rs`, `macros.rs` (`requires_kinds`, `requires_capability`) | 0, 1 |
| **3** | mod_tx | `servers/crates/mod_tx/`, apply `tx.sql`, row mappers from `tx.proto` | 0 |
| **4** | Query engine | `servers/crates/mod_site_query/` or `mod_site/src/query/`, `ReqSiteQueryRun` | 0, 1 |
| **5** | Query seeds | `tx.profit_summary`, `tx.sales_summary`, `product.list`, `product.stock_status` | 3, 4 |
| **6** | Tx + query tools | `tools/builtin/site_tx.rs`, `site_query.rs`, `wire_ws/session.rs` | 2, 3, 4 |
| **7** | inst seeds | `_/schemas/inst.sql` — `inst.site.commerce`, `inst.site.compare`, `inst.site.report` | — (can parallel Wave 2) |
| **8** | POS UI | `clients/app/lib/widgets/sites/tx/` port from id.alienai | 3, 6 |
| **9** | Receipt UI | `receipt/` port — `ui_receipt`, `receipt_pdf_generator` | 8 |
| **10** | Guest HTTP | `wire_http` guest order routes | 3 |
| **11** | QA | `mention_registry_test`, `compose_test`, integration tests | all |

---

## Status: IMPLEMENTED 2026-09-23

All tracks 0–10 shipped. Verify: `cargo build -p server_ai`, `cargo test -p c35_mod_tx -p c35_mod_site -p c35_mod_chat -p c35_wire_http`, `flutter analyze lib/widgets/sites`.

---

## Track 0 — Proto + tool metadata

- [x] **0.1** Add `ReqSiteQueryRun` / `ResSiteQueryRun` to proto; regenerate Dart + Rust
- [ ] **0.2** Extend `ToolDefinition`: `requires_kinds: Vec<String>`, `requires_capability: Option<String>`
- [ ] **0.3** Extend `tool!` macro to accept `requires_kinds`, `requires_capability`
- [ ] **0.4** Register `ReqTx*` / `ReqSiteQueryRun` in `wire.proto` if not present

---

## Track 1 — MentionContext

- [ ] **1.1** `MentionContext` struct: `sites`, `devices`, `default_site_iid`
- [ ] **1.2** `mention_context_build(resolved) -> MentionContext`
- [ ] **1.3** Replace single `site_ctx` in `prompt_turn.rs` with multi `[SITE CONTEXTS]` block
- [ ] **1.4** `ToolContext` → add `mention: MentionContext` (or `site_iids: Vec<i64>`)
- [ ] **1.5** `site_iid_resolve`: 1 site default; 2+ sites require arg
- [ ] **1.6** Tests: two site mentions → both in prompt; write without `site_iid` fails when ambiguous

---

## Track 2 — Compose filter

- [ ] **2.1** `tool_mention_eligible(def, &MentionContext)` in compose
- [ ] **2.2** `site_capability_check(site_iid, "commerce")` for commerce tools
- [ ] **2.3** Topic `site.commerce` in `mention_active_topic` when commerce inst matches
- [ ] **2.4** Centralize `mention_force_tools` registry (replace hardcoded if/else)
- [ ] **2.5** Register missing `site.contact_put` tool (inst already references it)

---

## Track 3 — mod_tx server

- [ ] **3.1** Crate `c35_mod_tx` — `tx_get`, `tx_list`, `tx_put`, `tx_preview`, `tx_debt_pay`
- [ ] **3.2** Grant check via `site_grant_check` on every `site_iid`
- [ ] **3.3** Child tables on full get/put (items, payments, acc, stock, tax, discount)
- [ ] **3.4** Sync collection `tx` header (+ children on full get per tx.md)
- [ ] **3.5** Unit tests: put sale → stock movement denorm

---

## Track 4 — Query engine

- [ ] **4.1** `QueryDef` trait + registry (`query_register!`)
- [ ] **4.2** `site_query_run(pool, caller, site_iids, query_id, params)` — grant per site
- [ ] **4.3** Chat tool `site.query.run` (`readonly: true`, `requires_kinds: ["site"]`)
- [ ] **4.4** Default `site_iids` from `MentionContext.sites` when arg empty

---

## Track 5 — Query catalog seeds

- [ ] **5.1** `product.list` — name, price, stock_qty per site
- [ ] **5.2** `product.stock_status` — low stock filter
- [ ] **5.3** `tx.sales_summary` — revenue by date range
- [ ] **5.4** `tx.profit_summary` — multi-site compare (port id.alienai P&L logic simplified)
- [ ] **5.5** Tests: caller without grant on site B → error

---

## Track 6 — Commerce write tools + wire

- [ ] **6.1** `site.tx.put`, `site.tx.preview`, `site.tx.debt_pay` tools (`topics: ["site.commerce"]`, `requires_capability: "commerce"`)
- [ ] **6.2** `wire_ws` handlers for `ReqTx*` and `ReqSiteQueryRun`
- [ ] **6.3** `SiteApi` / `ChatConn` Dart stubs for tx + query (client RPC)

---

## Track 7 — inst seeds

- [ ] **7.1** `inst.site.commerce` — topic steering for tx write tools
- [ ] **7.2** `inst.site.compare` — multi-site profit compare → `site.query.run`
- [ ] **7.3** `inst.site.report` — report phrases → `site.query.run`
- [ ] **7.4** Update `inst.web.builder` — clarify single-site writes vs query for analytics

---

## Track 8 — Flutter POS UI (id.alienai port)

**Yes — follow id.alienai, not CSA.**

- [ ] **8.1** Sites detail: **Orders** tab (`site.tx` UITable browse — date, type, contact, total, state)
- [ ] **8.2** Port `page_transaksi_edit.dart` → `ui_site_tx_editor.dart` (ledger: Items | Payments | Acc | Stock)
- [ ] **8.3** Port supporting: `transaksi_tx_build`, `transaksi_tx_map`, `section_transaksi_*`, payment/debt dialogs
- [ ] **8.4** Wire to `ReqTxGet` / `ReqTxPut` / `ReqTxPreview` via `SiteApi`
- [ ] **8.5** Contact picker → `site.contact`
- [ ] **8.6** `hint` navigate `site.pos` → Orders tab (already in hint.md)

Source map:

| id.alienai | c35 |
|------------|-----|
| `page_transaksi_edit.dart` | `widgets/sites/tx/ui_site_tx_editor.dart` |
| `section_transaksi_items.dart` | `widgets/sites/tx/section_tx_items.dart` |
| `ui_transaksi_save_menu.dart` | `widgets/sites/tx/ui_tx_save_menu.dart` |
| `transaksi_items_catalog.dart` | product picker from `site.product` |

---

## Track 9 — Receipt (id.alienai port)

- [ ] **9.1** Port `ui_receipt.dart`, `receipt_pdf_generator.dart`, `receipt_pdf_preview.dart`
- [ ] **9.2** Port `receipt_config` / project receipt settings → `site.config` or site-scoped JSON
- [ ] **9.3** Print action from tx editor save menu
- [ ] **9.4** `page_transaksi_nota` flow if separate nota view needed

---

## Track 10 — Guest checkout HTTP

- [ ] **10.1** `ReqSiteGuestOrderPut` / `Get` on api host (CSA finalizer patterns)
- [ ] **10.2** Stock + payment finalizer hooks
- [ ] **10.3** Integration test: guest order → `site.tx` row

---

## Track 11 — Verify

- [ ] **11.1** `cargo build -p server_ai`
- [ ] **11.2** `cargo test -p mod_chat -p mod_tx` (new tests)
- [ ] **11.3** `flutter analyze`
- [ ] **11.4** Manual: `@site1 @site2 compare profit` → `site.query.run` with both iids
- [ ] **11.5** Manual: single `@site` → `site.product_put` default site works

---

## POS UI decision (locked)

| Use | Don't use |
|-----|-----------|
| id.alienai `transaksi/` editor + receipt | CSA `ui_staff_tx_board` |
| Sites → Orders tab + ledger detail | CSA 3-pane staff chrome |
| `site_iid` replaces id.alienai `aid` | CSA `mod_site_tx` data model wholesale |

Guest-facing shop blocks stay in SiteDoc; staff POS is Flutter Sites detail only.
