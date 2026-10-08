# Product default icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a product has no photo, the editor, the guest app, and the public HTML site show a food-or-drink Iconify icon chosen from the product name, backed by a shared lookup table filled once by the cheap text model.

**Architecture:** One Rust const, `CHEAP_MODEL`, is the housekeeping text model. Product names are normalized to a `name_key` and resolved in order: keyword rules, then `site.product_icon`, then one unbilled `CHEAP_MODEL` JSON call that may only return a kind id from a closed list. The kind map supplies the Iconify id. A real `pic` always wins. Public HTML inlines the SVG for that id. The app uses the existing `UiIcon` widget.

**Tech Stack:** Rust `c35_mod_llm` + `c35_mod_site`, YSQL `site.product_icon`, protobuf `site.proto`, Flutter `UiIcon`.

**Specs:** [`_/specs/site.md`](../site.md) | [`_/specs/billing.md`](../billing.md) | [`_/schemas/site.sql`](../../schemas/site.sql) | [`_/schemas/proto/c35/site.proto`](../../schemas/proto/c35/site.proto)

## Global Constraints

- `CHEAP_MODEL` is the string `gemini-3.1-flash-lite`. It is a Rust const in `c35_mod_llm`. There is no environment variable.
- `CHEAP_MODEL` is text only. Image draft stays `gemini-3.1-flash-lite-image` (`C35_IMAGE_DEFAULT_TIER` / `image.default_tier`).
- Do not bill the site owner for icon classify. Platform COGS, same class as memory-retrieve embed. Do not call `billing_usage_report`.
- The model returns a kind id. It never returns an Iconify string. Unknown kind becomes `generic`.
- Lookup is an exact `name_key`. No embeddings. No full-text search.
- Do not add provider web grounding.
- New or edited `.rs`, `.dart`, `.sql`, `.md`, `.proto` files are UTF-8 (no BOM).
- A non-empty `pic` skips classify and renders the photo. Icon fields stay empty in that case.
- Classify failure must not fail `site_product_put`.

---

## File map

| File | Role |
|---|---|
| `servers/crates/mod_llm/src/lib.rs` | `pub const CHEAP_MODEL` |
| `servers/crates/mod_chat/src/context_compact.rs` | Use `CHEAP_MODEL` instead of `CONTEXT_COMPACT_MODEL`'s literal |
| `servers/crates/mod_chat/src/memory_extract.rs` | Use `CHEAP_MODEL` |
| `servers/crates/mod_voice/src/stt.rs` | Use `CHEAP_MODEL` |
| `servers/crates/mod_voice/Cargo.toml` | Depend on `c35_mod_llm` |
| `_/specs/billing.md` | Cheap model section; fix the stale `gemini-2.0-flash` line |
| `_/specs/context-compaction.md` | Point extractor and compact at `CHEAP_MODEL` |
| `_/specs/site.md` | `site.product_icon` row |
| `_/schemas/site.sql` | `site.product_icon` |
| `servers/crates/mod_site/src/product_icon.rs` | Name key, kind catalog, rules, ensure, lookup |
| `servers/crates/mod_site/src/product_icon_svg.rs` | Closed-set inline SVG for guest HTML |
| `servers/crates/mod_site/Cargo.toml` | Depend on `c35_mod_llm` |
| `servers/crates/mod_site/src/site_product.rs` | Ensure on put; fill `icon` on list |
| `servers/crates/mod_site/src/guest_product.rs` | `ProductRow.icon`, guest JSON |
| `servers/crates/mod_site/src/render.rs` | Placeholder markup when `pic` is empty |
| `_/schemas/proto/c35/site.proto` | `icon` on `SiteProduct` and `SiteGuestProductItem` |
| `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart` | Empty photo tile shows `UiIcon` |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | Grid and list placeholders |
| `clients/app/lib/widgets/sites/tx/ui_site_product_thumb.dart` | POS thumb |
| `servers/crates/mod_site/tests/product_icon_test.rs` | Key, rules, HTML |
| `servers/crates/mod_llm/src/cheap_model.rs` | Tests that the const is the flash-lite id |

