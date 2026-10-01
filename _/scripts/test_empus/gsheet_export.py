#!/usr/bin/env python3
"""Export Google Sheet (CSV publish URL) to data/gsheet.json — all columns."""
from __future__ import annotations

import csv
import json
import sys
import urllib.request
from pathlib import Path


def load_config() -> dict:
    root = Path(__file__).resolve().parent
    for name in ("config.json", "config.example.json"):
        path = root / name
        if path.is_file():
            return json.loads(path.read_text(encoding="utf-8"))
    return {}


def main() -> int:
    cfg = load_config()
    url = (cfg.get("sheet_export_url") or "").strip()
    if not url:
        print("sheet_export_url missing in config.json", file=sys.stderr)
        return 1
    raw = urllib.request.urlopen(url, timeout=120).read().decode("utf-8-sig")
    rows = list(csv.reader(raw.splitlines()))
    if len(rows) < 2:
        print("sheet empty", file=sys.stderr)
        return 1
    headers = [h.strip() for h in rows[0]]
    out = []
    for sheet_row, cells in enumerate(rows[1:], start=2):
        if not any((c or "").strip() for c in cells):
            continue
        row = {"sheet_row": sheet_row}
        for i, key in enumerate(headers):
            if not key:
                continue
            row[key] = cells[i].strip() if i < len(cells) else ""
        out.append(row)
    dest = Path(__file__).resolve().parent / "data" / "gsheet.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"wrote {len(out)} rows -> {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())