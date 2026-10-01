#!/usr/bin/env python3
"""Split participants.jsonl into N shards for parallel extract workers."""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--parts", type=int, default=4, help="number of shard files")
    p.add_argument("--input", default="data/participants.jsonl")
    p.add_argument("--out-dir", default="data/shards")
    args = p.parse_args()
    if args.parts < 1:
        print("--parts must be >= 1", file=sys.stderr)
        return 1
    root = Path(__file__).resolve().parent
    src = root / args.input
    if not src.is_file():
        print(f"missing {src}; run sheet_export.py first", file=sys.stderr)
        return 1
    rows = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    n = len(rows)
    if n == 0:
        print("no participants", file=sys.stderr)
        return 1
    out_dir = root / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    chunk = math.ceil(n / args.parts)
    for i in range(args.parts):
        part = rows[i * chunk : (i + 1) * chunk]
        if not part:
            continue
        path = out_dir / f"shard-{i:02d}.json"
        path.write_text(json.dumps(part, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"shard-{i:02d}: {len(part)} rows -> {path}")
    print(f"total {n} rows in {args.parts} shards (chunk~{chunk})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
