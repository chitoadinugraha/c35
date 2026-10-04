# Presentations & Slide Decks (LOCKED)

Status: **locked** 2026-10-03

Visual presentation generation, interactive viewing, slide-level patching, and export in Alien AI.

---

## 1. Architectural Principles

1. **Zero WebView (100% Native Flutter)**:
   - All presentation previews, card transitions, and slide layouts render entirely via native Flutter widgets (`UiSlideDeckCard`).
   - No headless browser, no `webview_flutter` iframe, zero web rendering overhead on mobile or desktop.
2. **Compact Inline Cards with On-Demand Preview**:
   - Presentations generate as compact collapsible cards in the chat flow to preserve conversation readability.
   - Tap `[ Open ]` to expand into a 16:9 widescreen preview with interactive pagination, toolbar, and full deck inspection.
3. **Slide-Level Patching (Option C)**:
   - When the user asks to edit, add, or delete slides, the AI outputs only targeted patches instead of rewriting the entire deck.
   - Reduces output token consumption and latency by ~90% on iterations.
4. **Structured Blocks & Fenced Code Fallback**:
   - Structured JSON tool execution emits `ChatBlock(kind: "presentation.deck")`.
   - Raw markdown output wrapped in ````slide, ````slides, ````presentation, ````marp, or ````slide-patch is automatically intercepted and rendered as `UiSlideDeckCard`.

---

## 2. UI Component Specification (`UiSlideDeckCard`)

The presentation viewer lives in `clients/app/lib/widgets/ai/ui_slide_deck_card.dart`.

### A. Collapsed State (Default Card)
Rendered inline in the message bubble:
- **Icon**: Presentation / slideshow icon (`Icons.slideshow_rounded` or `Icons.view_carousel_rounded`).
- **Title**: Deck title (e.g. *"Cara Memasak Indomie"*).
- **Metadata**: Slide count and creation timestamp (e.g. `3 slides • 3 Oct, 6:11 am`).
- **Action**: Neon-bordered `[ Open ]` pill button to expand.

```
┌────────────────────────────────────────────────────────┐
│ 🎴 Cara Memasak Indomie                                 │
│    3 slides • 3 Oct, 6:11 am                 [ Open ]  │
└────────────────────────────────────────────────────────┘
```

### B. Expanded State (Canonical 16:9 Canvas & Mobile-First Toolbar)
When toggled open via `AnimatedSize`:
- **Canonical 16:9 Widescreen Presentation Canvas (960 x 540)**:
  - Both the inline chat preview and fullscreen slideshow render the exact same canonical `_SlideCanvasView` (960 x 540 pt) scaled faithfully using `FittedBox(fit: BoxFit.contain)`.
  - Ensures 100% visual parity across Preview, Fullscreen, PDF (`SlideDeckPdfExporter`), and PowerPoint (`render_pptx.ts`).
  - No text re-wrapping or layout drift between small mobile viewports and large desktop screens.
- **Mobile-Friendly Toolbar**:
  - Replaces crowded micro-buttons with comfortable touch targets (minimum 32-34px hit test).
  - **Left**: Deck title with presentation icon (expanded with ellipsis truncation).
  - **Right**:
    - **Slide Navigation Pill**: `[ ‹ ]  1/3  [ › ]` with dedicated previous and next chevron buttons.
    - **Hamburger Menu Button `[ ☰ ]`**: Opens a compact dropdown menu (fullscreen, export, collapse). **Theme** opens a dialog with catalog swatches.
- **Deck menu + theme dialog**:
  - **Presentation Mode**: Fullscreen presentation slideshow with swipe & keyboard navigation.
  - **Theme picker** (`io_slide_theme_pick.dart`): `UiDialog` + `UiDialogSearchHeader` (search replaces title; top-right close). Rows show **iconify** icon, label, accent dot, checkmark. Catalog: `ai.presentation_theme` (`icon`, `tokens_json`, aliases) via `/v1/catalog/presentation-themes` with builtin fallback.
    - `dark` (Dark Neon) — `mdi:flash`
    - `midnight` (Midnight Indigo) — `mdi:moon-waning-crescent` · alias `indigo`
    - `emerald` (Emerald Modern) — `mdi:leaf` · aliases `corporate`, `mint`
    - `sunset` (Sunset Glow) — `mdi:white-balance-sunny` · aliases `coral`, `pink`
    - `ocean` (Ocean Deep) — `mdi:waves` · aliases `cyan`, `aqua`
    - `ruby` (Ruby Noir) — `mdi:gem` · aliases `rose`, `red`
    - `gold` (Royal Gold) — `mdi:crown` · aliases `amber`, `yellow`
    - `arctic` (Arctic Light) — `mdi:snowflake` · aliases `light`, `white` (high-contrast light deck)
  - **Export to PowerPoint (.pptx)**: Compiles slide deck into an editable `.pptx` presentation (13.333 in x 7.5 in widescreen) via `/v1/presentation/export` and saves with human-readable filename (e.g. `Cara_Menanam_Bunga.pptx`).
  - **Export to PDF (.pdf)**: Compiles 16:9 widescreen PDF slides (960 x 540 pt) via `SlideDeckPdfExporter` (`package:pdf` + `package:printing`) with identical badges, cards, progress capsules, and image layouts.
  - **Copy Slides Markdown**: Copies raw markdown formatted with `---` dividers.
  - **Open in Canvas**: Opens the presentation side-by-side in the canvas editing panel (when canvas is active).
  - **Collapse Preview**: Folds the expanded preview back into the compact inline card.