`mod_chat` already depends on `mod_site` and `mod_llm`. `mod_llm` does not depend on `mod_site`. `mod_site` may depend on `mod_llm`. Do not depend on `mod_chat` from `mod_site`.

---

### Task 1: Name the cheap model

**Files:**
- Modify: `servers/crates/mod_llm/src/lib.rs`
- Create: `servers/crates/mod_llm/src/cheap_model.rs`
- Modify: `servers/crates/mod_chat/src/context_compact.rs`
- Modify: `servers/crates/mod_chat/src/memory_extract.rs`
- Modify: `servers/crates/mod_voice/Cargo.toml`
- Modify: `servers/crates/mod_voice/src/stt.rs`
- Modify: `_/specs/billing.md`
- Modify: `_/specs/context-compaction.md`

**Interfaces:**
- Consumes: nothing
- Produces: `c35_mod_llm::CHEAP_MODEL: &str` equal to `gemini-3.1-flash-lite`

- [ ] **Step 1: Write the failing const test**

Create `servers/crates/mod_llm/src/cheap_model.rs`:

```rust
#[cfg(test)]
mod tests {
    use crate::CHEAP_MODEL;

    #[test]
    fn cheap_model_is_gemini_flash_lite() {
        assert_eq!(CHEAP_MODEL, "gemini-3.1-flash-lite");
        assert!(!CHEAP_MODEL.contains("image"));
    }
}
```

Declare `mod cheap_model;` in `lib.rs`.

- [ ] **Step 2: Run the test and confirm it fails**

```powershell
cd servers
cargo test -p c35_mod_llm cheap_model_is_gemini_flash_lite
```

Expected: compile error, `CHEAP_MODEL` not found.

- [ ] **Step 3: Add the const and point existing callers at it**

In `servers/crates/mod_llm/src/lib.rs`:

```rust
/// Housekeeping text model for work that is not the user's selected chat model.
/// Compaction, memory extraction, speech-to-text, and later product-icon classify.
/// Not configurable by env. Change this const to retarget every caller.
pub const CHEAP_MODEL: &str = "gemini-3.1-flash-lite";
```

`context_compact.rs`: delete the literal. Keep the name `CONTEXT_COMPACT_MODEL` as an alias so logs and billing call sites stay stable:

```rust
pub const CONTEXT_COMPACT_MODEL: &str = c35_mod_llm::CHEAP_MODEL;
```

`memory_extract.rs`:

```rust
const MEMORY_EXTRACT_MODEL: &str = c35_mod_llm::CHEAP_MODEL;
```

`mod_voice/Cargo.toml` add:

```toml
c35_mod_llm = { path = "../mod_llm", package = "c35_mod_llm" }
```

`stt.rs` inside `gemini_stt`, replace `let model = "gemini-3.1-flash-lite";` with `let model = c35_mod_llm::CHEAP_MODEL;`.

Do not change `MODEL_FLASH_LITE` in `mod_chat/src/tools/image_tier.rs`.

- [ ] **Step 4: Document it**

In `_/specs/billing.md`, replace the "### Model" paragraph that says `gemini-2.0-flash` with:

```markdown
### Cheap model

Housekeeping text calls use `CHEAP_MODEL` (`gemini-3.1-flash-lite`), defined in `servers/crates/mod_llm/src/lib.rs`. There is no env override. Change the const to retarget every caller.

| Caller | Const alias | Billed to the user |
|---|---|---|
| Context compaction, including idle compact | `CONTEXT_COMPACT_MODEL` | Yes, see the table above |
| Memory extraction | `MEMORY_EXTRACT_MODEL` | Yes, rolled into the parent turn or the idle compact report |
| Speech-to-text Gemini fallback | `CHEAP_MODEL` in `gemini_stt` | Voice billing, not this const's concern |
| Product default icon classify | `CHEAP_MODEL` | No. Platform COGS |

`CHEAP_MODEL` is not the image model. Draft images stay `gemini-3.1-flash-lite-image` (`C35_IMAGE_DEFAULT_TIER`, `ai.config` key `image.default_tier`).

Alien AI chat routing stays `ai.config` key `llm.alien_chain`. That chain prefers flash-lite models and is independent of `CHEAP_MODEL`.
```

