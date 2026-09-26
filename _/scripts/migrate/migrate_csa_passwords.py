#!/usr/bin/env python3
"""Import CSA password hashes (identity_user_password) into c35 ai.identity_provider."""

import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_lib import CHITO_OLD_IID, C35_DB, connect

BACKUP = Path(__file__).resolve().parents[3] / "alienai_proto" / "cluster" / "migrate-backup" / "yb-all-v2.sql"
if not BACKUP.exists():
    BACKUP = Path(r"D:\alienai_proto\cluster\migrate-backup\yb-all-v2.sql")

TABLES = ("identity_user", "identity_user_password", "identity_user_auth")
_EPOCH_MS = 1_767_225_600_000
_MIG_WORKER = 1023
_seq = 0


def snowflake_id() -> int:
    global _seq
    ts = int(time.time() * 1000) - _EPOCH_MS
    _seq = (_seq + 1) & 0xFFF
    return (ts << 22) | (_MIG_WORKER << 12) | _seq


def copy_blocks(path: Path) -> dict[str, list[str]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, list[str]] = {t: [] for t in TABLES}
    pat = re.compile(
        r"^COPY public\.(" + "|".join(TABLES) + r") \(([^)]+)\) FROM stdin;\n(.*?)^\\.\s*$",
        re.MULTILINE | re.DOTALL,
    )
    for m in pat.finditer(text):
        out[m.group(1)].extend(ln for ln in m.group(3).splitlines() if ln.strip())
    return out


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


def password_identifier(uid: int, subject: str | None, alien_id: str | None) -> str:
    sub = (subject or "").strip().lower()
    if sub:
        return sub
    alien = (alien_id or "").strip().lstrip("@").lower()
    if alien:
        return alien
    return f"u{uid}"


def main() -> int:
    if not BACKUP.exists():
        print(f"backup not found: {BACKUP}", file=sys.stderr)
        return 1

    blocks = copy_blocks(BACKUP)
    alien_by_uid: dict[int, str] = {}
    for row in (parse_tsv(ln) for ln in blocks["identity_user"]):
        if len(row) >= 4 and row[0]:
            alien_by_uid[int(row[0])] = (row[3] or "").strip()

    auth_by_uid: dict[int, dict[str, str]] = {}
    for row in (parse_tsv(ln) for ln in blocks["identity_user_auth"]):
        if len(row) < 4 or row[0] != "password" or not row[2]:
            continue
        uid = int(row[2])
        auth_by_uid[uid] = {
            "subject": (row[1] or "").strip(),
            "email": (row[3] or "").strip().lower(),
        }

    passwords: list[tuple[int, str]] = []
    for row in (parse_tsv(ln) for ln in blocks["identity_user_password"]):
        if len(row) < 2 or not row[0] or not row[1]:
            continue
        passwords.append((int(row[0]), row[1].strip()))

    c35 = connect(C35_DB)
    c35.autocommit = False
    inserted = updated = skipped = missing_identity = 0
    try:
        with c35.cursor() as cur:
            for uid, pass_hash in passwords:
                if uid == CHITO_OLD_IID:
                    skipped += 1
                    continue
                cur.execute(
                    "SELECT 1 FROM ai.identity WHERE id = %s AND deleted_ts IS NULL",
                    (uid,),
                )
                if not cur.fetchone():
                    missing_identity += 1
                    print(f"skip uid={uid}: no ai.identity row")
                    continue

                auth = auth_by_uid.get(uid, {})
                ident = password_identifier(uid, auth.get("subject"), alien_by_uid.get(uid))
                email = auth.get("email") or ""

                cur.execute(
                    """
                    SELECT id, COALESCE(secret_hash, '') AS secret_hash
                    FROM ai.identity_provider
                    WHERE identity_iid = %s AND kind = 'password' AND deleted_ts IS NULL
                    LIMIT 1
                    """,
                    (uid,),
                )
                existing = cur.fetchone()
                if existing and existing[1]:
                    skipped += 1
                    print(f"skip uid={uid} alien={alien_by_uid.get(uid, '?')}: password already set")
                    continue

                if existing:
                    cur.execute(
                        """
                        UPDATE ai.identity_provider
                        SET identifier = %s, secret_hash = %s, is_verified = true, is_primary = true,
                            verified_at = COALESCE(verified_at, NOW()), updated_ts = NOW()
                        WHERE id = %s
                        """,
                        (ident, pass_hash, existing[0]),
                    )
                    updated += 1
                else:
                    cur.execute(
                        """
                        INSERT INTO ai.identity_provider (
                            id, identity_iid, kind, identifier, secret_hash,
                            is_verified, is_primary, verified_at, meta
                        )
                        VALUES (%s, %s, 'password', %s, %s, true, true, NOW(), '{}'::jsonb)
                        ON CONFLICT (kind, identifier) DO UPDATE SET
                            identity_iid = EXCLUDED.identity_iid,
                            secret_hash = EXCLUDED.secret_hash,
                            is_verified = true,
                            is_primary = true,
                            verified_at = COALESCE(ai.identity_provider.verified_at, NOW()),
                            updated_ts = NOW()
                        """,
                        (snowflake_id(), uid, ident, pass_hash),
                    )
                    inserted += 1

                if email:
                    cur.execute(
                        """
                        SELECT 1 FROM ai.identity_provider
                        WHERE identity_iid = %s AND kind = 'email' AND deleted_ts IS NULL
                        LIMIT 1
                        """,
                        (uid,),
                    )
                    if not cur.fetchone():
                        cur.execute(
                            """
                            INSERT INTO ai.identity_provider (
                                id, identity_iid, kind, identifier, is_verified, is_primary, verified_at, meta
                            )
                            VALUES (%s, %s, 'email', %s, true, false, NOW(), '{}'::jsonb)
                            ON CONFLICT (kind, identifier) DO NOTHING
                            """,
                            (snowflake_id(), uid, email),
                        )

                print(f"ok uid={uid} ident={ident} alien={alien_by_uid.get(uid, '')}")

        c35.commit()
        print(
            f"done inserted={inserted} updated={updated} skipped={skipped} "
            f"missing_identity={missing_identity} from {BACKUP.name}"
        )
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
