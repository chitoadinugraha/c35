use axum::{
    extract::{Query, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
    Json, Router,
};
use chrono::{Duration, Utc};
use c35_ctx::{AppState, OAuthPending, OAuthResult};
use c35_mod_billing::billing_signup_credit;
use c35_store::snowflake_id;
use rand::RngCore;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::Row;
use tracing::error;

use crate::auth_session::auth_session_create;

pub const PATH_GOOGLE: &str = "/a/auth/google";
pub const PATH_GOOGLE_CALLBACK: &str = "/a/auth/google/callback";
pub const PATH_GOOGLE_RESULT: &str = "/a/auth/google/result";
pub const PATH_GOOGLE_DONE: &str = "/a/auth/google/done";

const OAUTH_RETURN_DEEPLINK_PREFIX: &str = "deeplink:";

pub fn oauth_router() -> Router<AppState> {
    Router::new()
        .route(PATH_GOOGLE, get(google_start))
        .route("/v1/auth/google", get(google_start))
        .route(PATH_GOOGLE_CALLBACK, get(google_callback))
        .route("/v1/auth/google/callback", get(google_callback))
        .route(PATH_GOOGLE_RESULT, get(google_result))
        .route("/v1/auth/google/result", get(google_result))
        .route(PATH_GOOGLE_DONE, get(google_done))
        .route("/v1/auth/google/done", get(google_done))
}

fn google_client_id() -> String {
    std::env::var("GOOGLE_CLIENT_ID")
        .or_else(|_| std::env::var("CSAI_GOOGLE_CLIENT_ID"))
        .unwrap_or_default()
}

fn google_client_secret() -> String {
    std::env::var("GOOGLE_CLIENT_SECRET")
        .or_else(|_| std::env::var("CSAI_GOOGLE_CLIENT_SECRET"))
        .unwrap_or_default()
}

fn public_origin(st: &AppState) -> String {
    if !st.public_origin.trim().is_empty() {
        return st.public_origin.trim_end_matches('/').to_string();
    }
    std::env::var("C35_PUBLIC_ORIGIN")
        .or_else(|_| std::env::var("CS_PUBLIC_ORIGIN"))
        .or_else(|_| std::env::var("CSAI_PUBLIC_ORIGIN"))
        .unwrap_or_else(|_| "https://alienai.id".to_string())
}

#[derive(Deserialize)]
pub struct GoogleStartQ {
    #[serde(rename = "return")]
    pub return_path: Option<String>,
    pub return_to: Option<String>,
    pub public_origin: Option<String>,
    pub client_id: Option<String>,
    pub launch: Option<String>,
}

pub async fn google_start(
    State(st): State<AppState>,
    Query(q): Query<GoogleStartQ>,
) -> Result<impl IntoResponse, StatusCode> {
    let client_id_cfg = google_client_id();
    if client_id_cfg.is_empty() {
        return Err(StatusCode::SERVICE_UNAVAILABLE);
    }
    let return_path = oauth_return_store(
        q.launch.as_deref(),
        &sanitize_return(q.return_to.as_deref().or(q.return_path.as_deref())),
    );
    let origin = q
        .public_origin
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| public_origin(&st));
    let client_id = q
        .client_id
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or_else(random_token);
    st.oauth.results.remove(&client_id);
    let oauth_state = random_token();
    let exp = Utc::now() + Duration::minutes(15);
    st.oauth.pending.insert(
        oauth_state.clone(),
        OAuthPending {
            client_id: client_id.clone(),
            return_path,
            origin: origin.clone(),
            expires_at: exp,
        },
    );
    Ok(Redirect::temporary(&google_auth_url(
        &client_id_cfg,
        &callback_url(&origin),
        &oauth_state,
    )))
}

#[derive(Deserialize)]
pub struct GoogleCallbackQ {
    pub state: Option<String>,
    pub code: Option<String>,
    pub error: Option<String>,
}

