from pathlib import Path
p = Path(r"D:/c35/remotes/c_remote_browser/src/browser_command.rs")
t = p.read_text(encoding="utf-8")
needle = '        "tabs" => crate::browser_tabs::tab_command(&bridge, &params).await,'
insert = needle + """
        \"navigate\" => {
            let url = params
                .get(\"url\")
                .and_then(|v| v.as_str())
                .ok_or_else(|| anyhow::anyhow!(\"url required\"))?;
            bridge.call(\"navigate\", json!({ \"url\": url })).await?;
            Ok(json!({ \"ok\": true }))
        }
        \"history.back\" => {
            bridge.call(\"history.back\", json!({})).await?;
            Ok(json!({ \"ok\": true }))
        }
        \"history.forward\" => {
            bridge.call(\"history.forward\", json!({})).await?;
            Ok(json!({ \"ok\": true }))
        }"""
if '"navigate"' not in t and needle in t:
    t = t.replace(needle, insert)
    p.write_text(t, encoding="utf-8", newline="\n")
    print("patched")
else:
    print("skip", '"navigate"' in t)