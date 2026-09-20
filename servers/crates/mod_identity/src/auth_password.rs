use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{
    extract::State,
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use c35_ctx::AppState;
use c35_mod_billing::billing_signup_credit;
use c35_store::snowflake_id;
use rand::rngs::OsRng;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::Row;

use crate::auth_ident::{alien_id_display, login_ident_parse, LoginIdent};
use crate::auth_session::{auth_session_create, auth_session_delete, auth_token_extract};

pub fn hash_password(password: &str) -> Result<String, argon2::password_hash::Error> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
}

pub fn verify_password(password: &str, hash: &str) -> bool {
    let Ok(parsed) = PasswordHash::new(hash) else {
        return false;
    };
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed)
        .is_ok()
}

#[derive(Debug, Deserialize)]
pub struct SignUpReq {
    pub name: String,
    pub email: String,
    pub password: String,
    pub handle: Option<String>,
    pub referral_code: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SignInReq {
    pub login: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct IdentityInfo {
    pub id: i64,
    pub name: String,
    pub handle: String,
    pub email: String,
    pub avatar_url: Option<String>,
    pub balance_usd: f64,
    pub balance_idr: f64,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub ok: bool,
    pub token: String,
    pub identity: IdentityInfo,
}

pub fn auth_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/v1/auth/signup", axum::routing::post(sign_up))
        .route("/v1/auth/sign-up", axum::routing::post(sign_up))
        .route("/v1/auth/signin", axum::routing::post(sign_in))
        .route("/v1/auth/sign-in", axum::routing::post(sign_in))
        .route("/v1/auth/login", axum::routing::post(sign_in))
        .route("/v1/auth/signout", axum::routing::post(sign_out))
        .route("/v1/auth/sign-out", axum::routing::post(sign_out))
        .route("/v1/auth/logout", axum::routing::post(sign_out))
        .route("/v1/auth/me", axum::routing::get(me))
}

pub async fn sign_up(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<SignUpReq>,
) -> Response {
    let name = req.name.trim();
    let ident = login_ident_parse(&req.email);
    let password = req.password.trim();
    if name.is_empty() || password.len() < 8 {
        return bad("Name, valid email or phone, and password (min 8 characters) are required.");
    }
    if !ident.is_email_or_phone() {
        return bad("Use an email address or phone number.");
    }
    if let LoginIdent::Email(ref email) = ident {
        if !email.contains('.') {
            return bad("Invalid email address format.");
        }
    }
    let login = ident.as_str().to_string();
    let email = match &ident {
        LoginIdent::Email(e) => e.clone(),
        _ => String::new(),
    };
    let phone = match &ident {
        LoginIdent::Phone(p) => p.clone(),
        _ => String::new(),
    };
    let pool = &st.pool;
    if sqlx::query(
        r#"
        SELECT 1 FROM ai.identity_provider
        WHERE LOWER(identifier) = LOWER($1)
           OR ($2 <> '' AND kind = 'phone' AND identifier = $2)
        LIMIT 1
        "#,
    )
    .bind(&login)
    .bind(&phone)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .is_some()
    {
        return conflict("An account with this email or phone already exists.");
    }

    let iid = if email == "chitoadinugraha@gmail.com" {
        99000
    } else {
        snowflake_id()
    };
    let base_handle = req
        .handle
        .as_deref()
        .map(|h| h.trim().trim_start_matches('@').to_lowercase())
        .filter(|h| !h.is_empty())
        .unwrap_or_else(|| {
            let seed = if !email.is_empty() {
                email.split('@').next().unwrap_or("user")
            } else {
                &phone
            };
            seed.chars()
                .filter(|c| c.is_ascii_alphanumeric() || *c == '_' || *c == '-')
                .collect::<String>()
        });
    let mut alien_id = base_handle.clone();
    let mut counter = 1;
    while sqlx::query(
        r#"
        SELECT 1 FROM ai.identity
        WHERE LOWER(alien_id) = LOWER($1) AND id != $2 LIMIT 1
        "#,
    )
    .bind(&alien_id)
    .bind(iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .is_some()
    {
        alien_id = format!("{base_handle}_{counter}");
        counter += 1;
    }
    let pwd_hash = match hash_password(password) {
        Ok(h) => h,
        Err(e) => return err(format!("Password hashing failed: {e}")),
    };
    let meta = json!({ "email": email, "phone": phone, "signup_via": "password" });
    if sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, billing_iid, meta, is_active)
        VALUES ($1, 'user', '', $2, $3, $1, $1, $4, true)
        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, alien_id = EXCLUDED.alien_id
        "#,
    )
    .bind(iid)
    .bind(&alien_id)
    .bind(name)
    .bind(meta)
    .execute(pool)
    .await
    .is_err()
    {
        return err("Failed to create identity.".into());
    }
    let prov_id = snowflake_id();
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.identity_provider (id, identity_iid, kind, identifier, secret_hash, is_verified, is_primary, verified_at)
        VALUES ($1, $2, 'password', $3, $4, true, true, NOW())
        ON CONFLICT DO NOTHING
        "#,
    )
    .bind(prov_id)
    .bind(iid)
    .bind(&login)
    .bind(&pwd_hash)
    .execute(pool)
    .await;
    if !phone.is_empty() {
        let phone_id = snowflake_id();
        let _ = sqlx::query(
            r#"
            INSERT INTO ai.identity_provider (id, identity_iid, kind, identifier, is_verified, is_primary, verified_at)
            VALUES ($1, $2, 'phone', $3, true, false, NOW())
            ON CONFLICT DO NOTHING
            "#,
        )
        .bind(phone_id)
        .bind(iid)
        .bind(&phone)
        .execute(pool)
        .await;
    }
    let initial_balance = if iid == 99000 || iid == 30000 {
        100.0
    } else {
        10.0
    };
    let initial_balance_idr = initial_balance * 17630.0;
    if let Err(e) = billing_signup_credit(pool, iid, initial_balance).await {
        return err(format!("Wallet setup failed: {e}"));
    }
    if let Some(ref_code) = req
        .referral_code
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
    {
        if let Ok(Some(row)) = sqlx::query(
            r#"
            SELECT issued_by_iid FROM ai.referral_code
            WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1
            "#,
        )
        .bind(ref_code)
        .fetch_optional(pool)
        .await
        {
            let parent_iid: i64 = row.get("issued_by_iid");
            if parent_iid != iid {
                let _ = sqlx::query(
                    "UPDATE ai.identity SET referred_by_iid = $1 WHERE id = $2",
                )
                .bind(parent_iid)
                .bind(iid)
                .execute(pool)
                .await;
                let _ = sqlx::query(
                    r#"
                    INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent)
                    VALUES ($1, $2, 25) ON CONFLICT DO NOTHING
                    "#,
                )
                .bind(parent_iid)
                .bind(iid)
                .execute(pool)
                .await;
                let _ = sqlx::query(
                    "UPDATE ai.referral_code SET used_count = used_count + 1 WHERE code = $1",
                )
                .bind(ref_code)
                .execute(pool)
                .await;
            }
        }
    }
    let ip = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    let ua = headers.get(header::USER_AGENT).and_then(|v| v.to_str().ok());
    let token = match auth_session_create(pool, iid, ip, ua).await {
        Ok(t) => t,
        Err(e) => return err(format!("Session creation failed: {e}")),
    };
    auth_response(
        iid,
        name,
        &alien_id_display(&alien_id),
        &email,
        None,
        initial_balance,
        initial_balance_idr,
        &token,
    )
}