pub async fn google_callback(
    State(st): State<AppState>,
    headers: HeaderMap,
    Query(q): Query<GoogleCallbackQ>,
) -> Response {
    let origin = public_origin(&st);
    if let Some(err) = q.error.filter(|s| !s.trim().is_empty()) {
        return Redirect::temporary(&oauth_done_url(&origin, false, None, None, Some(&err)))
            .into_response();
    }
    let oauth_state = q.state.as_deref().unwrap_or("").trim();
    let code = q.code.as_deref().unwrap_or("").trim();
    if oauth_state.is_empty() || code.is_empty() {
        return (StatusCode::BAD_REQUEST, "Missing OAuth state or code").into_response();
    }
    let pending = match st.oauth.pending.remove(oauth_state) {
        Some((_, p)) if p.expires_at > Utc::now() => p,
        _ => {
            return (StatusCode::BAD_REQUEST, "Invalid or expired OAuth state").into_response();
        }
    };
    let origin = if pending.origin.is_empty() {
        origin
    } else {
        pending.origin
    };
    let access_token = match google_exchange_code(&callback_url(&origin), code).await {
        Ok(t) => t,
        Err(e) => {
            error!("[auth:google] exchange failed: {}", e);
            return (StatusCode::BAD_GATEWAY, format!("OAuth code exchange error: {e}"))
                .into_response();
        }
    };
    let profile = match fetch_google_profile(&access_token).await {
        Ok(p) => p,
        Err(e) => {
            error!("[auth:google] profile failed: {}", e);
            return (StatusCode::BAD_GATEWAY, format!("OAuth user profile error: {e}"))
                .into_response();
        }
    };
    let pool = &st.pool;
    let iid = match get_or_create_google_identity(pool, &profile).await {
        Ok(id) => id,
        Err(e) => {
            error!("[auth:google] identity error: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Database identity error").into_response();
        }
    };
    let handle: String = sqlx::query_scalar(
        "SELECT alien_id FROM ai.identity WHERE id = $1 LIMIT 1",
    )
    .bind(iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .flatten()
    .unwrap_or_default();
    let ip = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    let ua = headers.get(header::USER_AGENT).and_then(|v| v.to_str().ok());
    let token = match auth_session_create(pool, iid, ip, ua).await {
        Ok(t) => t,
        Err(e) => {
            error!("[auth:google] session error: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Session create error").into_response();
        }
    };
    let exp = Utc::now() + Duration::minutes(10);
    st.oauth.results.insert(
        pending.client_id.clone(),
        OAuthResult {
            ready: true,
            ok: true,
            uid: Some(iid),
            token: Some(token.clone()),
            name: Some(profile.name.clone()),
            email: Some(profile.email.clone()),
            pic: Some(profile.picture.clone()),
            handle: Some(handle.clone()),
            expires_at: exp,
        },
    );
    let redirect_q = vec![
        ("google_auth".into(), "ok".into()),
        ("uid".into(), iid.to_string()),
        ("token".into(), token.clone()),
        ("name".into(), profile.name.clone()),
        ("pic".into(), profile.picture.clone()),
    ];
    let location = oauth_finish_redirect(&pending.return_path, &origin, &redirect_q, &profile.name);
    let cookie = format!("cs_session={token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000");
    let mut resp = Redirect::temporary(&location).into_response();
    if let Ok(hv) = HeaderValue::from_str(&cookie) {
        resp.headers_mut().insert(header::SET_COOKIE, hv);
    }
    resp
}

#[derive(Serialize)]
pub struct GoogleResultOut {
    pub ready: bool,
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub uid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pic: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub handle: Option<String>,
}

pub async fn google_result(
    State(st): State<AppState>,
    Query(q): Query<std::collections::HashMap<String, String>>,
) -> Json<GoogleResultOut> {
    let client_id = q.get("client_id").map(|s| s.trim()).unwrap_or("");
    let mut out = GoogleResultOut {
        ready: false,
        ok: false,
        uid: None,
        session_id: None,
        token: None,
        name: None,
        email: None,
        pic: None,
        handle: None,
    };
    if client_id.is_empty() {
        return Json(out);
    }
    if let Some((_, r)) = st.oauth.results.remove(client_id) {
        if r.expires_at > Utc::now() {
            out.ready = r.ready;
            out.ok = r.ok;
            out.uid = r.uid.map(|u| u.to_string());
            out.session_id = r.token.clone();
            out.token = r.token;
            out.name = r.name;
            out.email = r.email;
            out.pic = r.pic;
            out.handle = r.handle;
        }
    }
    Json(out)
}

pub async fn google_done(Query(q): Query<std::collections::HashMap<String, String>>) -> Html<String> {
    let ok = q.get("status").map(|s| s.as_str()) != Some("error");
    let name = q.get("name").map(|s| s.trim()).filter(|s| !s.is_empty());
    let pic = q.get("pic").map(|s| s.trim()).filter(|s| !s.is_empty());
    let reason = q.get("reason").map(|s| s.trim()).filter(|s| !s.is_empty());
    Html(oauth_done_html(ok, name, pic, reason))
}

#[derive(Debug, Deserialize)]
struct GoogleProfile {
    sub: String,
    email: String,
    name: String,
    picture: String,
}

async fn ensure_root_google_identity(pool: &sqlx::PgPool, profile: &GoogleProfile) -> Result<(), sqlx::Error> {
    const IID: i64 = 99000;
    let email = profile.email.trim().to_lowercase();
    let sub = profile.sub.trim();
    let meta = json!({ "email": email, "google_sub": sub, "is_root": true });
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, billing_iid, pic, meta, is_active)
        VALUES ($1, 'user', '', 'chito', $2, $1, $1, $3, $4, true)
        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name,
            pic = COALESCE(EXCLUDED.pic, ai.identity.pic),
            alien_id = CASE WHEN LOWER(ai.identity.alien_id) IN ('chitoadinugraha', 'chito') THEN EXCLUDED.alien_id ELSE ai.identity.alien_id END,
            meta = ai.identity.meta || EXCLUDED.meta, updated_ts = NOW()
        "#,
    )
    .bind(IID)
    .bind(&profile.name)
    .bind(&profile.picture)
    .bind(meta)
    .execute(pool)
    .await?;
    google_provider_attach_if_missing(pool, IID, sub, &email).await?;
    google_provider_sync_login(pool, IID, sub, &email).await?;
    let _ = billing_signup_credit(pool, IID, 100.0).await;
    Ok(())
}

