#!/usr/bin/env python3
"""Ensure ai.identity_grant rows on a site (owner already set by import)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_csa_google import snowflake_id
from migrate_lib import C35_DB, connect

VALID = frozenset({"staff", "manage", "guest", "owner"})


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("alien_id")
    ap.add_argument("grants", nargs="+", help="grantee_iid:role e.g. 1004:manage")
    args = ap.parse_args()
    alien = args.alien_id.strip().lstrip("@").lower()

    c35 = connect(C35_DB)
    cur = c35.cursor()
    cur.execute(
        "SELECT id FROM ai.identity WHERE alien_id = %s AND kind = 'site' AND deleted_ts IS NULL",
        (alien,),
    )
    row = cur.fetchone()
    if not row:
        print(f"site not found: {alien}", file=sys.stderr)
        return 1
    site_iid = row[0]

    for spec in args.grants:
        grantee_s, role = spec.split(":", 1)
        role = role.strip().lower()
        if role not in VALID:
            print(f"invalid role: {role}", file=sys.stderr)
            return 1
        grantee_iid = int(grantee_s)
        cur.execute(
            "SELECT 1 FROM ai.identity WHERE id = %s AND deleted_ts IS NULL",
            (grantee_iid,),
        )
        if not cur.fetchone():
            print(f"grantee missing: {grantee_iid}", file=sys.stderr)
            return 1
        cur.execute(
            "SELECT role FROM ai.identity_grant WHERE resource_iid = %s AND grantee_iid = %s AND deleted_ts IS NULL",
            (site_iid, grantee_iid),
        )
        existing = cur.fetchone()
        if existing and existing[0] == "owner" and role != "owner":
            print(f"skip {grantee_iid}: already owner")
            continue
        pinned = role == "owner"
        cur.execute(
            """
            INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, is_pinned, created_ts, updated_ts)
            VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
            ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
                role = EXCLUDED.role,
                is_pinned = EXCLUDED.is_pinned,
                updated_ts = NOW(),
                deleted_ts = NULL
            """,
            (snowflake_id(), site_iid, grantee_iid, role, pinned),
        )
        print(f"grant {grantee_iid} -> {role} on site {site_iid}")

    c35.commit()
    cur.close()
    c35.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
