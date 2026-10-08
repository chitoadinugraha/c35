# Ask image generate — multitask plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement task-by-task. Subagent model: **inherit** (see `.cursor/rules/subagent-model.mdc`). Steps use checkbox (`- [ ]`) syntax.

**Goal:** A reusable image-generate dialog for site assets (product photo, extra photos, site icon), plus a chat tool that writes a generated picture onto the mentioned site.

**Architecture:** One server function generates the image and charges the **frontier** ring only. The Flutter dialog and `askMedia(allowGenerate: true)` call it through a new wire RPC. Chat does not call the dialog; `site.pic.generate` calls the same server function and writes `identity.pic` or `site.product.pic` / `pics`. Default prompts are English scene descriptions, built in Dart for the dialog and in Rust for the tool, locked by the same strings.

**Tech stack:** Flutter `clients/app`, Rust `mod_billing` + `mod_chat` + `wire_http`, proto `wire.proto`, `ai.inst` seed in `_/schemas/inst.sql`.

**Specs:** [`spec.md`](../../spec.md) | [`_/specs/image.md`](../image.md) | [`_/specs/site.md`](../site.md) | [`_/specs/inst.md`](../inst.md)

---

## Global constraints

- Dialog quota copy, exact: `This uses your frontier API quota.`
- Empty-quota error, exact: `Not enough frontier quota`
- Generate path does **not** fall through to the alien ring or the on-demand wallet.
- `askMedia` `allowGenerate` defaults to **false**. Consumption, composer, payments, referrals, and face photos stay false.
- Model picker values are `MediaGenerationPrefs.imageProviders`: `auto`, `gemini`, `grok`. Initial selection is `MediaGenerationPrefs.instance.image`.
- Aspect ratio for these slots is `1:1`. Quality is `draft` (server tier still applies).
- Alien badge uses `UiAlienIcon` (`clients/app/lib/widgets/ai/ui_alien_icon.dart`).
- Do not add provider web grounding. Do not steer Home chat with new Rust phrase lists except the web pipeline exclusion in `prompt-run-test.mdc`. Site picture intent goes in `ai.inst`.
- Image models stay the tiers in `_/specs/image.md`. This feature does not add a new provider.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Product badge | Replace the camera glyph on the product hero tile with `UiAlienIcon`. Tap opens `askImageGenerate` for slot `product`. The tile body tap still picks a file (`askMedia`, `allowGenerate: false`). |
| More photos | `askMedia(..., allowGenerate: true, generateSlot: productExtra)`. Generate is a third source next to camera/gallery (desktop: next to the file picker). |
| Site icon | Site Info avatar uses `askImageGenerate` slot `siteIcon`, and still offers upload via the existing file pick as a second action. |
| Result strip | Each successful generate **appends**. Regenerate does not replace earlier results. Use Image returns the selected item and closes. |
| Prompt edit | Textarea is prefilled and editable. Regenerating sends the current textarea, not a hidden original. |
| Desc in prompt | Non-empty trimmed `desc` is appended after the name. The fixed tail still says no text / no logo / no watermark. |
| Empty name | Prefill is empty. Generate stays disabled until the textarea is non-empty. |
| Chat | `site.pic.generate` writes the asset. `img.generate` stays for images that are only shown in chat. When this inst matches, exclude `img.generate`. |
| Chat slot | Product name in the user text or `product_query` → product hero. Extra-photo wording (`more photos`, `foto tambahan`) → append `pics`. Otherwise site icon. |

## Prompt strings (exact)

`{name}` and `{desc}` are trimmed. `{desc}` clause is omitted when desc is empty (no trailing comma before the studio clause).

**product and productExtra, name only**

```
Photorealistic product photo of {name}, studio lighting, centered, plain background, no text, no logo, no watermark
```

**product and productExtra, name and desc**

```
Photorealistic product photo of {name}, {desc}, studio lighting, centered, plain background, no text, no logo, no watermark
```

**siteIcon, name only**

```
Simple app icon of {name}, flat graphic mark, centered, plain background, no text, no letters, no watermark
```

**siteIcon, name and desc**

