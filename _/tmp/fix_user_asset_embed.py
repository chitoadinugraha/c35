from pathlib import Path
p = Path(r"D:/c35/servers/crates/mod_chat/src/user_asset_rag.rs")
t = p.read_text(encoding="utf-8")
needle = 'let alien_id: String = r.get("alien_id");\n            Some(AssetCandidate {'
repl = 'let alien_id: String = r.get("alien_id");\n            let embed_text = asset_embed_text(&kind, &name, &alien_id, iid);\n            Some(AssetCandidate {'
if "let embed_text = asset_embed_text" not in t:
    if needle not in t:
        raise SystemExit("needle not found")
    p.write_text(t.replace(needle, repl, 1), encoding="utf-8", newline="\n")
    print("fixed")
else:
    print("already fixed")