/// Resolve existing account: Google `sub` first (stable when Gmail changes), then email fallbacks.
async fn google_login_resolve_iid(pool: &sqlx::PgPool, sub: &str, email: &str) -> Result<Option<i64>, sqlx::Error> {
    if !sub.is_empty() {
        if let Some(r) = sqlx::query(
            r#"
            SELECT identity_iid FROM ai.identity_provider
            WHERE kind = 'google' AND deleted_ts IS NULL AND meta->>'google_sub' = $1
            LIMIT 1
            "#,
        )
        .bind(sub)
        .fetch_optional(pool)
        .await?
        {
            return Ok(Some(r.get("identity_iid")));
        }
    }
    if !email.is_empty() {
        if let Some(r) = sqlx::query(
            r#"
            SELECT identity_iid FROM ai.identity_provider
            WHERE kind = 'google' AND deleted_ts IS NULL AND LOWER(identifier) = LOWER($1)
            LIMIT 1
            "#,
        )
        .bind(email)
        .fetch_optional(pool)
        .await?
        {
            return Ok(Some(r.get("identity_iid")));
        }
        if let Some(r) = sqlx::query(
            r#"
            SELECT identity_iid FROM ai.identity_provider
            WHERE kind = 'email' AND deleted_ts IS NULL AND LOWER(identifier) = LOWER($1)
            LIMIT 1
            "#,
        )
        .bind(email)
        .fetch_optional(pool)
        .await?
        {
            return Ok(Some(r.get("identity_iid")));
        }
        if let Some(r) = sqlx::query(
            "SELECT id FROM ai.identity WHERE deleted_ts IS NULL AND LOWER(meta->>'email') = LOWER($1) LIMIT 1",
        )
        .bind(email)
        .fetch_optional(pool)
        .await?
        {
            return Ok(Some(r.get("id")));
        }
    }
    Ok(None)
}

