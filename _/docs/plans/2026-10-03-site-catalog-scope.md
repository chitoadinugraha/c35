# Site catalog scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unmentioned site reads aggregate every granted site, a unique product match may be written, and a price question uses the store catalog before the web — including a market comparison when the user asks if their price is reasonable.

**Architecture:** One scope helper fills `site.query.run` and `site.product.patch`. Inst rows steer which tool the model calls. A small phase enum, keyed by those inst ids, stops `web.search` from running before the catalog and turns it back on only for an empty price lookup or a vs-market question. No new tool. No invented `@site` mention.

**Tech Stack:** Rust (`c35_mod_site`, `c35_mod_chat`), `ai.inst` seeds in `_/schemas/inst.sql`.

**Spec:** [`_/docs/site-ai.md`](../site-ai.md) (locked 2026-10-03), [`_/docs/inst.md`](../inst.md), [`_/docs/mention.md`](../mention.md).

## Global Constraints

- Mentioned sites are the whole scope. No mention means every site the caller owns or holds a staff-or-higher grant on.
- Writes stay one site per call. Two or more matching sites return `{ "ok": false, "ambiguous": true, "matches": [...] }` and do not `UPDATE`.
- Do not write `mention_ids` or `sticky_mention_ids`.
- Layout tools (`site.draft_put`, `site.publish`, `site.domain_*`) keep `requires_kinds: ["site"]`.
- Spoken steering lives in `ai.inst` only. Rust may branch on inst ids the way `compose_force_tool_call` already branches on `inst.web_search`. Do not add a new system-prompt paragraph in `tool_loop.rs`.
- Stock never falls through to `web.search`.
- Price lookup searches the web only when `product.stock` returns no rows.
- Vs-market (reasonable, kemahalan, harga pasaran) runs `web.search` after the store rows, even when rows exist.
- Do not commit unless the user asks.
- Verify from `servers/`: `cargo test -p c35_mod_chat -- catalog_web site_scope product_match` and `cargo build -p server_ai`.

## Multitask Map

```
Track 1 (scope pick + granted iids) ──┬──► Track 2 (site.query.run)
                                      └──► Track 3 (site.product.patch)

Track 4 (inst seeds) ──► Track 5 (catalog web phase + tool loop)
Track 2 + Track 5 ──► Track 6 (docs + prompt_compose)
```

| Track | Focus | Depends |
|-------|--------|---------|
| 1 | Pure scope pick + `site_granted_iids` | — |
| 2 | `site.query.run` uses scope; drop site mention gate | 1 |
| 3 | Patch unique-or-ambiguous across scope | 1 |
| 4 | Three inst rows | — |
| 5 | Skip web prefetch; resume web only for the two price cases | 4 |
| 6 | Mark the contract table done; `prompt_compose` | 2, 5 |

Wave 1 is Track 1 and Track 4 in parallel. Wave 2 is Track 2, Track 3, and Track 5 (Track 5 only needs the inst id strings, which Track 4 defines below). Wave 3 is Track 6.

---

### Task 1: Site scope pick

**Files:**
- Create: `servers/crates/mod_chat/src/site_scope.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` (pub use the new module next to `mention_context`)
- Modify: `servers/crates/mod_site/src/grant.rs`
- Modify: `servers/crates/mod_site/src/lib.rs` (`pub use grant::site_granted_iids`)
- Test: `servers/crates/mod_chat/src/site_scope.rs` (`mod tests`)

**Interfaces:**
- Consumes: nothing
- Produces:
  - `pub fn site_scope_pick(mentioned: &[i64], granted: &[i64], arg_iids: &[i64]) -> Result<Vec<i64>, String>`
  - `pub async fn site_granted_iids(pool: &PgPool, caller_iid: i64) -> Result<Vec<i64>>`

`site_scope_pick` rules, in order:

1. `arg_iids` non-empty: each id must be in `mentioned` when `mentioned` is non-empty. Return `arg_iids` deduped, order preserved. Error string: `site_iid is outside the mentioned sites`.
2. `mentioned` non-empty: return `mentioned`.
3. Return `granted`.

Empty `granted` is `Ok(vec![])`, not an error. Callers treat that as "no store".

