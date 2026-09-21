#!/usr/bin/env python3
"""Import CSA users/referrals/blobs from yb-all-v2.sql backup into c35 ai schema."""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("pip install psycopg2-binary blake3", file=sys.stderr)
    raise

from migrate_lib import (
    CAS_SECRET,
    CHITO_NEW_IID,
    CHITO_OLD_IID,
    C35_DB,
    alien_id_of,
    cas_sign_path,
    connect,
    pic_from_csa,
)

BACKUP = Path(__file__).resolve().parents[3] / "alienai_proto" / "cluster" / "migrate-backup" / "yb-all-v2.sql"
if not BACKUP.exists():
    BACKUP = Path(r"D:\alienai_proto\cluster\migrate-backup\yb-all-v2.sql")

TABLES = (
    "identity_user",
    "identity_alien_id",
    "identity_user_global_role",
    "referral_share",
    "referral_code",
    "file_meta",
    "file_inline",
)


def copy_blocks(path: Path) -> tuple[dict[str, list[str]], dict[str, list[str]]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, list[str]] = {t: [] for t in TABLES}
    cols: dict[str, list[str]] = {t: [] for t in TABLES}
    pat = re.compile(
        r"^COPY public\.(" + "|".join(TABLES) + r") \(([^)]+)\) FROM stdin;\n(.*?)^\\.\s*$",
        re.MULTILINE | re.DOTALL,
    )
    for m in pat.finditer(text):
        name = m.group(1)
        col_names = [c.strip() for c in m.group(2).split(",")]
        body = m.group(3)
        lines = [ln for ln in body.splitlines() if ln.strip()]
        out[name].extend(lines)
        cols[name] = col_names
    return out, cols


def parse_tsv(line: str) -> list[str | None]:
    parts: list[str | None] = []
    cur: list[str] = []
    i = 0

    def flush() -> None:
        nonlocal cur
        s = "".join(cur)
        parts.append(None if s == "\\N" else s)
        cur = []

    while i < len(line):
        c = line[i]
        if c == "\t":
            flush()
            i += 1
            continue
        if c == "\\" and i + 1 < len(line):
            n = line[i + 1]
            if n == "N" and not cur:
                parts.append(None)
                i += 2
                if i < len(line) and line[i] == "\t":
                    i += 1
                continue
            if n == "t":
                cur.append("\t")
            elif n == "n":
                cur.append("\n")
            elif n == "r":
                cur.append("\r")
            elif n == "\\":
                cur.append("\\")
            else:
                cur.append(n)
            i += 2
            continue
        cur.append(c)
        i += 1
    flush()
    return parts


def decode_bytea(raw: str) -> bytes | None:
    if not raw:
        return None
    s = raw
    if s.startswith("\\x") or s.startswith("\\X"):
        try:
            return bytes.fromhex(s[2:])
        except ValueError:
            return None
    out = bytearray()
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            n = s[i + 1]
            if n in "01234567" and i + 3 < len(s):
                out.append(int(s[i + 1 : i + 4], 8))
                i += 4
                continue
            if n == "\\":
                out.append(92)
            elif n == "x" and i + 2 < len(s):
                j = i + 2
                while j < len(s) and s[j] in "0123456789abcdefABCDEF":
                    j += 1
                try:
                    return bytes.fromhex(s[i + 2 : j]) + bytes(out)
                except ValueError:
                    return None
            else:
                out.append(ord(n))
            i += 2
            continue
        out.append(ord(s[i]))
        i += 1
    return bytes(out)


