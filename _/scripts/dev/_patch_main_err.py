from pathlib import Path
p = Path(r"D:/c35/remotes/c_remote_browser/src/main.rs")
t = p.read_text(encoding="utf-8")
old = '                    Err(e) => tracing::warn!("browser_engine not started: {e:#}"),'
new = '                    Err(e) => {\n                        eprintln!("browser_engine not started: {e:#}");\n                        tracing::warn!("browser_engine not started: {e:#}");\n                    }'
if old not in t: raise SystemExit('missing')
p.write_text(t.replace(old,new), encoding='utf-8', newline='\n')
print('ok')