- [ ] **Step 1: Write the failing tests**

```rust
#[test]
fn site_scope_pick_mentioned_ignores_other_grants() {
    let mentioned = [111_i64];
    let granted = [111, 222];
    assert_eq!(site_scope_pick(&mentioned, &granted, &[]).unwrap(), vec![111]);
}

#[test]
fn site_scope_pick_no_mention_uses_all_granted() {
    assert_eq!(site_scope_pick(&[], &[111, 222], &[]).unwrap(), vec![111, 222]);
}

#[test]
fn site_scope_pick_arg_outside_mention_errors() {
    let err = site_scope_pick(&[111], &[111, 222], &[222]).unwrap_err();
    assert!(err.contains("outside the mentioned sites"));
}

#[test]
fn site_scope_pick_empty_is_ok() {
    assert_eq!(site_scope_pick(&[], &[], &[]).unwrap(), Vec::<i64>::new());
}
```

- [ ] **Step 2: Run the tests**

```powershell
cd servers
cargo test -p c35_mod_chat site_scope_pick -- --nocapture
```

Expected: fail to compile (`site_scope_pick` not found).

- [ ] **Step 3: Implement**

`site_scope.rs` holds the function above. Dedup with the same fold used in `mention_context.rs` `device_iids_collect`.

`site_granted_iids` in `grant.rs` — same visibility as `site_list` (owner or any non-deleted grant), excluding archived grants:

```sql
SELECT i.id
FROM ai.identity i
LEFT JOIN ai.identity_grant g
  ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
WHERE i.kind = 'site' AND i.deleted_ts IS NULL
  AND (i.owner_iid = $1 OR g.grantee_iid IS NOT NULL)
  AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0
ORDER BY i.id
```

Owners with no grant row still match `i.owner_iid = $1`. Do not filter those out because `g.meta` is null: the archived predicate must be `g.meta IS NULL OR COALESCE(...) = 0`.

- [ ] **Step 4: Re-run the four tests. Expected: pass.**

---

### Task 2: `site.query.run` uses the scope

**Files:**
- Modify: `servers/crates/mod_chat/src/tools/builtin/site_query.rs` (`site_iids_resolve`, tool `requires_kinds`, `topics`, description)
- Test: `servers/crates/mod_chat/src/site_scope.rs` already covers pick. Add a unit test only if resolve grows a second branch.

**Interfaces:**
- Consumes: `site_scope_pick`, `site_granted_iids`
- Produces: async `site_iids_resolve(ctx, args) -> Result<Vec<i64>>` used by `site_query_run_exec`

- [ ] **Step 1: Change the resolver**

Replace the bail at the bottom of `site_iids_resolve` (`site_iids required — mention @site or pass site_iids`):

```rust
async fn site_iids_resolve(ctx: &ToolContext, args: &Value) -> Result<Vec<i64>> {
    let arg_iids = args_site_iids(args); // existing array parse; empty if omitted
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() && arg_iids.is_empty() {
        c35_mod_site::site_granted_iids(&ctx.pool, ctx.owner_iid).await?
    } else {
        Vec::new()
    };
    let ids = site_scope_pick(&mentioned, &granted, &arg_iids)
        .map_err(|e| anyhow!(e))?;
    Ok(ids)
}
```

`site_query_run_exec` already passes the vec into `site_query_run`. An empty vec makes `product.stock` return no rows (`query/product.rs` returns early). That empty result is the price-lookup signal for Track 5. Do not error.

- [ ] **Step 2: Tool metadata**

In the `tool!` block for `SiteQueryRunTool`:

- Delete `requires_kinds: ["site"]`.
- Set `topics: ["site.commerce", "web.builder"]` (drop `general`, so RAG on a normal chat does not feed it).
- Description: `Readonly site query. Omit site_iids to use @mentioned sites, or every site the caller can access when nothing is mentioned. product.stock params.q matches name, sku, or category.`

`compose_inject_force_tools` still injects this tool when inst `tool_include`s it, because force-include bypasses the topic filter and the mention gate is now open.

- [ ] **Step 3: Build**

```powershell
cd servers
cargo test -p c35_mod_chat site_scope_pick -- --nocapture
cargo build -p server_ai
```

