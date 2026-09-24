# Site AI — mentions, tools, queries (LOCKED)

Status: **locked** 2026-09-23

How the Home assistant operates on **Sites**: `@mention` scoping, multi-site context, write tools vs read queries, and `inst` steering.

Related: [site.md](site.md) (schema + UITable), [tx.md](tx.md) (POS), [inst.md](inst.md), [chat.md](chat.md), [hint.md](hint.md).

---

## Principles

| Rule | Detail |
|------|--------|
| **Mention = scope** | `@site` resolves `site_iid`(s) + activates site topics/tools |
| **Writes = one site per call** | `site.product_put`, `site.tx.put`, … — single `site_iid`; never batch-mutate across sites |
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

### Write default rule

| `sites.len()` | `site_iid` in tool args | Behavior |
|---------------|-------------------------|----------|
| 0 | required | Error: mention site or pass `site_iid` |
| 1 | optional | Default to `default_site_iid` |
| 2+ | required | Error if omitted — ambiguous write |

Compare / report turns use **all** `site_iids` from context via `site.query.run`.

---

## Topics

| Topic | When active | Write tools | Read tools |
|-------|-------------|-------------|------------|
| `web.builder` | `@site` (layout/catalog) | `site.draft_put`, `site.publish`, `site.product_put`, `site.contact_put`, `site.object_put` | `site.collection.list` (optional) |
| `site.commerce` | `@site` + `commerce` capability, or tx/report phrases | `site.tx.put`, `site.tx.preview`, `site.tx.debt_pay` | `site.query.run` |
| `general` | no mention | — | global readonly only |

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

**Do not** add multi-site variants per tool (e.g. `stock.check` × N sites). Multi-site reads go through `site.query.run`.

### Naming

```
site.<domain>.<verb>

site.draft.put
site.product.put
site.tx.put
site.tx.preview
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
  repeated int64 site_iids = 2;   // empty → all sites from MentionContext
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

---

## What we do **not** do

- Raw `SELECT` tool for the LLM
- Multi-site write tools (`site.product_put` across `[111, 222]`)
- Per-tool multi-site array responses (`stock.check` returning N site blobs)
- CSA staff POS board UI — POS editor is **id.alienai** (see [tx.md](tx.md))

---

## Implementation map

Multitask plan: [`plans/2026-09-23-site-commerce-multitask.md`](plans/2026-09-23-site-commerce-multitask.md).