async fn google_provider_attach_if_missing(
    pool: &sqlx::PgPool,
    iid: i64,
    sub: &str,
    email: &str,
) -> Result<(), sqlx::Error> {
    if sqlx::query(
        "SELECT 1 FROM ai.identity_provider WHERE identity_iid = $1 AND kind = 'google' AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(iid)
    .fetch_optional(pool)
    .await?
    .is_some()
    {
        return Ok(());
    }
    let prov_id = snowflake_id();
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.identity_provider (id, identity_iid, kind, identifier, is_verified, is_primary, verified_at, meta)
        VALUES ($1, $2, 'google', $3, true, true, NOW(), $4)
        ON CONFLICT (kind, identifier) DO NOTHING
        "#,
    )
    .bind(prov_id)
    .bind(iid)
    .bind(email)
    .bind(json!({ "google_sub": sub }))
    .execute(pool)
    .await?;
    Ok(())
}

/// Refresh `google_sub` and Gmail identifier after OAuth; skip identifier change if another google row owns that email.
async fn google_provider_sync_login(
    pool: &sqlx::PgPool,
    iid: i64,
    sub: &str,
    email: &str,
) -> Result<(), sqlx::Error> {
    let sub_meta = json!({ "google_sub": sub });
    if let Some(r) = sqlx::query(
        r#"
        SELECT id, LOWER(identifier) AS ident
        FROM ai.identity_provider
        WHERE identity_iid = $1 AND kind = 'google' AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(iid)
    .fetch_optional(pool)
    .await?
    {
        let prov_id: i64 = r.get("id");
        let old_ident: String = r.get("ident");
        if !email.is_empty() && old_ident != email {
            let n = sqlx::query(
                r#"
                UPDATE ai.identity_provider
                SET identifier = $1,
                    meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
                    is_verified = true,
                    updated_ts = NOW()
                WHERE id = $3 AND deleted_ts IS NULL
                  AND NOT EXISTS (
                    SELECT 1 FROM ai.identity_provider o
                    WHERE o.kind = 'google' AND o.deleted_ts IS NULL
                      AND LOWER(o.identifier) = LOWER($1) AND o.id <> $3
                  )
                "#,
            )
            .bind(email)
            .bind(&sub_meta)
            .bind(prov_id)
            .execute(pool)
            .await?
            .rows_affected();
            if n == 0 {
                sqlx::query(
                    r#"
                    UPDATE ai.identity_provider
                    SET meta = COALESCE(meta, '{}'::jsonb) || $1::jsonb,
                        is_verified = true,
                        updated_ts = NOW()
                    WHERE id = $2 AND deleted_ts IS NULL
                    "#,
                )
                .bind(&sub_meta)
                .bind(prov_id)
                .execute(pool)
                .await?;
            }
        } else {
            sqlx::query(
                r#"
                UPDATE ai.identity_provider
                SET meta = COALESCE(meta, '{}'::jsonb) || $1::jsonb,
                    is_verified = true,
                    updated_ts = NOW()
                WHERE id = $2 AND deleted_ts IS NULL
                "#,
            )
            .bind(&sub_meta)
            .bind(prov_id)
            .execute(pool)
            .await?;
        }
    }
    if !email.is_empty() {
        sqlx::query(
            r#"
            UPDATE ai.identity
            SET meta = COALESCE(meta, '{}'::jsonb) || jsonb_build_object('email', $2::text),
                updated_ts = NOW()
            WHERE id = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(iid)
        .bind(email)
        .execute(pool)
        .await?;
        sqlx::query(
            r#"
            UPDATE ai.identity_provider
            SET identifier = $1, is_verified = true, updated_ts = NOW()
            WHERE identity_iid = $2 AND kind = 'email' AND deleted_ts IS NULL
              AND LOWER(identifier) <> LOWER($1)
              AND NOT EXISTS (
                SELECT 1 FROM ai.identity_provider o
                WHERE o.kind = 'email' AND o.deleted_ts IS NULL
                  AND LOWER(o.identifier) = LOWER($1) AND o.identity_iid <> $2
              )
            "#,
        )
        .bind(email)
        .bind(iid)
        .execute(pool)
        .await?;
    }
    Ok(())
}

async fn get_or_create_google_identity(pool: &sqlx::PgPool, profile: &GoogleProfile) -> Result<i64, sqlx::Error> {
    let sub = profile.sub.trim();
    let email = profile.email.trim().to_lowercase();
    if sub == "102004931260244923813" || email == "chitoadinugraha@gmail.com" {
        ensure_root_google_identity(pool, profile).await?;
        return Ok(99000);
    }
    if let Some(iid) = google_login_resolve_iid(pool, sub, &email).await? {
        google_provider_attach_if_missing(pool, iid, sub, &email).await?;
        google_provider_sync_login(pool, iid, sub, &email).await?;
        return Ok(iid);
    }
    let iid = snowflake_id();
    let meta = json!({ "email": email, "google_sub": sub, "signup_via": "google" });
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, billing_iid, pic, meta, is_active)
        VALUES ($1, 'user', '', NULL, $2, $1, $1, $3, $4, true)
        "#,
    )
    .bind(iid)
    .bind(&profile.name)
    .bind(&profile.picture)
    .bind(meta)
    .execute(pool)
    .await?;
    let prov_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity_provider (id, identity_iid, kind, identifier, is_verified, is_primary, verified_at, meta)
        VALUES ($1, $2, 'google', $3, true, true, NOW(), $4)
        "#,
    )
    .bind(prov_id)
    .bind(iid)
    .bind(&email)
    .bind(json!({ "google_sub": sub }))
    .execute(pool)
    .await?;
    let _ = billing_signup_credit(pool, iid, 10.0).await;
    Ok(iid)
}