pub async fn sign_in(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<SignInReq>,
) -> Response {
    let login_raw = req.login.trim();
    let password = req.password.trim();
    if login_raw.is_empty() || password.is_empty() {
        return bad("Login and password are required.");
    }
    let ident = login_ident_parse(login_raw);
    let login = ident.as_str().to_string();
    let phone = match &ident {
        LoginIdent::Phone(p) => p.clone(),
        _ => String::new(),
    };
    let pool = &st.pool;
    let handle_q = if login.starts_with('@') {
        login.trim_start_matches('@').to_string()
    } else {
        login.clone()
    };
    let row = sqlx::query(
        r#"
        SELECT ip.identity_iid, ip.secret_hash, i.name, i.alien_id, i.pic,
               COALESCE(i.meta->>'email', ip.identifier) AS email,
               COALESCE(b.balance_usd::float8, 0) AS balance_usd,
               COALESCE(b.balance_idr::float8, 0) AS balance_idr
        FROM ai.identity_provider ip
        JOIN ai.identity i ON i.id = ip.identity_iid
        LEFT JOIN ai.billing_account b ON b.owner_iid = i.id
        WHERE ip.kind = 'password' AND ip.deleted_ts IS NULL AND i.deleted_ts IS NULL
          AND (LOWER(ip.identifier) = LOWER($1)
            OR LOWER(i.alien_id) = LOWER($2)
            OR ($3 <> '' AND EXISTS (
                SELECT 1 FROM ai.identity_provider p
                WHERE p.identity_iid = ip.identity_iid AND p.kind = 'phone' AND p.identifier = $3
            )))
        LIMIT 1
        "#,
    )
    .bind(&login)
    .bind(&handle_q)
    .bind(&phone)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    let row = match row {
        Some(r) => r,
        None => return unauthorized("Invalid username/email or password."),
    };
    let secret_hash: Option<String> = row.get("secret_hash");
    let secret_hash = match secret_hash.filter(|h| !h.is_empty()) {
        Some(h) => h,
        None => return unauthorized("Invalid username/email or password."),
    };
    if !verify_password(password, &secret_hash) {
        return unauthorized("Invalid username/email or password.");
    }
    let iid: i64 = row.get("identity_iid");
    let name: String = row.get("name");
    let alien_id: Option<String> = row.get("alien_id");
    let pic: Option<String> = row.get("pic");
    let email: String = row.get("email");
    let balance_usd: f64 = row.try_get("balance_usd").unwrap_or(0.0);
    let balance_idr: f64 = row.try_get("balance_idr").unwrap_or(0.0);
    let ip = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    let ua = headers.get(header::USER_AGENT).and_then(|v| v.to_str().ok());
    let token = match auth_session_create(pool, iid, ip, ua).await {
        Ok(t) => t,
        Err(e) => return err(format!("Session creation failed: {e}")),
    };
    auth_response(
        iid,
        &name,
        &alien_id_display(alien_id.as_deref().unwrap_or("user")),
        &email,
        pic.as_deref(),
        balance_usd,
        balance_idr,
        &token,
    )
}

