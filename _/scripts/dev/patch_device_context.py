from pathlib import Path
p = Path(r"D:/c35/servers/crates/mod_chat/src/device_context.rs")
t = p.read_text(encoding="utf-8")
old = "AND (c.meta->>'bound_device_iid')::bigint = $2"
new = "AND c.bound_device_iid = $2"
t = t.replace(old, new)
old_ins = """        INSERT INTO ai.chat (id, kind, owner_iid, title, model, meta, created_ts, updated_ts)
        VALUES ($1, 'prompt', $2, $3, 'cloud', $4, NOW(), NOW())"""
new_ins = """        INSERT INTO ai.chat (id, kind, owner_iid, title, model, meta, bound_device_iid, created_ts, updated_ts)
        VALUES ($1, 'prompt', $2, $3, 'cloud', $4, $5, NOW(), NOW())"""
if old_ins not in t:
    raise SystemExit("insert block not found")
t = t.replace(old_ins, new_ins)
t = t.replace(".bind(meta)\n    .execute(&mut *tx)", ".bind(meta)\n    .bind(device_iid)\n    .execute(&mut *tx)", 1)
old_prep = """    let row = sqlx::query_as::<_, (i64, Value)>(
        \"SELECT owner_iid, meta FROM ai.chat WHERE id = $1 AND kind = 'prompt' AND deleted_ts IS NULL\",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let Some((chat_owner, meta)) = row else {
        bail!(\"chat not found\");
    };
    if chat_owner != owner_iid {
        bail!(\"chat not found\");
    }
    let bound = chat_bound_device_iid(&meta);"""
new_prep = """    let row = sqlx::query_as::<_, (i64, i64, Value)>(
        \"SELECT owner_iid, bound_device_iid, meta FROM ai.chat WHERE id = $1 AND kind = 'prompt' AND deleted_ts IS NULL\",
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let Some((chat_owner, bound_col, meta)) = row else {
        bail!(\"chat not found\");
    };
    if chat_owner != owner_iid {
        bail!(\"chat not found\");
    }
    let bound = if bound_col > 0 { bound_col } else { chat_bound_device_iid(&meta) };"""
if old_prep not in t:
    raise SystemExit("prep block not found")
t = t.replace(old_prep, new_prep)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok", t.count("c.bound_device_iid"))
