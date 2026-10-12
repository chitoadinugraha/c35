# File CAS (LOCKED)

Status: **locked** 2026-09-21

Content-addressed blobs for avatars, chat attachments, product pics, release zips.

## Storage tiers

| Size | `store` | Bytes live in |
|------|---------|---------------|
| `< 512 KiB` | `inline` | `ai.file_blob_inline` |
| `≥ 512 KiB` | `s3` | OCI/S3-compatible (`loc.key` = `fs/{hash}`) |
| dev fallback | `disk` | `CAS_DIR/{prefix}/{hash}` (optional) |

Constant: `CAS_INLINE_MAX_BYTES = 524_288` in `mod_file`.

## Schema

See [`../schemas/file.sql`](../schemas/file.sql).

| Table | Purpose |
|-------|---------|
| `ai.file_blob_meta` | hash, mime, size, store, loc, **variants** |
| `ai.file_blob_inline` | inline bytes; CASCADE delete with meta |

### Variants (canonical row only)

```json
{ "thumb": "abc…", "small": "def…" }
```

Derivative hashes are separate meta rows. Set via `file_variant_set` after optimize worker runs.

### Document index

Variant key `doc_index` is a separate CAS blob (`application/json`) referenced from `ai.file_blob_meta.variants`, same slot pattern as `thumb` / `small`. It is built on first read of a PDF, DOCX, or PPTX. The image optimize worker does not build it.

Original bytes stay the canonical hash. The index is never a replacement for the file.

Kinds: `pdf`, `docx`, `pptx`. Legacy `doc`, `ppt`, `xls`, and `xlsx` are out of scope.

| Cap | Limit |
|-----|-------|
| Parse size | 32 MiB |
| Zip entries | 200 |
| Zip uncompressed | 32 MiB |
| Outline entries | 80 |
| Chars per page or slide | 8000 |
| Total index chars | 200000 |
| Prompt outline | 2000 chars |
| Extract default | 14000 chars |
| Extract absolute | 32000 chars |
| OCR pages per turn | 4 |
| Parse timeout | 5 seconds |

Local parse is free (no LLM). OCR of an empty PDF page that has an embedded image is billed by chat via the parent turn `extra_cost_usd`. `mod_file` does not bill that OCR. A cache hit is not billed again.

```json
{
  "kind": "pdf",
  "name": "brief.pdf",
  "units": "pages",
  "outline": [{ "title": "Intro", "unit": 1, "level": 1 }],
  "pages": [{ "n": 1, "text": "...", "chars": 12, "needs_ocr": false }]
}
```

Image bytes are not stored in the JSON.

## HTTP

| Route | Auth |
|-------|------|
| `GET /fs/{hash}` | signed URL, session, or public site blob (avatar, product/object pic, storefront post thumb, hash cited in site draft or publish doc) |
| `HEAD /fs/{hash}` | same |
| `GET /fs/{hash}?v=thumb` | resolves variant on canonical |
| `PUT /fs/{hash}` | session required for **new** blobs; existing hash → `204` without re-upload |
| `POST /v1/file/upload` | session required |

Headers: ETag = hash, `Cache-Control: public, max-age=31536000, immutable`, `If-None-Match` → 304.

## References

| Project | Borrow |
|---------|--------|
| `D:\csa_site_published` | S3 backend, HEAD/ETag/304, hash verify |
| `E:\Project Archive\csa_os` | variants JSON design |
| `D:\cs_agent` | turbojpeg for JPEG `small` variant |

## Blob attribution (`ai.blob_ref`)

Each kept CAS hash can be indexed per **scope** for rollups and GC:

| Column | Meaning |
|--------|---------|
| `billable_owner_iid` | User billed for the bytes (rollup key) |
| `scope_kind` | `user` \| `site` \| `bot` \| `mailbox` |
| `scope_iid` | Identity id (user/site/bot) or `mail.mailbox.id` |
| `source` / `source_key` | Writer idempotency (`chat_msg:…`, `drive:{id}`, `variant:thumb:…`) |

**Tool:** `storage.usage` (account / site / bot / mailbox; staff may set `subject_*` for director/root).

**Query:** `storage_usage_account` / `storage_usage_scope` in `c35_mod_file` join `ai.file_blob_meta` for sizes. `total_bytes` uses **distinct** hashes per owner; per-scope rows sum attributed bytes (may double-count shared hashes).

**Backfill:** `.\_\scripts\dev\backfill_blob_ref.ps1` after deploy. New uploads also write refs from chat, drive, tool artifacts, and variant propagation.

## References (legacy surfaces)

Hashes are still cited directly in:

| Surface | Field / pattern |
|---------|-----------------|
| Chat | `ai.chat_msg.attachments`, `blocks_json`, `content` (`/fs/{hash}` or 64-hex) |
| Drive | `ai.drive_file.hash_blake3` |
| Tool traces | `ai.tool_artifact.hash_blake3` (FK; evict after TTL) |
| Mail | `mail.message.attachments_json` |
| Prompt runs | `ai.prompt_run.attachments_json` |
| Releases | `ai.config.value_json` (`hash` for APK/agent) |
| Identity avatar | `ai.identity.pic` |
| Site | `site.product` (`pic`, `product_json`), `site.object.pic`, `site.post` thumb/media, `site.draft` / `site.publish` `doc_json`, `site.member_face.file_hash` |
| Variants | `ai.file_blob_meta.variants` on canonical rows (`thumb`, `small`, `doc_index`, …) |

Guest `GET /fs` public access uses the same site/identity/product rules as `cas_is_public` in `mod_file`.

## Orphan GC

Inline blobs with **no** root reference (above) and **not** reachable as a variant of a kept canonical row may be removed to reclaim YB disk.

- SQL CTE: [`../schemas/cas_gc.sql`](../schemas/cas_gc.sql)
- Drivers:
  - `.\_\scripts\dev\fs_gc.ps1` — inline + S3 (dry-run default)
  - `.\_\scripts\dev\cleanup_cas_orphans.ps1` — inline only (`-MinAgeDays 0` deletes recent orphans; default filter: small `image/jpeg`/`image/webp`)
  - `.\_\scripts\dev\cleanup_cas_s3_orphans.ps1` — `store=s3` rows not in `cas_kept` (deletes object `fs/{hash}` then meta)

Run during low traffic; full scans over millions of CAS rows can take minutes. Always dry-run first.

## Image optimize

Thumb (`image/webp`, max 320px) and `small` (`image/jpeg`, max 1280px) are **lazy by default**:

- **Upload** (`cas_put`): stores canonical bytes only. No variants unless `IMAGE_OPTIMIZE_ON_PUT=1` or `CasPutOptions { optimize_image: true }`.
- **First read**: `GET /fs/{canonical}?v=thumb` or `?v=small` runs optimize once (sync on that request), writes variant CAS rows, sets `variants` on the canonical meta row, then serves the variant.

Derivative `cas_put` from the optimize worker uses `CasPutOptions::derivative` (never re-optimizes variant blobs).

## Implementation

Crate: `servers/crates/mod_file`

All multi-row writes use **SQL transactions** (meta + inline, or meta + S3 then commit).
