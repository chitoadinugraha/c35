#!/usr/bin/env python3
"""Post-adapt fixes for manager.rs."""
from pathlib import Path
import re

p = Path(__file__).parent / "src" / "manager.rs"
text = p.read_text(encoding="utf-8")

text = text.replace('ch.id', 'ch.channel_id')
text = text.replace('{other_id}', '{other_cid}')
text = text.replace('&other_id', '&other_cid')
text = text.replace('"active"', '"connected"')
text = text.replace('skip_if_active && status == "connected"', 'skip_if_active && status == "connected"')

# DashMap remove: channel_id is &str in stop_channel_inner
text = text.replace(
    "fn stop_channel_inner(&self, bot_iid: i64, channel_id: &str, wipe_session: bool) {\n"
    "        if let Some((_, rt)) = self.runtimes.remove(&channel_id) {",
    "fn stop_channel_inner(&self, bot_iid: i64, channel_id: &str, wipe_session: bool) {\n"
    "        if let Some((_, rt)) = self.runtimes.remove(channel_id) {",
)
text = text.replace(
    "        self.clients.remove(&channel_id);\n        let pool = self.pool.clone();",
    "        self.clients.remove(channel_id);\n        let pool = self.pool.clone();",
)

# cleanup_expired_pairing log
text = text.replace(
    """            wa_channel_log(
                &self.pool,
                ch.owner_iid,
                ch.channel_id,
                "pair_expired",""",
    """            wa_channel_log(
                &self.pool,
                ch.owner_iid,
                ch.bot_iid,
                &ch.channel_id,
                "pair_expired",""",
)

# start_channel initial log
text = text.replace(
    """        wa_channel_log(
            &self.pool,
            row.owner_iid,
            channel_id,
            "worker_start",""",
    """        wa_channel_log(
            &self.pool,
            row.owner_iid,
            bot_iid,
            &channel_id,
            "worker_start",""",
)

# ChannelRuntime missing bot_iid
text = text.replace(
    """        let rt = ChannelRuntime {
            channel_id,
            owner_iid: row.owner_iid,""",
    """        let rt = ChannelRuntime {
            bot_iid,
            channel_id: channel_id.clone(),
            owner_iid: row.owner_iid,""",
)

# run_channel_bot call
text = text.replace(
    """            let result = run_channel_bot(
                pool.clone(),
                nats,
                channel_id,
                owner_iid,""",
    """            let result = run_channel_bot(
                pool.clone(),
                nats,
                bot_iid,
                channel_id.clone(),
                owner_iid,""",
)

# spawn error handler wa_channel_log
text = text.replace(
    """                    wa_channel_log(
                        &pool,
                        owner_iid,
                        channel_id,
                        "error",""",
    """                    wa_channel_log(
                        &pool,
                        owner_iid,
                        bot_iid,
                        &channel_id,
                        "error",""",
)

# db calls: channel_id String -> &channel_id
text = re.sub(
    r"db::channel_update_status\(&pool, bot_iid, channel_id,",
    "db::channel_update_status(&pool, bot_iid, &channel_id,",
    text,
)
text = re.sub(
    r"db::channel_pair_watch_active\(&pool, bot_iid, channel_id\)",
    "db::channel_pair_watch_active(&pool, bot_iid, &channel_id)",
    text,
)

# channel_patch_session missing bot_iid (3-arg broken calls)
text = re.sub(
    r"db::channel_patch_session\(\s*&pool,\s*channel_id,",
    "db::channel_patch_session(\n                            &pool,\n                            bot_iid,\n                            &channel_id,",
    text,
)
text = re.sub(
    r"db::channel_patch_session\(\s*&pool,\s*bot_iid,\s*channel_id,",
    "db::channel_patch_session(\n            &pool,\n            bot_iid,\n            &channel_id,",
    text,
)

# shutdown wa_channel_log + persist
text = text.replace(
    """                wa_channel_log(
                    &pool,
                    owner_iid,
                    channel_id,
                    "worker_stop",
                    "WhatsApp worker shutting down",
                    serde_json::json!({}),
                )
                .await;
                let _ = persist_session_file(&pool, channel_id, &session_path_outer).await;""",
    """                wa_channel_log(
                    &pool,
                    owner_iid,
                    bot_iid,
                    &channel_id,
                    "worker_stop",
                    "WhatsApp worker shutting down",
                    serde_json::json!({}),
                )
                .await;
                let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path_outer).await;""",
)
text = text.replace(
    "let _ = persist_session_file(&pool, channel_id, &session_path_outer).await;",
    "let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path_outer).await;",
)

# EvChannelMsgIn
text = text.replace(
    """                            let ev = EvChannelMsgIn {
                                channel_id,
                                channel_type:""",
    """                            let ev = EvChannelMsgIn {
                                bot_iid,
                                channel_id: channel_id.clone(),
                                channel_type:""",
)

# extract_message_payload + peer_avatar_hash
text = text.replace(
    "extract_message_payload(&http, &client, channel_id, &webhook_secret, &msg)",
    "extract_message_payload(&http, &client, bot_iid, &channel_id, &webhook_secret, &msg)",
)
text = text.replace(
    "peer_avatar_hash(&http, &client, channel_id, &webhook_secret, &peer_id)",
    "peer_avatar_hash(&http, &client, bot_iid, &channel_id, &webhook_secret, &peer_id)",
)

p.write_text(text, encoding="utf-8")
print("fixed manager.rs")
