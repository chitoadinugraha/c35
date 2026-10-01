#!/usr/bin/env python3
"""Deprecated: use sheet_export.py. Kept as alias."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    script = Path(__file__).resolve().parent / "sheet_export.py"
    return subprocess.call([sys.executable, str(script), "--mode", "todo"])


if __name__ == "__main__":
    raise SystemExit(main())