```
Simple app icon of {name}, {desc}, flat graphic mark, centered, plain background, no text, no letters, no watermark
```

Example: name `es teh`, empty desc → `Photorealistic product photo of es teh, studio lighting, centered, plain background, no text, no logo, no watermark`.

Example: name `es teh`, desc `teh manis dalam gelas plastik` → `Photorealistic product photo of es teh, teh manis dalam gelas plastik, studio lighting, centered, plain background, no text, no logo, no watermark`.

## File map

| File | Action |
|------|--------|
| `clients/app/lib/c/media/image_generate_prompt.dart` | **Create** — slot enum + default prompt |
| `clients/app/test/image_generate_prompt_test.dart` | **Create** |
| `servers/crates/mod_billing/src/billing_profile.rs` | **Modify** — frontier-only try-deduct |
| `servers/crates/mod_billing/src/lib.rs` | **Modify** — export the new fn |
| `servers/crates/mod_chat/src/tools/asset_image.rs` | **Create** — shared generate + frontier charge |
| `servers/crates/mod_chat/src/tools/mod.rs` | **Modify** — mod + pub use |
| `_/schemas/proto/c35/wire.proto` | **Modify** — `ReqImgGenerate` / `ResImgGenerate` |
| `servers/crates/wire_http` handler for wire oneof | **Modify** — dispatch the new RPC |
| `clients/app/lib/c/media/image_generate_api.dart` | **Create** — dart client |
| `clients/app/lib/widgets/media/ui_ask_image_generate.dart` | **Create** — dialog |
| `clients/app/lib/c/media/ask_media.dart` | **Modify** — `allowGenerate` |
| `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart` | **Modify** — alien badge + extra photos |
| `clients/app/lib/widgets/sites/editor/ui_site_info_editor.dart` | **Modify** — icon generate |
| `servers/crates/mod_chat/src/tools/builtin/site_pic.rs` | **Create** — `site.pic.generate` |
| `_/schemas/inst.sql` | **Modify** — `inst.task.site_pic_generate` |
| `_/specs/image.md` | **Modify** — dialog + frontier gate |
| `_/specs/site.md` | **Modify** — asset picture tool |

Find the wire oneof handler by searching `site_product_put` in `servers/crates/wire_http`. Add the new variant beside that match. Regenerate dart/rust proto the way neighboring RPCs were generated (do not hand-edit `*.pb.dart` if a script exists; search `wire.proto` comments or `_/scripts` for `protoc`).

---

## Interfaces

Later tasks use these names. Do not rename them.

### Dart prompt

```dart
enum ImageGenerateSlot { product, productExtra, siteIcon }

String imageGenerateDefaultPrompt({
  required ImageGenerateSlot slot,
  required String name,
  String desc = '',
});
```

Empty trimmed name returns `''` for every slot.

### Dart dialog

```dart
class GeneratedImage {
  const GeneratedImage({required this.hash, required this.url, required this.prompt});
  final String hash;
  final String url;
  final String prompt;
}

Future<GeneratedImage?> askImageGenerate(
  BuildContext context, {
  required ChatConn conn,
  required ImageGenerateSlot slot,
  required String name,
  String desc = '',
});
```

Null means dismiss or cancel. A value means Use Image.

### Dart API

```dart
class ImageGenerateResult {
  final String hash;
  final String url;
  final String mime;
}

Future<ImageGenerateResult> imageGenerate(
  ChatConn conn, {
  required String prompt,
  required String provider, // auto | gemini | grok
});
```

Throws `ImageGenerateQuotaException` when the server says frontier quota is insufficient. Message shown in the dialog: `Not enough frontier quota`.

### askMedia

Add optional named args, defaults preserve every current caller:

```dart
Future<List<StagedMedia>?> askMedia({
  BuildContext? context,
  List<MediaType> types = const [MediaType.image, MediaType.document],
  bool allowMultiple = true,
  int maxCount = defaultMaxMediaFiles,
  int maxBytesPerFile = defaultMaxFileBytes,
  bool allowGenerate = false,
  ChatConn? conn,
  ImageGenerateSlot generateSlot = ImageGenerateSlot.productExtra,
  String generateName = '',
  String generateDesc = '',
});
```

