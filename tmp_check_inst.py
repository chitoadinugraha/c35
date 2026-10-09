import re
from pathlib import Path
text = Path(r"D:/c35/_/schemas/inst.sql").read_text(encoding="utf-8")
parts = re.split(r"INSERT INTO ai\.inst\s*\(", text)
for p in parts[1:]:
    m = re.match(r"\s*([^)]+)\)\s*VALUES\s*\(", p, re.I)
    if not m:
        continue
    cols = [c.strip() for c in re.sub(r"\s+", " ", m.group(1)).split(",")]
    rest = p[m.end() :]
    end = rest.find(") ON CONFLICT")
    if end < 0:
        end = rest.find(");")
    if end < 0:
        continue
    vals = rest[:end]
    depth = 0
    exprs = 0
    for ch in vals:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            exprs += 1
    exprs += 1
    if len(cols) != exprs:
        idm = re.search(r"'([^']+)'", vals)
        print(f"mismatch cols={len(cols)} vals={exprs} id={idm.group(1) if idm else '?'}")