Expected: tests pass, build succeeds.

---

### Task 3: `site.product.patch` unique or ambiguous

**Files:**
- Create: `servers/crates/mod_chat/src/site_product_match.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs` (mod declaration)
- Modify: `servers/crates/mod_chat/src/tools/builtin/site.rs` (`site_product_patch_exec`, tool metadata)
- Test: `servers/crates/mod_chat/src/site_product_match.rs`

**Interfaces:**
- Consumes: `site_scope_pick`, `site_granted_iids`, existing `site_iid_resolve` for the single-site path
- Produces:

```rust
pub struct ProductHit {
    pub site_iid: i64,
    pub product_id: i64,
    pub name: String,
    pub price: i64,
}

pub enum ProductMatch {
    None,
    One(ProductHit),
    Many(Vec<ProductHit>),
}

pub fn product_match_classify(hits: Vec<ProductHit>) -> ProductMatch
```

`One` only when every hit shares one `site_iid` and there is exactly one hit. Two products on one site is `Many`. Two sites is `Many`.

- [ ] **Step 1: Failing tests**

```rust
#[test]
fn product_match_one_site_one_row() {
    let hit = ProductHit { site_iid: 1, product_id: 9, name: "A".into(), price: 10000 };
    assert!(matches!(product_match_classify(vec![hit]), ProductMatch::One(_)));
}

#[test]
fn product_match_two_sites_is_many() {
    let hits = vec![
        ProductHit { site_iid: 1, product_id: 9, name: "A".into(), price: 10000 },
        ProductHit { site_iid: 2, product_id: 8, name: "A".into(), price: 12000 },
    ];
    assert!(matches!(product_match_classify(hits), ProductMatch::Many(_)));
}

#[test]
fn product_match_two_rows_one_site_is_many() {
    let hits = vec![
        ProductHit { site_iid: 1, product_id: 9, name: "A".into(), price: 10000 },
        ProductHit { site_iid: 1, product_id: 10, name: "A besar".into(), price: 11000 },
    ];
    assert!(matches!(product_match_classify(hits), ProductMatch::Many(_)));
}
```

- [ ] **Step 2: Run `cargo test -p c35_mod_chat product_match_ -- --nocapture`. Expected: compile fail.**

- [ ] **Step 3: Implement classify, then the exec branch**

Lookup SQL, bound to the scope iids and the name (`name` arg, or `q` if `name` is absent). Case-insensitive contains, same predicate as `product.stock`:

```sql
SELECT p.site_iid, p.product_id, p.name, p.price, i.name AS site_name
FROM site.product p
JOIN ai.identity i ON i.id = p.site_iid
WHERE p.site_iid = ANY($1)
  AND p.deleted_ts IS NULL AND p.is_archived = false
  AND (p.name ILIKE ('%' || $2 || '%') OR p.sku ILIKE ('%' || $2 || '%'))
ORDER BY p.site_iid, p.product_id
LIMIT 20
```

`site_product_patch_exec` order:

1. Explicit `site_iid`, or exactly one mentioned site (`site_iid_resolve` already does this): keep today's update path, including lookup by `product_id` or exact `name` on that one site.
2. Otherwise resolve scope with `site_scope_pick` + `site_granted_iids`. Require `name` or `q`. Classify hits.
3. `None` → `bail!("product not found")`.
4. `Many` → return JSON, no `UPDATE`:

```json
{ "ok": false, "ambiguous": true, "matches": [ { "site_iid": 1, "site_name": "Warung A", "product_id": 9, "name": "A", "price": 10000 } ] }
```

5. `One` → call the existing update using that `site_iid` and `product_id`.

Do not insert mentions.

Tool metadata: delete `requires_kinds: ["site"]`. Topics stay `site.commerce` and `web.builder` (drop `general`). Add optional `q` parameter, described as an alias of `name`. Description adds: `When site_iid is omitted and several sites match, returns ambiguous and does not write.`

- [ ] **Step 4: Re-run `product_match_` tests and `cargo build -p server_ai`.**

---

### Task 4: Inst seeds

