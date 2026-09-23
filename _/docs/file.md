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

## HTTP

| Route | Auth |
|-------|------|
| `GET /fs/{hash}` | signed URL, session, or public avatar |
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
