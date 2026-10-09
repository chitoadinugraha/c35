lines = open(r"D:/c35/_/schemas/inst.sql", encoding="utf-8").read().splitlines()
for i, l in enumerate(lines, 1):
    s = l.split("--")[0].rstrip()
    if not s.endswith(";"):
        continue
    if s.count("'") % 2 == 1:
        print(i, s[:140])
