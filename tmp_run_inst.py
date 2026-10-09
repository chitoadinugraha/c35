import re, subprocess, json, urllib.request

def strip_line_comment(line):
    pos = line.find("--")
    return line[:pos].rstrip() if pos >= 0 else line

def dollar_block_opens(line):
    upper = line.upper()
    return upper.startswith("DO $$") or " AS $$" in line

def dollar_block_closes(line):
    if "$$" not in line:
        return False
    if dollar_block_opens(line):
        return False
    return "$$ LANGUAGE" in line or line.endswith("$$;") or line.upper().endswith("END $$;")

def sql_stmts(sql):
    cur = []
    out = []
    in_dollar = False
    for raw in sql.splitlines():
        line = strip_line_comment(raw).strip()
        if not line:
            continue
        if not in_dollar and dollar_block_opens(line):
            in_dollar = True
        cur.append(line)
        if in_dollar:
            if dollar_block_closes(line):
                in_dollar = False
                s = "\n".join(cur).strip().rstrip(";").strip()
                cur = []
                if s:
                    out.append(s)
        elif line.endswith(";"):
            s = "\n".join(cur).strip().rstrip(";").strip()
            cur = []
            if s:
                out.append(s)
    if cur:
        s = "\n".join(cur).strip().rstrip(";").strip()
        if s:
            out.append(s)
    return out

sql = open(r"D:/c35/_/schemas/inst.sql", encoding="utf-8").read()
stmts = sql_stmts(sql)
print("stmt count", len(stmts))
for i, s in enumerate(stmts):
    if not s.upper().startswith("INSERT INTO AI.INST"):
        continue
    cols = s.split("VALUES", 1)[0]
    if "include_tools" not in cols:
        continue
    # quick check: count columns between first ( and )
    m = re.search(r"INSERT INTO ai\.inst\s*\(([^)]+)\)", s, re.I)
    if not m:
        continue
    ncol = len([c.strip() for c in m.group(1).replace("\n"," ").split(",")])
    # find id
    idm = re.search(r"VALUES\s*\(\s*'([^']+)'", s, re.I)
    iid = idm.group(1) if idm else "?"
for i, s in enumerate(stmts):
    if not s.upper().startswith("INSERT INTO AI.INST"):
        continue
    idm = re.search(r"VALUES\s*\(\s*'([^']+)'", s, re.I)
    cols = s.split("VALUES", 1)[0]
    has_inc = "include_tools" in cols
    print(i, idm.group(1) if idm else "?", "inc" if has_inc else "")