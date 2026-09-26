#!/usr/bin/env python3
"""Import CSA Google sign-in (identity_user_auth + u_auth_google) into ai.identity_provider."""

import argparse
import json
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

from migrate_csa_passwords import copy_blocks, parse_tsv
from migrate_lib import CHITO_NEW_IID, CHITO_OLD_IID, C35_DB, connect

BACKUP = Path(__file__).resolve().parents[3] / "alienai_proto" / "cluster" / "migrate-backup" / "yb-all-v2.sql"
if not BACKUP.exists():
    BACKUP = Path(r"D:\alienai_proto\cluster\migrate-backup\yb-all-v2.sql")

TABLES = ("identity_user_auth", "u_auth_google")
_EPOCH_MS = 1_767_225_600_000
_MIG_WORKER = 1024
_seq = 0


def snowflake_id() -> int:
    global _seq
    ts = int(time.time() * 1000) - _EPOCH_MS
    _seq = (_seq + 1) & 0xFFF
    return (ts << 22) | (_MIG_WORKER << 12) | _seq


def copy_google_blocks(path: Path) -> dict[str, list[str]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, list[str]] = {t: [] for t in TABLES}
    pat = re.compile(
        r"^COPY public\.(" + "|".join(TABLES) + r") \([^)]+\) FROM stdin;\n(.*?)^\\.\s*$",
        re.MULTILINE | re.DOTALL,
    )
    for m in pat.finditer(text):
        out[m.group(1)].extend(ln for ln in m.group(2).splitlines() if ln.strip())
    return out


def map_uid(uid: int) -> int:
    return CHITO_NEW_IID if uid == CHITO_OLD_IID else uid


def load_google_rows(blocks: dict[str, list[str]]) -> list[dict]:
    profile_by_sub: dict[str, dict[str, str]] = {}
    for row in (parse_tsv(ln) for ln in blocks.get("u_auth_google", [])):
        if len(row) < 3 or not row[0]:
            continue
        profile_by_sub[row[0].strip()] = {
            "email": (row[2] or "").strip().lower(),
            "name": (row[3] or "").strip() if len(row) > 3 else "",
            "pic": (row[4] or "").strip() if len(row) > 4 else "",
        }

    by_sub: dict[str, dict] = {}
    for row in (parse_tsv(ln) for ln in blocks.get("identity_user_auth", [])):
        if len(row) < 4 or row[0] != "google" or not row[1] or not row[2]:
            continue
        sub = row[1].strip()
        uid = map_uid(int(row[2]))
        email = (row[3] or "").strip().lower()
        prof = profile_by_sub.get(sub, {})
        if not email:
            email = prof.get("email") or ""
        by_sub[sub] = {
            "sub": sub,
            "uid": uid,
            "email": email,
            "name": prof.get("name") or "",
            "pic": prof.get("pic") or "",
        }
    return list(by_sub.values())


def resolve_identity_iid(cur, sub: str, email: str, csa_uid: int) -> int | None:
    cur.execute(
        """
        SELECT identity_iid FROM ai.identity_provider
        WHERE deleted_ts IS NULL AND kind = 'google' AND meta->>'google_sub' = %s
        LIMIT 1
        """,
        (sub,),
    )
    row = cur.fetchone()
    if row:
        return int(row[0])

    if email:
        cur.execute(
            """
            SELECT identity_iid FROM ai.identity_provider
            WHERE deleted_ts IS NULL AND kind = 'google' AND LOWER(identifier) = %s
            LIMIT 1
            """,
            (email,),
        )
        row = cur.fetchone()
        if row:
            return int(row[0])

    cur.execute(
        "SELECT id FROM ai.identity WHERE id = %s AND deleted_ts IS NULL LIMIT 1",
        (csa_uid,),
    )
    row = cur.fetchone()
    if row:
        return int(row[0])

    if email:
        cur.execute(
            """
            SELECT id FROM ai.identity
            WHERE deleted_ts IS NULL AND LOWER(meta->>'email') = %s
            LIMIT 1
            """,
            (email,),
        )
        row = cur.fetchone()
        if row:
            return int(row[0])
    return None


