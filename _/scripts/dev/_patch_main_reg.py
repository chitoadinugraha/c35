from pathlib import Path
p = Path(r"D:/c35/remotes/c_remote_browser/src/main.rs")
t = p.read_text(encoding="utf-8")
if "mod agent_version;" not in t:
    t = t.replace("mod browser_command;", "mod agent_version;\nmod browser_command;")
if "agent_version::register();" not in t:
    t = t.replace("    log_local::init();\n", "    log_local::init();\n    agent_version::register();\n")
p.write_text(t, encoding="utf-8", newline="\n")
print("main ok")