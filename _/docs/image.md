# Image generation and editing

Status: **locked** 2026-09-23

Tools `img.generate` (text-to-image) and `img.edit` (attachment/CAS → edited image). Steering lives in [`../schemas/inst.sql`](../schemas/inst.sql) and [`../schemas/mention.sql`](../schemas/mention.sql).

---

## Model tiers (server-enforced)

Tier selection runs in `servers/crates/mod_chat/src/tools/image_tier.rs` on **every** tool call. The LLM may pass `quality`, but the server re-resolves tier from mention ids + user text + tool prompt so billing and API model stay aligned.

| Tier id | Model | Size | Typical retail | When |
|---------|-------|------|----------------|------|
| `lite_draft` | `gemini-3.1-flash-lite-image` | 1K | ~$0.050 | Default generate |
| `flash_draft` | `gemini-3.1-flash-image` | 1K | ~$0.101 | Edit, retry phrases, escalation |
| `flash_hd` | `gemini-3.1-flash-image` | 2K | ~$0.152 | `@image-high`, `quality=hd`, logo/text phrases |
| `grok_draft` | `xai/grok-imagine-image` (optional) | 1K | ~$0.030 | Lite path only if `C35_IMG_PROVIDER=grok` + CF Gateway |
| fallback | `imagen-3.0-generate-002` | 1K | ~$0.053 | API fallback |

Wholesale constants: `servers/crates/mod_billing/src/billing_cost.rs`. Tool JSON returns `image_tier`, `provider_model`, `wholesale_usd` for audit.

---

## Routing priority (highest wins)

1. **`@image-high` mention** (`mention_ids` contains `image_high`) → `flash_hd`
2. **Tool arg** `quality=hd` → `flash_hd`
3. **HD phrases** in user text or tool prompt (logo, poster, text-in-image, 4k, …) → `flash_hd`
4. **`img.edit`** (any edit) → at least `flash_draft`; upgrades to `flash_hd` if 1–3 match
5. **Retry phrases** (try again, kurang bagus, coba lagi, …) → `flash_draft` on generate
6. **Default generate** → `lite_draft`

Attachments are **not** a tier signal. Attachments mean **edit source** (`img.edit`) or food logging (`consumption.add`), not “use Pro model”.

---

## Composer mentions

| Mention | Id | Effect |
|---------|-----|--------|
| `@image-high` | `image_high` | Always Flash Image 2K (`flash_hd`) |
| `@image` | `image` | Disabled — gen/edit routed via inst phrases |

Seed: `inst.mention.image_high` + `ai.mention` row `image_high`.

---

## Inst steering

| Inst | Role |
|------|------|
| `inst.core.assistant` | Block img tools on food/calorie photos; allow `img.edit` on explicit edit |
| `inst.task.img_generate` | Phrases → `img.generate`; explain draft vs hd |
| `inst.task.img_edit` | Phrases → `img.edit`; exclude generate |
| `inst.mention.image_high` | `@image-high` → quality hd + Flash |

Food inst rows use `tool_exclude:img.generate` and `tool_exclude:img.edit`.

---

## API

Primary: Gemini `interactions` with `response_format` (`aspect_ratio`, `image_size`). Fallback: `generateContent` with `imageConfig`. Edit input: multimodal `input` (text + inline image bytes from CAS).

Env:

| Var | Role |
|-----|------|
| `GEMINI_API_KEY` | Required for Gemini tiers |
| `C35_IMG_PROVIDER=grok` | Optional Lite-path Grok via CF (`cf_image.rs`) |
| `CLOUDFLARE_*` | CF Gateway for Grok path |

---

## Billing

Pre-flight: `image_tier_retail_usd(&tier)` before API call. Post-charge: `wholesale_usd` from tool result × 1.5 retail markup.

---

## Related

- [`inst.md`](inst.md) — inst pipeline
- [`../schemas/inst.sql`](../schemas/inst.sql) — seeds
- Plan: [`plans/2026-09-23-image-gen-multitask.md`](plans/2026-09-23-image-gen-multitask.md)
