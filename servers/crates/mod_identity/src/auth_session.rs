use blake3;
use c35_store::{db_retry, snowflake_id};
use sqlx::PgPool;

use crate::auth_jwt::{jwt_issue, jwt_verify};

pub fn token_hash(raw: &str) -> String {
    blake3::hash(raw.trim().as_bytes()).to_hex().to_string()
}

pub async fn auth_session_create(
    pool: &PgPool,
    identity_iid: i64,
    ip: Option<&str>,
    ua: Option<&str>,
) -> Result<(String, i64), sqlx::Error> {
    db_retry(pool, || async {
        let row = sqlx::query_as::<_, (String, Option<String>, Option<String>)>(
            r#"
            SELECT name, alien_id, pic FROM ai.identity
            WHERE id = $1 AND deleted_ts IS NULL LIMIT 1
            "#,
        )
        .bind(identity_iid)
        .fetch_optional(pool)
        .await?;

        let (name, alien_id, pic) = row.unwrap_or((String::new(), None, None));
        let handle = alien_id
            .map(|a| format!("@{a}"))
            .unwrap_or_else(|| "@user".into());
        let session_id = snowflake_id();
        let raw_token = jwt_issue(
            identity_iid,
            &name,
            &handle,
            pic.as_deref().unwrap_or(""),
            session_id,
        )
        .map_err(|e| sqlx::Error::Protocol(format!("jwt: {e}")))?;
        let hash = token_hash(&raw_token);
        sqlx::query(
            r#"
            INSERT INTO ai.auth_session (id, identity_iid, token_hash, ip_address, user_agent, expires_at)
            VALUES ($1, $2, $3, $4, $5, NOW() + INTERVAL '30 days')
            "#,
        )
        .bind(session_id)
        .bind(identity_iid)
        .bind(hash)
        .bind(ip)
        .bind(ua)
        .execute(pool)
        .await?;
        Ok((raw_token, session_id))
    })
    .await
}

pub async fn auth_session_resolve(pool: &PgPool, raw_token: &str) -> Result<Option<i64>, sqlx::Error> {
    let token = raw_token.trim();
    if token.is_empty() {
        return Ok(None);
    }
    if let Ok(Some(claims)) = jwt_verify(token) {
        return Ok(claims.iid());
    }
    db_retry(pool, || async {
        let row = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT identity_iid FROM ai.auth_session
            WHERE token_hash = $1 AND expires_at > NOW() LIMIT 1
            "#,
        )
        .bind(token_hash(token))
        .fetch_optional(pool)
        .await?;
        Ok(row)
    })
    .await
}

pub async fn auth_session_delete(pool: &PgPool, raw_token: &str) -> Result<(), sqlx::Error> {
    let token = raw_token.trim();
    if token.is_empty() {
        return Ok(());
    }
    db_retry(pool, || async {
        sqlx::query("DELETE FROM ai.auth_session WHERE token_hash = $1")
            .bind(token_hash(token))
            .execute(pool)
            .await
            .map(|_| ())
    })
    .await
}

pub fn auth_token_extract(
    headers: &axum::http::HeaderMap,
    query_token: Option<&str>,
) -> Option<String> {
    if let Some(t) = query_token.filter(|s| !s.trim().is_empty()) {
        return Some(t.trim().to_string());
    }
    if let Some(auth_val) = headers
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
    {
        if let Some(t) = auth_val.strip_prefix("Bearer ") {
            let t = t.trim();
            if !t.is_empty() {
                return Some(t.to_string());
            }
        }
    }
    for header_name in &["X-Session-Token", "X-CSA-Session", "X-CSAI-Session"] {
        if let Some(val) = headers.get(*header_name).and_then(|v| v.to_str().ok()) {
            let t = val.trim();
            if !t.is_empty() {
                return Some(t.to_string());
            }
        }
    }
    if let Some(cookie_hdr) = headers
        .get(axum::http::header::COOKIE)
        .and_then(|v| v.to_str().ok())
    {
        for piece in cookie_hdr.split(';') {
            let piece = piece.trim();
            for cookie_key in &["cs_session=", "csa_session="] {
                if let Some(val) = piece.strip_prefix(cookie_key) {
                    let val = val.trim();
                    if !val.is_empty() {
                        return Some(val.to_string());
                    }
                }
            }
        }
    }
    None
}

pub async fn auth_session_caller_iid(
    pool: &PgPool,
    headers: &axum::http::HeaderMap,
    query_token: Option<&str>,
) -> Option<i64> {
    let token = auth_token_extract(headers, query_token)?;
    auth_session_resolve(pool, &token).await.ok().flatten()
}
