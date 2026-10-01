#!/usr/bin/env python3
"""Extract ePus patient detail to JSONL (search + observe + parse)."""
from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from c35_agent import tool_exec


def load_config() -> dict:
    root = Path(__file__).resolve().parent
    path = root / "config.json"
    if not path.is_file():
        path = root / "config.example.json"
    return json.loads(path.read_text(encoding="utf-8"))


def root_dir() -> Path:
    return Path(__file__).resolve().parent


def load_queue(cfg: dict) -> list[dict[str, Any]]:
    root = root_dir()
    shard = (cfg.get("shard_json") or "").strip()
    if shard:
        path = root / shard
        return json.loads(path.read_text(encoding="utf-8"))
    jsonl = root / (cfg.get("participants_jsonl") or "data/participants.jsonl")
    if jsonl.is_file():
        return [json.loads(line) for line in jsonl.read_text(encoding="utf-8").splitlines() if line.strip()]
    path = root / (cfg.get("queue_json") or "data/queue.json")
    return json.loads(path.read_text(encoding="utf-8"))


def load_done(cfg: dict) -> set[str]:
    path = root_dir() / (cfg.get("done_json") or "data/done_no_kartu.json")
    if not path.is_file():
        return set()
    return set(json.loads(path.read_text(encoding="utf-8")))


def save_done(cfg: dict, done: set[str]) -> None:
    path = root_dir() / (cfg.get("done_json") or "data/done_no_kartu.json")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(sorted(done), ensure_ascii=False, indent=2), encoding="utf-8")


def append_jsonl(cfg: dict, row: dict[str, Any]) -> None:
    path = root_dir() / (cfg.get("output_jsonl") or "data/peserta.jsonl")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")


def tab_params(cfg: dict) -> dict[str, str]:
    tab = (cfg.get("epus_tab_id") or "").strip()
    return {"tab_id": tab} if tab else {}


_DUSUN_ALAMAT_HEAD = re.compile(r"^(?:dusun|dsn)\s+(.+)$", re.IGNORECASE)
_DUSUN_ALAMAT_IN = re.compile(r"\b(?:dusun|dsn)\s+([^,\n/]+)", re.IGNORECASE)


EPUS_NOT_FOUND_FASKES = "TIDAK DITEMUKAN"


def epus_not_found_fields() -> dict[str, str]:
    return {"faskes": EPUS_NOT_FOUND_FASKES}


def epus_search_not_found(snap: str, act: dict[str, Any], url: str = "") -> bool:
    if "/pasien/show" in (url or ""):
        return False
    if act.get("row_opened"):
        return False
    if act.get("not_found"):
        return True
    low = (snap or "").lower()
    return "data tidak ditemukan" in low


def normalize_epus_fields(fields: dict[str, str]) -> dict[str, str]:
    """If Alamat is DUSUN/DSN <name>, copy <name> into Dusun."""
    f = {k: str(v or "") for k, v in fields.items()}
    alamat = f.get("alamat", "").strip()
    if not alamat:
        return f
    head = _DUSUN_ALAMAT_HEAD.match(alamat)
    if head:
        f["dusun"] = head.group(1).strip()
        return f
    found = _DUSUN_ALAMAT_IN.search(alamat)
    if found and not f.get("dusun", "").strip():
        f["dusun"] = found.group(1).strip()
    return f


def line_after(text: str, label: str) -> str:
    needle = f"{label}\n"
    i = text.find(needle)
    if i < 0:
        return ""
    line = text[i + len(needle) :].split("\n", 1)[0].strip()
    return "" if line == "-" else line


def parse_epus_observe(ob: dict[str, Any]) -> dict[str, str]:
    snap = str(ob.get("snapshot") or "")
    rt_rw = line_after(snap, "RT/RW")
    rt, rw = "", ""
    if "/" in rt_rw:
        rt, rw = [p.strip().strip("'\"") for p in rt_rw.split("/", 1)]
    dusun = line_after(snap, "Dusun")
    desa = line_after(snap, "Kelurahan")
    kecamatan = line_after(snap, "Kecamatan")
    alamat = line_after(snap, "Alamat") or line_after(snap, "Alamat Lengkap")
    if not alamat:
        bits = [p for p in (dusun, f"RT {rt}" if rt else "", f"RW {rw}" if rw else "", desa, kecamatan) if p]
        alamat = ", ".join(bits)
    return normalize_epus_fields(
        {
            "alamat": alamat,
            "dusun": dusun,
            "rt": rt,
            "rw": rw,
            "desa": desa,
            "kecamatan": kecamatan,
            "faskes": line_after(snap, "Puskesmas"),
            "nama": line_after(snap, "Nama"),
            "no_kartu": line_after(snap, "No. Penjamin"),
            "no_telp": line_after(snap, "No. HP"),
        }
    )