pub async fn sign_out(State(st): State<AppState>, headers: HeaderMap) -> Response {
    if let Some(token) = auth_token_extract(&headers, None) {
        let _ = auth_session_delete(&st.pool, &token).await;
    }
    let mut resp = Json(json!({ "ok": true })).into_response();
    if let Ok(hv) = HeaderValue::from_str("cs_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0") {
        resp.headers_mut().insert(header::SET_COOKIE, hv);
    }
    resp
}

pub async fn me(State(st): State<AppState>, headers: HeaderMap) -> Response {
    let token = match auth_token_extract(&headers, None) {
        Some(t) => t,
        None => return unauthorized("Missing or invalid session token."),
    };
    let iid = match crate::auth_session::auth_session_resolve(&st.pool, &token).await {
        Ok(Some(id)) => id,
        _ => return unauthorized("Session expired or invalid."),
    };
    let row = sqlx::query(
        r#"
        SELECT i.id, i.name, i.alien_id, i.pic,
               COALESCE(i.meta->>'email', '') AS email,
               COALESCE(i.meta->>'is_root', 'false') AS is_root,
               COALESCE(b.balance_usd::float8, 0) AS balance_usd,
               COALESCE(b.balance_idr::float8, 0) AS balance_idr,
               COALESCE(b.plan_tier, 'free') AS plan_tier
        FROM ai.identity i
        LEFT JOIN ai.billing_account b ON b.owner_iid = i.id AND b.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL LIMIT 1
        "#,
    )
    .bind(iid)
    .fetch_optional(&st.pool)
    .await
    .ok()
    .flatten();
    match row {
        Some(r) => Json(json!({
            "ok": true,
            "identity": {
                "id": iid,
                "name": r.get::<String, _>("name"),
                "handle": alien_id_display(r.get::<Option<String>, _>("alien_id").as_deref().unwrap_or("user")),
                "email": r.get::<String, _>("email"),
                "avatar_url": r.get::<Option<String>, _>("pic"),
                "balance_usd": r.try_get::<f64, _>("balance_usd").unwrap_or(0.0),
                "balance_idr": r.try_get::<f64, _>("balance_idr").unwrap_or(0.0),
                "is_root": r.get::<String, _>("is_root") == "true",
            }
        }))
        .into_response(),
        None => (
            StatusCode::NOT_FOUND,
            Json(json!({ "error": "User identity not found" })),
        )
            .into_response(),
    }
}

fn auth_response(
    iid: i64,
    name: &str,
    handle: &str,
    email: &str,
    avatar_url: Option<&str>,
    balance_usd: f64,
    balance_idr: f64,
    token: &str,
) -> Response {
    let out = AuthResponse {
        ok: true,
        token: token.to_string(),
        identity: IdentityInfo {
            id: iid,
            name: name.to_string(),
            handle: handle.to_string(),
            email: email.to_string(),
            avatar_url: avatar_url.map(str::to_string),
            balance_usd,
            balance_idr,
        },
    };
    let cookie = format!("cs_session={token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000");
    let mut resp = Json(out).into_response();
    if let Ok(hv) = HeaderValue::from_str(&cookie) {
        resp.headers_mut().insert(header::SET_COOKIE, hv);
    }
    if let Ok(hv) = HeaderValue::from_str(token) {
        resp.headers_mut().insert("X-Session-Token", hv.clone());
        resp.headers_mut().insert("X-CSA-Session", hv);
    }
    resp
}

fn bad(msg: &str) -> Response {
    (StatusCode::BAD_REQUEST, Json(json!({ "error": msg }))).into_response()
}

fn conflict(msg: &str) -> Response {
    (StatusCode::CONFLICT, Json(json!({ "error": msg }))).into_response()
}

fn unauthorized(msg: &str) -> Response {
    (StatusCode::UNAUTHORIZED, Json(json!({ "error": msg }))).into_response()
}

fn err(msg: String) -> Response {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(json!({ "error": msg })),
    )
        .into_response()
}
