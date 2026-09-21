#!/usr/bin/env python3
"""Migrate CSA users, referral tree, badges, and inline avatar blobs into c35 (ai schema)."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2.extras
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_lib import CSA_DB, C35_DB, CAS_SECRET, alien_id_of, connect, pic_from_csa


def main() -> int:
    csa = connect(CSA_DB)
    c35 = connect(C35_DB)
    csa.autocommit = False
    c35.autocommit = False
    try:
        with csa.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT u.uid, u.name,
                       COALESCE(NULLIF(TRIM(u.alien_id), ''), a.alien_id) AS alien_id,
                       COALESCE(u.pic, '') AS pic,
                       u.referred_by, u.is_root, (u.banned_at IS NULL) AS is_active,
                       COALESCE((SELECT json_agg(r.role ORDER BY r.role) FROM identity_user_global_role r WHERE r.uid = u.uid), '[]'::json) AS global_roles
                FROM identity_user u
                LEFT JOIN identity_alien_id a ON a.kind = 'user' AND a.ref_id = u.uid
                ORDER BY u.uid
                """
            )
            users = cur.fetchall()
            cur.execute("SELECT parent_uid, child_uid, share_percent FROM referral_share")
            shares = cur.fetchall()
            cur.execute("SELECT code, issued_by, expires_at, created_at FROM referral_code ORDER BY code")
            codes = cur.fetchall()
            cur.execute(
                """
                SELECT DISTINCT TRIM(LEADING '/fs/' FROM split_part(u.pic, '?', 1)) AS hash
                FROM identity_user u
                WHERE u.pic LIKE '/fs/%'
                """
            )
            pic_hashes = [r["hash"] for r in cur.fetchall() if r["hash"]]
            blobs = []
            if pic_hashes:
                cur.execute(
                    """
                    SELECT m.hash, m.mime, m.size, i.body
                    FROM file_meta m
                    JOIN file_inline i ON i.hash = m.hash
                    WHERE m.hash = ANY(%s) AND COALESCE(m.size, octet_length(i.body)) < 524288
                    """,
                    (pic_hashes,),
                )
                blobs = cur.fetchall()

        with c35.cursor() as cur:
            for u in users:
                meta = {"is_root": bool(u["is_root"]), "global_roles": u["global_roles"] or []}
                pic = pic_from_csa(u["pic"], CAS_SECRET)
                uid = int(u["uid"])
                cur.execute(
                    """
                    INSERT INTO ai.identity (
                        id, kind, type, alien_id, name, pic, owner_iid, billing_iid,
                        referred_by_iid, meta, is_active, created_ts, updated_ts
                    )
                    VALUES (%s, 'user', '', %s, %s, %s, %s, %s, %s, %s::jsonb, %s, NOW(), NOW())
                    ON CONFLICT (id) DO UPDATE SET
                        alien_id = EXCLUDED.alien_id,
                        name = EXCLUDED.name,
                        pic = EXCLUDED.pic,
                        owner_iid = EXCLUDED.owner_iid,
                        billing_iid = EXCLUDED.billing_iid,
                        referred_by_iid = EXCLUDED.referred_by_iid,
                        meta = EXCLUDED.meta,
                        is_active = EXCLUDED.is_active,
                        updated_ts = NOW()
                    """,
                    (
                        uid,
                        alien_id_of(u["alien_id"], uid),
                        u["name"],
                        pic,
                        uid,
                        uid,
                        u["referred_by"],
                        json.dumps(meta),
                        u["is_active"],
                    ),
                )
            for s in shares:
                cur.execute(
                    """
                    INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent, created_ts, updated_ts)
                    VALUES (%s, %s, %s, NOW(), NOW())
                    ON CONFLICT (parent_iid, child_iid) DO UPDATE SET
                        share_percent = EXCLUDED.share_percent,
                        updated_ts = NOW()
                    """,
                    (s["parent_uid"], s["child_uid"], s["share_percent"]),
                )
            for c in codes:
                cur.execute(
                    """
                    INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, created_ts, updated_ts)
                    VALUES (%s, %s, 0, %s, COALESCE(%s, NOW()), NOW())
                    ON CONFLICT (code) DO UPDATE SET
                        issued_by_iid = EXCLUDED.issued_by_iid,
                        expires_at = EXCLUDED.expires_at,
                        updated_ts = NOW()
                    """,
                    (c["code"], c["issued_by"], c["expires_at"], c["created_at"]),
                )
            for b in blobs:
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, created_ts)
                    VALUES (%s, %s, COALESCE(%s, 'application/octet-stream'), true, NOW())
                    ON CONFLICT (hash_blake3) DO NOTHING
                    """,
                    (b["hash"], b["size"] or len(b["body"] or b""), b["mime"]),
                )
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_inline (hash_blake3, bytes)
                    VALUES (%s, %s)
                    ON CONFLICT (hash_blake3) DO NOTHING
                    """,
                    (b["hash"], psycopg2.Binary(b["body"])),
                )
        c35.commit()
        print(f"migrated users={len(users)} shares={len(shares)} codes={len(codes)} blobs={len(blobs)} -> {C35_DB}")
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        csa.close()
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