fn callback_url(public_origin: &str) -> String {
    format!(
        "{}{}",
        public_origin.trim_end_matches('/'),
        PATH_GOOGLE_CALLBACK
    )
}

fn google_auth_url(client_id: &str, redirect_uri: &str, state: &str) -> String {
    format!(
        "https://accounts.google.com/o/oauth2/v2/auth?client_id={}&redirect_uri={}&response_type=code&scope=openid%20email%20profile&state={}&access_type=online&prompt=select_account",
        urlencoding::encode(client_id),
        urlencoding::encode(redirect_uri),
        urlencoding::encode(state),
    )
}

async fn google_exchange_code(redirect_uri: &str, code: &str) -> Result<String, String> {
    #[derive(serde::Deserialize)]
    struct TokenRes {
        access_token: Option<String>,
        error: Option<String>,
    }
    let res = reqwest::Client::new()
        .post("https://oauth2.googleapis.com/token")
        .form(&[
            ("code", code),
            ("client_id", google_client_id().as_str()),
            ("client_secret", google_client_secret().as_str()),
            ("redirect_uri", redirect_uri),
            ("grant_type", "authorization_code"),
        ])
        .send()
        .await
        .map_err(|e| e.to_string())?;
    let body: TokenRes = res.json().await.map_err(|e| e.to_string())?;
    if let Some(err) = body.error {
        return Err(err);
    }
    body.access_token
        .filter(|s| !s.is_empty())
        .ok_or_else(|| "no access_token".into())
}

async fn fetch_google_profile(access_token: &str) -> Result<GoogleProfile, String> {
    #[derive(serde::Deserialize)]
    struct ProfileRes {
        sub: Option<String>,
        email: Option<String>,
        name: Option<String>,
        picture: Option<String>,
    }
    let p: ProfileRes = reqwest::Client::new()
        .get("https://www.googleapis.com/oauth2/v3/userinfo")
        .header("Authorization", format!("Bearer {access_token}"))
        .send()
        .await
        .map_err(|e| e.to_string())?
        .json()
        .await
        .map_err(|e| e.to_string())?;
    let sub = p.sub.unwrap_or_default();
    if sub.trim().is_empty() {
        return Err("missing sub".into());
    }
    Ok(GoogleProfile {
        sub,
        email: p.email.unwrap_or_default(),
        name: p.name.unwrap_or_default(),
        picture: p.picture.unwrap_or_default(),
    })
}

