#!/usr/bin/env python3
"""Phase 1: pull NAMA + NO KARTU from Google Sheet (CSV export). No browser."""
from __future__ import annotations

import argparse
import csv
import json
import sys
import urllib.request
from pathlib import Path
from typing import Any


def load_config() -> dict:
    root = Path(__file__).resolve().parent
    path = root / "config.json"
    if not path.is_file():
        path = root / "config.example.json"
    return json.loads(path.read_text(encoding="utf-8"))


def fetch_csv(url: str) -> list[list[str]]:
    raw = urllib.request.urlopen(url, timeout=120).read().decode("utf-8-sig")
    return list(csv.reader(raw.splitlines()))


def export_participants(rows: list[list[str]], mode: str) -> list[dict[str, Any]]:
    if not rows:
        return []
    header = [h.strip().upper() for h in rows[0]]
    idx = {name: i for i, name in enumerate(header)}
    for col in ("NAMA", "NO KARTU"):
        if col not in idx:
            raise ValueError(f"missing column {col}; header={header}")
    no_i = idx.get("NO")
    faskes_i = idx.get("FASKES")
    out: list[dict[str, Any]] = []
    for sheet_row, cells in enumerate(rows[1:], start=2):
        if not any((c or "").strip() for c in cells):
            continue
        no_kartu = (cells[idx["NO KARTU"]] if idx["NO KARTU"] < len(cells) else "").strip()
        nama = (cells[idx["NAMA"]] if idx["NAMA"] < len(cells) else "").strip()
        if not no_kartu:
            continue
        if mode == "todo" and faskes_i is not None and faskes_i < len(cells):
            if (cells[faskes_i] or "").strip():
                continue
        item: dict[str, Any] = {"sheet_row": sheet_row, "nama": nama, "no_kartu": no_kartu}
        if no_i is not None and no_i < len(cells):
            item["no"] = (cells[no_i] or "").strip()
        out.append(item)
    return out


def main() -> int:
    p = argparse.ArgumentParser(description="Export nama + no_kartu from Google Sheet CSV")
    p.add_argument(
        "--mode",
        choices=("all", "todo"),
        default="all",
        help="all=every row with NO KARTU; todo=only rows with empty FASKES",
    )
    args = p.parse_args()
    cfg = load_config()
    url = cfg.get("sheet_export_url") or ""
    if not url:
        print("sheet_export_url missing in config", file=sys.stderr)
        return 1
    root = Path(__file__).resolve().parent
    data = root / "data"
    data.mkdir(parents=True, exist_ok=True)
    try:
        items = export_participants(fetch_csv(url), args.mode)
    except ValueError as e:
        print(e, file=sys.stderr)
        return 1
    json_path = data / "participants.json"
    jsonl_path = data / "participants.jsonl"
    csv_path = data / "participants.csv"
    json_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    with jsonl_path.open("w", encoding="utf-8") as f:
        for row in items:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["sheet_row", "no", "nama", "no_kartu"], extrasaction="ignore")
        w.writeheader()
        w.writerows(items)
    # legacy name used by extract.py
    legacy = root / (cfg.get("queue_json") or "data/queue.json")
    legacy.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"mode={args.mode} rows={len(items)}")
    print(f"  {json_path}")
    print(f"  {jsonl_path}")
    print(f"  {csv_path}")
    print(f"  {legacy} (synced for extract.py)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
