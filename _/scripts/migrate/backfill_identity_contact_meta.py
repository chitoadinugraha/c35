#!/usr/bin/env python3
"""Backfill ai.identity meta.email / google_sub and email providers (CSA backup + live providers)."""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from migrate_auth_contact import (
    auth_email_by_uid_from_backup,
    identity_contact_meta_ensure,
    identity_email_provider_ensure,
    retire_google_signup_shells,
)
from migrate_csa_google import BACKUP, load_google_rows, copy_google_blocks, map_uid, snowflake_id
from migrate_lib import C35_DB, connect

_EPOCH_MS = 1_767_225_600_000
_MIG_WORKER = 1025
_seq = 0


def _snowflake() -> int:
    global _seq
    ts = int(time.time() * 1000) - _EPOCH_MS
    _seq = (_seq + 1) & 0xFFF
    return (ts << 22) | (_MIG_WORKER << 12) | _seq


def main() -> int:
    c35 = connect(C35_DB)
    c35.autocommit = False
    meta_from_backup = 0
    meta_from_providers = 0
    email_providers = 0
    retired = 0
    try:
        with c35.cursor() as cur:
            if BACKUP.exists():
                emails_by_uid = auth_email_by_uid_from_backup(BACKUP)
                for uid, email in emails_by_uid.items():
                    cur.execute(
                        "SELECT 1 FROM ai.identity WHERE id = %s AND deleted_ts IS NULL LIMIT 1",
                        (uid,),
                    )
                    if not cur.fetchone():
                        continue
                    identity_contact_meta_ensure(cur, uid, email, None)
                    identity_email_provider_ensure(cur, uid, email, _snowflake)
                    meta_from_backup += 1

                for g in load_google_rows(copy_google_blocks(BACKUP)):
                    uid = map_uid(g["uid"])
                    email, sub = g["email"], g["sub"]
                    if not email or not sub:
                        continue
                    cur.execute(
                        "SELECT 1 FROM ai.identity WHERE id = %s AND deleted_ts IS NULL LIMIT 1",
                        (uid,),
                    )
                    if not cur.fetchone():
                        continue
                    identity_contact_meta_ensure(cur, uid, email, sub)
                    identity_email_provider_ensure(cur, uid, email, _snowflake)
                    retired += retire_google_signup_shells(cur, uid, email)

            cur.execute(
                """
                SELECT ip.identity_iid, LOWER(ip.identifier) AS email, ip.meta->>'google_sub' AS sub
                FROM ai.identity_provider ip
                JOIN ai.identity i ON i.id = ip.identity_iid AND i.deleted_ts IS NULL
                WHERE ip.deleted_ts IS NULL AND ip.kind = 'google' AND ip.identifier <> ''
                """
            )
            for iid, email, sub in cur.fetchall():
                identity_contact_meta_ensure(cur, int(iid), email, sub)
                identity_email_provider_ensure(cur, int(iid), email, _snowflake)
                meta_from_providers += 1
                email_providers += 1
                retired += retire_google_signup_shells(cur, int(iid), email)

            cur.execute(
                """
                SELECT ip.identity_iid, LOWER(ip.identifier) AS email
                FROM ai.identity_provider ip
                JOIN ai.identity i ON i.id = ip.identity_iid AND i.deleted_ts IS NULL
                WHERE ip.deleted_ts IS NULL AND ip.kind = 'email' AND ip.identifier <> ''
                """
            )
            for iid, email in cur.fetchall():
                identity_contact_meta_ensure(cur, int(iid), email, None)
                meta_from_providers += 1

        c35.commit()
        print(
            f"done backup_users={meta_from_backup} provider_rows={meta_from_providers} "
            f"email_provider_touches={email_providers} retired_shells={retired}"
        )
        return 0
    except Exception:
        c35.rollback()
        raise
    finally:
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
