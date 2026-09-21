#!/usr/bin/env python3
"""Adapt cs_bots manager/outbound for c35 channel_whatsapp_device."""
from pathlib import Path

ROOT = Path(__file__).parent / "src"

def adapt_manager(text: str) -> str:
    text = text.replace("owner_uid", "owner_iid")
    text = text.replace("[wa-channel]", "[wa-device]")
    text = text.replace(
        "struct ChannelRuntime {\n    channel_id: i64,\n    owner_iid: i64,",
        "struct ChannelRuntime {\n    bot_iid: i64,\n    channel_id: String,\n    owner_iid: i64,",
    )
    text = text.replace("DashMap<i64, ChannelRuntime>", "DashMap<String, ChannelRuntime>")
    text = text.replace("DashMap<i64, Arc<Client>>", "DashMap<String, Arc<Client>>")
    text = text.replace(
        "pub fn client_for(&self, channel_id: i64) -> Option<Arc<Client>> {\n        self.clients.get(&channel_id)",
        "pub fn client_for(&self, channel_id: &str) -> Option<Arc<Client>> {\n        self.clients.get(channel_id)",
    )
    text = text.replace("pub fn stop_channel(&self, channel_id: i64)", "pub fn stop_channel(&self, bot_iid: i64, channel_id: String)")
    text = text.replace("fn stop_runtime(&self, channel_id: i64)", "fn stop_runtime(&self, bot_iid: i64, channel_id: &str)")
    text = text.replace(
        "fn stop_channel_inner(&self, channel_id: i64, wipe_session: bool)",
        "fn stop_channel_inner(&self, bot_iid: i64, channel_id: &str, wipe_session: bool)",
    )
    text = text.replace("pub fn restart_channel(&self, channel_id: i64)", "pub fn restart_channel(&self, bot_iid: i64, channel_id: String)")
    text = text.replace("pub async fn start_channel(&self, channel_id: i64)", "pub async fn start_channel(&self, bot_iid: i64, channel_id: String)")
    text = text.replace("fn session_path(&self, channel_id: i64)", "fn session_path(&self, bot_iid: i64, channel_id: &str)")
    text = text.replace(
        'PathBuf::from(&self.sessions_dir).join(format!("whatsapp_channel_{channel_id}.db"))',
        'PathBuf::from(&self.sessions_dir).join(format!("wa_{bot_iid}_{channel_id}.db"))',
    )
    text = text.replace(
        """async fn wa_channel_log(
    pool: &PgPool,
    owner_iid: i64,
    channel_id: i64,""",
        """async fn wa_channel_log(
    pool: &PgPool,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,""",
    )
    text = text.replace(
        "let _ = db::channel_log(pool, owner_iid, channel_id, kind, text, meta).await;",
        "let _ = db::channel_log(pool, owner_iid, bot_iid, channel_id, kind, text, meta).await;",
    )
    text = text.replace("async fn wipe_channel_session(pool: &PgPool, channel_id: i64,", "async fn wipe_channel_session(pool: &PgPool, bot_iid: i64, channel_id: &str,")
    text = text.replace("db::channel_session_blob_clear(pool, channel_id)", "db::channel_session_blob_clear(pool, bot_iid, channel_id)")
    text = text.replace("async fn open_sqlite_store(pool: &PgPool, channel_id: i64,", "async fn open_sqlite_store(pool: &PgPool, bot_iid: i64, channel_id: &str,")
    text = text.replace("wipe_channel_session(pool, channel_id, session_path)", "wipe_channel_session(pool, bot_iid, channel_id, session_path)")
    text = text.replace("async fn persist_session_file(pool: &PgPool, channel_id: i64,", "async fn persist_session_file(pool: &PgPool, bot_iid: i64, channel_id: &str,")
    text = text.replace("db::channel_session_blob_put(pool, channel_id,", "db::channel_session_blob_put(pool, bot_iid, channel_id,")
    text = text.replace("db::channel_get(&self.pool, channel_id)", "db::channel_get(&self.pool, bot_iid, &channel_id)")
    text = text.replace("db::channel_get(&pool, channel_id)", "db::channel_get(&pool, bot_iid, &channel_id)")
    text = text.replace("db::channel_update_status(&pool, channel_id,", "db::channel_update_status(&pool, bot_iid, channel_id,")
    text = text.replace("db::channel_patch_session(\n            &pool,\n            channel_id,", "db::channel_patch_session(\n            &pool,\n            bot_iid,\n            channel_id,")
    text = text.replace("db::channel_patch_session(&pool, channel_id,", "db::channel_patch_session(&pool, bot_iid, channel_id,")
    text = text.replace("db::channel_pair_watch_active(&pool, channel_id)", "db::channel_pair_watch_active(&pool, bot_iid, channel_id)")
    text = text.replace("db::channel_session_blob_get(&self.pool, channel_id)", "db::channel_session_blob_get(&self.pool, bot_iid, &channel_id)")
    text = text.replace("db::channel_session_blob_get(&pool, channel_id)", "db::channel_session_blob_get(&pool, bot_iid, channel_id)")
    text = text.replace("db::channel_abort_pairing(&self.pool, ch.id)", "db::channel_abort_pairing(&self.pool, ch.bot_iid, &ch.channel_id)")
    text = text.replace("self.stop_channel_inner(channel_id, true)", "self.stop_channel_inner(bot_iid, &channel_id, true)")
    text = text.replace("self.stop_channel_inner(channel_id, false)", "self.stop_channel_inner(bot_iid, channel_id, false)")
    text = text.replace("self.stop_channel(channel_id)", "self.stop_channel(bot_iid, channel_id.to_string())")
    text = text.replace("self.stop_runtime(ch.id)", "self.stop_runtime(ch.bot_iid, &ch.channel_id)")
    text = text.replace("self.stop_runtime(other_id)", "self.stop_runtime(row.bot_iid, &other_id)")
    text = text.replace("self.restart_channel(act.channel_id)", "self.restart_channel(act.bot_iid, act.channel_id.clone())")
    text = text.replace("if self.runtimes.contains_key(&ch.id)", "if self.runtimes.contains_key(&ch.channel_id)")
    text = text.replace("info!(\"[wa-device] poll starting channel_id={} status={}\", ch.id, ch.status)", "info!(\"[wa-device] poll starting channel_id={} status={}\", ch.channel_id, ch.status)")
    text = text.replace("self.start_channel(ch.id)", "self.start_channel(ch.bot_iid, ch.channel_id.clone())")
    text = text.replace("error!(\"[wa-device] poll start failed channel_id={}: {e:#}\", ch.id)", "error!(\"[wa-device] poll start failed channel_id={}: {e:#}\", ch.channel_id)")
    text = text.replace("if self.runtimes.contains_key(&ch.id)", "if self.runtimes.contains_key(&ch.channel_id)")
    text = text.replace("self.stop_runtime(ch.id)", "self.stop_runtime(ch.bot_iid, &ch.channel_id)")
    text = text.replace("ch.id,", "ch.channel_id,")
    text = text.replace("row.id,", "row.channel_id,")
    text = text.replace("let row = db::channel_get(&self.pool, bot_iid, &channel_id)\n            .await?\n            .with_context(|| format!(\"channel {channel_id} not found\"))?", "let row = db::channel_get(&self.pool, bot_iid, &channel_id)\n            .await?\n            .with_context(|| format!(\"channel {channel_id} not found\"))?")
    text = text.replace("e.channel_id != channel_id", "e.channel_id != channel_id")
    text = text.replace("e.owner_iid == row.owner_iid && e.channel_id != channel_id", "e.owner_iid == row.owner_iid && e.channel_id != channel_id")
    text = text.replace(".map(|e| e.channel_id)", ".map(|e| e.channel_id.clone())")
    text = text.replace("for other_id in superseded", "for other_cid in superseded")
    text = text.replace("self.stop_runtime(other_id)", "self.stop_runtime(row.bot_iid, &other_cid)")
    text = text.replace("keep={channel_id})", "keep={channel_id})")
    text = text.replace("let session_path = self.session_path(channel_id)", "let session_path = self.session_path(bot_iid, &channel_id)")
    text = text.replace("channel_id,\n            owner_iid,", "bot_iid,\n            channel_id: channel_id.clone(),\n            owner_iid,")
    text = text.replace("self.runtimes.insert(channel_id, rt)", "self.runtimes.insert(channel_id.clone(), rt)")
    text = text.replace("async fn run_channel_bot(\n    pool: PgPool,\n    nats: Option<NatsService>,\n    channel_id: i64,\n    owner_iid: i64,", "async fn run_channel_bot(\n    pool: PgPool,\n    nats: Option<NatsService>,\n    bot_iid: i64,\n    channel_id: String,\n    owner_iid: i64,")
    text = text.replace("let webhook_secret = db::channel_webhook_secret(&pool, channel_id)\n        .await\n        .unwrap_or_default();", "let webhook_secret = String::new();")
    text = text.replace("let backend = open_sqlite_store(&pool_ev, channel_id, &session_path)", "let backend = open_sqlite_store(&pool_ev, bot_iid, &channel_id, &session_path)")
    text = text.replace("clients.entry(channel_id)", "clients.entry(channel_id.clone())")
    text = text.replace(
        """async fn publish_pair_update(
    nats: &Option<NatsService>,
    owner_iid: i64,
    channel_id: i64,""",
        """async fn publish_pair_update(
    nats: &Option<NatsService>,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,""",
    )
    text = text.replace(
        """        let ev = EvChannelPairUpdate {
            channel_id,
            owner_iid,""",
        """        let ev = EvChannelPairUpdate {
            bot_iid,
            channel_id: channel_id.to_string(),
            owner_iid,""",
    )
    text = text.replace("publish_pair_update(&nats, owner_iid, channel_id,", "publish_pair_update(&nats, owner_iid, bot_iid, &channel_id,")
    text = text.replace("wa_channel_log(\n                            &pool,\n                            owner_iid,\n                            channel_id,", "wa_channel_log(\n                            &pool,\n                            owner_iid,\n                            bot_iid,\n                            &channel_id,")
    text = text.replace("wa_channel_log(\n                    &pool,\n                    row.owner_iid,\n                    channel_id,", "wa_channel_log(\n                    &pool,\n                    row.owner_iid,\n                    bot_iid,\n                    &channel_id,")
    text = text.replace("wa_channel_log(\n                &pool,\n                ch.owner_iid,\n                ch.channel_id,", "wa_channel_log(\n                &pool,\n                ch.owner_iid,\n                ch.bot_iid,\n                &ch.channel_id,")
    text = text.replace("persist_session_file(&pool_p, channel_id, &path_p)", "persist_session_file(&pool_p, bot_iid, &channel_id, &path_p)")
    text = text.replace("persist_session_file(&pool, channel_id, &session_path)", "persist_session_file(&pool, bot_iid, &channel_id, &session_path)")
    text = text.replace("wipe_channel_session(&pool, channel_id, &session_path)", "wipe_channel_session(&pool, bot_iid, &channel_id, &session_path)")
    text = text.replace("mgr.restart_channel(channel_id)", "mgr.restart_channel(bot_iid, channel_id.clone())")
    text = text.replace("runtimes.remove(&channel_id)", "runtimes.remove(&channel_id)")
    text = text.replace("clients_cleanup.remove(&channel_id)", "clients_cleanup.remove(&channel_id)")
    text = text.replace("if let Err(e) = mgr.start_channel(channel_id).await", "if let Err(e) = mgr.start_channel(bot_iid, channel_id.clone()).await")
    text = text.replace("self.stop_channel_inner(channel_id, true)", "self.stop_channel_inner(bot_iid, &channel_id, true)")
    text = text.replace("self.restart_channel(act.channel_id)", "self.restart_channel(act.bot_iid, act.channel_id)")
    # EvChannelMsgIn publish
    text = text.replace("channel_id,\n                        channel_type:", "bot_iid,\n                        channel_id: channel_id.clone(),\n                        channel_type:")
    text = text.replace("nats.publish_msg_in(owner_iid, channel_id, &ev)", "nats.publish_msg_in(&ev)")
    return text

