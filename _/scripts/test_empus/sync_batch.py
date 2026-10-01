#!/usr/bin/env python3
"""Process participants in waves (default 5 rows per wave, serial ePus per Chrome)."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from extract import load_config
from sheet_pending import filter_pending_participants


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--wave-size", type=int, default=5)
    p.add_argument("--shard", default="", help="e.g. data/shards/shard-00.json")
    p.add_argument("--start-sheet-row", type=int, default=0, help="skip rows before this sheet_row")
    p.add_argument("--limit", type=int, default=0)
    p.add_argument("--api", action="store_true", help="write sheet via Google Sheets API")
    p.add_argument("--no-incremental", action="store_true")
    args = p.parse_args()
    root = Path(__file__).resolve().parent
    cfg = load_config()
    sync = root / "sync_row.py"
    if args.shard:
        rows = json.loads((root / args.shard).read_text(encoding="utf-8"))
    else:
        rows = [
            json.loads(line)
            for line in (root / "data/participants.jsonl").read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
    rows = filter_pending_participants(
        rows,
        cfg,
        start_sheet_row=args.start_sheet_row,
        incremental=not args.no_incremental,
    )
    if args.limit > 0:
        rows = rows[: args.limit]
    wave = max(1, args.wave_size)
    failed = 0
    for i, part in enumerate(rows):
        sr = int(part["sheet_row"])
        print(f"\n=== [{i + 1}/{len(rows)}] sheet_row={sr} ===", flush=True)
        cmd = [sys.executable, str(sync), "--sheet-row", str(sr)]
        if args.api:
            cmd.append("--api")
        code = subprocess.call(cmd)
        if code != 0:
            failed += 1
        if (i + 1) % wave == 0:
            print(f"--- wave checkpoint at {i + 1} (failed={failed}) ---", flush=True)
    print(f"done rows={len(rows)} failed={failed}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
