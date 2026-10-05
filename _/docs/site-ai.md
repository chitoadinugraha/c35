# Site AI — mentions, tools, queries (LOCKED)

Status: **locked** 2026-10-03

How the Home assistant operates on **Sites**: `@mention` scoping, unmentioned multi-site reads, write disambiguation, and `inst` steering.

Related: [site.md](site.md) (schema + UITable), [tx.md](tx.md) (POS), [inst.md](inst.md), [chat.md](chat.md), [mention.md](mention.md) (bracket text + `mention_ids[]`), [hint.md](hint.md).

---

## Principles

| Rule | Detail |
|------|--------|
| **Mention = scope** | One or more `@site` mentions limit every site read and write to those sites |
| **No mention = all granted sites** | Reads aggregate. Writes proceed only when the target (usually a product name) matches exactly one granted site |
| **Writes = one site per call** | `site.product.patch`, `site.tx.put`, … — single `site_iid`; never batch-mutate across sites |
| **Do not invent a mention** | Product resolution must not write `mention_ids` or `sticky_mention_ids` |
| **Reads / compare / reports = query catalog** | One readonly tool `site.query.run` + registered `QueryDef`s — not raw SQL to the LLM |
| **No LLM SQL** | Server runs parameterized SQL inside query defs; grant-check every `site_iid` |
| **Money/stock** | Tx API / query defs only — never free-form JSON on checkout paths |

Reference for query catalog shape: `E:\Project Archive\id.alienai` (`ca/query`, `lib/project/bisnis/query`).

---

## Multi-site `MentionContext`

Composer may attach **multiple** mention refs per turn (`mention_ids[]`). Server builds:

```rust
MentionContext {
    sites: Vec<SiteContext>,       // all resolved @site identities (order preserved)
    devices: Vec<i64>,             // remote / iot
    bots: Vec<i64>,                // bot identities (future)
    default_site_iid: Option<i64>, // Some only when sites.len() == 1
}
```

### Prompt blocks

```
[MENTION TARGETS]
- Warung A (ref=iid:111, iid=111, topic=web.builder)
- Warung B (ref=iid:222, iid=222, topic=web.builder)

[SITE CONTEXTS]
- site_iid=111 alien_id=warung-a name=Warung A
- site_iid=222 alien_id=warung-b name=Warung B
```

Replace single `[SITE CONTEXT]` (one site) with `[SITE CONTEXTS]` when `sites.len() > 0`.

### Site scope

Scope is the set of sites a turn may touch. The server computes it. The model does not pick a hidden default site.

| User mentions | Scope |
|---------------|--------|
| One `@site` | That site |
| Two or more `@site` | Those sites only |
| None | Every site the caller owns or has a staff grant on |

`default_site_iid` stays set only when the mention list has exactly one site. An empty mention list does not invent one.

### Reads

`site.query.run` with `site_iids` omitted uses the scope above.

| Scope | Result |
|-------|--------|
| Mentioned sites | Rows for those sites |
| No mention | Rows for every granted site, each tagged with `site_iid` + `site_name` |

Answer from the rows. A product that exists on two sites is two lines (Warung A: 5, Warung B: 10). A product that exists on one site is that site only.

### Writes

One site per call. Never update every match.

| Scope | Product / target match | Behavior |
|-------|------------------------|----------|
| One mentioned site | — | Write on `default_site_iid` |
| Mentioned set, or all granted sites | Exactly one site | Write on that site |
| Mentioned set, or all granted sites | Zero sites | Error: not found in scope |
| Mentioned set, or all granted sites | Two or more sites | Do not write. Return `ambiguous: true` plus each site name and current value. The model asks which site |

A caller with a single granted site and no mention is the "exactly one site" row: change the price there.

Passing an explicit `site_iid` still wins, after the same grant check, and must be inside the mentioned set when mentions exist.

Layout tools (`site.draft_put`, `site.publish`, `site.domain_*`) stay mention-gated. Homepage and domain edits are one site and are not a product lookup.

---

## Topics

| Topic | When active | Write tools | Read tools |
|-------|-------------|-------------|------------|
| `web.builder` | `@site` (layout/catalog/domains) | `site.draft_put`, `site.publish`, `site.product_put`, `site.contact_put`, `site.object_put`, `site.domain_put`, `site.domain_verify` | `site.draft_get`, `site.collection.list` |
| `site.commerce` | `@site` + `commerce` capability, or tx/report phrases | `site.tx.put`, `site.tx.preview`, `site.tx.debt_pay`, `site.order_status` | `site.query.run`, `site.tx.list` |
| `general` | no `@site` | catalog writes only when a product name matches one granted site (`site.product.patch`) | `site.query.run` when a catalog/report inst matches |