def adapt_outbound(text: str) -> str:
    text = text.replace("owner_uid", "owner_iid")
    text = text.replace("[wa-channel]", "[wa-device]")
    text = text.replace(
        "async fn wa_outbound_log(pool: &sqlx::PgPool, channel_id: i64, kind: &str, text: &str, meta: serde_json::Value) {\n    let Ok(Some(row)) = db::channel_get(pool, channel_id).await else { return };\n    let _ = db::channel_log(pool, row.owner_iid, channel_id, kind, text, meta).await;\n}",
        "async fn wa_outbound_log(pool: &sqlx::PgPool, bot_iid: i64, channel_id: &str, kind: &str, text: &str, meta: serde_json::Value) {\n    let Ok(Some(row)) = db::channel_get(pool, bot_iid, channel_id).await else { return };\n    let _ = db::channel_log(pool, row.owner_iid, bot_iid, channel_id, kind, text, meta).await;\n}",
    )
    text = text.replace("mgr.client_for(act.channel_id)", "mgr.client_for(&act.channel_id)")
    text = text.replace("wa_outbound_log(\n                        &pool,\n                        act.channel_id,", "wa_outbound_log(\n                        &pool,\n                        act.bot_iid,\n                        &act.channel_id,")
    text = text.replace("mgr.client_for(act.channel_id) else { continue; }", "mgr.client_for(&act.channel_id) else { continue; }")
    return text

if __name__ == "__main__":
    mgr = adapt_manager((ROOT / "manager.rs").read_text(encoding="utf-8"))
    (ROOT / "manager.rs").write_text(mgr, encoding="utf-8")
    out = adapt_outbound((ROOT / "outbound.rs").read_text(encoding="utf-8"))
    (ROOT / "outbound.rs").write_text(out, encoding="utf-8")
    print("adapted")
