use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{
    extract::{Query, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use c35_ctx::AppState;
use c35_mod_billing::billing_signup_credit;
use c35_store::{db_retry, snowflake_id};
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

pub fn referral_code_norm(code: &str) -> String {
    code.chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .collect::<String>()
        .to_uppercase()
}

pub fn referral_code_is_special(code: &str) -> bool {
    let norm = referral_code_norm(code);
    norm == "CHITOKERENSEKALI9999"
}

pub fn alien_id_valid(alien_id: &str) -> bool {
    !alien_id.is_empty()
        && alien_id
            .chars()
            .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-')
}

#[derive(Debug, Deserialize)]
pub struct SignUpReq {
    pub name: String,
    pub email: String,
    pub password: String,
    pub handle: Option<String>,
    pub alien_id: Option<String>,
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
    pub alien_id: Option<String>,
    pub email: String,
    pub avatar_url: Option<String>,
    pub balance_usd: f64,
    pub balance_idr: f64,
    pub referred_by_iid: Option<i64>,
    pub referral_prompt_dismissed: bool,
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
        .route("/v1/auth/referral/lookup", axum::routing::get(referral_lookup))
        .route("/v1/auth/referral/claim", axum::routing::post(referral_claim))
        .route("/v1/auth/referral/dismiss", axum::routing::post(referral_dismiss))
        .route("/v1/auth/alien_id/check", axum::routing::get(alien_id_check))
        .route("/v1/auth/alien_id/claim", axum::routing::post(alien_id_claim))
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
    let alien_id_opt: Option<String> = req
        .handle
        .as_deref()
        .or(req.alien_id.as_deref())
        .map(|h| h.trim().trim_start_matches('@').to_lowercase())
        .filter(|h| !h.is_empty());
    if let Some(ref aid) = alien_id_opt {
        if !alien_id_valid(aid) {
            return bad("Invalid Alien ID. Use lowercase letters, digits, _, and -.");
        }
        let taken = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM ai.identity WHERE LOWER(alien_id) = LOWER($1) AND id != $2 AND deleted_ts IS NULL)",
        )
        .bind(aid)
        .bind(iid)
        .fetch_one(pool)
        .await
        .unwrap_or(false);
        if taken {
            return conflict("Alien ID is already taken.");
        }
    }
    let pwd_hash = match hash_password(password) {
        Ok(h) => h,
        Err(e) => return err(format!("Password hashing failed: {e}")),
    };
    let meta = json!({ "email": email, "phone": phone, "signup_via": "password" });
    if db_retry(pool, || async {
        sqlx::query(
            r#"
            INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, billing_iid, meta, is_active)
            VALUES ($1, 'user', '', $2, $3, $1, $1, $4, true)
            ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, alien_id = EXCLUDED.alien_id
            "#,
        )
        .bind(iid)
        .bind(&alien_id_opt)
        .bind(name)
        .bind(meta.clone())
        .execute(pool)
        .await
        .map(|_| ())
    })
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
    let mut balance_usd = initial_balance;
    let mut balance_idr = initial_balance * 17630.0;
    if let Err(e) = billing_signup_credit(pool, iid, initial_balance).await {
        return err(format!("Wallet setup failed: {e}"));
    }

    let mut referred_by_iid: Option<i64> = None;
    let mut referral_prompt_dismissed = false;

    if let Some(raw_code) = req.referral_code.as_deref().map(str::trim).filter(|s| !s.is_empty()) {
        let code_norm = referral_code_norm(raw_code);
        let special = referral_code_is_special(&code_norm);
        let parent_opt: Option<i64> = if special {
            Some(99000)
        } else {
            sqlx::query_scalar("SELECT issued_by_iid FROM ai.referral_code WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1")
                .bind(&code_norm)
                .fetch_optional(pool)
                .await
                .ok()
                .flatten()
        };

        if let Some(parent_iid) = parent_opt {
            if parent_iid != iid {
                referred_by_iid = Some(parent_iid);
                referral_prompt_dismissed = true;
                let _ = sqlx::query("UPDATE ai.identity SET referred_by_iid = $1, meta = meta || '{\"referral_prompt_dismissed\": true}'::jsonb WHERE id = $2")
                    .bind(parent_iid)
                    .bind(iid)
                    .execute(pool)
                    .await;
                let _ = sqlx::query("INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent) VALUES ($1, $2, 25) ON CONFLICT DO NOTHING")
                    .bind(parent_iid)
                    .bind(iid)
                    .execute(pool)
                    .await;
                if !special {
                    let _ = sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1 WHERE code = $1")
                        .bind(&code_norm)
                        .execute(pool)
                        .await;
                }
                const BONUS_IDR: f64 = 10_000.0;
                let bonus_usd = BONUS_IDR / 17_630.0;
                balance_idr += BONUS_IDR;
                balance_usd += bonus_usd;
                let _ = sqlx::query(
                    r#"
                    UPDATE ai.billing_account SET balance_idr = balance_idr + $2, balance_usd = balance_usd + $3, updated_ts = NOW()
                    WHERE owner_iid = $1
                    "#,
                )
                .bind(iid)
                .bind(BONUS_IDR)
                .bind(bonus_usd)
                .execute(pool)
                .await;
            }
        } else {
            return bad("Invalid or expired referral code.");
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
        alien_id_opt.as_deref(),
        &email,
        None,
        balance_usd,
        balance_idr,
        referred_by_iid,
        referral_prompt_dismissed,
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
    let handle_q = match &ident {
        LoginIdent::AlienId(a) => a.clone(),
        LoginIdent::Email(e) if e.ends_with("@alienai.id") => {
            e.trim_end_matches("@alienai.id").to_string()
        }
        _ => {
            if login.starts_with('@') {
                login.trim_start_matches('@').to_string()
            } else {
                login.clone()
            }
        }
    };
    let row = match db_retry(pool, || async {
        sqlx::query(
            r#"
            SELECT ip.identity_iid, ip.secret_hash, i.name, i.alien_id, i.pic, i.referred_by_iid, i.meta,
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
    })
    .await
    {
        Ok(Some(r)) => r,
        Ok(None) => return unauthorized("Invalid username/email or password."),
        Err(e) => return err(format!("Database error: {e}")),
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
    let referred_by_iid: Option<i64> = row.try_get("referred_by_iid").ok().flatten();
    let meta: serde_json::Value = row.try_get("meta").unwrap_or_else(|_| json!({}));
    let referral_prompt_dismissed = meta.get("referral_prompt_dismissed").and_then(|v| v.as_bool()).unwrap_or(false);

    let ip = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    let ua = headers.get(header::USER_AGENT).and_then(|v| v.to_str().ok());
    let token = match auth_session_create(pool, iid, ip, ua).await {
        Ok(t) => t,
        Err(e) => return err(format!("Session creation failed: {e}")),
    };
    auth_response(
        iid,
        &name,
        alien_id.as_deref(),
        &email,
        pic.as_deref(),
        balance_usd,
        balance_idr,
        referred_by_iid,
        referral_prompt_dismissed,
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
        SELECT i.id, i.name, i.alien_id, i.pic, i.referred_by_iid, i.meta,
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
        Some(r) => {
            let alien_id: Option<String> = r.get("alien_id");
            let handle = alien_id
                .as_deref()
                .map(|s| s.trim())
                .filter(|s| !s.is_empty())
                .map(alien_id_display)
                .unwrap_or_default();
            let meta: serde_json::Value = r.try_get("meta").unwrap_or_else(|_| json!({}));
            let referral_prompt_dismissed = meta.get("referral_prompt_dismissed").and_then(|v| v.as_bool()).unwrap_or(false);
            let referred_by_iid: Option<i64> = r.try_get("referred_by_iid").ok().flatten();

            Json(json!({
                "ok": true,
                "identity": {
                    "id": iid,
                    "name": r.get::<String, _>("name"),
                    "handle": handle,
                    "alien_id": alien_id,
                    "email": r.get::<String, _>("email"),
                    "avatar_url": r.get::<Option<String>, _>("pic"),
                    "balance_usd": r.try_get::<f64, _>("balance_usd").unwrap_or(0.0),
                    "balance_idr": r.try_get::<f64, _>("balance_idr").unwrap_or(0.0),
                    "is_root": r.get::<String, _>("is_root") == "true",
                    "referred_by_iid": referred_by_iid,
                    "referral_prompt_dismissed": referral_prompt_dismissed,
                }
            }))
            .into_response()
        }
        None => (
            StatusCode::NOT_FOUND,
            Json(json!({ "error": "User identity not found" })),
        )
            .into_response(),
    }
}

#[derive(Debug, Deserialize)]
pub struct ReferralLookupQ {
    pub code: Option<String>,
}

pub async fn referral_lookup(
    State(st): State<AppState>,
    Query(q): Query<ReferralLookupQ>,
) -> Response {
    let raw = q.code.as_deref().unwrap_or("").trim();
    let norm = referral_code_norm(raw);
    if norm.is_empty() {
        return Json(json!({
            "valid": false,
            "code": "",
            "issuer_name": "",
            "issuer_pic": "",
            "allow_short_id": false,
            "type": ""
        }))
        .into_response();
    }
    if referral_code_is_special(&norm) {
        return Json(json!({
            "valid": true,
            "code": norm,
            "issuer_name": "Alien AI",
            "issuer_pic": "",
            "allow_short_id": true,
            "type": "referral"
        }))
        .into_response();
    }
    let row = sqlx::query(
        r#"
        SELECT rc.code, rc.issued_by_iid, i.name AS issuer_name, COALESCE(i.pic, '') AS issuer_pic,
               COALESCE((rc.meta->>'allow_short_id')::boolean, false) AS allow_short_id
        FROM ai.referral_code rc
        JOIN ai.identity i ON i.id = rc.issued_by_iid
        WHERE rc.code = $1 AND (rc.expires_at IS NULL OR rc.expires_at > NOW())
        LIMIT 1
        "#,
    )
    .bind(&norm)
    .fetch_optional(&st.pool)
    .await
    .ok()
    .flatten();

    match row {
        Some(r) => {
            let issuer_name: String = r.get("issuer_name");
            let issuer_pic: String = r.get("issuer_pic");
            let allow_short_id: bool = r.try_get("allow_short_id").unwrap_or(false);
            Json(json!({
                "valid": true,
                "code": norm,
                "issuer_name": issuer_name,
                "issuer_pic": issuer_pic,
                "allow_short_id": allow_short_id,
                "type": "referral"
            }))
            .into_response()
        }
        None => Json(json!({
            "valid": false,
            "code": norm,
            "issuer_name": "",
            "issuer_pic": "",
            "allow_short_id": false,
            "type": ""
        }))
        .into_response(),
    }
}

#[derive(Debug, Deserialize)]
pub struct ReferralClaimReq {
    pub code: String,
}

pub async fn referral_claim(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<ReferralClaimReq>,
) -> Response {
    let token = match auth_token_extract(&headers, None) {
        Some(t) => t,
        None => return unauthorized("Missing session token."),
    };
    let iid = match crate::auth_session::auth_session_resolve(&st.pool, &token).await {
        Ok(Some(id)) => id,
        _ => return unauthorized("Invalid or expired session."),
    };
    let pool = &st.pool;
    let existing_ref: Option<Option<i64>> = sqlx::query_scalar(
        "SELECT referred_by_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    if let Some(Some(ref_id)) = existing_ref {
        if ref_id > 0 {
            return bad("Account already has a referral upline.");
        }
    }

    let code_norm = referral_code_norm(&req.code);
    if code_norm.is_empty() {
        return bad("Referral code is required.");
    }
    let special = referral_code_is_special(&code_norm);
    let (parent_iid, issuer_name) = if special {
        (99000, "Alien AI".to_string())
    } else {
        let row = sqlx::query(
            r#"
            SELECT rc.issued_by_iid, i.name AS issuer_name
            FROM ai.referral_code rc
            JOIN ai.identity i ON i.id = rc.issued_by_iid
            WHERE rc.code = $1 AND (rc.expires_at IS NULL OR rc.expires_at > NOW())
            LIMIT 1
            "#,
        )
        .bind(&code_norm)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten();

        match row {
            Some(r) => (
                r.get::<i64, _>("issued_by_iid"),
                r.get::<String, _>("issuer_name"),
            ),
            None => return bad("Invalid or expired referral code."),
        }
    };

    if parent_iid == iid {
        return bad("Cannot refer yourself.");
    }

    let _ = sqlx::query(
        "UPDATE ai.identity SET referred_by_iid = $1, meta = meta || '{\"referral_prompt_dismissed\": true}'::jsonb, updated_ts = NOW() WHERE id = $2",
    )
    .bind(parent_iid)
    .bind(iid)
    .execute(pool)
    .await;

    let _ = sqlx::query(
        "INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent) VALUES ($1, $2, 25) ON CONFLICT DO NOTHING",
    )
    .bind(parent_iid)
    .bind(iid)
    .execute(pool)
    .await;

    if !special {
        let _ = sqlx::query(
            "UPDATE ai.referral_code SET used_count = used_count + 1 WHERE code = $1",
        )
        .bind(&code_norm)
        .execute(pool)
        .await;
    }

    const BONUS_IDR: f64 = 10_000.0;
    let bonus_usd = BONUS_IDR / 17_630.0;
    let _ = sqlx::query(
        r#"
        INSERT INTO ai.billing_account (id, owner_iid, balance_usd, balance_idr, plan_tier, billing_currency, fx_micro_per_usd)
        VALUES ($1, $2, $3, $4, 'free', 'IDR', 17630000000)
        ON CONFLICT (owner_iid) WHERE deleted_ts IS NULL
        DO UPDATE SET balance_idr = ai.billing_account.balance_idr + EXCLUDED.balance_idr,
                      balance_usd = ai.billing_account.balance_usd + EXCLUDED.balance_usd,
                      updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(iid)
    .bind(bonus_usd)
    .bind(BONUS_IDR)
    .execute(pool)
    .await;

    Json(json!({
        "ok": true,
        "bonus_idr": BONUS_IDR,
        "issuer_name": issuer_name
    }))
    .into_response()
}

pub async fn referral_dismiss(
    State(st): State<AppState>,
    headers: HeaderMap,
) -> Response {
    let token = match auth_token_extract(&headers, None) {
        Some(t) => t,
        None => return unauthorized("Missing session token."),
    };
    let iid = match crate::auth_session::auth_session_resolve(&st.pool, &token).await {
        Ok(Some(id)) => id,
        _ => return unauthorized("Invalid or expired session."),
    };
    let _ = sqlx::query(
        "UPDATE ai.identity SET meta = meta || '{\"referral_prompt_dismissed\": true}'::jsonb, updated_ts = NOW() WHERE id = $1",
    )
    .bind(iid)
    .execute(&st.pool)
    .await;
    Json(json!({ "ok": true })).into_response()
}

#[derive(Debug, Deserialize)]
pub struct AlienIdCheckQ {
    pub alien_id: Option<String>,
    pub referral_code: Option<String>,
}

pub async fn alien_id_check(
    State(st): State<AppState>,
    Query(q): Query<AlienIdCheckQ>,
) -> Response {
    let raw = q.alien_id.as_deref().unwrap_or("").trim();
    let norm = raw.trim_start_matches('@').to_lowercase();
    if norm.is_empty() {
        return Json(json!({ "available": false, "message": "Alien ID cannot be empty" }))
            .into_response();
    }
    if !alien_id_valid(&norm) {
        return Json(json!({ "available": false, "message": "Only lowercase letters, numbers, _ and - allowed" }))
            .into_response();
    }
    let ref_norm = referral_code_norm(q.referral_code.as_deref().unwrap_or(""));
    let allows_short = if referral_code_is_special(&ref_norm) {
        true
    } else if !ref_norm.is_empty() {
        sqlx::query_scalar::<_, bool>(
            "SELECT COALESCE((meta->>'allow_short_id')::boolean, false) FROM ai.referral_code WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1",
        )
        .bind(&ref_norm)
        .fetch_optional(&st.pool)
        .await
        .ok()
        .flatten()
        .unwrap_or(false)
    } else {
        false
    };

    if norm.len() < 7 && !allows_short {
        return Json(json!({
            "available": false,
            "message": "Minimum 7 characters (or use a special referral code for short IDs)"
        }))
        .into_response();
    }

    let taken = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM ai.identity WHERE LOWER(alien_id) = LOWER($1) AND deleted_ts IS NULL)",
    )
    .bind(&norm)
    .fetch_one(&st.pool)
    .await
    .unwrap_or(false);

    if taken {
        Json(json!({ "available": false, "message": "Alien ID already taken" })).into_response()
    } else {
        Json(json!({ "available": true, "message": "Available" })).into_response()
    }
}

#[derive(Debug, Deserialize)]
pub struct AlienIdClaimReq {
    pub alien_id: String,
    pub referral_code: Option<String>,
}

pub async fn alien_id_claim(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<AlienIdClaimReq>,
) -> Response {
    let token = match auth_token_extract(&headers, None) {
        Some(t) => t,
        None => return unauthorized("Missing session token."),
    };
    let iid = match crate::auth_session::auth_session_resolve(&st.pool, &token).await {
        Ok(Some(id)) => id,
        _ => return unauthorized("Invalid or expired session."),
    };
    let pool = &st.pool;
    let existing_alien: Option<Option<String>> = sqlx::query_scalar(
        "SELECT alien_id FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();

    if let Some(Some(ref cur)) = existing_alien {
        if !cur.trim().is_empty() {
            return bad("Alien ID is already set and cannot be changed.");
        }
    }

    let norm = req.alien_id.trim().trim_start_matches('@').to_lowercase();
    if norm.is_empty() || !alien_id_valid(&norm) {
        return bad("Invalid Alien ID format. Use lowercase letters, digits, _ and -.");
    }
    let ref_norm = referral_code_norm(req.referral_code.as_deref().unwrap_or(""));
    let allows_short = if referral_code_is_special(&ref_norm) {
        true
    } else if !ref_norm.is_empty() {
        sqlx::query_scalar::<_, bool>(
            "SELECT COALESCE((meta->>'allow_short_id')::boolean, false) FROM ai.referral_code WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1",
        )
        .bind(&ref_norm)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        .unwrap_or(false)
    } else {
        false
    };

    if norm.len() < 7 && !allows_short {
        return bad("Minimum 7 characters required for Alien ID (or enter a referral code allowing short IDs).");
    }

    let taken = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM ai.identity WHERE LOWER(alien_id) = LOWER($1) AND id != $2 AND deleted_ts IS NULL)",
    )
    .bind(&norm)
    .bind(iid)
    .fetch_one(pool)
    .await
    .unwrap_or(false);

    if taken {
        return conflict("Alien ID is already taken.");
    }

    let res = sqlx::query(
        "UPDATE ai.identity SET alien_id = $1, updated_ts = NOW() WHERE id = $2 AND (alien_id IS NULL OR alien_id = '')",
    )
    .bind(&norm)
    .bind(iid)
    .execute(pool)
    .await;

    match res {
        Ok(r) if r.rows_affected() > 0 => {
            if !ref_norm.is_empty() {
                let has_ref = sqlx::query_scalar::<_, Option<i64>>(
                    "SELECT referred_by_iid FROM ai.identity WHERE id = $1",
                )
                .bind(iid)
                .fetch_optional(pool)
                .await
                .ok()
                .flatten()
                .flatten()
                .is_some();

                if !has_ref {
                    let special = referral_code_is_special(&ref_norm);
                    let parent_iid = if special {
                        Some(99000)
                    } else {
                        sqlx::query_scalar("SELECT issued_by_iid FROM ai.referral_code WHERE code = $1 AND (expires_at IS NULL OR expires_at > NOW()) LIMIT 1")
                            .bind(&ref_norm)
                            .fetch_optional(pool)
                            .await
                            .ok()
                            .flatten()
                    };

                    if let Some(pid) = parent_iid {
                        if pid != iid {
                            let _ = sqlx::query("UPDATE ai.identity SET referred_by_iid = $1, meta = meta || '{\"referral_prompt_dismissed\": true}'::jsonb WHERE id = $2")
                                .bind(pid)
                                .bind(iid)
                                .execute(pool)
                                .await;
                            let _ = sqlx::query("INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent) VALUES ($1, $2, 25) ON CONFLICT DO NOTHING")
                                .bind(pid)
                                .bind(iid)
                                .execute(pool)
                                .await;
                            if !special {
                                let _ = sqlx::query("UPDATE ai.referral_code SET used_count = used_count + 1 WHERE code = $1")
                                    .bind(&ref_norm)
                                    .execute(pool)
                                    .await;
                            }
                            const BONUS_IDR: f64 = 10_000.0;
                            let bonus_usd = BONUS_IDR / 17_630.0;
                            let _ = sqlx::query(
                                r#"
                                UPDATE ai.billing_account SET balance_idr = balance_idr + $2, balance_usd = balance_usd + $3, updated_ts = NOW()
                                WHERE owner_iid = $1
                                "#,
                            )
                            .bind(iid)
                            .bind(BONUS_IDR)
                            .bind(bonus_usd)
                            .execute(pool)
                            .await;
                        }
                    }
                }
            }

            Json(json!({ "ok": true, "alien_id": norm })).into_response()
        }
        _ => bad("Failed to set Alien ID or already set."),
    }
}

fn auth_response(
    iid: i64,
    name: &str,
    alien_id: Option<&str>,
    email: &str,
    avatar_url: Option<&str>,
    balance_usd: f64,
    balance_idr: f64,
    referred_by_iid: Option<i64>,
    referral_prompt_dismissed: bool,
    token: &str,
) -> Response {
    let handle = alien_id
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(alien_id_display)
        .unwrap_or_default();
    let out = AuthResponse {
        ok: true,
        token: token.to_string(),
        identity: IdentityInfo {
            id: iid,
            name: name.to_string(),
            handle,
            alien_id: alien_id.map(str::to_string),
            email: email.to_string(),
            avatar_url: avatar_url.map(str::to_string),
            balance_usd,
            balance_idr,
            referred_by_iid,
            referral_prompt_dismissed,
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