def wake_extension() -> None:
    host = root_dir().parents[1] / "dev" / "test_chrome_native_host.py"
    if not host.is_file():
        return
    try:
        subprocess.run([sys.executable, str(host)], capture_output=True, timeout=15, check=False)
    except (OSError, subprocess.TimeoutExpired):
        pass


EPUS_LIST_URL = "https://malang.epuskesmas.id/pasien?broadcastNotif=1"


def epus_tab_id(cfg: dict) -> str:
    return (cfg.get("epus_tab_id") or "").strip()


def _epus_list_tabs(owner: int, dev: int) -> list[dict[str, Any]]:
    raw = tool_exec("browser.tabs", {"device_iid": dev, "op": "list"}, owner)
    return list((raw.get("result") or {}).get("tabs") or [])


def epus_close_show_tabs(cfg: dict, owner: int) -> None:
    dev = int(cfg["device_iid"])
    for t in _epus_list_tabs(owner, dev):
        url = t.get("url") or ""
        tid = str(t.get("tabId") or "")
        if "/pasien/show/" in url and tid:
            tool_exec("browser.tabs", {"device_iid": dev, "op": "close", "tab_id": tid}, owner)
            time.sleep(0.3)


def epus_list_tab_ids(owner: int, dev: int) -> list[str]:
    out: list[str] = []
    for t in _epus_list_tabs(owner, dev):
        url = t.get("url") or ""
        tid = str(t.get("tabId") or "")
        if tid and "epuskesmas.id/pasien" in url and "/show/" not in url:
            out.append(tid)
    return out


def epus_activate_tab(cfg: dict, owner: int, tab_id: str) -> None:
    dev = int(cfg["device_iid"])
    tool_exec("browser.tabs", {"device_iid": dev, "op": "activate", "tab_id": tab_id}, owner)
    cfg["epus_tab_id"] = tab_id
    time.sleep(0.6)


def epus_goto_list(cfg: dict, owner: int, tab_id: str) -> None:
    dev = int(cfg["device_iid"])
    tool_exec(
        "browser.page.act",
        {
            "device_iid": dev,
            "action": "goto",
            "url": EPUS_LIST_URL,
            "tab_id": tab_id,
            "focus": False,
        },
        owner,
    )
    time.sleep(1.5)


def epus_tab_pool_fresh(cfg: dict, owner: int, n: int) -> list[str]:
    """Close all ePus tabs and open n new list tabs (parallel workers)."""
    dev = int(cfg["device_iid"])
    n = max(1, n)
    for t in _epus_list_tabs(owner, dev):
        url = t.get("url") or ""
        tid = str(t.get("tabId") or "")
        if tid and "epuskesmas.id" in url:
            tool_exec("browser.tabs", {"device_iid": dev, "op": "close", "tab_id": tid}, owner)
            time.sleep(0.25)
    pool: list[str] = []
    while len(pool) < n:
        raw = tool_exec(
            "browser.tabs",
            {"device_iid": dev, "op": "new", "url": EPUS_LIST_URL},
            owner,
        )
        tid = str((raw.get("result") or {}).get("tabId") or "")
        if not tid:
            raise RuntimeError("failed to open ePus list tab for pool")
        pool.append(tid)
        time.sleep(2.0)
    return pool


def epus_tab_pool_ensure(cfg: dict, owner: int, n: int) -> list[str]:
    """Open or reuse n distinct ePus list tabs (left open for workers)."""
    dev = int(cfg["device_iid"])
    n = max(1, n)
    epus_close_show_tabs(cfg, owner)
    pool = epus_list_tab_ids(owner, dev)
    while len(pool) < n:
        raw = tool_exec(
            "browser.tabs",
            {"device_iid": dev, "op": "new", "url": EPUS_LIST_URL},
            owner,
        )
        tid = str((raw.get("result") or {}).get("tabId") or "")
        if not tid:
            raise RuntimeError("failed to open ePus list tab for pool")
        pool.append(tid)
        time.sleep(2.0)
    return pool[:n]


