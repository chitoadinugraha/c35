use anyhow::{anyhow, Result};
use c35_mod_identity::identity_put;
use c35_proto::ReqIdentityPut;
use serde_json::{json, Value};
use sqlx::Row;

use crate::bot_draft::flag_true;
use crate::bot_meta::bot_active_parse;
use crate::tool;
use crate::tools::ToolContext;

fn arg_str(args: &Value, key: &str) -> String {
    args.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn arg_i64(args: &Value, key: &str) -> i64 {
    args.get(key)
        .map(|v| {
            v.as_i64()
                .or_else(|| v.as_f64().map(|n| n as i64))
                .or_else(|| v.as_str().and_then(|s| s.parse().ok()))
        })
        .flatten()
        .unwrap_or(0)
}

/// Present in JSON (including explicit false) vs omitted.
pub(crate) fn optional_bool_arg(args: &Value, key: &str) -> Option<bool> {
    let v = args.get(key)?;
    if v.is_null() {
        return None;
    }
    if let Some(b) = v.as_bool() {
        return Some(b);
    }
    let s = v.as_str().unwrap_or("");
    if s.trim().is_empty() {
        return None;
    }
    let lower = s.trim().to_ascii_lowercase();
    if matches!(lower.as_str(), "0" | "false" | "no" | "off" | "mati") {
        return Some(false);
    }
    Some(flag_true(s))
}

async fn bot_row_full(ctx: &ToolContext, bot_iid: i64) -> Result<(String, String, Value)> {
    let row = sqlx::query(
        r#"
        SELECT name, COALESCE(pic, '') AS pic, meta
        FROM ai.identity
        WHERE id = $1 AND owner_iid = $2 AND kind = 'bot' AND deleted_ts IS NULL
        "#,
    )
    .bind(bot_iid)
    .bind(ctx.owner_iid)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("bot not found"))?;
    let meta: Value = row.try_get("meta").unwrap_or(json!({}));
    Ok((
        row.try_get::<String, _>("name").unwrap_or_default(),
        row.try_get::<String, _>("pic").unwrap_or_default(),
        meta,
    ))
}

pub async fn bot_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let bot_iid = arg_i64(args, "bot_iid");
    if bot_iid <= 0 {
        return Ok(json!({
            "ok": false,
            "tool": "bot.put",
            "error": "bot_iid required",
        }));
    }

    let (existing_name, pic, existing_meta) = bot_row_full(ctx, bot_iid).await?;

    let name = arg_str(args, "name");
    let put_name = if name.is_empty() {
        existing_name.clone()
    } else {
        name.clone()
    };
    if put_name.is_empty() {
        return Ok(json!({
            "ok": false,
            "tool": "bot.put",
            "error": "name required",
        }));
    }

    let mut patch = json!({});
    let mut touched = false;

    if let Some(active) = optional_bool_arg(args, "active") {
        patch["active"] = json!(active);
        touched = true;
    }
    let inst_base = arg_str(args, "inst_base");
    if !inst_base.is_empty() {
        patch["inst_base"] = json!(inst_base);
        touched = true;
    }
    if let Some(web_search) = optional_bool_arg(args, "web_search") {
        patch["web_search"] = json!(web_search);
        touched = true;
    }
    if let Some(strict_mode) = optional_bool_arg(args, "strict_mode") {
        patch["strict_mode"] = json!(strict_mode);
        touched = true;
    }
    if !name.is_empty() {
        touched = true;
    }

    if !touched {
        return Ok(json!({
            "ok": false,
            "tool": "bot.put",
            "error": "nothing to update — pass active, name, inst_base, web_search, or strict_mode",
        }));
    }

    identity_put(
        &ctx.pool,
        ctx.nats.as_ref(),
        ctx.owner_iid,
        &ctx.req_id,
        ReqIdentityPut {
            iid: bot_iid,
            kind: "bot".into(),
            r#type: "chat".into(),
            name: put_name.clone(),
            pic,
            alien_id: String::new(),
            meta_json: patch.to_string(),
        },
    )
    .await?;

    let merged = {
        let mut m = existing_meta.clone();
        if let Some(obj) = patch.as_object() {
            for (k, v) in obj {
                m[k] = v.clone();
            }
        }
        m
    };
    let active = bot_active_parse(Some(&merged));
    let summary = if ctx.locale.trim().to_ascii_lowercase().starts_with("id") {
        if active {
            format!("Bot {put_name} diperbarui, sudah aktif.")
        } else {
            format!("Bot {put_name} diperbarui, masih mati.")
        }
    } else if active {
        format!("Bot {put_name} updated, on.")
    } else {
        format!("Bot {put_name} updated, off.")
    };

    Ok(json!({
        "ok": true,
        "tool": "bot.put",
        "bot_iid": bot_iid,
        "name": put_name,
        "active": active,
        "summary": summary,
    }))
}

tool! {
    struct: BotPutTool,
    name: "bot.put",
    aliases: ["bot_put", "bot.update"],
    description: "Update an existing chat bot: turn on or off (active), rename, replace instruction (inst_base), or toggle web_search and strict_mode. Resolve bot_iid from bot.list or an earlier bot.draft turn. Does not attach sheets or connect channels — use bot.draft for that.",
    topics: ["general", "bot"],
    rag_phrases: [
        "aktifkan bot",
        "matikan bot",
        "hidupkan bot",
        "turn bot on",
        "turn bot off",
        "disable bot",
        "enable bot",
        "rename bot",
        "ganti nama bot",
        "ubah instruksi bot",
    ],
    ui_calling_key: "tool.bot.put.calling",
    ui_done_key: "tool.bot.put.done",
    parameters: {
        bot_iid: (integer, "Bot identity id from bot.list or bot.draft", required),
        active: (boolean, "true to run channel AI; false to turn off", optional),
        name: (string, "New display name", optional, default = ""),
        inst_base: (string, "Replacement bot instruction", optional, default = ""),
        web_search: (boolean, "Allow web search for this bot", optional),
        strict_mode: (boolean, "Strict business-boundary mode", optional),
    },
    execute: |args, ctx| {
        bot_put_exec(ctx, &args).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn optional_bool_parses_strings() {
        assert_eq!(optional_bool_arg(&json!({"active": "true"}), "active"), Some(true));
        assert_eq!(optional_bool_arg(&json!({"active": "mati"}), "active"), Some(false));
        assert_eq!(optional_bool_arg(&json!({}), "active"), None);
    }
}