When generate succeeds, return one `StagedMedia` with `hash` set to the CAS hash, `bytes` empty, `mime` from the response, `name` `generated.png`. Callers that already have a hash must **not** call `casUpload`.

### Rust billing

```rust
/// Frontier ring only. Ok(true) when remaining USD >= cost and the deduct committed.
/// Ok(false) when frontier remaining is short. Does not touch alien rings or wallet.
pub async fn billing_frontier_try_deduct(
    pool: &PgPool,
    owner_iid: i64,
    cost_usd: f64,
) -> Result<bool>;
```

Remaining USD is the frontier half of `profile_ring_remaining_usd` after the same window roll `billing_profile_deduct_rings` already does. Deduct with `ring_deduct_pair` on `frontier_allow_5h_*` and `frontier_allow_weekly_*` only. If overflow > 0, roll back and return `Ok(false)`.

### Rust generate

```rust
pub struct AssetImage {
    pub hash: String,
    pub url: String,
    pub mime: String,
    pub prompt: String,
}

pub async fn asset_image_generate(
    pool: &PgPool,
    owner_iid: i64,
    client: &reqwest::Client,
    prompt: &str,
    provider: &str,
) -> Result<AssetImage>;
```

Steps: trim prompt, bail if empty; tier = `image_tier_resolve` with empty mentions, user text = prompt, quality `draft`, edit = false; retail = `image_tier_retail_usd`; `billing_frontier_try_deduct` **before** the provider call; on false, `bail!("Not enough frontier quota")`; then `img_generate_exec(..., aspect 1:1, quality draft, provider)`. Map `file_hash` / url from that JSON (`block.body.hash`, `block.body.url`, `block.body.mime`).

### Rust tool

Name: `site.pic.generate`

Aliases: `site_pic_generate`, `site.pic_generate`

Parameters:

| Arg | Required | Notes |
|-----|----------|--------|
| `prompt` | no | When empty, build from slot + product/site name + product desc |
| `slot` | no | `icon`, `product`, `product_extra`. Empty → routing rule below |
| `product_query` | no | Match `site_product_match` |
| `provider` | no | `auto` / `gemini` / `grok`, else user `generation.image` |

Site id: `site_iid_resolve` in `builtin/site.rs` (mention, else ctx.site_iid).

Slot when `slot` is empty:

1. User text or args contain `foto tambahan` or `more photos` → `product_extra`
2. `product_query` non-empty, or `product_match_classify` finds one product → `product`
3. Else → `icon`

Writes:

- `icon`: set `ai.identity.pic` for that site identity to `fileStoragePath`-equivalent stored by site info (`identity` pic column the Info editor already writes). Read `ui_site_info_editor.dart` `_pickAvatar` and the identity put it calls; persist the same path shape `fs/<hash>` or whatever `fileStoragePath` returns. Match that string.
- `product`: `UPDATE site.product SET pic = $path` for the matched product.
- `product_extra`: append path to the product `pics` JSON the editor uses (`siteProductApplyPics` / column read in `site_product_json.dart`). Do not duplicate `pic`.

Return JSON: `ok`, `slot`, `site_iid`, `product_id` (0 for icon), `hash`, `url`, `pic`.

Inst id: `inst.task.site_pic_generate`

```
[SITE PICTURE] When the user asks to create, draw, or generate a picture, photo, or icon for a mentioned site or one of its products, call site.pic.generate. Expand the visual prompt in English. Slot icon updates the site icon. Slot product replaces the product photo. Slot product_extra appends an extra photo. Do not call img.generate for this — the tool saves the file onto the site.
```

Triggers: `tool_include:site.pic.generate`, `tool_exclude:img.generate`.

Phrases (substring, Indonesian and English): `buatkan gambar`, `gambar untuk`, `foto produk`, `icon`, `ikon`, `generate image`, `generate icon`, `more photos`, `foto tambahan`.

`include_tools`: `site.pic.generate`. `exclude_tools`: `img.generate`.

