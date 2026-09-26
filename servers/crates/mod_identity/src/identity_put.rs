use anyhow::{anyhow, Result};
use async_nats::Client;
use c35_mod_log::{log_put, LogPut};
use c35_proto::{ReqIdentityPut, ResIdentityPut};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::identity_list::identity_list_row_get;

fn alien_id_normalize(raw: &str) -> String {
    raw.trim().trim_start_matches('@').to_lowercase()
}

fn alien_id_valid(alien_id: &str) -> bool {
    !alien_id.is_empty()
        && alien_id
            .chars()
            .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-')
}

async fn alien_id_taken(pool: &PgPool, alien_id: &str, exclude: i64) -> Result<bool> {
    sqlx::query_scalar(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM ai.identity
            WHERE LOWER(alien_id) = LOWER($1) AND id != $2 AND deleted_ts IS NULL
        )
        "#,
    )
    .bind(alien_id)
    .bind(exclude)
    .fetch_one(pool)
    .await
    .map_err(Into::into)
}

fn validate_kind_type(kind: &str, typ: &str) -> Result<()> {
    if kind == "bot" && typ != "chat" {
        return Err(anyhow!("bot kind requires type=chat"));
    }
    Ok(())
}

fn meta_parse(raw: &str) -> Result<Value> {
    if raw.trim().is_empty() {
        return Ok(json!({ "inst_base": "", "channels": [] }));
    }
    serde_json::from_str(raw).map_err(|e| anyhow!("invalid meta_json: {e}"))
}

fn meta_merge(existing: &Value, incoming: &Value) -> Value {
    let mut out = if existing.is_object() {
        existing.clone()
    } else {
        json!({})
    };
    if out.get("channels").is_none() {
        out["channels"] = json!([]);
    }
    if out.get("inst_base").is_none() {
        out["inst_base"] = json!("");
    }
    if out.get("strict_mode").is_none() {
        out["strict_mode"] = json!(true);
    }
    if out.get("web_search").is_none() {
        out["web_search"] = json!(false);
    }
    if let Some(in_obj) = incoming.as_object() {
        for (k, v) in in_obj {
            if k == "channels" && v.as_array().is_some_and(|a| a.is_empty()) {
                continue;
            }
            if let Some(out_obj) = out.as_object_mut() {
                out_obj.insert(k.clone(), v.clone());
            }
        }
    }
    out
}

async fn identity_mutate_allowed(pool: &PgPool, caller_iid: i64, resource_iid: i64) -> Result<i64> {
    let row = sqlx::query(
        r#"
        SELECT i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL
        "#,
    )
    .bind(resource_iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("identity not found"))?;
    let owner_iid: i64 = row.get("owner_iid");
    let role: Option<String> = row.try_get("role").ok().flatten();
    let allowed = owner_iid == caller_iid || role.as_deref() == Some("admin");
    if !allowed {
        return Err(anyhow!("forbidden"));
    }
    Ok(owner_iid)
}

async fn log_bot_event(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    req_id: &str,
    topic: &str,
    text: &str,
    bot_iid: i64,
    name: &str,
) {
    let _ = log_put(
        pool,
        nats,
        LogPut {
            class: None,            owner_iid,
            kind: "system",
            topic,
            dv: "c35-server",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text,
            model: "",
            tokens_in: 0,
            tokens_out: 0,
            duration_ms: 0,
            cost_usd: 0.0,
            meta: json!({ "bot_iid": bot_iid, "name": name }),
        },
    )
    .await;
}

pub async fn identity_put(
    pool: &PgPool,
    nats: Option<&Client>,
    caller_iid: i64,
    req_id: &str,
    req: ReqIdentityPut,
) -> Result<ResIdentityPut> {
    let kind = req.kind.trim();
    let typ = req.r#type.trim();
    validate_kind_type(kind, typ)?;

    let name = req.name.trim();
    if name.is_empty() {
        return Err(anyhow!("name required"));
    }

    let alien_id = alien_id_normalize(&req.alien_id);
    if !alien_id.is_empty() && !alien_id_valid(&alien_id) {
        return Err(anyhow!("invalid alien_id"));
    }

    let incoming_meta = meta_parse(&req.meta_json)?;
    let pic = req.pic.trim();

    if req.iid == 0 {
        if kind.is_empty() {
            return Err(anyhow!("kind required"));
        }
        if typ.is_empty() {
            return Err(anyhow!("type required"));
        }
        if !alien_id.is_empty() && alien_id_taken(pool, &alien_id, 0).await? {
            return Err(anyhow!("alien_id taken"));
        }
        let id = snowflake_id();
        let meta = meta_merge(&json!({ "inst_base": "", "channels": [] }), &incoming_meta);
        sqlx::query(
            r#"
            INSERT INTO ai.identity (id, kind, type, alien_id, name, pic, owner_iid, meta, created_ts, updated_ts)
            VALUES ($1, $2, $3, NULLIF($4, ''), $5, NULLIF($6, ''), $7, $8, NOW(), NOW())
            "#,
        )
        .bind(id)
        .bind(kind)
        .bind(typ)
        .bind(&alien_id)
        .bind(name)
        .bind(pic)
        .bind(caller_iid)
        .bind(&meta)
        .execute(pool)
        .await?;
        log_bot_event(
            pool,
            nats,
            caller_iid,
            req_id,
            "bot_create",
            &format!("Bot created: {name}"),
            id,
            name,
        )
        .await;
        if kind == "site" {
            let _ = c35_mod_hint::hint_invalidate_for_asset(pool, id).await;
        }
        let row = identity_list_row_get(pool, caller_iid, id).await?;
        return Ok(ResIdentityPut { row: Some(row) });
    }

    let iid = req.iid;
    let owner_iid = identity_mutate_allowed(pool, caller_iid, iid).await?;
    if !alien_id.is_empty() && alien_id_taken(pool, &alien_id, iid).await? {
        return Err(anyhow!("alien_id taken"));
    }
    let existing_meta: Value = sqlx::query_scalar("SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(iid)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| anyhow!("identity not found"))?;
    let meta = meta_merge(&existing_meta, &incoming_meta);
    sqlx::query(
        r#"
        UPDATE ai.identity SET
            name = $2,
            pic = NULLIF($3, ''),
            alien_id = CASE WHEN $4 = '' THEN alien_id ELSE NULLIF($4, '') END,
            meta = $5,
            updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(iid)
    .bind(name)
    .bind(pic)
    .bind(&alien_id)
    .bind(&meta)
    .execute(pool)
    .await?;
    log_bot_event(
        pool,
        nats,
        owner_iid,
        req_id,
        "bot_update",
        &format!("Bot updated: {name}"),
        iid,
        name,
    )
    .await;
    let kind: String = sqlx::query_scalar("SELECT kind FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(iid)
        .fetch_one(pool)
        .await?;
    if kind == "site" {
        let _ = c35_mod_hint::hint_invalidate_for_asset(pool, iid).await;
    }
    let row = identity_list_row_get(pool, caller_iid, iid).await?;
    Ok(ResIdentityPut { row: Some(row) })
}