`mention_active_topic`: first non-general resolved topic; commerce phrases may promote to `site.commerce` via `inst` task rows.

Capability gate: `site.config.capabilities_json.commerce = true` (see [hint.md](hint.md) POS chip).

---

## Tool metadata

Extend `ToolDefinition` (see [inst.md](inst.md) triggers):

| Field | Purpose |
|-------|---------|
| `topics` | Intent filter when topic active |
| `always` | Force-include when topic matches (skip RAG gap) |
| `readonly` | Allowed in `tool_mode = ask` |
| `requires_kinds` | Hard gate: `["site"]`, `["device"]`, … — only when mention resolves that kind |
| `requires_capability` | e.g. `"commerce"` on site config |
| `requires_global_roles` | Staff badge OR-gate (`partner`, `director`, `finance`, …); `is_root` passes all |

**Do not** add a general-topic twin (`stock.check`, `product.find`, …). Multi-site reads stay on `site.query.run`. Price and stock edits stay on `site.product.patch`.

`tool_include` only injects a tool that already passed the mention gate. `requires_kinds: ["site"]` removes `site.query.run` before inst can add it, so those catalog tools cannot keep that gate.

- Clear `requires_kinds` on `site.query.run` and `site.product.patch`.
- Drop `general` from their `topics`, so a normal chat does not RAG them in.
- `inst` `tool_include` injects them. Force-include bypasses the topic filter. It does not bypass the mention gate.
- Keep `requires_kinds: ["site"]` on layout and domain tools.

### Naming

```
site.<domain>.<verb>

site.draft.put
site.draft.get          readonly (inspect current SiteDoc blocks/theme)
site.publish
site.product.put
site.product.patch
site.domain.put         (attach custom hostname)
site.domain.verify      (check CNAME/apex DNS propagation)
site.tx.put
site.tx.preview
site.order.status       (shorthand order state update)
site.query.run          readonly
site.collection.list    readonly (optional thin list API)
```

---

## Query catalog (`site.query.run`)

### Wire (proto)

Add to [`../schemas/proto/c35/site.proto`](../schemas/proto/c35/site.proto) or `query.proto`:

```protobuf
message ReqSiteQueryRun {
  string query_id = 1;
  repeated int64 site_iids = 2;   // empty → site scope (mentions, else all granted sites)
  string params_json = 3;         // validated per QueryDef
}

message ResSiteQueryRun {
  repeated SiteQueryRow rows = 1;
  string result_json = 2;         // optional structured blob
}

message SiteQueryRow {
  int64 site_iid = 1;
  string site_name = 2;
  map<string, string> cells = 3;
}
```

### `QueryDef` (server registry)

```rust
QueryDef {
  id: "tx.profit_summary",           // stable id
  label: "Profit summary",
  site_scoped: true,                 // inject site_iid IN (...)
  readonly: true,
  params_schema: ...,                // JSON Schema fragment
  run: fn(pool, caller_iid, site_iids, params) -> rows,
}
```

Grant: for each `site_iid`, same check as `site_grant_check` (owner or staff grant).

### Seed queries (Phase 9 minimum)

| `query_id` | Purpose |
|------------|---------|
| `product.list` | Catalog rows (name, price, stock) per site |
| `product.stock` | One product by `q` (name / sku) or `product_id`, one row per matching site |
| `product.stock_status` | Low stock / qty snapshot |
| `tx.sales_summary` | Revenue by period |
| `tx.profit_summary` | Profit compare (multi-site) |

Port SQL ideas from id.alienai `tx.acc_profit_loss` / CSA `mod_site_tx` reports — implement as defs, not LLM SQL.

### Compare flow

User: `compare @warung-a @warung-b which is more profitable?`

1. `MentionContext.sites` = [A, B]
2. `inst.site.compare` → `tool_include:site.query.run`
3. Model calls `site.query.run { query_id: "tx.profit_summary", site_iids: [111, 222], params: { range: "this_month" } }`
4. Model summarizes rows side-by-side

---

## `inst` seeds (add to `inst.sql`)

| id | kind | triggers |
|----|------|----------|
| `inst.web.builder` | mention | existing layout/catalog tools |
| `inst.site.commerce` | topic | `site.tx.*` write tools when commerce |
| `inst.site.compare` | task | `tool_include:site.query.run` — phrases: compare, lebih untung, which is more profitable |
| `inst.site.report` | task | `tool_include:site.query.run` — laporan, report, sales today |
| `inst.site.catalog` | task | `tool_include:site.query.run` — stock, stok, harga, price, product lookup. On price-change phrases also `tool_include:site.product.patch` |

