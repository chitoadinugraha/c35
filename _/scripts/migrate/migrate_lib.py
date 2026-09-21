"""Shared config for c35 CSA → c35 YSQL migrations."""

import hashlib
import os
import time

HOST = os.environ.get("YB_HOST", "yb-tservers.yugabyte.svc.cluster.local")
PORT = int(os.environ.get("YB_PORT", "5433"))
USER = os.environ.get("YB_USER", "csa")
PASSWORD = os.environ.get("YB_PASSWORD", os.environ.get("PGPASSWORD", ""))
CSA_DB = os.environ.get("CSA_DATABASE", "csa")
C35_DB = os.environ.get("YB_DATABASE", "c35")
CAS_SECRET = os.environ.get("CAS_HMAC_SECRET", os.environ.get("C35_JWT_SECRET", ""))
CAS_TTL_SEC = int(os.environ.get("CAS_URL_TTL_SEC", str(365 * 24 * 60 * 60)))
CHITO_OLD_IID = int(os.environ.get("CHITO_OLD_IID", "1001"))
CHITO_NEW_IID = int(os.environ.get("CHITO_NEW_IID", "99000"))


def connect(db: str):
    import psycopg2

    return psycopg2.connect(host=HOST, port=PORT, user=USER, password=PASSWORD, dbname=db)


def alien_id_of(raw: str | None, uid: int) -> str:
    slug = (raw or "").strip().lstrip("@").lower()
    if slug:
        return slug
    return f"u{uid}"


def _now_ms() -> int:
    return int(time.time() * 1000)


def _cas_mac(secret: str, hash_val: str, exp_ms: int) -> str:
    try:
        import blake3

        key = blake3.blake3(secret.encode()).digest(length=32)
        h = blake3.blake3(key=key)
        h.update(hash_val.encode())
        h.update(b"|")
        h.update(exp_ms.to_bytes(8, "big", signed=True))
        return h.hexdigest()
    except ImportError:
        import hmac

        msg = f"{hash_val}|{exp_ms}".encode()
        return hmac.new(secret.encode(), msg, hashlib.sha256).hexdigest()


def cas_sign_path(secret: str, hash_val: str, ttl_sec: int | None = None) -> str:
    if not secret:
        return f"/fs/{hash_val}"
    ttl = CAS_TTL_SEC if ttl_sec is None else ttl_sec
    exp = _now_ms() + ttl * 1000
    sig = _cas_mac(secret, hash_val, exp)
    return f"/fs/{hash_val}?exp={exp}&sig={sig}"


def pic_from_csa(pic: str | None, secret: str) -> str | None:
    p = (pic or "").strip()
    if not p:
        return None
    if p.startswith("/fs/"):
        hash_val = p.removeprefix("/fs/").split("?", 1)[0].strip()
        if hash_val:
            return cas_sign_path(secret, hash_val)
    return p