fn sanitize_return(return_path: Option<&str>) -> String {
    let p = return_path.unwrap_or("/").trim();
    if p.is_empty() {
        return "/".into();
    }
    if p.contains("://") {
        return if is_app_oauth_return(p) {
            p.to_string()
        } else {
            "/".into()
        };
    }
    if !p.starts_with('/') || p.starts_with("//") {
        return "/".into();
    }
    p.to_string()
}

fn oauth_return_store(launch: Option<&str>, return_path: &str) -> String {
    if launch == Some("custom_tab") && is_app_oauth_return(return_path) {
        format!("{OAUTH_RETURN_DEEPLINK_PREFIX}{return_path}")
    } else {
        return_path.to_string()
    }
}

fn oauth_return_resolve(stored: &str) -> (&str, bool) {
    if let Some(rest) = stored.strip_prefix(OAUTH_RETURN_DEEPLINK_PREFIX) {
        (rest, true)
    } else {
        (stored, false)
    }
}

fn is_app_oauth_return(return_path: &str) -> bool {
    let p = return_path.trim();
    if !p.contains("://") {
        return false;
    }
    let scheme = p.split("://").next().unwrap_or("").to_ascii_lowercase();
    !scheme.is_empty() && scheme != "http" && scheme != "https"
}

fn oauth_finish_redirect(
    return_path_stored: &str,
    public_origin: &str,
    q: &[(String, String)],
    name: &str,
) -> String {
    let (return_path, deeplink) = oauth_return_resolve(return_path_stored);
    if deeplink && is_app_oauth_return(return_path) {
        return oauth_redirect_url(return_path, public_origin, q);
    }
    if is_app_oauth_return(return_path) {
        let ok = q.iter().any(|(k, v)| k == "google_auth" && v == "ok");
        let name = if name.is_empty() {
            q.iter()
                .find(|(k, _)| k == "name")
                .map(|(_, v)| v.as_str())
        } else {
            Some(name)
        };
        let pic = q.iter().find(|(k, _)| k == "pic").map(|(_, v)| v.as_str());
        return oauth_done_url(public_origin, ok, name, pic, None);
    }
    oauth_redirect_url(return_path, public_origin, q)
}

fn oauth_redirect_url(return_path: &str, public_origin: &str, q: &[(String, String)]) -> String {
    let base = public_origin.trim_end_matches('/');
    let p = return_path.trim();
    let qs = q
        .iter()
        .map(|(k, v)| format!("{}={}", urlencoding::encode(k), urlencoding::encode(v)))
        .collect::<Vec<_>>()
        .join("&");
    if p.contains("://") {
        return if p.contains('?') {
            format!("{p}&{qs}")
        } else {
            format!("{p}?{qs}")
        };
    }
    let path = if p.starts_with('/') { p } else { "/" };
    format!("{base}{path}?{qs}")
}

fn oauth_done_url(
    public_origin: &str,
    ok: bool,
    name: Option<&str>,
    pic: Option<&str>,
    reason: Option<&str>,
) -> String {
    let origin = public_origin.trim_end_matches('/');
    let origin = if origin.is_empty() {
        "http://localhost:8080"
    } else {
        origin
    };
    let mut pairs = vec![("status", if ok { "ok" } else { "error" })];
    if let Some(n) = name.filter(|s| !s.is_empty()) {
        pairs.push(("name", n));
    }
    if let Some(p) = pic.filter(|s| !s.is_empty()) {
        pairs.push(("pic", p));
    }
    if let Some(r) = reason.filter(|s| !s.is_empty()) {
        pairs.push(("reason", r));
    }
    let qs = pairs
        .iter()
        .map(|(k, v)| format!("{}={}", urlencoding::encode(k), urlencoding::encode(v)))
        .collect::<Vec<_>>()
        .join("&");
    format!("{origin}{PATH_GOOGLE_DONE}?{qs}")
}