**Files:**
- Modify: `_/schemas/inst.sql` (append three rows after `inst.site.report`)
- Modify: `_/docs/inst.md` phrase table (ids below; remove "not seeded yet" when Track 6 runs)
- Test: `servers/crates/mod_chat/tests/compose_test.rs`

**Interfaces:**
- Consumes: tool names `site.query.run`, `site.product.patch`, `web.search`
- Produces: inst ids `inst.site.catalog.stock`, `inst.site.catalog.price`, `inst.site.price_compare`, `inst.site.catalog.write`

Priority: write `140`, price_compare `135`, price `130`, stock `128`. `inst.web_search` stays at `100`, so these bodies are ordered with it, not instead of deleting `harga` from `inst.web_search`.

Bodies (single line, prefix tag):

- `inst.site.catalog.stock` — `[SITE.CATALOG.STOCK] Call site.query.run query_id product.stock with params.q set to the product name. Omit site_iids. Answer each row as site name and stock. Do not call web.search.`
  Phrases: `stok`, `stock`, `sisa barang`.
  `include_tools`: `site.query.run`. Also `triggers`: `tool_include:site.query.run`.
  `topics`: `{web.builder,site.commerce,general}`.

- `inst.site.catalog.price` — `[SITE.CATALOG.PRICE] Call site.query.run query_id product.stock with params.q set to the product name. Omit site_iids. If rows come back, answer each site name and price. Do not call web.search when rows exist. If rows are empty, the server will search the web.`
  Phrases: `harga`, `price`, `berapa harga`, `how much is`.
  `include_tools`: `site.query.run`.

- `inst.site.price_compare` — `[SITE.PRICE.COMPARE] Call site.query.run query_id product.stock first (params.q = product name, omit site_iids). Then the server searches the web for the same product. Answer with the store price and the web price. Say the product is not in the stores when the catalog is empty.`
  Phrases: `reasonable`, `kemahalan`, `harga pasaran`, `too expensive`, `my price`, `harga saya`, `compare to the web`, `bandingkan harga`.
  `include_tools`: `site.query.run`.

- `inst.site.catalog.write` — `[SITE.CATALOG.WRITE] Call site.product.patch with q or name and the new field. Omit site_iid. If the tool returns ambiguous true, ask which site. Do not pick a site. Do not call web.search.`
  Phrases: `ubah harga`, `ganti harga`, `change price`, `set price`, `update price`, `ubah stok`, `change stock`.
  `include_tools`: `site.product.patch`. `exclude_tools`: `web.search`, `web.visit` (a price-change sentence still contains `harga`, which would otherwise leave web search in the tool list).

`scope` `global`, `kind` `task`, `topic_id` `''`, `def_hash` `seed`. `ON CONFLICT DO UPDATE` the inst, phrases, triggers, include_tools, topics, priority.

Bare `harga` stays on `inst.web_search`. Track 5 suppresses the prefetch; this seed does not delete that phrase.

- [ ] **Step 1: Compose test**

Build fixture `InstRow`s for `inst.site.catalog.price` (`include_tools: ["site.query.run"]`, phrases containing `harga`) and a `ToolDef` named `site.query.run` with `topics: ["site.commerce", "web.builder"]`, `requires_kinds: []`.

```rust
#[test]
fn compose_price_phrase_includes_site_query_without_mention() {
    let mention = MentionContext::empty();
    let out = compose_tools_and_inst(
        &[inst_site_catalog_price(), inst_web_search_fixture()],
        "berapa harga indomie",
        &[site_query_tool(), web_search_tool()],
        &["general"],
        &[],
        &[],
        "agent",
        &[],
        &inst_scopes_home(),
        &mention,
        &SiteCapabilityView::empty(),
        ComposeTurnOpts::default(),
    );
    assert!(out.matched_ids.iter().any(|id| id == "inst.site.catalog.price"));
    assert!(out.tools.iter().any(|t| t.name == "site.query.run"));
}
```

Copy the `compose_tools_and_inst` argument order from `compose_mention_image_high_matched` in the same file. `inst_web_search_fixture` is a local `InstRow` with id `inst.web_search`, phrase `harga`, `include_tools: ["web.search"]`.

- [ ] **Step 2: Run that test. Expected: fail until the fixture rows exist in the test (the test constructs rows in-process; it does not read SQL). Implement the fixture helpers and confirm pass.**