Apply with `inst_put` after the SQL seed so the live row exists. Git seed alone is not live (`prompt-run-test.mdc`).

---

## Multitask waves

```
WAVE 1  P1  Dart prompt helper + unit test
        B1  billing_frontier_try_deduct + unit test
WAVE 2  S1  asset_image_generate
        W1  wire RPC + dart imageGenerate client
WAVE 3  D1  askImageGenerate dialog
        A1  askMedia allowGenerate
WAVE 4  U1  product hero alien badge
        U2  more photos allowGenerate
        U3  site info icon
WAVE 5  T1  site.pic.generate + inst.sql + inst_put
        T2  prompt_compose + prompt_run
WAVE 6  DOC image.md + site.md
        V1  flutter analyze, cargo test, utf8 check
```

### Parallel assignment

| Wave | Agent A | Agent B |
|------|---------|---------|
| 1 | P1 prompt | B1 frontier deduct |
| 2 | S1 asset_image_generate | W1 wire + dart client (after S1 signature exists; start proto in parallel, call S1 at the end) |
| 3 | D1 dialog | A1 askMedia |
| 4 | U1 + U2 product editor | U3 site info |
| 5 | T1 tool + inst | T2 prompt_run after T1 inst_put |
| 6 | DOC | V1 |

Do not edit this plan file from a track agent.

---

## Track details

### P1 — Prompt helper

**Files:** `clients/app/lib/c/media/image_generate_prompt.dart`, `clients/app/test/image_generate_prompt_test.dart`

- [x] **P1.1** Write `image_generate_prompt_test.dart` with these cases:
  - product, `es teh`, desc `''` equals the name-only product string above
  - product, `es teh`, desc `teh manis dalam gelas plastik` equals the name+desc product string
  - productExtra uses the same two strings as product
  - siteIcon, `testing`, desc `''` equals the icon string
  - siteIcon with desc `warung teh` equals the icon+desc string
  - whitespace name returns `''`
  - desc that is only spaces is treated as empty
- [x] **P1.2** Run `flutter test test/image_generate_prompt_test.dart` from `clients/app`. Expect fail (library missing).
- [x] **P1.3** Implement `imageGenerateDefaultPrompt` to satisfy the cases.
- [x] **P1.4** Re-run the test. Expect pass.

### B1 — Frontier deduct

**Files:** `servers/crates/mod_billing/src/billing_profile.rs`, `lib.rs`, existing billing tests.

- [x] **B1.1** Add a unit test around `ring_deduct_pair` behavior the helper relies on: frontier used/limit that cannot cover `0.05` USD returns not deducted; a limit with room covers it and increases frontier used only.
- [x] **B1.2** Implement `billing_frontier_try_deduct`. Export it from `mod_billing`.
- [x] **B1.3** `cargo test -p c35_mod_billing` from `servers/`. Expect the new test pass. Do not change `billing_can_afford_tool` (chat `img.generate` keeps rings + wallet).

### S1 — Shared generate

**Files:** `servers/crates/mod_chat/src/tools/asset_image.rs`, `tools/mod.rs`

- [x] **S1.1** Implement `asset_image_generate` as specified. Preflight deduct **before** `img_generate_exec`.
- [x] **S1.2** On `Ok(false)` from deduct, return `Err` whose Display is exactly `Not enough frontier quota`.
- [x] **S1.3** `cargo build -p server_ai` from `servers/`.

`img_generate_exec` currently has its own afford check inside the tool wrapper, not inside `img_generate_exec`. Call `img_generate_exec` directly so the wallet check in `ImgGenerateTool` is not a second gate. Frontier deduct in S1 is the only gate for this path.

### W1 — Wire RPC

**Files:** `_/schemas/proto/c35/wire.proto`, wire handler, `clients/app/lib/c/media/image_generate_api.dart`

Message fields:

```
ReqImgGenerate: prompt string, provider string
ResImgGenerate: hash string, url string, mime string, error string
```

