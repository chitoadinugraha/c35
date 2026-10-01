#!/usr/bin/env python3
"""Write G-L via official Google Sheets API (service account). Read back to verify."""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.parse
from pathlib import Path

from google.oauth2 import service_account
from google.auth.transport.requests import Request
import urllib.request

SCOPES = (
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
)
DEFAULT_SA = Path(__file__).resolve().parents[2] / "certs" / "firebase-service.json"
SPREADSHEET_ID = "1XDNFZmTI-QBXjvPZQji9K4Mw7sI_7gY7DPTyQonTwjg"
GID = "0"
ADDRESS_COLS = 7  # G:M Alamat, DUSUN, RT, RW, DESA, KECAMATAN, FASKES
_TAB_TITLE_CACHE: str | None = None


def root_dir() -> Path:
    return Path(__file__).resolve().parent


def sa_path() -> Path:
    for key in (
        "FIREBASE_SERVICE_ACCOUNT_PATH",
        "GOOGLE_APPLICATION_CREDENTIALS",
        "GOOGLE_SERVICE_ACCOUNT_PATH",
    ):
        v = (os.environ.get(key) or "").strip()
        if v and Path(v).is_file():
            return Path(v)
    if DEFAULT_SA.is_file():
        return DEFAULT_SA
    raise SystemExit(
        "service account json not found — set FIREBASE_SERVICE_ACCOUNT_PATH or place firebase-service.json in _/certs/"
    )


def credentials():
    return service_account.Credentials.from_service_account_file(str(sa_path()), scopes=list(SCOPES))


def sheet_a1_tab_quote(tab: str) -> str:
    t = tab.strip()
    if re.search(r"[\s'!]", t):
        return "'" + t.replace("'", "''") + "'"
    return t


def sheet_a1_range(tab: str, cell_range: str) -> str:
    r = cell_range.strip()
    if "!" in r:
        return r
    return f"{sheet_a1_tab_quote(tab)}!{r}"


def api_get(creds, url: str) -> dict:
    creds.refresh(Request())
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {creds.token}"})
    with urllib.request.urlopen(req, timeout=60) as res:
        return json.loads(res.read().decode())


