#!/usr/bin/env python3

"""ePus + Sheets API sync: 1 serial ePus or N pinned tabs (--epus-workers), API parallel."""

from __future__ import annotations



import argparse

import json

import queue

import sys

import threading

import time

from pathlib import Path

from typing import Any



from extract import (
    ensure_browser_online,
    epus_not_found_fields,
    epus_tab_pool_fresh,
    fetch_one,
    load_config,
    wake_extension,
)

from sheet_pending import filter_pending_empty_faskes, filter_pending_participants

from sheet_write_api import write_sheet_row_gl





def load_rows(

    root: Path,

    shard: str,

    start_sheet_row: int,

    limit: int,

    cfg: dict,

    incremental: bool,

    empty_only: bool = False,

) -> list[dict[str, Any]]:

    if shard:

        rows = json.loads((root / shard).read_text(encoding="utf-8"))

    else:

        rows = [

            json.loads(line)

            for line in (root / "data/participants.jsonl").read_text(encoding="utf-8").splitlines()

            if line.strip()

        ]

    if empty_only:
        rows = filter_pending_empty_faskes(rows, cfg, start_sheet_row=start_sheet_row)
    else:
        rows = filter_pending_participants(
            rows, cfg, start_sheet_row=start_sheet_row, incremental=incremental
        )

    if limit > 0:

        rows = rows[:limit]

    return rows





def _run_epus_pool(

    rows: list[dict[str, Any]],

    cfg: dict,

    owner: int,

    wait_ms: int,

    epus_n: int,

    wave: int,

) -> int:

    wake_extension()

    tab_pool = epus_tab_pool_fresh(cfg, owner, epus_n)

    print(f"epus tab pool ({len(tab_pool)}): {tab_pool}", flush=True)



    row_q: queue.Queue[dict[str, Any] | None] = queue.Queue()

    for part in rows:

        row_q.put(part)

    stats = {"epus_fail": 0, "write_fail": 0, "ok": 0, "done": 0}

    lock = threading.Lock()



    def epus_worker(wid: int, tab_id: str) -> None:

        while True:

            part = row_q.get()

            try:

                if part is None:

                    return

                sr = int(part["sheet_row"])

                no_kartu = str(part.get("no_kartu") or "")

                nama = str(part.get("nama") or "")

                print(f"[e{wid}] tab={tab_id} sheet_row={sr} {nama}", flush=True)

                epus = fetch_one(

                    cfg, owner, no_kartu, wait_ms, nama=nama, tab_id=tab_id, keep_tab=True

                )

                if not epus.get("ok"):

                    with lock:

                        stats["epus_fail"] += 1

                        stats["done"] += 1

                    print(f"[e{wid}] epus FAIL {json.dumps(epus, ensure_ascii=False)}", flush=True)

                    continue

                try:

                    raw = write_sheet_row_gl(sr, epus.get("fields") or {})

                    ok = bool(raw.get("ok"))

                except Exception as e:

                    print(f"[e{wid}] sheet_row={sr} write error={e}", flush=True)

                    ok = False

                with lock:

                    stats["done"] += 1

                    if ok:

                        stats["ok"] += 1

                    else:

                        stats["write_fail"] += 1

                    done = stats["done"]

                    if done % wave == 0:

                        print(

                            f"--- wave {done}/{len(rows)} ok={stats['ok']} "

                            f"epus_fail={stats['epus_fail']} write_fail={stats['write_fail']} ---",

                            flush=True,

                        )

                print(f"[e{wid}] sheet_row={sr} write={'ok' if ok else 'FAIL'}", flush=True)

            finally:

                row_q.task_done()



    threads = [

        threading.Thread(target=epus_worker, args=(i, tab_pool[i]), daemon=True)

        for i in range(len(tab_pool))

    ]

    for t in threads:

        t.start()

    for _ in threads:

        row_q.put(None)

    for t in threads:

        t.join(timeout=600)



    print(

        f"done rows={len(rows)} ok={stats['ok']} epus_fail={stats['epus_fail']} write_fail={stats['write_fail']}",

        flush=True,

    )

    return 1 if stats["epus_fail"] or stats["write_fail"] else 0





