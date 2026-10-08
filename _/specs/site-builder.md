# Conversational Site Builder — Architecture & Token Cache Spec

Status: **Shipped** (Aligned with Slide Deck paradigm, 2026-10-03). Compose injects inst-forced site tools from the full catalog; hop-1 `site.create` when `inst.site.builder` matches and a name is present.

This specification defines the conversational, block-level site creation and editing workflow in Alien AI, mirroring the interactive, lightweight, and token-cache friendly architecture of the presentation slide deck (`inst.presentation`).

---

## 1. Principles & Alignment with Slide Deck

| Principle | Slide Deck Pattern (`presentation.*`) | Conversational Site Builder (`site.*`) |
| :--- | :--- | :--- |
| **Instruction Steering** | `inst.presentation` steers on keywords (`bikin slide`, `pitch deck`). | `inst.site.builder` steers on keywords (`bikin web`, `landing page`, `buat website`). |
| **Creation Fast-Path** | Asks title/topic if ambiguous; immediately calls `presentation.create`. | Discovery first (about, reference links, logo); `site.create` only after user says proceed. |
| **Identity & Slug** | Ephemeral card in chat. | New sites start at numeric path `alienai.id/{site_iid}`; user claims handle via app or `site.handle.update`. |
| **Turn-by-turn Edits** | `presentation.patch` with `action: replace \| insert \| delete` by slide index. | `site.patch` with `action: update_block \| insert_block \| delete_block \| patch_theme`. |
| **Interactive Card** | Native `UiSlideDeckCard` rendered in chat bubble for `presentation.deck`. | Native `UiSitePreviewCard` rendered in chat bubble for `site.preview`. |
| **Finalization** | `presentation.export` ($\to$ `.pptx` CAS download). | `site.publish` ($\to$ snapshots draft to production HTML at `alienai.id/<handle>`). |

---

## 2. Token Cache & Lightweight Design

### Why Traditional Site Builders Fail KV Caching
Traditional LLM site builders generate raw HTML/CSS (2,000–4,000 tokens) or complete 500-line JSON trees every turn. By Turn 4, the conversation context balloons past 12,000 tokens, triggering token limits, dropping KV prefix cache hits, and causing high latency.

### The Lightweight Patch Paradigm
1. **Initial Creation (`site.create`)**:
   - The LLM outputs ~35 tokens: `site.create(name: "Kopi Kenangan", theme: "emerald")`.
   - The Rust backend initializes the standard `SiteDoc` skeleton (Hero, Catalog/Services, Contact, Footer) in `site.draft`.
2. **Targeted Edits (`site.patch`)**:
   - The LLM outputs ~50–100 tokens targeting a single block or theme property:
     ```json
     {
       "site_iid": 123456,
       "action": "update_block",
       "block_id": "hero1",
       "block": {
         "id": "hero1",
         "type": "hero",
         "props": { "title": "Kopi Susu Senja", "subtitle": "Nikmat setiap tetes" }
       }
     }
     ```
   - Rust mutates only the specified block in `site.draft.doc_json`.
3. **KV Cache Preservation**:
   - **Prefix Cache Hit Rate**: History grows by $<150$ tokens per turn instead of thousands.
   - **Context Hygiene**: The full rendered HTML is **never** reflected back into LLM history; it is delivered directly to the client UI via `block.kind: "site.preview"`.

---

## 3. Tool Specifications

### A. `site.create`
Creates a new site identity, access grant, site config, and initial `SiteDoc` draft.

- **Parameters**:
  - `name` (string, required): Brand or site name (e.g. "Kopi Kenangan").
  - `alien_id` (string, optional): Custom handle/slug. If omitted, public path stays numeric (`site_iid`) until claimed.
  - `tagline` (string, optional): One-line description.
  - `theme` (string, optional, default: `"dark"`): Visual theme preset (e.g. `dark`, `emerald`, `indigo`, `sunset`).
  - `features` (object, optional): Enabled capabilities (e.g. `commerce: true`, `booking: false`).
