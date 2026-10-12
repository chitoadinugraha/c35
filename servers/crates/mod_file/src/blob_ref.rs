use serde_json::Value as JsonValue;
use sqlx::{PgPool, Row};

use crate::cas_hash_normalize;

#[derive(Debug, Clone, Copy)]
pub struct BlobRefScope {
    pub scope_kind: &'static str,
    pub scope_iid: i64,
    pub billable_owner_iid: i64,
}

pub async fn blob_ref_upsert(
    pool: &PgPool,
    scope: &BlobRefScope,
    hash: &str,
    source: &str,
    source_key: &str,
) -> Result<(), sqlx::Error> {
    let Some(hash) = cas_hash_normalize(hash) else {
        return Ok(());
    };
    if source_key.is_empty() {
        return Ok(());
    }
    sqlx::query(
        r#"
        INSERT INTO ai.blob_ref (
            billable_owner_iid, scope_kind, scope_iid, hash_blake3, source, source_key
        ) VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (scope_kind, scope_iid, source_key)
        DO UPDATE SET
            hash_blake3 = EXCLUDED.hash_blake3,
            billable_owner_iid = EXCLUDED.billable_owner_iid,
            source = EXCLUDED.source
        "#,
    )
    .bind(scope.billable_owner_iid)
    .bind(scope.scope_kind)
    .bind(scope.scope_iid)
    .bind(&hash)
    .bind(source)
    .bind(source_key)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn blob_ref_delete_source_key(
    pool: &PgPool,
    scope_kind: &str,
    scope_iid: i64,
    source_key: &str,
) -> Result<(), sqlx::Error> {
    if source_key.is_empty() {
        return Ok(());
    }
    sqlx::query(
        "DELETE FROM ai.blob_ref WHERE scope_kind = $1 AND scope_iid = $2 AND source_key = $3",
    )
    .bind(scope_kind)
    .bind(scope_iid)
    .bind(source_key)
    .execute(pool)
    .await?;
    Ok(())
}

fn push_hash(out: &mut Vec<String>, raw: &str) {
    if let Some(h) = cas_hash_normalize(raw) {
        if !out.contains(&h) {
            out.push(h);
        }
    }
}

fn hex_run_at(s: &str, start: usize) -> Option<(usize, usize)> {
    if start + 64 > s.len() {
        return None;
    }
    let slice = &s[start..start + 64];
    if !slice.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    let before_ok = start == 0
        || !s[start - 1..start]
            .chars()
            .next()
            .is_some_and(|c| c.is_ascii_hexdigit());
    let after_ok = start + 64 >= s.len()
        || !s[start + 64..start + 65]
            .chars()
            .next()
            .is_some_and(|c| c.is_ascii_hexdigit());
    if before_ok && after_ok {
        Some((start, start + 64))
    } else {
        None
    }
}

pub fn cas_hashes_from_text(s: &str) -> Vec<String> {
    let mut out = Vec::new();
    let lower = s.to_ascii_lowercase();
    let mut i = 0;
    while i < lower.len() {
        if lower[i..].starts_with("/fs/") {
            let start = i + 4;
            if let Some((_, end)) = hex_run_at(&lower, start) {
                push_hash(&mut out, &lower[start..end]);
                i = end;
                continue;
            }
        }
        if let Some((start, end)) = hex_run_at(&lower, i) {
            push_hash(&mut out, &lower[start..end]);
            i = end;
            continue;
        }
        i += 1;
    }
    out
}

pub fn cas_hashes_from_json_value(v: &JsonValue) -> Vec<String> {
    let mut out = Vec::new();
    cas_hashes_from_json_walk(v, &mut out);
    out
}

fn cas_hashes_from_json_walk(v: &JsonValue, out: &mut Vec<String>) {
    match v {
        JsonValue::String(s) => {
            if let Some(h) = cas_hash_normalize(s) {
                push_hash(out, &h);
            } else {
                for h in cas_hashes_from_text(s) {
                    push_hash(out, &h);
                }
            }
        }
        JsonValue::Array(a) => {
            for item in a {
                if let Some(h) = item.get("hash").and_then(|x| x.as_str()) {
                    push_hash(out, h);
                }
                cas_hashes_from_json_walk(item, out);
            }
        }
        JsonValue::Object(map) => {
            if let Some(h) = map.get("hash").and_then(|x| x.as_str()) {
                push_hash(out, h);
            }
            for val in map.values() {
                cas_hashes_from_json_walk(val, out);
            }
        }
        _ => {}
    }
}

pub async fn blob_ref_propagate_variant(
    pool: &PgPool,
    canonical_hash: &str,
    variant_key: &str,
    variant_hash: &str,
) -> Result<(), sqlx::Error> {
    let Some(canonical_hash) = cas_hash_normalize(canonical_hash) else {
        return Ok(());
    };
    let Some(variant_hash) = cas_hash_normalize(variant_hash) else {
        return Ok(());
    };
    let rows = sqlx::query(
        r#"
        SELECT DISTINCT scope_kind, scope_iid, billable_owner_iid
        FROM ai.blob_ref
        WHERE hash_blake3 = $1
        "#,
    )
    .bind(&canonical_hash)
    .fetch_all(pool)
    .await?;
    if rows.is_empty() {
        return Ok(());
    }
    let source = format!("variant.{}", variant_key);
    let source_key = format!("variant:{}:{}", variant_key, canonical_hash);
    for r in rows {
        let scope_kind: String = r.get("scope_kind");
        let scope_iid: i64 = r.get("scope_iid");
        let billable_owner_iid: i64 = r.get("billable_owner_iid");
        let kind = match scope_kind.as_str() {
            "user" => "user",
            "site" => "site",
            "bot" => "bot",
            "mailbox" => "mailbox",
            _ => continue,
        };
        let scope = BlobRefScope {
            scope_kind: kind,
            scope_iid,
            billable_owner_iid,
        };
        blob_ref_upsert(pool, &scope, &variant_hash, &source, &source_key).await?;
    }
    Ok(())
}

pub async fn blob_ref_chat_msg(
    pool: &PgPool,
    chat_id: i64,
    msg_id: i64,
    owner_iid: i64,
    attachments_json: &str,
    content: &str,
    blocks_json: &str,
) -> Result<(), sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT kind, COALESCE(bot_iid, 0) AS bot_iid, owner_iid
        FROM ai.chat
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    let Some(row) = row else {
        return Ok(());
    };
    let kind: String = row.get("kind");
    let bot_iid: i64 = row.get("bot_iid");
    let chat_owner: i64 = row.get("owner_iid");

    let (scope_kind, scope_iid, billable_owner_iid) = if kind == "bot_peer" && bot_iid > 0 {
        let bot_owner: Option<i64> = sqlx::query_scalar(
            "SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
        )
        .bind(bot_iid)
        .fetch_optional(pool)
        .await?;
        let billable = bot_owner.unwrap_or(chat_owner);
        ("bot", bot_iid, billable)
    } else {
        let uid = if owner_iid > 0 { owner_iid } else { chat_owner };
        ("user", uid, uid)
    };

    let scope = BlobRefScope {
        scope_kind,
        scope_iid,
        billable_owner_iid,
    };

    let mut hashes = Vec::new();
    if let Ok(v) = serde_json::from_str::<JsonValue>(attachments_json) {
        for h in cas_hashes_from_json_value(&v) {
            push_hash(&mut hashes, &h);
        }
    }
    if let Ok(v) = serde_json::from_str::<JsonValue>(blocks_json) {
        for h in cas_hashes_from_json_value(&v) {
            push_hash(&mut hashes, &h);
        }
    }
    for h in cas_hashes_from_text(content) {
        push_hash(&mut hashes, &h);
    }

    for hash in hashes {
        let source_key = format!("chat_msg:{}:{}", msg_id, hash);
        blob_ref_upsert(pool, &scope, &hash, "chat", &source_key).await?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cas_hashes_from_text_fs_path() {
        let h = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";
        let body = format!("see /fs/{} ok", h);
        let got = cas_hashes_from_text(&body);
        assert_eq!(got, vec![h]);
    }
}
