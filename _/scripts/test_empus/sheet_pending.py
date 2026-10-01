#!/usr/bin/env python3
"""Skip sheet rows that already have address columns filled (live CSV)."""
from __future__ import annotations

import csv
import urllib.request
from typing import Any


def fetch_csv(url: str) -> list[list[str]]:
    raw = urllib.request.urlopen(url, timeout=120).read().decode("utf-8-sig")
    return list(csv.reader(raw.splitlines()))


def _header_index(header: list[str]) -> dict[str, int]:
    return {name.strip().upper(): i for i, name in enumerate(header)}


NOT_FOUND_FASKES = "TIDAK DITEMUKAN"


def faskes_by_sheet_row(rows: list[list[str]]) -> dict[int, str]:
    if not rows:
        return {}
    idx = _header_index(rows[0])
    faskes_i = idx.get("FASKES")
    if faskes_i is None:
        return {}
    out: dict[int, str] = {}
    for sheet_row, cells in enumerate(rows[1:], start=2):
        v = cells[faskes_i] if faskes_i < len(cells) else ""
        out[sheet_row] = (v or "").strip()
    return out


def filled_sheet_rows(rows: list[list[str]]) -> set[int]:
    """Rows with FASKES (M) non-empty — treated as already synced."""
    if not rows:
        return set()
    idx = _header_index(rows[0])
    faskes_i = idx.get("FASKES")
    if faskes_i is None:
        return set()
    out: set[int] = set()
    for sheet_row, cells in enumerate(rows[1:], start=2):
        if faskes_i < len(cells) and (cells[faskes_i] or "").strip():
            out.add(sheet_row)
    return out


def filter_pending_empty_faskes(
    participants: list[dict[str, Any]],
    cfg: dict,
    *,
    start_sheet_row: int = 0,
    include_not_found_marker: bool = True,
) -> list[dict[str, Any]]:
    """Rows whose FASKES cell is blank (and optionally prior TIDAK DITEMUKAN marker)."""
    rows = list(participants)
    if start_sheet_row > 0:
        rows = [r for r in rows if int(r.get("sheet_row") or 0) >= start_sheet_row]
    url = (cfg.get("sheet_export_url") or "").strip()
    if not url:
        return rows
    try:
        faskes = faskes_by_sheet_row(fetch_csv(url))
    except OSError as e:
        print(f"sheet_pending: csv fetch failed ({e}); processing all rows", flush=True)
        return rows

    def needs_retry(sr: int) -> bool:
        v = faskes.get(sr, "")
        if not v:
            return True
        if include_not_found_marker and v.upper() == NOT_FOUND_FASKES:
            return True
        return False

    pending = [r for r in rows if needs_retry(int(r.get("sheet_row") or 0))]
    skipped = len(rows) - len(pending)
    if skipped:
        print(f"sheet_pending: skip {skipped} rows with FASKES set; {len(pending)} empty/retry", flush=True)
    return pending


def filter_pending_participants(
    participants: list[dict[str, Any]],
    cfg: dict,
    *,
    start_sheet_row: int = 0,
    incremental: bool = True,
) -> list[dict[str, Any]]:
    rows = list(participants)
    if start_sheet_row > 0:
        rows = [r for r in rows if int(r.get("sheet_row") or 0) >= start_sheet_row]
    if not incremental:
        return rows
    url = (cfg.get("sheet_export_url") or "").strip()
    if not url:
        return rows
    try:
        filled = filled_sheet_rows(fetch_csv(url))
    except OSError as e:
        print(f"sheet_pending: csv fetch failed ({e}); processing all rows", flush=True)
        return rows
    pending = [r for r in rows if int(r.get("sheet_row") or 0) not in filled]
    skipped = len(rows) - len(pending)
    if skipped:
        print(f"sheet_pending: skip {skipped} rows with FASKES already set; {len(pending)} to run", flush=True)
    return pending