The SQL seed is still required so production compose sees the same ids. The test does not load `inst.sql`.

- [ ] **Step 3: Append the four `INSERT`s to `inst.sql`.**

---

### Task 5: Catalog before web

**Files:**
- Create: `servers/crates/mod_chat/src/catalog_web.rs`
- Modify: `servers/crates/mod_chat/src/lib.rs`
- Modify: `servers/crates/mod_chat/src/compose/mod.rs` (`compose_force_tool_call` callers stay; add phase next to it)
- Modify: `servers/crates/mod_chat/src/prompt/mod.rs` (`ChatReq.catalog_web`)
- Modify: `servers/crates/mod_chat/src/prompt/tool_loop.rs` (prefetch guard + after-tool resume)
- Modify: `servers/crates/mod_chat/src/prompt_turn.rs` and `channel_prompt_turn.rs` (set the field)
- Test: `servers/crates/mod_chat/src/catalog_web.rs`

**Interfaces:**
- Consumes: inst ids from Task 4. `site_granted_iids` or `mention.sites` to set `has_site`.
- Produces:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum CatalogWebPhase {
    #[default]
    Off,
    Stock,
    PriceLookup,
    PriceCompare,
}

pub fn catalog_web_phase(matched_ids: &[String], has_site: bool) -> CatalogWebPhase

pub fn catalog_web_after_stock(phase: CatalogWebPhase, row_count: usize) -> bool
```

`catalog_web_phase`:

- `has_site == false` → `Off` (unless write is matched: still `Off` for the web phase; the write tool is included by inst)
- id `inst.site.price_compare` present, and write is not → `PriceCompare`
- id `inst.site.catalog.price` present, and write is not → `PriceLookup`
- id `inst.site.catalog.stock` present, and write is not → `Stock`
- else `Off`

Check write before compare. "ubah harga" matches write, price, and `inst.web_search` together. Write wins, phase stays `Off`.

```rust
pub fn catalog_skip_web_prefetch(matched_ids: &[String], phase: CatalogWebPhase) -> bool {
    phase != CatalogWebPhase::Off
        || matched_ids.iter().any(|id| id == "inst.site.catalog.write")
}
```

`catalog_web_after_stock` is true only for `PriceLookup` with `row_count == 0`, or `PriceCompare` with any count. Write never reaches it.

- [ ] **Step 1: Tests**

```rust
#[test]
fn catalog_web_no_site_stays_off() {
    let ids = vec!["inst.site.catalog.price".into(), "inst.web_search".into()];
    assert_eq!(catalog_web_phase(&ids, false), CatalogWebPhase::Off);
}

#[test]
fn catalog_web_price_lookup_when_site() {
    let ids = vec!["inst.site.catalog.price".into(), "inst.web_search".into()];
    assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::PriceLookup);
    assert!(!catalog_web_after_stock(CatalogWebPhase::PriceLookup, 1));
    assert!(catalog_web_after_stock(CatalogWebPhase::PriceLookup, 0));
}

#[test]
fn catalog_web_compare_beats_lookup() {
    let ids = vec!["inst.site.catalog.price".into(), "inst.site.price_compare".into()];
    assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::PriceCompare);
    assert!(catalog_web_after_stock(CatalogWebPhase::PriceCompare, 2));
}

#[test]
fn catalog_web_stock_never_searches() {
    assert!(!catalog_web_after_stock(CatalogWebPhase::Stock, 0));
}

#[test]
fn catalog_web_write_skips_prefetch() {
    let ids = vec!["inst.site.catalog.write".into(), "inst.site.catalog.price".into(), "inst.web_search".into()];
    assert_eq!(catalog_web_phase(&ids, true), CatalogWebPhase::Off);
    assert!(catalog_skip_web_prefetch(&ids, CatalogWebPhase::Off));
}
```

- [ ] **Step 2: Run `cargo test -p c35_mod_chat catalog_web_ -- --nocapture`. Expected: compile fail, then pass after the enum exists.**

- [ ] **Step 3: Wire `ChatReq`**

Add `pub catalog_web: CatalogWebPhase` to `ChatReq`. Both prompt turn builders set it:

```rust
let has_site = !mention.sites.is_empty()
    || !site_granted_iids(&pool, owner_iid).await?.is_empty();
