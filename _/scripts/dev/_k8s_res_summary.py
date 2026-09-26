import json
import subprocess
import sys
from collections import defaultdict


def parse_cpu(s):
    if not s:
        return 0
    s = str(s)
    if s.endswith("m"):
        return int(s[:-1])
    return int(float(s) * 1000)


def parse_mem_mib(s):
    if not s:
        return 0
    s = str(s)
    if s.endswith("Ki"):
        return int(s[:-2]) / 1024
    if s.endswith("Mi"):
        return int(s[:-2])
    if s.endswith("Gi"):
        return int(s[:-2]) * 1024
    return 0


raw = subprocess.check_output(["kubectl", "get", "pods", "-A", "-o", "json"], text=True)
data = json.loads(raw)
rows = []
for p in data["items"]:
    ns = p["metadata"]["namespace"]
    name = p["metadata"]["name"]
    phase = p["status"].get("phase", "")
    cs = p["status"].get("containerStatuses") or []
    ready = sum(1 for c in cs if c.get("ready"))
    total = len(p["spec"].get("containers") or [])
    rc = rm = lc = lm = 0
    for c in p["spec"].get("containers") or []:
        r = (c.get("resources") or {}).get("requests") or {}
        l = (c.get("resources") or {}).get("limits") or {}
        rc += parse_cpu(r.get("cpu"))
        rm += parse_mem_mib(r.get("memory"))
        lc += parse_cpu(l.get("cpu"))
        lm += parse_mem_mib(l.get("memory"))
    rows.append(
        dict(
            ns=ns,
            name=name,
            phase=phase,
            ready=f"{ready}/{total}",
            rc=rc,
            rm=rm,
            lc=lc,
            lm=lm,
        )
    )

print("NOT READY:")
for r in rows:
    a, b = r["ready"].split("/")
    if r["phase"] != "Running" or a != b:
        print(f"  {r['ns']}/{r['name']} {r['phase']} ready={r['ready']}")

print()
print("BY NAMESPACE (sum req/limit):")
agg = defaultdict(lambda: [0, 0, 0, 0])
for r in rows:
    for i, key in enumerate(["rc", "rm", "lc", "lm"]):
        agg[r["ns"]][i] += r[key]
for ns in sorted(agg):
    a = agg[ns]
    print(
        f"  {ns}: req {a[0]}m CPU / {a[1]:.0f}Mi mem"
        f" -- limits {a[2]}m CPU / {a[3]:.0f}Mi mem"
    )

tr = [sum(r[x] for r in rows) for x in ["rc", "rm", "lc", "lm"]]
print()
print(
    f"CLUSTER TOTAL: req {tr[0]}m CPU / {tr[1]:.0f}Mi mem"
    f" -- limits {tr[2]}m CPU / {tr[3]:.0f}Mi mem"
)
print("(node allocatable ~3815m CPU, ~19673Mi mem)")
print()
print("WORKLOADS WITH LIMITS:")
for r in sorted(rows, key=lambda x: -x["lm"]):
    if r["lc"] or r["lm"]:
        print(
            f"  {r['ns']}/{r['name']}: req {r['rc']}m/{r['rm']:.0f}Mi"
            f" lim {r['lc']}m/{r['lm']:.0f}Mi [{r['ready']}]"
        )