In `_/specs/context-compaction.md` Model & Billing, replace the extractor-model bullet with: extractor and compact both call `c35_mod_llm::CHEAP_MODEL` (`gemini-3.1-flash-lite`).

- [ ] **Step 5: Tests**

```powershell
cd servers
cargo test -p c35_mod_llm cheap_model_is_gemini_flash_lite
cargo test -p c35_mod_chat context_compact
cargo build -p c35_mod_voice
```

Expected: cheap-model test passes, compact tests still pass, voice crate builds.

---

### Task 2: Kind catalog, name key, and keyword rules

**Files:**
- Create: `servers/crates/mod_site/src/product_icon.rs`
- Modify: `servers/crates/mod_site/src/lib.rs`
- Test: `servers/crates/mod_site/tests/product_icon_test.rs`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `pub fn product_icon_name_key(name: &str) -> String`
  - `pub fn product_icon_kind_from_rules(name_key: &str) -> Option<&'static str>`
  - `pub fn product_icon_id(kind: &str) -> &'static str` — unknown kind returns `mdi:shopping`
  - `pub fn product_icon_kinds() -> &'static [ProductIconKind]`
  - `pub struct ProductIconKind { pub kind: &'static str, pub icon: &'static str, pub keywords: &'static [&'static str] }`

- [ ] **Step 1: Write failing tests**

`servers/crates/mod_site/tests/product_icon_test.rs`:

```rust
use c35_mod_site::{product_icon_id, product_icon_kind_from_rules, product_icon_name_key};

#[test]
fn name_key_strips_size_and_temperature() {
    assert_eq!(product_icon_name_key("Es Kopi Susu"), "kopi susu");
    assert_eq!(product_icon_name_key("Kopi Susu Panas"), "kopi susu");
    assert_eq!(product_icon_name_key("Large Iced Latte 500ml"), "latte");
}

#[test]
fn rules_prefer_specific_kind_over_drink() {
    assert_eq!(product_icon_kind_from_rules("kopi susu"), Some("coffee"));
    assert_eq!(product_icon_kind_from_rules(&product_icon_name_key("Es Teh")), Some("tea"));
    assert_eq!(product_icon_kind_from_rules("burger keju"), Some("burger"));
    assert_eq!(product_icon_kind_from_rules("nasi goreng spesial"), Some("rice"));
    assert_eq!(product_icon_id("coffee"), "mdi:coffee");
    assert_eq!(product_icon_id("nope"), "mdi:shopping");
}

#[test]
fn rules_miss_non_food() {
    assert_eq!(product_icon_kind_from_rules("kursi kayu"), None);
}
```

Export the three functions from `lib.rs`.

- [ ] **Step 2: Run and confirm fail**

```powershell
cd servers
cargo test -p c35_mod_site --test product_icon_test
```

Expected: compile error, functions missing.

- [ ] **Step 3: Implement the catalog**

`product_icon_name_key`:

1. Trim, lowercase, replace any char that is not ASCII alphanumeric and not a letter outside ASCII with a space (keep Unicode letters so Indonesian words survive).
2. Split on whitespace.
3. Drop tokens in this set: `es`, `ice`, `iced`, `hot`, `panas`, `dingin`, `cold`, `warm`, `large`, `small`, `medium`, `regular`, `jumbo`, `big`, `pcs`, `pc`, `ml`, `gr`, `gram`, `kg`, `oz`, `liter`, `l`, `spesial`, `special`, `original`, `new`.
4. Drop tokens that are only digits.
5. Join with a single space. Empty input stays empty.

Keyword match is substring on the `name_key`, first hit in this order. More specific rows come before `drink`.