def api_put(creds, url: str, body: dict) -> dict:
    creds.refresh(Request())
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method="PUT",
        headers={
            "Authorization": f"Bearer {creds.token}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as res:
        return json.loads(res.read().decode())


def tab_for_gid(creds, spreadsheet_id: str, gid: str) -> str:
    url = (
        f"https://sheets.googleapis.com/v4/spreadsheets/{spreadsheet_id}"
        "?fields=sheets.properties(title,sheetId)"
    )
    meta = api_get(creds, url)
    for sh in meta.get("sheets") or []:
        props = sh.get("properties") or {}
        sid = props.get("sheetId")
        if sid is not None and str(sid) == str(gid):
            title = (props.get("title") or "").strip()
            if title:
                return title
    raise SystemExit(f"no tab for gid={gid}")


def values_get(creds, spreadsheet_id: str, a1_range: str) -> list[list[str]]:
    q = urllib.parse.quote(a1_range, safe="")
    url = f"https://sheets.googleapis.com/v4/spreadsheets/{spreadsheet_id}/values/{q}"
    out = api_get(creds, url)
    return out.get("values") or []


def values_update(creds, spreadsheet_id: str, a1_range: str, row: list[str]) -> dict:
    q = urllib.parse.quote(a1_range, safe="")
    url = (
        f"https://sheets.googleapis.com/v4/spreadsheets/{spreadsheet_id}/values/{q}"
        "?valueInputOption=USER_ENTERED"
    )
    return api_put(creds, url, {"values": [row]})


def fields_to_row(fields: dict[str, str]) -> list[str]:
    from extract import normalize_epus_fields

    fields = normalize_epus_fields(fields)
    return [
        str(fields.get("alamat") or ""),
        str(fields.get("dusun") or ""),
        str(fields.get("rt") or ""),
        str(fields.get("rw") or ""),
        str(fields.get("desa") or ""),
        str(fields.get("kecamatan") or ""),
        str(fields.get("faskes") or ""),
    ]


def write_sheet_row_gl(sheet_row: int, fields: dict[str, str]) -> dict:
    global _TAB_TITLE_CACHE
    creds = credentials()
    tab = _TAB_TITLE_CACHE or tab_for_gid(creds, SPREADSHEET_ID, GID)
    if not _TAB_TITLE_CACHE:
        _TAB_TITLE_CACHE = tab
    a1 = sheet_a1_range(tab, f"G{sheet_row}:M{sheet_row}")
    row = fields_to_row(fields)
    resp = values_update(creds, SPREADSHEET_ID, a1, row)
    after = values_get(creds, SPREADSHEET_ID, a1)
    got = ((after[0] if after else []) + [""] * ADDRESS_COLS)[:ADDRESS_COLS]
    return {"ok": got == row, "range": a1, "row": row, "read_back": got, "update": resp}


def participant_fields(sheet_row: int) -> list[str]:
    path = root_dir() / "data" / "participants.jsonl"
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if int(row.get("sheet_row") or 0) == sheet_row:
            epus = row.get("epus") or {}
            return fields_to_row(
                {
                    "alamat": str(epus.get("alamat") or row.get("alamat") or ""),
                    "dusun": str(epus.get("dusun") or row.get("dusun") or ""),
                    "rt": str(epus.get("rt") or row.get("rt") or ""),
                    "rw": str(epus.get("rw") or row.get("rw") or ""),
                    "desa": str(epus.get("desa") or row.get("desa") or ""),
                    "kecamatan": str(epus.get("kecamatan") or row.get("kecamatan") or ""),
                    "faskes": str(epus.get("faskes") or row.get("faskes") or ""),
                }
            )
    raise SystemExit(f"no participant for sheet_row={sheet_row}")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sheet-row", type=int, default=3)
    p.add_argument(
        "--values",
        nargs=ADDRESS_COLS,
        metavar=("ALAMAT", "DUSUN", "RT", "RW", "DESA", "KEC", "FASKES"),
        help="seven cells G-M",
    )
    p.add_argument("--probe", action="store_true", help="write c35-api-probe in G only (rest empty)")
    p.add_argument("--read-only", action="store_true", help="only read G:M for row")
    args = p.parse_args()

    creds = credentials()
    tab = tab_for_gid(creds, SPREADSHEET_ID, GID)
    cell = f"G{args.sheet_row}:M{args.sheet_row}"
    a1 = sheet_a1_range(tab, cell)
    print(f"spreadsheet={SPREADSHEET_ID} tab={tab!r} range={a1}", flush=True)
    print(f"service_account={creds.service_account_email}", flush=True)

    before = values_get(creds, SPREADSHEET_ID, a1)
    print("before", before, flush=True)

    if args.read_only:
        return 0

    if args.values:
        row = list(args.values)
    elif args.probe:
        row = ["c35-api-probe"] + [""] * (ADDRESS_COLS - 1)
    else:
        try:
            row = participant_fields(args.sheet_row)
        except SystemExit:
            row = ["c35-api-probe", "API", "TEST", "write", "row", str(args.sheet_row), ""]

    print("writing", row, flush=True)
    try:
        resp = values_update(creds, SPREADSHEET_ID, a1, row)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")[:500]
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        print(
            "If 403: share the sheet with the service account email as Editor, "
            "or Anyone with the link can edit.",
            file=sys.stderr,
        )
        return 1

    print("update_response", json.dumps(resp, ensure_ascii=False), flush=True)
    after = values_get(creds, SPREADSHEET_ID, a1)
    print("after", after, flush=True)
    got = (after[0] if after else []) + [""] * (ADDRESS_COLS - len(after[0] if after else []))
    got = got[:ADDRESS_COLS]
    if got != row:
        print("read-back mismatch", {"expected": row, "got": got}, file=sys.stderr)
        return 1
    print("ok", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
