#!/usr/bin/env python3
"""One-shot native messaging frame test (pair.status)."""
import json
import struct
import subprocess
import sys
from pathlib import Path

def main() -> int:
    exe = Path(
        sys.argv[1]
        if len(sys.argv) > 1
        else Path.home()
        / "AppData/Local/AlienAI/chrome_extension/install/alienai_remote_browser.exe"
    )
    if not exe.is_file():
        print(f"missing exe: {exe}", file=sys.stderr)
        return 1
    msg = json.dumps({"type": "pair.status"}).encode("utf-8")
    proc = subprocess.Popen(
        [str(exe), "--chrome-native-host"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert proc.stdin and proc.stdout
    proc.stdin.write(struct.pack("<I", len(msg)) + msg)
    proc.stdin.close()
    raw_len = proc.stdout.read(4)
    if len(raw_len) != 4:
        err = proc.stderr.read().decode("utf-8", errors="replace")
        print(f"no response (stderr={err[:500]})", file=sys.stderr)
        return 1
    n = struct.unpack("<I", raw_len)[0]
    if n > 1_000_000:
        print(f"bad frame length {n}", file=sys.stderr)
        return 1
    body = proc.stdout.read(n)
    print(body.decode("utf-8"))
    proc.wait(timeout=10)
    return 0 if proc.returncode == 0 else proc.returncode or 1


if __name__ == "__main__":
    raise SystemExit(main())