#!/usr/bin/env python3
"""Download http(s) avatars into ai.file_blob_* and set signed /fs/ pic URLs."""

import hashlib
import mimetypes
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_lib import CAS_SECRET, C35_DB, cas_sign_path, connect

INLINE_MAX = 524_288


def blake3_hex(data: bytes) -> str:
    try:
        import blake3

        return blake3.blake3(data).hexdigest()
    except ImportError:
        return hashlib.sha256(data).hexdigest()


def main() -> int:
    if not CAS_SECRET:
        print("CAS_HMAC_SECRET required for signed pic URLs", file=sys.stderr)
        return 1
    c35 = connect(C35_DB)
    c35.autocommit = False
    migrated = 0
    skipped = 0
    try:
        with c35.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT id, name, pic
                FROM ai.identity
                WHERE is_active = true
                  AND pic IS NOT NULL
                  AND pic LIKE 'http%'
                ORDER BY id
                """
            )
            rows = cur.fetchall()
            for row in rows:
                url = row["pic"].strip()
                try:
                    req = urllib.request.Request(url, headers={"User-Agent": "c35-avatar-migrate/1.0"})
                    with urllib.request.urlopen(req, timeout=30) as res:
                        data = res.read(INLINE_MAX + 1)
                        mime = res.headers.get_content_type() or "image/jpeg"
                except Exception as e:
                    print(f"skip {row['id']} {row['name']}: {e}", file=sys.stderr)
                    skipped += 1
                    continue
                if len(data) == 0 or len(data) > INLINE_MAX:
                    print(f"skip {row['id']} size={len(data)}", file=sys.stderr)
                    skipped += 1
                    continue
                if not mime.startswith("image/"):
                    mime = mimetypes.guess_type(url)[0] or "image/jpeg"
                h = blake3_hex(data)
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, created_ts)
                    VALUES (%s, %s, %s, true, NOW())
                    ON CONFLICT (hash_blake3) DO UPDATE SET mime_type = EXCLUDED.mime_type, is_inline = true
                    """,
                    (h, len(data), mime),
                )
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_inline (hash_blake3, bytes)
                    VALUES (%s, %s)
                    ON CONFLICT (hash_blake3) DO UPDATE SET bytes = EXCLUDED.bytes
                    """,
                    (h, psycopg2.Binary(data)),
                )
                cur.execute(
                    "UPDATE ai.identity SET pic = %s, updated_ts = NOW() WHERE id = %s",
                    (cas_sign_path(CAS_SECRET, h), row["id"]),
                )
                migrated += 1
        c35.commit()
        print(f"migrated={migrated} skipped={skipped}")
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