`inst.site.catalog` tells the model how to talk. It does not choose a site.

- Stock: call `site.query.run` with `query_id: product.stock` and `params.q`. Omit `site_iids`. Summarize every returned row by site name. No web search.
- Price read: catalog first. Web search only when the catalog has no row.
- Price vs market: catalog and web search both run. See below.
- Price change: call `site.product.patch` with the product name and the new price. Omit `site_iid`. If the tool returns `ambiguous: true`, ask which site and wait for an `@site` (or a site name that resolves to one). Do not guess.

### Price read, market compare, then web search

`harga` / `price` already match `inst.web_search`. That inst force-includes `web.search`, and the tool loop **runs `web.search` before the first model hop** (`prompt/tool_loop.rs`). Catalog still goes first so the store price is known before any search.

Two price intents:

| Intent | Phrases (examples) | After `product.stock` |
|--------|--------------------|------------------------|
| Lookup | berapa harga, how much is, price of | Rows exist → answer those site prices. Web search stays off. No rows → web search |
| Vs market | reasonable, kemahalan, harga pasaran, compare to the web, too expensive, my price | Rows exist → then `web.search` for the same product, and answer with both. No rows → web search only, and say it is not in the stores |

```
caller has no granted site
  → today's web.search prefetch

caller has a site (mention set, or all granted sites)
  → do not prefetch web.search
  → first hop: site.query.run { query_id: product.stock, params.q = product name }
  → lookup + rows: answer per site. Leave web.search out
  → vs market + rows: run web.search, then compare store price to the web price
  → no rows: run web.search
```

The model picks `q` (the product name, not the whole sentence). The server decides the scope, and whether this turn is lookup or vs-market, from the matched inst. Vs-market is a phrase on `inst.site.catalog` (or a sibling inst), not a guess after the catalog hits.

Stock questions stop at the catalog. An empty stock lookup says the product is not in those stores.

### Examples

Stock, no mention, product on two sites:

```text
User: how much stock product A?
Tool: site.query.run { query_id: "product.stock", params: { q: "product A" } }
Rows: Warung A stock_qty=5, Warung B stock_qty=10
Reply: Warung A: 5, Warung B: 10
```

Price change, no mention, one granted site (or the name exists on one site):

```text
User: change price of product A to 10000
Tool: site.product.patch { q: "product A", price: 10000 }
Result: updated on Warung A
```

Price change, name on two sites:

```text
User: change price of product A to 10000
Tool: site.product.patch → { ambiguous: true, matches: [Warung A, Warung B] }
Reply: which site? (no UPDATE)
User: [@iid:111]
Tool: site.product.patch on site 111
```

Mentioned pair:

```text
User: stock of product A on [@iid:111] [@iid:222]
Scope: 111 and 222 only — other stores are out
```

Price vs market:

```text
User: is my Indomie price reasonable?
Tool: site.query.run { query_id: "product.stock", params: { q: "Indomie" } }
Rows: Warung A price=3500
Tool: web.search { query: "harga Indomie" }
Reply: Warung A sells it at 3500. Web listings are around …, so that price is …
```

---

## What we do **not** do

- Raw `SELECT` tool for the LLM
- Multi-site write tools (`site.product.patch` across `[111, 222]` in one call)
- A new general-topic tool that duplicates `site.query.run` / `site.product.patch`
- Auto-inserting an `@site` mention when the user did not name a site
- Letting inst text be the only guard on an ambiguous price change
- CSA staff POS board UI — POS editor is **id.alienai** (see [tx.md](tx.md))

---

## Current code vs this contract

Shipped (see the implementation map):

- `site.query.run` has no `requires_kinds` site gate. Empty `site_iids` uses `site_scope_pick` (mentions, else `site_granted_iids`). Empty scope returns no rows.
- `site.product.patch` accepts `q` or `name` without a mention. A unique match writes. Two or more sites, or two or more products, return `{ "ok": false, "ambiguous": true }` and do not `UPDATE`.
- Inst seeds: `inst.site.catalog.stock`, `inst.site.catalog.price`, `inst.site.price_compare`, `inst.site.catalog.write`.
- `catalog_web.rs` skips the `web.search` prefetch when those catalog insts match and the caller has a site. Price lookup searches the web only when `product.stock` returns no rows. Price compare searches after the store rows. Stock never searches. Write skips the prefetch.

---

## Implementation map

Multitask plan: [`plans/2026-10-03-site-catalog-scope.md`](plans/2026-10-03-site-catalog-scope.md). Commerce baseline: [`plans/2026-09-23-site-commerce-multitask.md`](plans/2026-09-23-site-commerce-multitask.md).