- [x] **W1.1** Add the messages and oneof tags at the next free field numbers. Follow the next integer after the current max in each oneof.
- [x] **W1.2** Handler: authenticated owner iid, call `asset_image_generate`. Map quota bail to `error = "Not enough frontier quota"` and empty hash. Other errors use the project’s existing friendly error string path.
- [x] **W1.3** Dart `imageGenerate` sends the RPC and throws `ImageGenerateQuotaException` when `error` equals that sentence or hash is empty with that error.
- [x] **W1.4** `cargo build -p server_ai` from `servers/`.

### D1 — Dialog

**Files:** `clients/app/lib/widgets/media/ui_ask_image_generate.dart`

Layout, dark, consistent with site editor dialogs (`showDialog`, scrollable):

1. Title: `Generate image`
2. Provider dropdown: Auto, Gemini, Grok. Value from `MediaGenerationPrefs.instance.image`.
3. Multiline prompt, min 4 lines, prefilled by `imageGenerateDefaultPrompt`.
4. Caption: `This uses your frontier API quota.`
5. Primary button `Generate`. Disabled when prompt is empty or a request is in flight.
6. After at least one result: horizontal list of thumbnails (`url`). The latest is selected. `Regenerate` runs generate again and appends. `Use image` pops `GeneratedImage` for the selection.
7. Quota failure: inline text `Not enough frontier quota`. Leave prior thumbnails in place. Do not close.

- [x] **D1.1** Implement `askImageGenerate` and the dialog. No second copy of the prompt strings; call the helper.
- [x] **D1.2** Changing the dropdown does not write settings. It only overrides `provider` for this dialog session.

### A1 — askMedia flag

**File:** `clients/app/lib/c/media/ask_media.dart`

- [x] **A1.1** Add the named args. Default `allowGenerate: false`.
- [x] **A1.2** When `allowGenerate` is true and the pick is image-only and `context` is mounted, add a Generate action (`UiAlienIcon` + label `Generate`) to `_askImageSource`. On that choice, `await askImageGenerate(...)` with `generateSlot`, `generateName`, `generateDesc`. Map a non-null result to the staged hash contract. Cancel returns null so the sheet can dismiss without a file.
- [x] **A1.3** Desktop / non-mobile image pick: if `allowGenerate`, show the same three-choice sheet (Files, Generate) before `FilePicker`. Files keeps today’s picker.
- [x] **A1.4** Grep `askMedia(` under `clients/app`. Every existing call stays `allowGenerate` false because the new arg defaults false. Do not pass true except the product extra-photo call in U2.

### U1 — Product hero

**File:** `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart`

- [x] **U1.1** Split the tile: body tap stays `_pickPic` (upload). The bottom-right badge is its own `InkWell` that stops the tile tap and calls `askImageGenerate(slot: product, name: _nameCtrl.text, desc: _descCtrl.text)`.
- [x] **U1.2** Badge child: `UiAlienIcon(size: 14, color: Colors.white)` inside the existing dark rounded box. Remove `Icons.photo_camera_outlined` from this badge only.
- [x] **U1.3** On a returned image, set `product.pic` to the same path shape `_pickPic` writes (`fileStoragePath(hash)`) and `productPut`. Skip `casUpload`.

### U2 — More photos

**File:** `ui_site_product_detail.dart` `_pickExtraPics`

- [x] **U2.1** Call `askMedia` with `allowGenerate: true`, `generateSlot: ImageGenerateSlot.productExtra`, `generateName: _nameCtrl.text`, `generateDesc: _descCtrl.text`.
- [x] **U2.2** If `staged.hash` is non-empty, append `fileStoragePath(hash)` and skip `casUpload`. Otherwise keep the current upload loop.

### U3 — Site icon

**File:** `clients/app/lib/widgets/sites/editor/ui_site_info_editor.dart`

- [x] **U3.1** Avatar tap opens a small chooser: `Upload` (existing `_pickAvatar` body) and `Generate` (`askImageGenerate(slot: siteIcon, name: site name, desc: tagline)`).
- [x] **U3.2** Generate success writes pic through the same identity update `_pickAvatar` uses, with `fileStoragePath(hash)`, no second upload.
- [x] **U3.3** Put `UiAlienIcon` on the generate choice. Leave the empty-avatar placeholder icon as it is.

