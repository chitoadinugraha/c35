from pathlib import Path
p = Path("D:/c35/remotes/browser_engine/browser.ts")
t = p.read_text(encoding="utf-8")
if "async reload()" not in t:
    anchor = "  public async pageObserve("
    insert = "  public async reload(): Promise<void> {\n    const page = this.activePage();\n    if (!page) throw new Error('no active tab');\n    await page.reload({ waitUntil: 'domcontentloaded', timeout: 60_000 });\n  }\n\n"
    t = t.replace(anchor, insert + anchor)
    p.write_text(t, encoding="utf-8", newline="\n")
w = Path("D:/c35/remotes/browser_engine/worker.ts")
wt = w.read_text(encoding="utf-8")
if "case 'reload'" not in wt:
    wt = wt.replace("case 'history.back':", "case 'reload': { await engine.reload(); writeMessage(resOk(id)); return; }\n      case 'history.back':")
    w.write_text(wt, encoding="utf-8", newline="\n")
b = Path("D:/c35/remotes/c_remote_browser/src/browser_command.rs")
bt = b.read_text(encoding="utf-8")
if '"reload"' not in bt:
    bt = bt.replace('"history.back" => {', '"reload" => {\n            bridge.call("reload", json!({})).await?;\n            Ok(json!({ "ok": true }))\n        }\n        "history.back" => {')
    b.write_text(bt, encoding="utf-8", newline="\n")
print("ok")