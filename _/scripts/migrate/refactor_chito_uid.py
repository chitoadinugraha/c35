#!/usr/bin/env python3
"""Merge CSA Chito uid 1001 into dev uid 99000; re-sync handles, badges, pics, referrals."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import psycopg2.extras
except ImportError:
    print("pip install psycopg2-binary", file=sys.stderr)
    raise

from migrate_lib import (
    CAS_SECRET,
    CHITO_NEW_IID,
    CHITO_OLD_IID,
    CSA_DB,
    C35_DB,
    alien_id_of,
    connect,
    pic_from_csa,
)

# (table, column) pairs that store identity iids and may reference uid 1001
_IID_COLUMNS = [
    ("ai.identity", "referred_by_iid"),
    ("ai.identity", "owner_iid"),
    ("ai.identity", "billing_iid"),
    ("ai.referral_share", "parent_iid"),
    ("ai.referral_share", "child_iid"),
    ("ai.referral_code", "issued_by_iid"),
    ("ai.identity_provider", "identity_iid"),
    ("ai.auth_session", "identity_iid"),
    ("ai.identity_grant", "grantee_iid"),
    ("ai.identity_grant", "resource_iid"),
    ("ai.identity_client", "identity_iid"),
    ("ai.billing_account", "owner_iid"),
    ("ai.billing_wallet", "owner_iid"),
    ("ai.billing_tx", "owner_iid"),
    ("ai.billing_invoice", "owner_iid"),
    ("ai.billing_payout", "owner_iid"),
    ("ai.billing_referral_commission", "owner_iid"),
    ("ai.billing_package_purchase", "owner_iid"),
    ("ai.chat", "owner_iid"),
    ("ai.chat", "bot_iid"),
    ("ai.chat_member", "member_iid"),
    ("ai.chat_msg", "owner_iid"),
    ("ai.chat_msg", "sender_iid"),
    ("ai.consumption_entry", "owner_iid"),
    ("ai.consumption_food", "owner_iid"),
    ("ai.consumption_prefs", "owner_iid"),
    ("ai.log_event", "owner_iid"),
    ("ai.log_event", "device_iid"),
    ("ai.memory_doc", "owner_iid"),
    ("ai.memory_doc", "bot_iid"),
    ("ai.skill", "owner_iid"),
    ("ai.skill_version", "owner_iid"),
    ("ai.skill_install", "owner_iid"),
    ("ai.skill_review", "author_iid"),
    ("ai.skill_review", "rater_iid"),
    ("ai.site", "owner_iid"),
    ("ai.site_page", "owner_iid"),
    ("ai.site_product", "owner_iid"),
    ("ai.site_order", "owner_iid"),
    ("ai.site_member", "owner_iid"),
    ("ai.site_tx", "owner_iid"),
    ("ai.site_tx", "created_by_iid"),
    ("ai.tx", "owner_iid"),
    ("ai.tx", "created_by_iid"),
    ("ai.channel_bot", "bot_iid"),
]


def main() -> int:
    old_iid = CHITO_OLD_IID
    new_iid = CHITO_NEW_IID
    csa = connect(CSA_DB)
    c35 = connect(C35_DB)
    csa.autocommit = True
    c35.autocommit = True
    try:
        with csa.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                SELECT u.uid, u.name,
                       COALESCE(NULLIF(TRIM(u.alien_id), ''), a.alien_id) AS alien_id,
                       COALESCE(u.pic, '') AS pic, u.referred_by, u.is_root,
                       (u.banned_at IS NULL) AS is_active,
                       COALESCE((SELECT json_agg(r.role ORDER BY r.role) FROM identity_user_global_role r WHERE r.uid = u.uid), '[]'::json) AS global_roles
                FROM identity_user u
                LEFT JOIN identity_alien_id a ON a.kind = 'user' AND a.ref_id = u.uid
                ORDER BY u.uid
                """
            )
            users = {int(r["uid"]): r for r in cur.fetchall()}

        with c35.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM ai.identity WHERE id IN (%s, %s)", (old_iid, new_iid))
            rows = {int(r["id"]): r for r in cur.fetchall()}
            if old_iid not in rows and old_iid not in users:
                print(f"uid {old_iid} not in c35 or csa", file=sys.stderr)
                return 1

            src = users.get(old_iid, {})
            old = rows.get(old_iid, {})
            old_meta = old.get("meta") if isinstance(old.get("meta"), dict) else {}
            meta = {
                "is_root": bool(src.get("is_root", old_meta.get("is_root", True))),
                "global_roles": src.get("global_roles") or old_meta.get("global_roles") or ["root"],
            }
            pic = pic_from_csa(src.get("pic") or old.get("pic"), CAS_SECRET)
            alien_id = alien_id_of(src.get("alien_id") or "chito", new_iid)
            name = src.get("name") or old.get("name") or "Chito Adinugraha"

            if old_iid in rows:
                cur.execute(
                    "UPDATE ai.identity SET alien_id = %s, updated_ts = NOW() WHERE id = %s",
                    (f"_merge_{old_iid}", old_iid),
                )
            if new_iid in rows:
                cur.execute(
                    """
                    UPDATE ai.identity
                    SET alien_id = %s, name = %s, pic = %s, meta = %s::jsonb,
                        is_active = true, owner_iid = %s, billing_iid = %s, updated_ts = NOW()
                    WHERE id = %s
                    """,
                    (alien_id, name, pic, json.dumps(meta), new_iid, new_iid, new_iid),
                )
            else:
                cur.execute(
                    """
                    INSERT INTO ai.identity (
                        id, kind, type, alien_id, name, pic, owner_iid, billing_iid,
                        referred_by_iid, meta, is_active, created_ts, updated_ts
                    )
                    VALUES (%s, 'user', '', %s, %s, %s, %s, %s, NULL, %s::jsonb, true, NOW(), NOW())
                    """,
                    (new_iid, alien_id, name, pic, new_iid, new_iid, json.dumps(meta)),
                )

            for table, col in _IID_COLUMNS:
                try:
                    cur.execute(f"UPDATE {table} SET {col} = %s WHERE {col} = %s", (new_iid, old_iid))
                except Exception as e:
                    if "does not exist" in str(e).lower():
                        continue
                    raise

            if old_iid in rows and old_iid != new_iid:
                cur.execute("DELETE FROM ai.identity WHERE id = %s", (old_iid,))

            synced = 0
            for uid, u in users.items():
                if uid == old_iid:
                    continue
                referred = u["referred_by"]
                if referred == old_iid:
                    referred = new_iid
                meta_u = {"is_root": bool(u["is_root"]), "global_roles": u["global_roles"] or []}
                pic_u = pic_from_csa(u.get("pic"), CAS_SECRET)
                cur.execute(
                    """
                    UPDATE ai.identity
                    SET alien_id = %s,
                        name = %s,
                        pic = COALESCE(%s, pic),
                        meta = %s::jsonb,
                        is_active = %s,
                        referred_by_iid = %s,
                        owner_iid = COALESCE(owner_iid, id),
                        billing_iid = COALESCE(billing_iid, id),
                        updated_ts = NOW()
                    WHERE id = %s
                    """,
                    (
                        alien_id_of(u.get("alien_id"), uid),
                        u["name"],
                        pic_u,
                        json.dumps(meta_u),
                        u["is_active"],
                        referred,
                        uid,
                    ),
                )
                if cur.rowcount:
                    synced += 1

        print(f"merged chito {old_iid} -> {new_iid} (@chito), synced users={synced}")
        return 0
    finally:
        csa.close()
        c35.close()


if __name__ == "__main__":
    raise SystemExit(main())
