"""Extract ca_skillplus pg_dump section from yb-all-v2.sql for restore into existing DB."""
import re
import sys
from pathlib import Path

MARK_START = '-- Database "ca_skillplus" dump'
MARK_DB = re.compile(r"^-- Database .+ dump\s*$")


def main() -> None:
    if len(sys.argv) < 3:
        print("usage: _extract_ca_skillplus.py <yb-all-v2.sql> <out.sql>", file=sys.stderr)
        sys.exit(1)
    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    lines: list[str] = []
    in_block = False
    with src.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            if not in_block:
                if line.startswith(MARK_START):
                    in_block = True
                continue
            if MARK_DB.match(line):
                break
            if line.startswith("CREATE DATABASE ca_skillplus"):
                continue
            if line.startswith("ALTER DATABASE ca_skillplus"):
                continue
            if line.strip() == r"\connect ca_skillplus":
                continue
            lines.append(line)
    body = "".join(lines)
    if not body.strip():
        print("empty ca_skillplus section", file=sys.stderr)
        sys.exit(1)
    out.write_text(body, encoding="utf-8")
    print(f"wrote {out} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
