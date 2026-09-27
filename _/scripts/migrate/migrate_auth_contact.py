"""Shared helpers: identity contact meta, email provider, OAuth duplicate shells."""

import json
import re
from pathlib import Path

from migrate_csa_passwords import parse_tsv
from migrate_lib import CHITO_NEW_IID, CHITO_OLD_IID

_AUTH_TABLES = ("identity_user_auth", "u_auth_google")


def copy_auth_blocks(path: Path) -> dict[str, list[str]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    out: dict[str, list[str]] = {t: [] for t in _AUTH_TABLES}
    pat = re.compile(
        r"^COPY public\.(" + "|".join(_AUTH_TABLES) + r") \([^)]+\) FROM stdin;\n(.*?)^\\.\s*$",
        re.MULTILINE | re.DOTALL,
    )
    for m in pat.finditer(text):
        out[m.group(1)].extend(ln for ln in m.group(2).splitlines() if ln.strip())
    return out


def map_uid(uid: int) -> int:
    return CHITO_NEW_IID if uid == CHITO_OLD_IID else uid


def auth_email_by_uid_from_backup(backup: Path) -> dict[int, str]:
    """Primary login email per CSA uid (google auth row, else password auth email)."""
    blocks = copy_auth_blocks(backup)
    profile_by_sub: dict[str, str] = {}
    for row in (parse_tsv(ln) for ln in blocks.get("u_auth_google", [])):
        if len(row) < 3 or not row[0]:
            continue
        profile_by_sub[row[0].strip()] = (row[2] or "").strip().lower()

    out: dict[int, str] = {}
    for row in (parse_tsv(ln) for ln in blocks.get("identity_user_auth", [])):
        if len(row) < 4 or not row[2]:
            continue
        kind = row[0].strip()
        uid = map_uid(int(row[2]))
        email = (row[3] or "").strip().lower()
        if kind == "google" and not email:
            email = profile_by_sub.get((row[1] or "").strip(), "")
        if not email:
            continue
        prev = out.get(uid)
        if kind == "google" or not prev:
            out[uid] = email
    return out


def identity_contact_meta_ensure(cur, iid: int, email: str, google_sub: str | None = None) -> None:
    email = (email or "").strip().lower()
    sub = (google_sub or "").strip()
    if not email and not sub:
        return
    payload: dict[str, str] = {}
    if email:
        payload["email"] = email
    if sub:
        payload["google_sub"] = sub
    cur.execute(
        """
        UPDATE ai.identity
        SET meta = COALESCE(meta, '{}'::jsonb) || %s::jsonb,
            updated_ts = NOW()
        WHERE id = %s AND deleted_ts IS NULL
        """,
        (json.dumps(payload), iid),
    )


def identity_email_provider_ensure(cur, iid: int, email: str, snowflake_id) -> None:
    email = (email or "").strip().lower()
    if not email:
        return
    cur.execute(
        """
        SELECT 1 FROM ai.identity_provider
        WHERE identity_iid = %s AND kind = 'email' AND deleted_ts IS NULL
        LIMIT 1
        """,
        (iid,),
    )
    if cur.fetchone():
        return
    cur.execute(
        """
        INSERT INTO ai.identity_provider (
            id, identity_iid, kind, identifier, is_verified, is_primary, verified_at, meta
        )
        VALUES (%s, %s, 'email', %s, true, false, NOW(), '{}'::jsonb)
        ON CONFLICT (kind, identifier) DO NOTHING
        """,
        (snowflake_id(), iid, email),
    )


def retire_google_signup_shells(cur, canonical_iid: int, email: str) -> int:
    """Soft-delete empty Google signup duplicates for this Gmail (canonical row kept)."""
    email = (email or "").strip().lower()
    if not email or canonical_iid <= 0:
        return 0
    cur.execute(
        """
        SELECT i.id
        FROM ai.identity i
        WHERE i.deleted_ts IS NULL
          AND i.kind = 'user'
          AND i.id <> %s
          AND COALESCE(i.meta->>'signup_via', '') = 'google'
          AND (i.alien_id IS NULL OR TRIM(i.alien_id) = '')
          AND (
            LOWER(COALESCE(i.meta->>'email', '')) = %s
            OR EXISTS (
              SELECT 1 FROM ai.identity_provider g
              WHERE g.identity_iid = i.id AND g.deleted_ts IS NULL AND g.kind = 'google'
                AND LOWER(g.identifier) = %s
            )
          )
        """,
        (canonical_iid, email, email),
    )
    retired = 0
    for (dup_id,) in cur.fetchall():
        cur.execute("DELETE FROM ai.auth_session WHERE identity_iid = %s", (dup_id,))
        cur.execute(
            """
            UPDATE ai.identity_client
            SET identity_iid = %s, updated_ts = NOW()
            WHERE identity_iid = %s
            """,
            (canonical_iid, dup_id),
        )
        cur.execute(
            """
            UPDATE ai.identity
            SET is_active = false, deleted_ts = NOW(), updated_ts = NOW()
            WHERE id = %s AND deleted_ts IS NULL
            """,
            (dup_id,),
        )
        retired += 1
    return retired
