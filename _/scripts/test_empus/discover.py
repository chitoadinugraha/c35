#!/usr/bin/env python3
"""List paired browser devices and open tabs (find epus_tab_id)."""
from __future__ import annotations

import json
import sys

from c35_agent import device_list, tool_exec


def main() -> int:
    owner = int(sys.argv[1]) if len(sys.argv) > 1 else 99000
    dl = device_list(owner)
    if not dl.get("ok"):
        print(json.dumps(dl, indent=2, ensure_ascii=False))
        return 1
    devices = [d for d in dl.get("devices", []) if d.get("type") == "browser"]
    print(f"browser devices ({len(devices)}):")
    for d in devices:
        iid = d.get("device_iid")
        print(f"  {iid}  online={d.get('online')}  {d.get('name')}")
        if not d.get("online"):
            continue
        tabs = tool_exec("browser.tabs", {"device_iid": int(iid), "op": "list"}, owner)
        if not tabs.get("ok"):
            print(f"    tabs error: {tabs.get('error')}")
            continue
        result = tabs.get("result") or tabs
        items = result.get("tabs") if isinstance(result, dict) else None
        if not items and isinstance(tabs.get("tabs"), list):
            items = tabs["tabs"]
        for t in items or []:
            url = t.get("url") or ""
            mark = " *epus*" if "epuskesmas" in url else ""
            print(f"    tab_id={t.get('tabId') or t.get('tab_id')}  {t.get('title', '')[:50]}{mark}")
            print(f"      {url[:100]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
