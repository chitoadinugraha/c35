from pathlib import Path
p = Path(r"D:/c35/remotes/c_remote_browser/src/engine/process.rs")
t = p.read_text(encoding="utf-8")
needle = "        .await?;\n\n    let _ = bridge.call(\"screencast.start\""
insert = "        .await?;\n\n    if !headless {\n        eprintln!(\n            \"Playwright Chromium started (headed). Look for the taskbar window titled Alien AI Remote Browser.\"\n        );\n    }\n\n    let _ = bridge.call(\"screencast.start\""
if needle not in t:
    raise SystemExit("needle missing")
p.write_text(t.replace(needle, insert), encoding="utf-8", newline="\n")
print("ok")