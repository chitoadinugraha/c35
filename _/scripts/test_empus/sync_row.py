#!/usr/bin/env python3
"""One row: ePus lookup by no_kartu -> browser.sheets.row_set (G-L)."""
from __future__ import annotations

import argparse
import json
import sys
import time
from typing import Any

from c35_agent import tool_exec

from extract import epus_release_tab, epus_reset_tab, fetch_one, load_config, root_dir, wake_extension
from sheet_write_api import write_sheet_row_gl


def participant_by_sheet_row(sheet_row: int) -> dict[str, Any]:
    path = root_dir() / "data" / "participants.jsonl"
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if int(row.get("sheet_row") or 0) == sheet_row:
            return row
    raise SystemExit(f"no participant for sheet_row={sheet_row}")


def sheet_row_set(cfg: dict, owner: int, sheet_row: int, nama: str, fields: dict[str, str]) -> dict[str, Any]:
    tab = (cfg.get("sheet_tab_id") or "").strip()
    if not tab:
        raise SystemExit("sheet_tab_id required in config (Google Sheet Chrome tab)")
    values = [
        fields.get("alamat") or "",
        fields.get("dusun") or "",
        fields.get("rt") or "",
        fields.get("rw") or "",
        fields.get("desa") or "",
        fields.get("kecamatan") or "",
        fields.get("faskes") or "",
    ]
    return tool_exec(
        "browser.sheets.row_set",
        {
            "device_iid": int(cfg["device_iid"]),
            "tab_id": tab,
            "row": sheet_row,
            "key": nama,
            "values": values,
        },
        owner,
    )


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sheet-row", type=int, required=True, help="1-based Google Sheet row number")
    p.add_argument("--dry-run", action="store_true", help="ePus only, no sheet write")
    p.add_argument("--api", action="store_true", help="write G-L via Google Sheets API (service account)")
    p.add_argument(
        "--search-by",
        default="nama",
        choices=("nama", "penjamin", "kartu"),
        help="penjamin/kartu = NIK/No Asuransi field (No. Penjamin)",
    )
    args = p.parse_args()
    cfg = load_config()
    owner = int(cfg.get("owner_iid") or 99000)
    wait_ms = int(cfg.get("wait_ms") or 3200)

    part = participant_by_sheet_row(args.sheet_row)
    no_kartu = str(part["no_kartu"])
    nama = str(part.get("nama") or "")

    wake_extension()
    epus_reset_tab(cfg, owner)

    print(f"sheet_row={args.sheet_row} nama={nama} no_kartu={no_kartu}", flush=True)
    keep_tab = bool(cfg.get("keep_epus_tab"))
    epus = fetch_one(
        cfg,
        owner,
        no_kartu,
        wait_ms,
        nama=nama,
        search_by=args.search_by,
        keep_tab=keep_tab,
    )
    print("epus", json.dumps(epus, ensure_ascii=False, indent=2), flush=True)
    if not epus.get("ok"):
        epus_release_tab(cfg, owner)
        return 1
    if args.dry_run:
        epus_release_tab(cfg, owner)
        return 0

    fields = epus.get("fields") or {}
    if args.api:
        raw = write_sheet_row_gl(args.sheet_row, fields)
        print("sheet_api", json.dumps(raw, ensure_ascii=False, indent=2), flush=True)
        epus_release_tab(cfg, owner)
        return 0 if raw.get("ok") else 1

    sheet_tab = (cfg.get("sheet_tab_id") or "").strip()
    if sheet_tab:
        tool_exec("browser.tabs", {"device_iid": int(cfg["device_iid"]), "op": "activate", "tab_id": sheet_tab}, owner)
        time.sleep(0.5)
    raw = sheet_row_set(cfg, owner, args.sheet_row, nama, fields)
    print("row_set", json.dumps(raw, ensure_ascii=False, indent=2), flush=True)
    epus_release_tab(cfg, owner)
    inner = raw.get("result") if isinstance(raw.get("result"), dict) else {}
    ok = bool(raw.get("ok")) and inner.get("ok", True) is not False
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