- **Rust Execution**:
  1. Set `alien_id` to `site_iid` string unless `alien_id` param provided (then slugify + uniqueness).
  2. Insert `ai.identity(id, kind='site', type='web', name, alien_id, owner_iid)`.
  3. Insert `ai.identity_grant(resource_iid, grantee_iid, role='owner')`.
  4. Insert `site.config(site_iid, owner_iid, capabilities_json)`.
  5. Insert `site.draft(site_iid, owner_iid, doc_json)`.
- **Response Block**:
  ```json
  {
    "ok": true,
    "site_iid": 123456789,
    "alien_id": "kopi-kenangan",
    "name": "Kopi Kenangan",
    "block": {
      "kind": "site.preview",
      "body": {
        "site_iid": 123456789,
        "alien_id": "kopi-kenangan",
        "name": "Kopi Kenangan",
        "doc": { ... },
        "preview_path": "/"
      }
    }
  }
  ```

### B. `site.patch`
Applies an atomic mutation to the site draft.

- **Parameters**:
  - `site_iid` (integer, optional if 1 site in scope): Target site identity ID.
  - `action` (string, required): `update_block` | `insert_block` | `delete_block` | `patch_theme` | `patch_meta`.
  - `block_id` (string, optional): ID of block to update or delete.
  - `after_block_id` (string, optional): Reference block for insertions.
  - `block` (object, optional): Block payload for insert/update (`id`, `type`, `props`).
  - `theme` (object, optional): Theme overrides (`accent`, `font`, `layout`, `background`).
  - `meta` (object, optional): Metadata overrides (`seo_title`, `seo_desc`).
- **Response**:
  ```json
  {
    "ok": true,
    "site_iid": 123456789,
    "action": "update_block",
    "block_id": "hero1",
    "block": {
      "kind": "site.preview",
      "body": { ... }
    }
  }
  ```

### C. `site.handle.update`
Safely updates the site's public URL handle (`alien_id`).

- **Parameters**:
  - `site_iid` (integer, required): Site identity ID.
  - `new_alien_id` (string, required): Desired new slug.
- **Rules**:
  - Validates format: `[a-z0-9_-]{3,48}`.
  - Checks uniqueness in `ai.identity`.
  - Updates `ai.identity.alien_id` and records `site.config.alien_id_changed_ts = NOW()`.
  - Steered by prompt to ask user confirmation before triggering if site is already active/published.

---

## 4. UI Specification: `UiSitePreviewCard`

- **Location**: `clients/app/lib/widgets/ai/ui_site_preview_card.dart`, integrated into `ui_msg_blocks.dart` under `case 'site.preview':`.
- **Card Elements**:
  1. **Header Bar**:
     - Site Name & `@alien_id` handle chip.
     - Live/Draft status pill.
     - Open in Browser button (`alienai.id/<alien_id>`).
  2. **Preview Canvas**:
     - Visual rendering of the `SiteDoc` page blocks (Hero banner, image gallery/product grid cards, markdown text, contact info).
     - Alternatively embeds a live iframe/webview using `site_preview_token_issue`.
  3. **Action Footer**:
     - "Visit Site" / "Publish Changes" / "Customize Handle".

---

## 5. Instruction Seed: `inst.site.builder`

Added to `_/schemas/inst.sql`:
- **ID**: `inst.site.builder`
- **Scope**: `global`
- **Kind**: `task`
- **Phrases**: `bikin web`, `buat web`, `bikin website`, `buat website`, `landing page`, `create site`, `build website`, `site builder`
- **Include Tools**: `site.create`, `site.patch`, `site.publish`, `site.handle.update`, `img.generate`
- **Instructions**:
  - If user mentions creating a website and hasn't given a name, ask for the site/business name.
  - As soon as a name is provided, call `site.create(name)`. Inform the user of their generated handle `@handle` (`alienai.id/<handle>`) and that they can change it anytime.
  - For edits (tweaking text, adding pictures, changing colors, adding sections), **never** rewrite the entire site; call `site.patch`.
  - Propose image generation via `img.generate` for heroes and products.