fn random_token() -> String {
    let mut rng_bytes = [0u8; 32];
    rand::rngs::OsRng.fill_bytes(&mut rng_bytes);
    blake3::hash(&rng_bytes).to_hex().to_string()
}

const ALIEN_ICON_SVG: &str = r##"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true"><path fill="#fff" d="M12 3c4.97 0 9 3.58 9 8s-6 10-9 10s-9-5.58-9-10s4.03-8 9-8m-1.69 7.93C9.29 9.29 7.47 8.58 6.25 9.34s-1.38 2.71-.36 4.35c1.03 1.64 2.85 2.35 4.07 1.59c1.22-.78 1.37-2.71.35-4.35m3.38 0c-1.02 1.64-.87 3.57.35 4.35c1.22.76 3.04.05 4.07-1.59c1.02-1.64.86-3.59-.36-4.35s-3.04-.05-4.06 1.59M12 17.75c-2 0-2.5-.75-2.5-.75c0 .03.5 2 2.5 2s2.5-2 2.5-2s-.5.75-2.5.75"/></svg>"##;

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

fn first_name(name: &str) -> &str {
    name.split_whitespace().next().unwrap_or(name)
}

fn safe_avatar_url(pic: Option<&str>) -> Option<String> {
    let p = pic?.trim();
    if p.starts_with("https://") || p.starts_with("http://") {
        Some(html_escape(p))
    } else {
        None
    }
}

fn oauth_done_html(ok: bool, name: Option<&str>, pic: Option<&str>, reason: Option<&str>) -> String {
    let (title, heading, message, visual) = if ok {
        let heading = name
            .map(|n| format!("Welcome, {}", html_escape(first_name(n))))
            .unwrap_or_else(|| "You're signed in".to_string());
        let visual = match safe_avatar_url(pic) {
            Some(url) => format!(
                r#"<div class="avatar"><img src="{url}" alt="" referrerpolicy="no-referrer" /></div>"#
            ),
            None => format!(r#"<div class="icon logo">{ALIEN_ICON_SVG}</div>"#),
        };
        (
            "Sign-in successful",
            heading,
            "You're signed in to Alien AI. Close this tab and return to the app.".into(),
            visual,
        )
    } else {
        let message = reason
            .map(|r| format!("{}. Return to Alien AI and try again.", html_escape(r)))
            .unwrap_or_else(|| "Return to Alien AI and try again.".to_string());
        (
            "Sign-in failed",
            "Could not sign in".into(),
            message,
            r#"<div class="icon err">!</div>"#.into(),
        )
    };
    format!(
        r#"<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{title} · Alien AI</title>
<style>:root{{--bg:#08080a;--fg:#ededf0;--muted:#8e8e98;--err:#f87171;--card:#121215;--border:#222227}}*,*::before,*::after{{box-sizing:border-box}}html,body{{margin:0;height:100%}}body{{display:flex;align-items:center;justify-content:center;color:var(--fg);background:var(--bg);font-family:ui-sans-serif,system-ui,sans-serif;padding:24px}}
.card{{text-align:center;max-width:380px;width:100%;padding:2rem 1.6rem;border-radius:16px;border:1px solid var(--border);background:var(--card)}}
.avatar,.icon{{width:76px;height:76px;margin:0 auto 1.25rem;border-radius:50%;display:flex;align-items:center;justify-content:center;background:#141417;border:1.5px solid #27272a}}
.avatar img{{width:100%;height:100%;object-fit:cover;border-radius:50%}}.icon.err{{color:var(--err);font-size:1.65rem;font-weight:700}}
h1{{margin:0 0 .4rem;font-size:1.55rem}}p{{margin:0;color:var(--muted);font-size:.875rem}}</style></head>
<body><div class="card">{visual}<h1>{heading}</h1><p>{message}</p></div></body></html>"#
    )
}
