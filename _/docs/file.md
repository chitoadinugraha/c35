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
| `POST /v1/file/upload` | session required |

Headers: ETag = hash, `Cache-Control: public, max-age=31536000, immutable`, `If-None-Match` → 304.

## References

| Project | Borrow |
|---------|--------|
| `D:\csa_site_published` | S3 backend, HEAD/ETag/304, hash verify |
| `E:\Project Archive\csa_os` | variants JSON design |
| `D:\cs_agent` | turbojpeg for JPEG `small` variant |

## Implementation

Crate: `servers/crates/mod_file`

All multi-row writes use **SQL transactions** (meta + inline, or meta + S3 then commit).
