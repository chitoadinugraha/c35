#!/usr/bin/env python3
"""Copy CSA site logo blob and update Nate Paperie identity + draft pic."""
from __future__ import annotations

import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from migrate_lib import C35_DB, CSA_DB, CAS_SECRET, connect, pic_from_csa

SITE_IID = 80157132410142720
LOGO_HASH = "8f69fb2d59ca5a5261baab8ca7009527a762b739e7fd1460801a5e771041e47e"


def main() -> None:
    if not CAS_SECRET:
        raise SystemExit("CAS_HMAC_SECRET required")
    csa = connect(CSA_DB)
    c35 = connect(C35_DB)
    cur = csa.cursor()
    cur.execute(
        """
        SELECT m.hash, m.mime, m.size, i.body
        FROM file_meta m
        JOIN file_inline i ON i.hash = m.hash
        WHERE m.hash = %s
        LIMIT 1
        """,
        (LOGO_HASH,),
    )
    row = cur.fetchone()
    if not row:
        raise SystemExit(f"CSA blob missing: {LOGO_HASH}")
    hash_val, mime, size, body = row
    cur.close()

    cur = c35.cursor()
    cur.execute(
        "SELECT 1 FROM ai.file_blob_meta WHERE hash_blake3 = %s LIMIT 1",
        (hash_val,),
    )
    if not cur.fetchone():
        cur.execute(
            """
            INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, store, loc, variants)
            VALUES (%s, %s, %s, TRUE, 'inline', '{}'::jsonb, '{}'::jsonb)
            ON CONFLICT (hash_blake3) DO NOTHING
            """,
            (hash_val, int(size), mime or "image/png"),
        )
        cur.execute(
            """
            INSERT INTO ai.file_blob_inline (hash_blake3, bytes)
            VALUES (%s, %s)
            ON CONFLICT (hash_blake3) DO NOTHING
            """,
            (hash_val, body),
        )
        print(f"inserted blob {hash_val}")
    else:
        print(f"blob already present {hash_val}")

    signed = pic_from_csa(f"/fs/{hash_val}", CAS_SECRET)
    if not signed:
        raise SystemExit("sign failed")

    cur.execute(
        "UPDATE ai.identity SET pic = %s, updated_ts = now() WHERE id = %s",
        (signed, SITE_IID),
    )
    cur.execute(
        "SELECT doc_json FROM site.draft WHERE site_iid = %s AND deleted_ts IS NULL LIMIT 1",
        (SITE_IID,),
    )
    draft_row = cur.fetchone()
    if draft_row:
        doc = draft_row[0]
        if isinstance(doc, str):
            doc = json.loads(doc)
        meta = doc.get("meta") if isinstance(doc.get("meta"), dict) else {}
        meta["pic"] = signed
        doc["meta"] = meta
        for page in doc.get("pages") or []:
            if not isinstance(page, dict):
                continue
            for block in page.get("blocks") or []:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "hub_profile":
                    props = block.get("props") if isinstance(block.get("props"), dict) else {}
                    props["pic"] = signed
                    block["props"] = props
        cur.execute(
            "UPDATE site.draft SET doc_json = %s::jsonb, updated_ts = now() WHERE site_iid = %s AND deleted_ts IS NULL",
            (json.dumps(doc, ensure_ascii=False), SITE_IID),
        )
    c35.commit()
    print(f"updated site {SITE_IID} pic")
    cur.close()
    csa.close()
    c35.close()


if __name__ == "__main__":
    main()