def epus_open_list_tab(cfg: dict, owner: int) -> str:
    """Reuse pasien list tab or open a fresh one; close stale /show/ detail tabs."""
    dev = int(cfg["device_iid"])
    epus_close_show_tabs(cfg, owner)
    for t in _epus_list_tabs(owner, dev):
        url = t.get("url") or ""
        tid = str(t.get("tabId") or "")
        if "epuskesmas.id/pasien" in url and "/show/" not in url and tid:
            tool_exec("browser.tabs", {"device_iid": dev, "op": "activate", "tab_id": tid}, owner)
            cfg["epus_tab_id"] = tid
            time.sleep(1.0)
            return tid
    raw = tool_exec(
        "browser.tabs",
        {"device_iid": dev, "op": "new", "url": EPUS_LIST_URL},
        owner,
    )
    inner = raw.get("result") if isinstance(raw.get("result"), dict) else raw
    tid = str(inner.get("tabId") or inner.get("tab_id") or "")
    if not tid:
        raise RuntimeError(f"failed to open ePus list tab: {raw!r}")
    cfg["epus_tab_id"] = tid
    time.sleep(2.5)
    return tid


def epus_reset_tab(cfg: dict, owner: int) -> None:
    epus_open_list_tab(cfg, owner)


def epus_release_tab(cfg: dict, owner: int) -> None:
    """Close ePus tab after use; focus sheet tab (sheet cells unchanged except row_set)."""
    dev = int(cfg["device_iid"])
    tab_id = epus_tab_id(cfg)
    if tab_id:
        tool_exec("browser.tabs", {"device_iid": dev, "op": "close", "tab_id": tab_id}, owner)
        cfg["epus_tab_id"] = ""
        time.sleep(0.4)
    sheet_tab = (cfg.get("sheet_tab_id") or "").strip()
    if sheet_tab:
        tool_exec("browser.tabs", {"device_iid": dev, "op": "activate", "tab_id": sheet_tab}, owner)
        time.sleep(0.4)


