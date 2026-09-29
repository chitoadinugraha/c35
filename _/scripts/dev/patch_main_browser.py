import subprocess
import sys

c = subprocess.check_output(
    ["git", "show", "HEAD:remotes/c_remote_browser/src/main.rs"],
    cwd=r"D:\c35",
    text=True,
)
old = (
    "            continue;\n"
    "        }\n\n"
    "        {\n"
    '            let mut slot = state.engine.lock().map_err(|_| anyhow::anyhow!("lock"))?;\n'
    "            if slot.is_none() {\n"
    "                let headless = mode::headless_from_config();\n"
    '                match engine::process::spawn_engine(headless, "default").await {'
)
new = (
    "            continue;\n"
    "        }\n\n"
    "        info!(\n"
    "            device_iid = device_iid_load().unwrap_or(0),\n"
    '            "already paired; pair window skipped (run dev_browser with -Unpair to re-pair)"\n'
    "        );\n\n"
    "        {\n"
    '            let mut slot = state.engine.lock().map_err(|_| anyhow::anyhow!("lock"))?;\n'
    "            if slot.is_none() {\n"
    "                let headless = mode::headless_from_config();\n"
    "                info!(\n"
    "                    headless,\n"
    '                    "launching Playwright Chromium (headless=false shows a visible window)"\n'
    "                );\n"
    '                match engine::process::spawn_engine(headless, "default").await {'
)
if old not in c:
    sys.exit("anchor missing")
path = r"D:\c35\remotes\c_remote_browser\src\main.rs"
with open(path, "wb") as f:
    f.write(c.replace(old, new).encode("utf-8"))
print("patched")