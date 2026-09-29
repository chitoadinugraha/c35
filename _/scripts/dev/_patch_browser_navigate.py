from pathlib import Path
p = Path(r"D:/c35/remotes/c_remote_browser/src/browser_command.rs")
t = p.read_text(encoding="utf-8")
needle = '        "tabs" => crate::browser_tabs::tab_command(&bridge, &params).await,'
insert = '''        "tabs" => crate::browser_tabs::tab_command(&bridge, &params).await,
        "navigate" => {
            let url = params
                .get("url")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!("url required"))?;
            bridge.call("navigate", serde_json::json!({ "url": url })).await?;
            Ok(serde_json::json!({ "ok": true }))
        },'''
if '"navigate"' not in t:
    if needle not in t:
        raise SystemExit('tabs arm not found')
    t = t.replace(needle, insert, 1)
    p.write_text(t, encoding='utf-8', newline='\n')
    print('navigate added')
else:
    print('navigate already present')