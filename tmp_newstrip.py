def strip_line_comment(line):
    b = line.encode("utf-8")
    i, in_string = 0, False
    while i < len(b):
        c = b[i]
        if c == 39:
            if in_string and i + 1 < len(b) and b[i + 1] == 39:
                i += 2
                continue
            in_string = not in_string
            i += 1
            continue
        if not in_string and c == 45 and i + 1 < len(b) and b[i + 1] == 45:
            return line[:i].rstrip()
        i += 1
    return line

def dollar_block_opens(line):
    u = line.upper()
    return u.startswith("DO $$") or " AS $$" in line

def dollar_block_closes(line):
    if "$$" not in line:
        return False
    if dollar_block_opens(line):
        return False
    return "$$ LANGUAGE" in line or line.endswith("$$;") or line.upper().endswith("END $$;")

def sql_stmts(sql):
    cur, out, in_dollar = [], [], False
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
                if s: out.append(s)
        elif line.endswith(";"):
            s = "\n".join(cur).strip().rstrip(";").strip()
            cur = []
            if s: out.append(s)
    if cur:
        s = "\n".join(cur).strip().rstrip(";").strip()
        if s: out.append(s)
    return out

sql = open(r"D:/c35/_/schemas/inst.sql", encoding="utf-8").read()
stmts = sql_stmts(sql)
pres = [s for s in stmts if "inst.presentation" in s and s.startswith("INSERT")]
print("pres count", len(pres), "len", len(pres[0]) if pres else 0)
print("has slides sep", "---" in pres[0] if pres else False)
print("has slide-patch", "slide-patch" in pres[0] if pres else False)

pres=[s for s in stmts if 'inst.presentation' in s and s.startswith('INSERT')][0]
print('separated', 'separated by' in pres)
for i,s in enumerate(stmts):
    if s.startswith('INSERT INTO ai.inst') and 'include_tools' in s.split('VALUES')[0]:
        if 'VALUES' not in s or len(s)<200:
            print('BAD', i, s[:80])