def zero_balances(cur, owner_iids: list[int]) -> tuple[int, int]:
    if not owner_iids:
        return 0, 0
    cur.execute(
        """
        UPDATE ai.billing_wallet
        SET balance = 0, updated_ts = NOW()
        WHERE deleted_ts IS NULL AND owner_iid = ANY(%s) AND balance <> 0
        """,
        (owner_iids,),
    )
    wallets = cur.rowcount
    cur.execute(
        """
        UPDATE ai.billing_account
        SET balance_usd = 0,
            balance_idr = 0,
            updated_ts = NOW()
        WHERE owner_iid = ANY(%s)
          AND (COALESCE(balance_usd, 0) <> 0 OR COALESCE(balance_idr, 0) <> 0)
        """,
        (owner_iids,),
    )
    accounts = cur.rowcount
    return wallets, accounts


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--no-zero-balances",
        action="store_true",
        help="Do not reset wallet / legacy account balances for migrated Google users",
    )
    args = parser.parse_args()

    if not BACKUP.exists():
        print(f"backup not found: {BACKUP}", file=sys.stderr)
        return 1

    rows = load_google_rows(copy_google_blocks(BACKUP))
    if not rows:
        print("no google rows in backup", file=sys.stderr)
        return 1

    c35 = connect(C35_DB)
    c35.autocommit = False
    inserted = updated = skipped = missing = 0
    touched_iids: set[int] = set()

    try:
        with c35.cursor() as cur:
            for g in rows:
                sub, email, csa_uid = g["sub"], g["email"], g["uid"]
                if not sub:
                    skipped += 1
                    continue
                if not email:
                    print(f"skip sub={sub} uid={csa_uid}: no email")
                    skipped += 1
                    continue

                iid = resolve_identity_iid(cur, sub, email, csa_uid)
                if iid is None:
                    missing += 1
                    print(f"skip sub={sub} email={email} uid={csa_uid}: no ai.identity")
                    continue

                meta = {"google_sub": sub, "migrated_from": "csa"}
                if g["name"]:
                    meta["name"] = g["name"]
                if g["pic"]:
                    meta["pic"] = g["pic"]

                cur.execute(
                    """
                    SELECT id, identity_iid, meta->>'google_sub' AS sub
                    FROM ai.identity_provider
                    WHERE deleted_ts IS NULL AND kind = 'google'
                      AND (meta->>'google_sub' = %s OR LOWER(identifier) = %s)
                    LIMIT 1
                    """,
                    (sub, email),
                )
                existing = cur.fetchone()
                if existing and int(existing[1]) == iid and existing[2] == sub:
                    skipped += 1
                    touched_iids.add(iid)
                    continue

                if existing:
                    cur.execute(
                        """
                        UPDATE ai.identity_provider
                        SET identity_iid = %s,
                            identifier = %s,
                            is_verified = true,
                            is_primary = true,
                            verified_at = COALESCE(verified_at, NOW()),
                            meta = COALESCE(meta, '{}'::jsonb) || %s::jsonb,
                            updated_ts = NOW()
                        WHERE id = %s
                        """,
                        (iid, email, json.dumps(meta), existing[0]),
                    )
                    updated += 1
                else:
                    cur.execute(
                        """
                        INSERT INTO ai.identity_provider (
                            id, identity_iid, kind, identifier, is_verified, is_primary,
                            verified_at, meta
                        )
                        VALUES (%s, %s, 'google', %s, true, true, NOW(), %s::jsonb)
                        ON CONFLICT (kind, identifier) DO UPDATE SET
                            identity_iid = EXCLUDED.identity_iid,
                            is_verified = true,
                            is_primary = true,
                            verified_at = COALESCE(ai.identity_provider.verified_at, NOW()),
                            meta = COALESCE(ai.identity_provider.meta, '{}'::jsonb) || EXCLUDED.meta,
                            updated_ts = NOW()
                        """,
                        (snowflake_id(), iid, email, json.dumps(meta)),
                    )
                    if cur.rowcount:
                        inserted += 1
                    else:
                        updated += 1

                touched_iids.add(iid)
                print(f"ok iid={iid} sub={sub} email={email}")

            wallets = accounts = 0
            if not args.no_zero_balances:
                wallets, accounts = zero_balances(cur, sorted(touched_iids))

        c35.commit()
        print(
            f"done google={len(rows)} inserted={inserted} updated={updated} skipped={skipped} "
            f"missing={missing} balances_zeroed wallets={wallets} accounts={accounts} "
            f"from {BACKUP.name}"
        )
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