let catalog_web = catalog_web_phase(&composed.matched_ids, has_site);
```

`compose_force_tool_call` stays true when `inst.web_search` matched. The prefetch guard is separate so sheets behavior does not change.

- [ ] **Step 4: Tool loop**

Store `catalog_skip_web_prefetch` on `ChatReq` as `pub skip_web_prefetch: bool` next to `catalog_web`, computed in the prompt turn from `matched_ids`.

At the existing prefetch (`if req.force_tool_call && tools has web.search`): do not call `tool_loop_run_web_search` when `req.skip_web_prefetch` is true.

`ubah harga …` contains `harga`, so `inst.web_search` matches and would prefetch. `catalog_skip_web_prefetch` is true because `inst.site.catalog.write` matched, even though the phase is `Off`. The write inst also `tool_exclude`s `web.search`.

`berapa harga` matches web_search and `inst.site.catalog.price`. Phase is `PriceLookup` or `PriceCompare`, so the prefetch is skipped the same way.

Also skip the later fallback (`round == 0 && !used_tool && web.search`) when phase is `Stock` or when phase is `PriceLookup` / `PriceCompare` and `site.query.run` has not returned yet. After a catalog result, the resume below owns web search.

When a tool result is `site.query.run` and `args.query_id == "product.stock"`:

```rust
let row_count = result.get("rows").and_then(|v| v.as_array()).map(|a| a.len()).unwrap_or(0);
if catalog_web_after_stock(req.catalog_web, row_count) {
    // existing tool_loop_run_web_search with search_query_from_user(&req.user)
} else if req.catalog_web == CatalogWebPhase::PriceLookup && row_count > 0 {
    tools.retain(|t| t.name != "web.search" && t.name != "web.visit");
    // rebuild tool_json from tools so the next hop cannot search
}
```

`Stock` with zero rows: do not search. The model answers from the empty tool result.

Do not add inst text in this file.

- [ ] **Step 5: `cargo test -p c35_mod_chat catalog_web_ compose_force_tool_call -- --nocapture` and `cargo build -p server_ai`.**

Existing `compose_force_tool_call_when_web_search_inst_and_tool` must still pass.

---

### Task 6: Docs and compose check

**Files:**
- Modify: `_/docs/site-ai.md` "Current code vs this contract" — delete rows that now match, or mark them shipped.
- Modify: `_/docs/inst.md` — the four ids, drop "not seeded yet".

- [ ] **Step 1: `prompt_compose` (MCP `c35`), `owner_iid` 33000, locale `id-ID`.**

| text | expect in trace |
|------|-----------------|
| `berapa harga indomie` | `inst.site.catalog.price` matched, `site.query.run` fed |
| `stok indomie` | `inst.site.catalog.stock` matched, `web.search` not required for the answer |
| `harga indomie kemahalan tidak` | `inst.site.price_compare` matched |
| `ubah harga indomie jadi 10000` | `inst.site.catalog.write` matched, `site.product.patch` fed |

If MCP is down, say so. Do not claim the phrase path is fixed on cargo tests alone.

- [ ] **Step 2: UTF-8 check**

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

---

## Spec coverage

| Contract in site-ai.md | Task |
|------------------------|------|
| Mentioned sites only | 1, 2 |
| No mention aggregates granted sites | 1, 2 |
| One site / one product writes | 3 |
| Two sites, or two products, ambiguous, no UPDATE | 3 |
| Do not invent a mention | 3 |
| Layout tools stay mention-gated | 2, 3 (those tools are not edited) |
| Stock answers per site, no web | 4, 5 |
| Price lookup: web only when catalog is empty | 4, 5 |
| Vs-market: store price then web | 4, 5 |
| `harga` must not prefetch web before the catalog | 5 |
| No new general-topic tool | whole plan |

## Out of scope

- Changing `product.stock` SQL (it already filters `q` and returns per-site rows).
- Auto-binding a site into `sticky_mention_ids`.
- Fan-out price updates.
- Raising app `min` or publishing the server.