def main() -> int:
    if not BACKUP.exists():
        print(f"backup not found: {BACKUP}", file=sys.stderr)
        return 1
    blocks, colmaps = copy_blocks(BACKUP)
    users_raw = [parse_tsv(ln) for ln in blocks["identity_user"]]
    alien_rows = [parse_tsv(ln) for ln in blocks["identity_alien_id"]]
    role_rows = [parse_tsv(ln) for ln in blocks["identity_user_global_role"]]
    share_rows = [parse_tsv(ln) for ln in blocks["referral_share"]]
    code_rows = [parse_tsv(ln) for ln in blocks["referral_code"]]
    meta_rows = [parse_tsv(ln) for ln in blocks["file_meta"]]
    inline_rows = [parse_tsv(ln) for ln in blocks["file_inline"]]

    alien_by_uid: dict[int, str] = {}
    for row in alien_rows:
        if len(row) >= 4 and row[0] == "user" and row[2]:
            alien_by_uid[int(row[3])] = row[2]

    roles_by_uid: dict[int, list[str]] = {}
    for row in role_rows:
        if len(row) >= 2 and row[0] and row[1]:
            uid = int(row[0])
            roles_by_uid.setdefault(uid, []).append(row[1])

    users: list[dict] = []
    for row in users_raw:
        if len(row) < 7:
            continue
        uid = int(row[0])
        alien = (row[3] or "").strip() or alien_by_uid.get(uid, "")
        referred = int(row[5]) if row[5] else None
        users.append(
            {
                "uid": uid,
                "name": row[1] or "",
                "pic": row[2] or "",
                "alien_id": alien,
                "referred_by": referred,
                "is_root": (row[6] or "f") in ("t", "true", "True"),
                "is_active": row[7] is None,
                "global_roles": sorted(set(roles_by_uid.get(uid, []))),
            }
        )

    user_ids = {u["uid"] for u in users if u["uid"] != CHITO_OLD_IID} | {CHITO_NEW_IID}

    inline_by_hash = {}
    for row in inline_rows:
        if len(row) >= 2 and row[0]:
            inline_by_hash[row[0]] = row[1]
    meta_by_hash = {}
    meta_cols = colmaps.get("file_meta") or ["hash", "mime", "size"]
    for row in meta_rows:
        if len(row) < 2 or not row[0]:
            continue
        idx = {c: i for i, c in enumerate(meta_cols)}
        meta_by_hash[row[0]] = {
            "mime": row[idx.get("mime", 1)] if len(row) > idx.get("mime", 1) else None,
            "size": int(row[idx.get("size", 2)] or 0) if len(row) > idx.get("size", 2) else 0,
        }

    pic_hashes = set()
    for u in users:
        p = (u["pic"] or "").strip()
        if p.startswith("/fs/"):
            pic_hashes.add(p.removeprefix("/fs/").split("?", 1)[0])

    c35 = connect(C35_DB)
    c35.autocommit = False
    try:
        with c35.cursor() as cur:
            for u in users:
                uid = u["uid"]
                if uid == CHITO_OLD_IID:
                    continue
                meta = {"is_root": bool(u["is_root"]), "global_roles": u["global_roles"]}
                pic = pic_from_csa(u["pic"], CAS_SECRET)
                cur.execute(
                    """
                    INSERT INTO ai.identity (
                        id, kind, type, alien_id, name, pic, owner_iid, billing_iid,
                        referred_by_iid, meta, is_active, created_ts, updated_ts
                    )
                    VALUES (%s, 'user', '', %s, %s, %s, %s, %s, NULL, %s::jsonb, %s, NOW(), NOW())
                    ON CONFLICT (id) DO UPDATE SET
                        alien_id = EXCLUDED.alien_id,
                        name = EXCLUDED.name,
                        pic = EXCLUDED.pic,
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
                        json.dumps(meta),
                        u["is_active"],
                    ),
                )

            chito = next((u for u in users if u["uid"] == CHITO_OLD_IID), None)
            chito_roles = sorted(set((chito or {}).get("global_roles") or []))
            if not chito_roles and chito and chito.get("is_root"):
                chito_roles = ["root"]
            chito_meta = {
                "is_root": True,
                "global_roles": chito_roles or ["root"],
            }
            chito_pic = pic_from_csa((chito or {}).get("pic"), CAS_SECRET)
            chito_name = (chito or {}).get("name") or "Chito Adinugraha"
            cur.execute(
                """
                INSERT INTO ai.identity (
                    id, kind, type, alien_id, name, pic, owner_iid, billing_iid,
                    referred_by_iid, meta, is_active, created_ts, updated_ts
                )
                VALUES (%s, 'user', '', %s, %s, %s, %s, %s, NULL, %s::jsonb, true, NOW(), NOW())
                ON CONFLICT (id) DO UPDATE SET
                    alien_id = EXCLUDED.alien_id,
                    name = EXCLUDED.name,
                    pic = EXCLUDED.pic,
                    meta = EXCLUDED.meta,
                    is_active = true,
                    updated_ts = NOW()
                """,
                (
                    CHITO_NEW_IID,
                    "chito",
                    chito_name,
                    chito_pic,
                    CHITO_NEW_IID,
                    CHITO_NEW_IID,
                    json.dumps(chito_meta),
                ),
            )

            for u in users:
                uid = u["uid"]
                if uid == CHITO_OLD_IID:
                    continue
                referred = u["referred_by"]
                if referred == CHITO_OLD_IID:
                    referred = CHITO_NEW_IID
                if referred is None:
                    continue
                cur.execute(
                    "UPDATE ai.identity SET referred_by_iid = %s, updated_ts = NOW() WHERE id = %s",
                    (referred, uid),
                )

            for row in share_rows:
                if len(row) < 3:
                    continue
                parent = int(row[0])
                child = int(row[1])
                if parent == CHITO_OLD_IID:
                    parent = CHITO_NEW_IID
                if child == CHITO_OLD_IID:
                    child = CHITO_NEW_IID
                cur.execute(
                    """
                    INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent, created_ts, updated_ts)
                    VALUES (%s, %s, %s, NOW(), NOW())
                    ON CONFLICT (parent_iid, child_iid) DO UPDATE SET
                        share_percent = EXCLUDED.share_percent,
                        updated_ts = NOW()
                    """,
                    (parent, child, int(row[2] or 0)),
                )

            code_cols = colmaps.get("referral_code") or ["code", "issued_by"]
            code_idx = {c: i for i, c in enumerate(code_cols)}
            for row in code_rows:
                if len(row) < 2 or not row[0]:
                    continue
                issued_raw = row[code_idx.get("issued_by", 3)] if len(row) > code_idx.get("issued_by", 3) else None
                if not issued_raw:
                    continue
                issued = int(issued_raw)
                if issued == CHITO_OLD_IID:
                    issued = CHITO_NEW_IID
                if issued not in user_ids:
                    continue
                exp = row[code_idx["expires_at"]] if "expires_at" in code_idx and len(row) > code_idx["expires_at"] else None
                created = row[code_idx["created_at"]] if "created_at" in code_idx and len(row) > code_idx["created_at"] else None
                cur.execute(
                    """
                    INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, created_ts, updated_ts)
                    VALUES (%s, %s, 0, %s, COALESCE(%s, NOW()), NOW())
                    ON CONFLICT (code) DO UPDATE SET
                        issued_by_iid = EXCLUDED.issued_by_iid,
                        expires_at = EXCLUDED.expires_at,
                        updated_ts = NOW()
                    """,
                    (row[0], issued, exp, created),
                )

            blob_count = 0
            for h in pic_hashes:
                body_raw = inline_by_hash.get(h)
                if not body_raw:
                    continue
                raw = decode_bytea(body_raw)
                if not raw or len(raw) > 524_288:
                    continue
                meta = meta_by_hash.get(h, {})
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_meta (hash_blake3, size_bytes, mime_type, is_inline, created_ts)
                    VALUES (%s, %s, COALESCE(%s, 'application/octet-stream'), true, NOW())
                    ON CONFLICT (hash_blake3) DO NOTHING
                    """,
                    (h, len(raw), meta.get("mime")),
                )
                cur.execute(
                    """
                    INSERT INTO ai.file_blob_inline (hash_blake3, bytes)
                    VALUES (%s, %s)
                    ON CONFLICT (hash_blake3) DO NOTHING
                    """,
                    (h, psycopg2.Binary(raw)),
                )
                blob_count += 1

        c35.commit()
        print(
            f"imported users={len(users)} shares={len(share_rows)} codes={len(code_rows)} "
            f"blobs={blob_count} chito={CHITO_NEW_IID} from {BACKUP.name}"
        )
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