- **Slide Canvas Hierarchy (Identical across Preview, PDF, PPTX)**:
  - **Top Accent Line**: 4 pt full-width bar in theme accent color.
  - **Cover Slide (Slide 1)**: Left-aligned eyebrow badge pill, 36 pt bold title, 16 pt subtitle, accent gradient divider line, bottom Alien AI branding and progress capsules, optional 60/40 split image.
  - **Content Slides**: `SLIDE X OF Y` category badge pill, 24 pt bold title, 13 pt subtitle, numbered rounded cards (`1`, `2`, `3`) with circular accent badges, bottom progress indicator capsules (`• • — •`), and optional 60/40 right-side image card (`UiImg`).

### C. Fullscreen Presentation Mode (`_FullscreenDeckView`)
Tap *Fullscreen Presentation* in the hamburger menu to launch:
- Immersive widescreen presentation canvas (`maxWidth: 960px`).
- Renders the identical `_SlideCanvasView` with gesture drag, trackpad, and keyboard arrow navigation (`←` `→` arrows, `Esc` to exit).
- Interactive slide scrubber dots at the bottom.

---

## 3. Pictures & Media in Slides

Images are embedded directly using standard Markdown syntax:
```markdown
# 1. Persiapan Bahan
- 1 bungkus mie instan rasa ayam bawang
- 400ml air mendidih
- 1 butir telur & daun bawang
![Bahan-bahan](https://images.unsplash.com/photo-1612927601601-6638404737ce?w=600)
```

### Layout Engine
- `UiSlideDeckCard` parses `![caption](url)` from the slide content.
- Automatically reorganizes the slide into a **split layout**:
  - Left (60% width): Title and bullet cards.
  - Right (40% width): High-contrast rounded image card using `UiImg` (supports HTTPS, CAS `/fs/`, and local files).
- In Cover Slides with an image, renders title/subtitle on the left and a showcase hero image on the right.

### How to Add Pictures
1. **Web / Stock URLs**: The AI or user can embed Unsplash or web images (`![Indomie](https://images.unsplash.com/...)`).
2. **AI-Generated Visuals (`img.generate`)**: The LLM can call `img.generate` to synthesize an illustration, then embed the returned CAS URL (`/fs/...`) into the slide.
3. **Chat Attachments**: Users can attach images directly in the composer, and the LLM embeds the attachment CAS URL.
4. **Slide Patching**: Users can say *"tambahkan gambar di slide 2"* to patch a photo into an existing slide with `<!-- slide-patch:2 -->`.

---

## 3. Slide Patching Protocol (Option C)

To minimize token costs on multi-turn editing sessions, presentations support targeted slide-level patches:

### Syntax

| Action | Patch Delimiter | Description |
|--------|-----------------|-------------|
| **Replace** | `<!-- slide-patch:<index> -->` | Replaces the contents of slide `<index>` (1-indexed). |
| **Insert** | `<!-- slide-patch:add after=<index> -->` | Inserts a new slide immediately after slide `<index>`. |
| **Delete** | `<!-- slide-patch:delete <index> -->` | Removes slide `<index>` from the presentation. |

### Example Replace Patch
```markdown
<!-- slide-patch:2 -->
# Langkah 2: Masukkan Bumbu
- Masukkan minyak bumbu dan kecap manis ke piring
- Aduk rata sebelum mie ditiriskan
```

### Engine Handling
- `SlidePatch.tryParse(raw)` detects patch syntax from markdown code blocks or structured block bodies.
- `SlideDeckData.applyPatch(patch)` modifies the in-memory slide array in place (`replace`, `insert`, or `delete`).

---

## 4. Builtin Tools (`servers/crates/mod_chat`)

Presentation tools are defined in `servers/crates/mod_chat/src/tools/builtin/presentation_export.rs`:

| Tool | Parameters | Description |
|------|------------|-------------|
| **`presentation.create`** | `title` (string), `slides_markdown` (string) or `slides` (array), `theme` (string) | Generates a visual deck and emits `ChatBlock(kind: "presentation.deck")`. |
| **`presentation.patch`** | `slide_index` (int), `action` (string), `content` (string), `title` (string) | Applies a targeted slide modification without regenerating the deck. |
| **`presentation.export`** | `slides_markdown` (string), `title` (string), `theme` (string) | Compiles slides into an editable `.pptx` file stored in CAS via the render runner. |
| **`presentation.source.structure`** | `file_hash` (string), `file_name` (string) | Extracts PDF table of contents and page counts for presentation planning. |
| **`presentation.source.extract`** | `file_hash` (string), `page_from` (int), `page_to` (int) | Extracts bounded text from PDF page ranges for slide authoring. |
| **`presentation.source.video_structure`** | `url` (string) | Extracts YouTube chapters and video duration. |
| **`presentation.source.video_extract`** | `video_id` (string), `start_sec` (float), `end_sec` (float) | Extracts caption text for a specified video time range. |

---

## 5. Instruction Macro (`inst.presentation`)

Defined in `ai.inst` (seeded via `_/schemas/inst.sql`):
- **ID**: `inst.presentation`
- **Scope**: `global`
- **Priority**: `150`
- **Phrases**: `presentation`, `presentasi`, `slide`, `slides`, `slide deck`, `bikin slide`, `buat slide`, `bikin presentasi`, `buat presentasi`, `pitch deck`, `powerpoint`, `keynote`, `marp`, `slide-patch`.
- **Triggers**: `tool_include:presentation.create`, `tool_include:presentation.patch`.
- **Include Tools**: `['presentation.create', 'presentation.patch', 'presentation.export', 'presentation.source.structure', 'presentation.source.extract', 'presentation.source.video_structure', 'presentation.source.video_extract']`.
- **Fast Path Steering**:
  When the user provides a topic and slide count, the LLM must invoke `presentation.create` immediately on turn 1 without delay or preliminary clarification.