def fetch_one(
    cfg: dict,
    owner: int,
    no_kartu: str,
    wait_ms: int,
    *,
    nama: str = "",
    search_by: str = "nama",
    tab_id: str | None = None,
    keep_tab: bool = False,
) -> dict[str, Any]:
    dev = int(cfg["device_iid"])
    pinned = (tab_id or "").strip()

    def _tab() -> dict[str, str]:
        if pinned:
            return {"tab_id": pinned, "focus": False}
        return tab_params(cfg)

    def _reset_tab() -> None:
        if pinned:
            epus_goto_list(cfg, owner, pinned)
        else:
            epus_open_list_tab(cfg, owner)

    def _kartu_match(got: str, want: str, snap: str) -> bool:
        g, w = (got or "").strip(), (want or "").strip()
        if not w:
            return False
        if g and (g == w or g.lstrip("0") == w.lstrip("0")):
            return True
        return w in (snap or "")

    def _patient_ok(f: dict[str, str], snap_s: str, _url_s: str) -> bool:
        return _kartu_match(f.get("no_kartu") or "", no_kartu, snap_s)

    if pinned:
        epus_goto_list(cfg, owner, pinned)
    else:
        epus_open_list_tab(cfg, owner)
    tab = _tab()
    fields: dict[str, str] = {}
    observe: dict[str, Any] = {}
    snap = ""
    url = ""
    err: str | None = None

    kartu_q = (no_kartu or "").strip()
    sb = (search_by or "nama").strip().lower()
    if sb in ("penjamin", "nik", "asuransi"):
        sb = "kartu"
    phases: list[tuple[str, str, int]] = [(kartu_q, sb, 3)]

    hit = False
    saw_not_found = False
    for phase_i, (query, search_by, attempts) in enumerate(phases):
        saw_not_found = False
        for _ in range(attempts):
            fetch_raw = tool_exec(
                "browser.page.act",
                {
                    "device_iid": dev,
                    "action": "epus_pasien_fetch",
                    "text": query,
                    "search_by": search_by,
                    "wait_ms": wait_ms,
                    "no_kartu": kartu_q,
                    "nama": (nama or "").strip(),
                    **tab,
                },
                owner,
            )
            time.sleep(1.2)
            obs_raw = tool_exec(
                "browser.page.observe",
                {"device_iid": dev, "max_chars": 12000, **tab},
                owner,
            )
            inner = obs_raw.get("result") if isinstance(obs_raw.get("result"), dict) else {}
            observe = inner.get("observe") if isinstance(inner.get("observe"), dict) else inner
            fields = parse_epus_observe(observe)
            act = fetch_raw.get("result") if isinstance(fetch_raw.get("result"), dict) else {}
            nested = act.get("result") if isinstance(act.get("result"), dict) else {}
            if nested:
                act = {**act, **nested}
            act_fields = act.get("fields") if isinstance(act.get("fields"), dict) else {}
            if act_fields:
                merged = {**fields, **{k: str(v) for k, v in act_fields.items() if v is not None}}
                fields = normalize_epus_fields(merged)
            snap = str(observe.get("snapshot") or "")
            url = str(observe.get("url") or "")
            err = inner.get("error") or obs_raw.get("error")
            on_detail = "/pasien/show" in url
            if on_detail and _patient_ok(fields, snap, url):
                hit = True
                break
            if act.get("ambiguous"):
                err = f"ambiguous_match matches={act.get('matches')}"
                fields = {}
                break
            if epus_search_not_found(snap, act, url):
                saw_not_found = True
                err = "not_found"
                fields = {}
                break
            if _patient_ok(fields, snap, url):
                hit = True
                break
            _reset_tab()
            tab = _tab()
        if hit:
            break
        break

    if saw_not_found and not hit:
        if pinned:
            epus_goto_list(cfg, owner, pinned)
        elif not keep_tab:
            epus_release_tab(cfg, owner)
        return {
            "ok": False,
            "error": "not_found",
            "fields": {},
            "url": url,
            "title": observe.get("title"),
        }

    patient_ok = _patient_ok(fields, snap, url)
    ok = patient_ok and ("/pasien/show" in url or "Lihat Data" in snap)
    if ok and not fields.get("kecamatan"):
        ok = False
        err = err or "parse_missing_kecamatan"
    if not patient_ok:
        ok = False
        err = err or f"wrong_patient got_kartu={fields.get('no_kartu')}"
    if not keep_tab:
        epus_release_tab(cfg, owner)
    return {
        "ok": ok,
        "error": err,
        "fields": fields,
        "url": url,
        "title": observe.get("title"),
    }


def main() -> int:
    cfg = load_config()
    owner = int(cfg.get("owner_iid") or 99000)
    batch_size = max(1, int(cfg.get("batch_size") or 5))
    limit = int(cfg.get("limit") or 0)
    wait_ms = int(cfg.get("wait_ms") or 3200)

    queue = load_queue(cfg)
    done = load_done(cfg)
    pending = [q for q in queue if q.get("no_kartu") not in done]
    if limit > 0:
        pending = pending[:limit]

    wake_extension()
    processed = 0
    for item in pending:
        no_kartu = str(item.get("no_kartu") or "").strip()
        if not no_kartu:
            continue
        if processed > 0 and processed % batch_size == 0:
            wake_extension()
        epus = fetch_one(cfg, owner, no_kartu, wait_ms)
        record = {
            "ts": int(time.time()),
            "sheet_row": item.get("sheet_row"),
            "no_kartu": no_kartu,
            "nama_sheet": item.get("nama"),
            "ok": epus.get("ok"),
            "error": epus.get("error"),
            "epus": epus,
        }
        append_jsonl(cfg, record)
        if record["ok"]:
            done.add(no_kartu)
        processed += 1
        if processed % batch_size == 0:
            save_done(cfg, done)
            print(f"checkpoint {processed}/{len(pending)} (done={len(done)})", flush=True)
        time.sleep(0.4)

    save_done(cfg, done)
    print(f"finished {processed} rows -> {cfg.get('output_jsonl', 'data/peserta.jsonl')}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
