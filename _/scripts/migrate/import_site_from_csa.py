#!/usr/bin/env python3
"""Import CSA site catalog + draft design into c35 (products, /fs blobs, SiteDoc)."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2.extras
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_auth_contact import map_uid
from migrate_csa_google import snowflake_id
from migrate_lib import CAS_SECRET, CSA_DB, C35_DB, connect, pic_from_csa

_REPO = Path(__file__).resolve().parents[3]
_SERVERS = _REPO / "servers"
_FS_HASH_RE = re.compile(r"/fs/([0-9a-fA-F]{64})")


def capabilities_from_modules(modules: list[str] | None) -> dict[str, Any]:
    mods = set(modules or [])
    return {
        "commerce": "products" in mods or "transaction" in mods,
        "booking": "booking" in mods or "reservation" in mods,
        "queue": "queue" in mods,
        "attendance": "attendance" in mods,
    }


def fallback_hub_doc(name: str) -> dict[str, Any]:
    return {
        "pages": [{
            "path": "/",
            "title": name,
            "blocks": [
                {"id": "hub1", "type": "hub_profile", "props": {"title": name, "subtitle": "", "show_hours": False}},
                {"id": "grid1", "type": "product_grid", "props": {"filter": "all", "page_size": 24}},
            ],
        }],
        "theme": {"accent": "#2563eb", "preset": "modern"},
        "meta": {},
    }


def decode_csa_site_doc(doc_bytes: bytes) -> dict[str, Any]:
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as tmp:
        tmp.write(doc_bytes)
        path = tmp.name
    try:
        proc = subprocess.run(
            [
                "cargo",
                "run",
                "--quiet",
                "--example",
                "csa_decode_site_doc",
                "-p",
                "c35_mod_site",
                "--",
                path,
            ],
            cwd=_SERVERS,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise RuntimeError(proc.stderr or proc.stdout or "csa_decode_site_doc failed")
        return json.loads(proc.stdout)
    finally:
        Path(path).unlink(missing_ok=True)


def collect_fs_hashes(value: Any, out: set[str]) -> None:
    if isinstance(value, str):
        for m in _FS_HASH_RE.finditer(value):
            out.add(m.group(1).lower())
    elif isinstance(value, dict):
        for v in value.values():
            collect_fs_hashes(v, out)
    elif isinstance(value, list):
        for v in value:
            collect_fs_hashes(v, out)


def rewrite_fs_strings(value: Any, secret: str) -> Any:
    if isinstance(value, str):
        m = _FS_HASH_RE.search(value)
        if m and value.strip().startswith("/fs/"):
            signed = pic_from_csa(f"/fs/{m.group(1)}", secret)
            return signed if signed else value
        return value
    if isinstance(value, dict):
        return {k: rewrite_fs_strings(v, secret) for k, v in value.items()}
    if isinstance(value, list):
        return [rewrite_fs_strings(v, secret) for v in value]
    return value


def copy_blob(csa_cur, c35_cur, hash_val: str) -> None:
    h = hash_val.lower()
    c35_cur.execute(
        "SELECT 1 FROM ai.file_blob_meta WHERE hash_blake3 = %s LIMIT 1",
        (h,),
    )
    if c35_cur.fetchone():
        return
    csa_cur.execute(
        """
        SELECT m.mime, m.size, i.body
        FROM file_meta m
        JOIN file_inline i ON i.hash = m.hash
        WHERE m.hash = %s
        LIMIT 1
        """,
        (h,),
    )
    row = csa_cur.fetchone()
    if not row:
        print(f"warn: CSA blob missing {h}", file=sys.stderr)
        return
    mime, size, body = row["mime"], row["size"], row["body"]
    c35_cur.execute(
        """
        INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, store, loc, variants)
        VALUES (%s, %s, %s, TRUE, 'inline', '{}'::jsonb, '{}'::jsonb)
        ON CONFLICT (hash_blake3) DO NOTHING
        """,
        (h, int(size or 0), mime or "application/octet-stream"),
    )
    c35_cur.execute(
        """
        INSERT INTO ai.file_blob_inline (hash_blake3, bytes)
        VALUES (%s, %s)
        ON CONFLICT (hash_blake3) DO NOTHING
        """,
        (h, body),
    )


def product_extras_from_csa(row: dict[str, Any]) -> dict[str, Any]:
    extra = row.get("extra")
    if isinstance(extra, str) and extra.strip():
        try:
            extra = json.loads(extra)
        except json.JSONDecodeError:
            extra = {}
    if not isinstance(extra, dict):
        extra = {}
    pj = dict(extra)
    pj["csa_product_id"] = row["id"]
    pj.setdefault("active", bool(row.get("active")))
    pj.setdefault("sort_order", int(row.get("sort_order") or 0))
    for key in (
        "stock_unit",
        "stock_warning_enabled",
        "stock_warning_qty",
        "stock_critical_enabled",
        "stock_critical_qty",
        "stock_show_to_customer",
        "stock_show_max_qty",
        "duration_value",
        "duration_unit",
        "reservation_unit_selection",
    ):
        if key in row and row[key] is not None and key not in pj:
            pj[key] = row[key]
    return pj


def import_site(alien_id: str, dry_run: bool) -> int:
    if not CAS_SECRET:
        print("CAS_HMAC_SECRET required", file=sys.stderr)
        return 1

    csa = connect(CSA_DB)
    c35 = connect(C35_DB)
    csa_cur = csa.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    c35_cur = c35.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    csa_cur.execute(
        """
        SELECT s.*, sc.doc, sc.modules
        FROM site s
        LEFT JOIN site_config sc ON sc.site_id = s.id
        WHERE s.alien_id = %s
        LIMIT 1
        """,
        (alien_id,),
    )
    site = csa_cur.fetchone()
    if not site:
        print(f"CSA site not found: {alien_id}", file=sys.stderr)
        return 1

    site_iid = int(site["id"])
    owner_iid = map_uid(int(site["owner_uid"]))
    name = (site["name"] or alien_id).strip()

    c35_cur.execute(
        "SELECT id FROM ai.identity WHERE id = %s AND kind = 'site'",
        (site_iid,),
    )
    if not c35_cur.fetchone():
        c35_cur.execute(
            """
            INSERT INTO ai.identity (
                id, kind, type, alien_id, name, owner_iid, locale, tz, meta, is_active, created_ts, updated_ts
            ) VALUES (
                %s, 'site', '', %s, %s, %s, 'id_ID', %s, '{}'::jsonb, TRUE, NOW(), NOW()
            )
            """,
            (site_iid, alien_id, name, owner_iid, site.get("timezone") or "Asia/Jakarta"),
        )
        grant_id = snowflake_id()
        c35_cur.execute(
            """
            INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, is_pinned, created_ts, updated_ts)
            VALUES (%s, %s, %s, 'owner', TRUE, NOW(), NOW())
            ON CONFLICT (resource_iid, grantee_iid) DO NOTHING
            """,
            (grant_id, site_iid, owner_iid),
        )
        caps = capabilities_from_modules(site.get("modules"))
        c35_cur.execute(
            """
            INSERT INTO site.config (
                site_iid, owner_iid, published_version_id, inventory_costing_method, tz,
                payroll_policy_json, presence_policy_json, capabilities_json, created_ts, updated_ts
            ) VALUES (
                %s, %s, %s, %s, %s, %s::jsonb, %s::jsonb, %s::jsonb, NOW(), NOW()
            )
            ON CONFLICT (site_iid) DO NOTHING
            """,
            (
                site_iid,
                owner_iid,
                site.get("published_version_id"),
                site.get("inventory_costing_method") or "fifo",
                site.get("timezone") or "Asia/Jakarta",
                json.dumps(site.get("payroll_policy_json") or {}),
                json.dumps(site.get("presence_policy_json") or {}),
                json.dumps(caps),
            ),
        )

    doc_json: dict[str, Any] = {"pages": [], "theme": {}, "meta": {}}
    doc_bytes = site.get("doc")
    if doc_bytes:
        try:
            doc_json = decode_csa_site_doc(bytes(doc_bytes))
        except Exception as e:
            print(f"warn: CSA doc decode failed ({e}); using hub template", file=sys.stderr)
            doc_json = fallback_hub_doc(name)

    hashes: set[str] = set()
    collect_fs_hashes(doc_json, hashes)

    csa_cur.execute(
        "SELECT * FROM site_product WHERE site_id = %s ORDER BY sort_order, id",
        (site_iid,),
    )
    products = list(csa_cur.fetchall())

    if not dry_run:
        c35_cur.execute("DELETE FROM site.product WHERE site_iid = %s", (site_iid,))

    for row in products:
        pic = (row.get("pic") or "").strip()
        for m in _FS_HASH_RE.finditer(pic):
            hashes.add(m.group(1).lower())

    for h in sorted(hashes):
        if not dry_run:
            copy_blob(csa_cur, c35_cur, h)

    doc_json = rewrite_fs_strings(doc_json, CAS_SECRET)

    if not dry_run:
        c35_cur.execute(
            """
            INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
            VALUES (%s, %s, %s::jsonb, NOW(), NOW())
            ON CONFLICT (site_iid) DO UPDATE SET
                doc_json = EXCLUDED.doc_json,
                owner_iid = EXCLUDED.owner_iid,
                updated_ts = NOW(),
                deleted_ts = NULL
            """,
            (site_iid, owner_iid, json.dumps(doc_json, ensure_ascii=False)),
        )

    inserted = 0
    for row in products:
        product_id = snowflake_id()
        archived = row.get("archived_at") is not None
        active = bool(row.get("active"))
        pic_raw = (row.get("pic") or "").strip()
        pic = pic_from_csa(pic_raw, CAS_SECRET) if pic_raw.startswith("/fs/") else pic_raw
        pj = product_extras_from_csa(row)
        if not dry_run:
            c35_cur.execute(
                """
                INSERT INTO site.product (
                    site_iid, product_id, owner_iid, type, name, "desc", unit, sku, rev,
                    can_sell, can_reserve, can_produce, recommended_guest, track_stock, stock_qty,
                    price, cost_price, pic, category, obj_id, product_json, search_text, sort_order,
                    is_archived, created_ts, updated_ts
                ) VALUES (
                    %s, %s, %s, 0, %s, %s, %s, '', 0,
                    %s, %s, FALSE, FALSE, %s, %s,
                    %s, %s, %s, %s, 0, %s::jsonb, %s, %s,
                    %s, NOW(), NOW()
                )
                """,
                (
                    site_iid,
                    product_id,
                    owner_iid,
                    (row.get("name") or "")[:4000],
                    row.get("description") or "",
                    row.get("stock_unit") or "",
                    active and not archived,
                    bool(row.get("is_reservable")),
                    bool(row.get("track_stock")),
                    int(row.get("stock_qty") or 0),
                    int(row.get("price") or 0),
                    int(row.get("stock_cost_value") or 0),
                    pic or "",
                    row.get("category") or "",
                    json.dumps(pj, ensure_ascii=False),
                    row.get("search_text") or "",
                    int(row.get("sort_order") or 0),
                    archived,
                ),
            )
        inserted += 1

    if dry_run:
        print(
            f"dry-run: products={inserted} blobs={len(hashes)} "
            f"pages={len(doc_json.get('pages') or [])}"
        )
        return 0

    c35.commit()
    print(f"ok site_iid={site_iid} alien_id={alien_id} products={inserted} blobs={len(hashes)}")
    csa.close()
    c35.close()
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Import CSA site products + draft into c35")
    ap.add_argument("alien_id", help="CSA site alien_id (e.g. grosirprakarya)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    return import_site(args.alien_id.strip().lstrip("@").lower(), args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