### T1 — Chat tool

**Files:** `servers/crates/mod_chat/src/tools/builtin/site_pic.rs`, tool registry, `_/schemas/inst.sql`

- [x] **T1.1** Register `site.pic.generate` with the definition above. Topics: `site`, `image`. UI keys: `tool.site.pic.generate.calling` = `Generating site image…`, `tool.site.pic.generate.done` = `Updated site image`.
- [x] **T1.2** Resolve site, slot, and product. Build the default prompt with the **exact** strings in this plan (Rust twin of P1, including empty-desc punctuation). If the model passed `prompt`, use that string instead.
- [x] **T1.3** Call `asset_image_generate`. Persist the path. Return the JSON contract.
- [x] **T1.4** Unit-test slot choice and prompt assembly without a network call (pure functions extracted from the tool).
- [x] **T1.5** Insert `inst.task.site_pic_generate` in `inst.sql` using the same UPSERT style as `inst.task.img_generate`. Then `inst_put` the live row on the agent MCP.
- [x] **T1.6** `cargo test -p c35_mod_chat` for the new tests, from `servers/`.

### T2 — Prompt verification

Blocked 2026-10-08: `prompt_compose` to `http://127.0.0.1:8080/v1/mcp/agent` failed (fetch failed). `inst_get` shows `inst.task.site_pic_generate` in the database. `inst_put` cache publish failed with `getaddrinfo ENOTFOUND nats.c35.svc.cluster.local`, so running pods may still be on the previous inst cache until NATS publish or process reload.

Owner iid **33000** for automated regression.

- [ ] **T2.1** `prompt_compose` phrase `buatkan gambar untuk @mention site` with a site mention in context. Expect `inst.task.site_pic_generate` in `inst_ids` and `site.pic.generate` in `selected_tools`. `img.generate` must not be selected on that compose.
- [ ] **T2.2** `prompt_compose` phrase `buatkan gambar es teh di` plus the site mention. Expect the same inst, and the tool fed.
- [ ] **T2.3** `prompt_run` the product phrase on iid 33000 only if a seed site exists for 33000. Assert hop 1 tool is `site.pic.generate`, and the reply does not say the image could not be saved when the tool returns `ok: true`. If frontier quota on 33000 is empty, assert the tool error text is `Not enough frontier quota` and stop. Do not point this run at iid 99000.

### DOC — Docs

- [x] **DOC.1** `_/specs/image.md`: dialog, frontier-only gate, exact error string, slots. Note chat `img.generate` still uses `billing_can_afford_tool`.
- [x] **DOC.2** `_/specs/site.md`: `site.pic.generate` slots and the editor entry points.

### V1 — Checks

- [ ] **V1.1** `clients/app`: `flutter test test/image_generate_prompt_test.dart` and `./_/scripts/dev/verify_flutter_app.ps1` if the script is the repo’s analyze entry; otherwise `flutter analyze` on the touched dart files.
- [ ] **V1.2** `servers/`: `cargo test -p c35_mod_billing` and `cargo test -p c35_mod_chat` (the new tests at minimum) and `cargo build -p server_ai`.
- [ ] **V1.3** `./_/scripts/dev/check_utf8_sources.ps1 -Changed -Fix`

---

## Out of scope

- Consumption image generation
- Changing `img.generate` wallet fallback
- Video or music dialogs
- Publishing cluster images (`publish_server.ps1`) until a later request
- A user setting that picks Flash vs Lite; tier stays server-side `draft`

## Acceptance

1. Product hero badge is the alien. Tap opens the dialog prefilled for `es teh` with the product sentence. Upload still works from the tile body.
2. Generate with frontier remaining shows a thumbnail. Regenerate adds a second. Use Image sets `product.pic` and the preview updates.
3. Frontier remaining below the draft retail shows `Not enough frontier quota` and does not call the image provider.
4. More photos offers Generate. Consumption pickers do not.
5. Site Info can generate an icon with the icon sentence, not the product sentence.
6. Chat `buatkan gambar es teh` with the site mentioned calls `site.pic.generate` and stores the product photo.