def main() -> int:

    p = argparse.ArgumentParser()

    p.add_argument("--workers", type=int, default=3, help="parallel Sheets API writers (epus-workers=1 only)")

    p.add_argument(

        "--epus-workers",

        type=int,

        default=0,

        help="pinned ePus tabs in parallel (0=use --workers mode with serial ePus)",

    )

    p.add_argument("--wave-size", type=int, default=5, help="log checkpoint every N rows (after writes drain)")

    p.add_argument("--shard", default="")

    p.add_argument("--start-sheet-row", type=int, default=0)

    p.add_argument("--limit", type=int, default=0)

    p.add_argument(

        "--no-incremental",

        action="store_true",

        help="do not skip rows that already have FASKES in live sheet CSV",

    )

    p.add_argument(
        "--empty-only",
        action="store_true",
        help="only rows with empty FASKES or TIDAK DITEMUKAN (retry pass)",
    )

    p.add_argument(
        "--search-by",
        default="nama",
        choices=("nama", "nik", "penjamin", "kartu"),
        help="nama=Cari Nama; nik=NIK dropdown + value; penjamin/kartu=No Asuransi/penjamin",
    )

    args = p.parse_args()

    root = Path(__file__).resolve().parent

    cfg = load_config()

    owner = int(cfg.get("owner_iid") or 99000)

    wait_ms = int(cfg.get("wait_ms") or 3200)

    incremental = not args.no_incremental and not args.empty_only

    search_by = str(args.search_by or "nama")

    rows = load_rows(
        root,
        args.shard.strip(),
        args.start_sheet_row,
        args.limit,
        cfg,
        incremental,
        empty_only=bool(args.empty_only),
    )

    if not rows:

        print("no rows", file=sys.stderr)

        return 1



    epus_n = int(args.epus_workers or 0)

    if epus_n > 0:

        return _run_epus_pool(rows, cfg, owner, wait_ms, epus_n, max(1, args.wave_size))



    workers_n = max(1, args.workers)

    work_q: queue.Queue[tuple[int, dict[str, str]] | None] = queue.Queue(maxsize=workers_n * 2)

    stats = {"epus_fail": 0, "write_fail": 0, "ok": 0}

    lock = threading.Lock()



    def writer(wid: int) -> None:

        while True:

            item = work_q.get()

            try:

                if item is None:

                    return

                sheet_row, fields = item

                try:

                    raw = write_sheet_row_gl(sheet_row, fields)

                    ok = bool(raw.get("ok"))

                except Exception as e:

                    print(f"[w{wid}] sheet_row={sheet_row} error={e}", flush=True)

                    ok = False

                with lock:

                    if ok:

                        stats["ok"] += 1

                    else:

                        stats["write_fail"] += 1

                    tag = "ok" if ok else "FAIL"

                    print(f"[w{wid}] sheet_row={sheet_row} write={tag}", flush=True)

            finally:

                work_q.task_done()



    threads = [threading.Thread(target=writer, args=(i,), daemon=True) for i in range(workers_n)]

    for t in threads:

        t.start()



    if not ensure_browser_online(cfg, owner):
        print("abort: browser agent still offline", flush=True)
        return 2

    wave = max(1, args.wave_size)

    print(
        f"start rows={len(rows)} workers={workers_n} search_by={search_by} (ePus serial, API parallel)",
        flush=True,
    )



    for i, part in enumerate(rows):

        sr = int(part["sheet_row"])

        no_kartu = str(part.get("no_kartu") or "")

        nama = str(part.get("nama") or "")

        print(f"\n=== [{i + 1}/{len(rows)}] ePus sheet_row={sr} {nama} {no_kartu} ===", flush=True)

        try:

            epus = fetch_one(cfg, owner, no_kartu, wait_ms, nama=nama, search_by=search_by)

        except Exception as e:

            with lock:

                stats["epus_fail"] += 1

            print(f"epus ERROR sheet_row={sr} {e!r}", flush=True)

            continue

        if not epus.get("ok"):

            if epus.get("error") == "not_found":

                print(f"not_found sheet_row={sr} -> write FASKES marker", flush=True)

                work_q.put((sr, epus_not_found_fields()))

            else:

                with lock:

                    stats["epus_fail"] += 1

                print(f"epus FAIL {json.dumps(epus, ensure_ascii=False)}", flush=True)

            continue

        fields = epus.get("fields") or {}

        work_q.put((sr, fields))

        if (i + 1) % wave == 0:

            work_q.join()

            print(

                f"--- wave {i + 1} epus_fail={stats['epus_fail']} "

                f"write_ok={stats['ok']} write_fail={stats['write_fail']} ---",

                flush=True,

            )

        time.sleep(0.15)



    work_q.join()

    for _ in threads:

        work_q.put(None)

    for t in threads:

        t.join(timeout=30)



    print(

        f"done rows={len(rows)} ok={stats['ok']} epus_fail={stats['epus_fail']} write_fail={stats['write_fail']}",

        flush=True,

    )

    return 1 if stats["epus_fail"] or stats["write_fail"] else 0





if __name__ == "__main__":

    raise SystemExit(main())