| kind | icon | keywords |
|---|---|---|
| coffee | `mdi:coffee` | kopi, coffee, latte, espresso, americano, cappuccino, mocha, macchiato |
| tea | `mdi:tea` | teh, tea, matcha |
| juice | `mdi:fruit-citrus` | jus, juice, jeruk, smoothie |
| beer | `mdi:beer` | beer, bir |
| wine | `mdi:glass-wine` | wine |
| cocktail | `mdi:glass-cocktail` | cocktail, mojito, mocktail |
| water | `mdi:cup-water` | air mineral, mineral water |
| burger | `mdi:hamburger` | burger, hamburger |
| pizza | `mdi:pizza` | pizza |
| fries | `mdi:french-fries` | fries, kentang goreng |
| rice | `mdi:rice` | nasi, rice |
| noodles | `mdi:noodles` | mie, noodle, ramen, pasta, spaghetti, bakmi, kwetiau |
| bread | `mdi:bread-slice` | roti, bread, toast, sandwich |
| cake | `mdi:cake-variant` | kue, cake, pastry, donat, doughnut, croissant |
| ice_cream | `mdi:ice-cream` | es krim, ice cream, gelato |
| chicken | `mdi:food-drumstick` | ayam, chicken |
| meat | `mdi:food-steak` | steak, daging, sapi, beef |
| fish | `mdi:fish` | ikan, fish, seafood, udang, shrimp |
| soup | `mdi:bowl` | soup, soto, bakso |
| egg | `mdi:egg` | telur, egg, omelet, omelette |
| drink | `mdi:cup` | minuman, drink, soda, milkshake, float, lemonade |
| generic | `mdi:shopping` | (no keywords; fallback only) |

`product_icon_id` looks up `kind` in this table and returns `mdi:shopping` when missing.

Rules see `name_key` only. `Es Teh` becomes `teh`, which matches tea.

- [ ] **Step 4: Re-run**

```powershell
cd servers
cargo test -p c35_mod_site --test product_icon_test
```

Expected: pass.

---

### Task 3: Lookup table and cheap-model fill

**Files:**
- Modify: `_/schemas/site.sql` (append after `site.product_embed`)
- Modify: `servers/crates/mod_site/Cargo.toml`
- Modify: `servers/crates/mod_site/src/product_icon.rs`
- Modify: `servers/crates/mod_site/src/site_product.rs` (`site_product_put`)
- Modify: `_/specs/site.md` (tables section)

**Interfaces:**
- Consumes: `CHEAP_MODEL`, `product_icon_name_key`, `product_icon_kind_from_rules`, `product_icon_id`
- Produces:
  - `pub async fn product_icon_lookup(pool: &PgPool, name_keys: &[String]) -> HashMap<String, String>` mapping `name_key` → icon id
  - `pub async fn product_icon_ensure(pool: &PgPool, name: &str) -> String` returns an icon id, or `mdi:shopping` on any failure
  - Table `site.product_icon`

- [ ] **Step 1: Schema**

Append to `_/schemas/site.sql`:

```sql
-- Global product-name → default Iconify id. Shared across sites.
-- name_key is product_icon_name_key(name). icon is an id from the Rust kind catalog.
CREATE TABLE IF NOT EXISTS site.product_icon (
    name_key    TEXT PRIMARY KEY,
    icon        TEXT NOT NULL,
    kind        TEXT NOT NULL,
    source      TEXT NOT NULL,          -- rule | llm
    model       TEXT NOT NULL DEFAULT '',
    created_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Boot applies this when the schema bundle hash changes (`_/specs/schema-migrate.md`). No separate migration file.

In `_/specs/site.md` tables, add a row: `site.product_icon` | no | — | global name_key → iconify id for empty product photos. Not per site. Not `site.product_embed`.

- [ ] **Step 2: Lookup and rule write**

`product_icon_lookup` selects `name_key, icon` where `name_key = ANY($1)`.

`product_icon_ensure`:

1. `key = product_icon_name_key(name)`. Empty key returns `mdi:shopping` and writes nothing.
2. If lookup hits, return that icon.
3. If `product_icon_kind_from_rules(&key)` is `Some(kind)`, upsert `(key, product_icon_id(kind), kind, "rule", "")` and return the icon.
4. Otherwise call the model (step 3). On success upsert `source = "llm"` and `model = CHEAP_MODEL`. On failure or a kind not in the catalog, upsert `kind = "generic"`, `icon = "mdi:shopping"`, `source = "llm"` so the same key is not sent to the model again.
5. Use `ON CONFLICT (name_key) DO NOTHING` then re-read, so two puts of the same new name do not double-call.

- [ ] **Step 3: Model call inside `mod_site`**

Add `c35_mod_llm` to `mod_site/Cargo.toml`.

Add `product_icon_classify(name_key: &str) -> Result<String>` in `product_icon.rs`. It posts to Gemini `generateContent` for `CHEAP_MODEL` using the same API key order as `mod_voice` `gemini_stt` (`GEMINI_API_KEY`, then `GOOGLE_API_KEY`, then `GOOGLE_CLOUD_API_KEY`). Timeout 4 seconds. Temperature 0. Thinking off (`thinkingBudget: 0`, the flash-lite shape already used in `mod_chat/src/prompt/thought.rs`). `maxOutputTokens: 32`.

System text:

```text
Pick one kind for this product name. Reply with JSON only: {"kind":"<id>"}.
Ids: coffee, tea, juice, beer, wine, cocktail, water, burger, pizza, fries, rice, noodles, bread, cake, ice_cream, chicken, meat, fish, soup, egg, drink, generic.
Use generic when it is not food or drink. Do not explain.
```

User text is the `name_key`. Parse a JSON object; if the reply has extra text, slice from the first `{` to the last `}`. The `kind` string must be one of `product_icon_kinds()`. Otherwise treat as failure and store generic.

Before send, build the request JSON and pass it through `c35_mod_llm::gemini_request_reject_provider_grounding`. No `googleSearch`, no tools.

Do not call `billing_usage_report`. `tracing::debug` the `name_key`, kind, and token counts.

- [ ] **Step 4: Hook put, without failing the save**

At the end of a successful `site_product_put` transaction, if `product.pic.trim()` is empty and `product.name` is non-empty, call `product_icon_ensure`. If it returns an error type, it must not: the function returns an icon id. Ignore the icon for the put response in this task (Task 4 puts it on the wire).

If `pic` is non-empty, do not call ensure.

- [ ] **Step 5: Build**

```powershell
cd servers
cargo build -p c35_mod_site
cargo test -p c35_mod_site --test product_icon_test
.\_\scripts\dev\check_no_provider_grounding.ps1 -Changed
```

Run the grounding script from the repo root. Expected: build and tests pass, grounding check clean.

---

### Task 4: Render the icon when `pic` is empty

**Files:**
- Modify: `_/schemas/proto/c35/site.proto`
- Modify: `servers/crates/mod_site/src/guest_product.rs`
- Modify: `servers/crates/mod_site/src/site_product.rs` (`product_from_row`, list)
- Create: `servers/crates/mod_site/src/product_icon_svg.rs`
- Modify: `servers/crates/mod_site/src/render.rs` (`product_card_html` and any other product card that emits `pic`)
- Modify: `servers/crates/mod_site/tests/product_icon_test.rs`

**Interfaces:**
- Consumes: `product_icon_lookup`, `product_icon_ensure`, `product_icon_id("generic")`
- Produces:
  - `SiteProduct.icon` field 23, `SiteGuestProductItem.icon` field 7, both `string`
  - `ProductRow.icon: String`
  - `pub fn product_icon_svg(icon_id: &str) -> &'static str` — full `<svg>...</svg>` or empty when unknown
  - Guest HTML placeholder uses that SVG

- [ ] **Step 1: Proto**

```protobuf
// SiteProduct
string icon = 23; // iconify id when pic is empty; empty when pic is set

// SiteGuestProductItem
string icon = 7;
```

Regenerate Dart:

```powershell
.\_\scripts\protoc.ps1
```

Rust prost picks the field up on `cargo build -p c35_mod_site`.

- [ ] **Step 2: Fill icon on read**

`ProductRow` gains `icon: String`. `product_row_json` adds `"icon": p.icon`.

When building guest rows and `product_from_row` / product list:

- If `pic` is non-empty, `icon` is `""`.
- If `pic` is empty, `icon` is the lookup hit, else `mdi:shopping`.
- For lookup misses, `tokio::spawn` `product_icon_ensure(pool, name)` so the next read can leave `generic`. This request still returns `mdi:shopping`. Do not await the model on the guest HTML path.

`site_product_put` still awaits `product_icon_ensure` before returning (Task 3). Set `icon` on the in-memory product the editor will see: add `string icon = 2` on `ResSiteProductPut` and set it from ensure when `pic` is empty, else `""`.

- [ ] **Step 3: HTML**

`product_card_html`: when `pic` is empty, emit

```html
<div class="product-ph" aria-hidden="true">{svg}</div>
```

using `product_icon_svg(&p.icon)`, and if that returns empty, `product_icon_svg("mdi:shopping")`. When `pic` is non-empty, keep the current `<img>`.

Add CSS next to `.product-card img`:

```css
.product-card .product-ph { width:100%; aspect-ratio:1; display:flex; align-items:center; justify-content:center; background:#f4f4f5; }
.product-card .product-ph svg { width:28%; height:28%; }
```

`product_icon_svg` is a `match` on the icon ids in the kind table. Each arm is a small single-path SVG, `fill="currentColor"`, `viewBox="0 0 24 24"`, copied from the Iconify MDI set for that id (one path each). `mdi:shopping` is the default arm. Unknown ids return `""`.

Extend `product_icon_test` with a pure function test: a `ProductRow` with empty `pic`, name `Kopi`, icon `mdi:coffee` renders `class="product-ph"` and the coffee SVG, and does not render `<img`. A row with `pic = "abc"` renders `<img` and no `product-ph`.

- [ ] **Step 4: Verify**

```powershell
cd servers
cargo test -p c35_mod_site --test product_icon_test
cargo build -p server_ai
```

Expected: tests pass, server builds.

---

### Task 5: Editor, guest app, and POS thumb

**Files:**
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart` (`_ProductPicTile`)
- Modify: `clients/app/lib/guest_site/guest_site_blocks.dart` (both `_productThumbPlaceholder` widgets, list and grid)
- Modify: `clients/app/lib/widgets/sites/tx/ui_site_product_thumb.dart`

**Interfaces:**
- Consumes: `SiteProduct.icon`, guest product `icon`, `UiIcon` in `clients/app/lib/widgets/ui/ui_icon.dart`
- Produces: empty-pic surfaces render `UiIcon('iconify://$icon')` with the shopping id when `icon` is empty

- [ ] **Step 1: Shared fallback id**

Use the literal `mdi:shopping` when `icon` is empty. Pass `iconify://mdi:coffee` (the stored id prefixed) into `UiIcon`. `UiIcon` already loads Iconify SVG and recolors.

- [ ] **Step 2: Editor tile**

`_ProductPicTile` needs the icon string. When `pic` is empty, center `UiIcon` at 36px in the muted color instead of `Icons.add_photo_alternate_outlined`. Keep the camera badge and the tap target that opens the photo picker. When `pic` is set, keep `UiImg` and its broken-image fallback for a failed URL.

- [ ] **Step 3: Guest blocks**

Both placeholders take the product icon string. Replace `Icons.shopping_bag_outlined` with `UiIcon`. Size stays 22. Color stays the accent.

- [ ] **Step 4: POS thumb**

`UiSiteProductThumb`: empty `pic` uses `UiIcon` of `product.icon` (or `mdi:shopping`). Failed `UiImg` keeps `Icons.shopping_bag_outlined` so a broken photo URL does not pretend to be a drink.

- [ ] **Step 5: Analyze**

```powershell
.\_\scripts\dev\verify_flutter_app.ps1
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
```

Expected: analyze clean, UTF-8 clean.

Manual check when a site with an empty-pic product is available: editor tile shows the icon and the camera badge; guest app grid shows the same icon; published HTML shows the inline SVG and no request to `api.iconify.design`.

---

## Out of scope

- Backfill job over every existing product. Guest read spawns ensure on a miss, and put fills new or renamed rows.
- Per-site icon overrides.
- Letting the model invent Iconify ids.
- Charging the owner for classify.
- Embeddings or `tsvector` on `site.product_icon`.

## Self-review

- Cheap model is Task 1, including docs and the three existing callers.
- Table, rules, and model fill are Tasks 2–3. Exact key only.
- Editor, guest app, and public HTML are Tasks 4–5. Photo wins. Generic is `mdi:shopping`.
- Classify cannot fail a product save.
- Icon classify is unbilled. Compaction and memory extraction stay billed.
