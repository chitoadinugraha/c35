mod codes;
mod commission;
mod stats;

pub use codes::{referral_code_doc_from_row, referral_code_meta_from_doc, referral_package_get, ReferralPackage};
pub use commission::{commission_accrue_on_purchase, commission_simulate, MARKETING_POOL_RATE};
pub use stats::referral_user_stats;

use c35_mod_admin::require_admin;
use c35_proto::{
    ReferralCodeDoc, ReferralShareDoc, ReferralTreeNode, ReferralTreeSlice,
};
use sqlx::{PgPool, Row};

use codes::normalize_code;

const REFERRAL_TREE_SELECT: &str = r#"
        SELECT DISTINCT ON (t.id) t.id, t.name, t.alien_id, t.pic,
               COALESCE(t.referred_by, 0) AS referred_by, t.is_active, t.meta,
               COALESCE(cc.n, 0) AS child_count
        FROM tree t
        LEFT JOIN (
            SELECT i.referred_by_iid, COUNT(*)::bigint AS n
            FROM ai.identity i
            INNER JOIN tree t2 ON i.referred_by_iid = t2.id
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL
            GROUP BY i.referred_by_iid
        ) cc ON cc.referred_by_iid = t.id
        ORDER BY t.id, t.depth
"#;

fn meta_is_root(meta: &serde_json::Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

fn alien_id_handle(alien_id: Option<String>) -> String {
    let a = alien_id.unwrap_or_default();
    let a = a.trim().trim_start_matches('@');
    if a.is_empty() {
        "@user".into()
    } else {
        format!("@{a}")
    }
}

async fn referral_wide_access(pool: &PgPool, viewer_iid: i64) -> bool {
    require_admin(pool, viewer_iid).await.is_ok()
}

async fn referral_descends_from(pool: &PgPool, ancestor: i64, node: i64) -> bool {
    sqlx::query_scalar::<_, bool>(
        r#"
        WITH RECURSIVE up AS (
            SELECT id, referred_by_iid, 0 AS depth FROM ai.identity WHERE id = $1
            UNION ALL
            SELECT i.id, i.referred_by_iid, u.depth + 1
            FROM ai.identity i
            JOIN up u ON i.id = u.referred_by_iid
            WHERE u.depth < 32 AND i.id <> u.id
        )
        SELECT EXISTS (SELECT 1 FROM up WHERE id = $2)
        "#,
    )
    .bind(node)
    .bind(ancestor)
    .fetch_one(pool)
    .await
    .unwrap_or(false)
}

async fn referral_tree_rows_direct_branch(pool: &PgPool, parent_id: i64) -> Vec<sqlx::postgres::PgRow> {
    sqlx::query(&format!(
        r#"
        WITH tree AS (
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0) AS referred_by,
                   i.is_active, i.meta, 0 AS depth
            FROM ai.identity i
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL AND i.id = $1
            UNION ALL
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0),
                   i.is_active, i.meta, 1 AS depth
            FROM ai.identity i
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL AND i.referred_by_iid = $1
        )
        {REFERRAL_TREE_SELECT}
        "#
    ))
    .bind(parent_id)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
}

async fn referral_tree_rows_from_id(pool: &PgPool, start: i64, depth: i32) -> Vec<sqlx::postgres::PgRow> {
    sqlx::query(&format!(
        r#"
        WITH RECURSIVE tree AS (
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0) AS referred_by,
                   i.is_active, i.meta, 0 AS depth
            FROM ai.identity i
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL AND i.id = $1
            UNION ALL
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0),
                   i.is_active, i.meta, t.depth + 1
            FROM ai.identity i
            JOIN tree t ON i.referred_by_iid = t.id
            WHERE t.depth < $2 AND i.kind = 'user' AND i.deleted_ts IS NULL
        )
        {REFERRAL_TREE_SELECT}
        "#
    ))
    .bind(start)
    .bind(depth)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
}

async fn referral_tree_rows_forest(pool: &PgPool, viewer_iid: i64, depth: i32) -> Vec<sqlx::postgres::PgRow> {
    sqlx::query(&format!(
        r#"
        WITH RECURSIVE tree AS (
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0) AS referred_by,
                   i.is_active, i.meta, 0 AS depth
            FROM ai.identity i
            WHERE i.kind = 'user' AND i.deleted_ts IS NULL
              AND (i.referred_by_iid IS NULL OR i.id = $1)
            UNION ALL
            SELECT i.id, i.name, i.alien_id, i.pic, COALESCE(i.referred_by_iid, 0),
                   i.is_active, i.meta, t.depth + 1
            FROM ai.identity i
            JOIN tree t ON i.referred_by_iid = t.id
            WHERE t.depth < $2 AND i.kind = 'user' AND i.deleted_ts IS NULL
        )
        {REFERRAL_TREE_SELECT}
        "#
    ))
    .bind(viewer_iid)
    .bind(depth)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
}

async fn referral_tree_shares(pool: &PgPool, ids: &[i64]) -> Vec<ReferralShareDoc> {
    if ids.is_empty() {
        return vec![];
    }
    sqlx::query(
        r#"SELECT parent_iid, child_iid, share_percent::float8 AS share_percent FROM ai.referral_share
           WHERE parent_iid = ANY($1) OR child_iid = ANY($1)"#,
    )
    .bind(ids)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
    .into_iter()
    .map(|r| ReferralShareDoc {
        parent_uid: r.get("parent_iid"),
        child_uid: r.get("child_iid"),
        share_percent: r.get::<f64, _>("share_percent") as i32,
    })
    .collect()
}

fn referral_tree_node_from_row(r: sqlx::postgres::PgRow) -> ReferralTreeNode {
    let meta: serde_json::Value = r.try_get("meta").unwrap_or(serde_json::json!({}));
    let is_root = meta_is_root(&meta);
    let roles = meta
        .get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();
    let active: bool = r.get("is_active");
    ReferralTreeNode {
        identity_id: r.get("id"),
        name: r.get("name"),
        email: String::new(),
        avatar_url: r.get::<Option<String>, _>("pic").unwrap_or_default(),
        handle: alien_id_handle(r.get("alien_id")),
        referred_by: r.get("referred_by"),
        child_count: r.get::<i64, _>("child_count") as i32,
        is_root,
        is_banned: !active,
        global_roles: roles,
    }
}

pub async fn referral_tree_get(
    pool: &PgPool,
    viewer_iid: i64,
    root_id: i64,
    depth: i32,
) -> ReferralTreeSlice {
    let depth = if depth > 0 && depth <= 8 { depth } else { 2 };
    let wide = referral_wide_access(pool, viewer_iid).await;
    let forest = wide && root_id <= 0;
    let rows = if forest {
        referral_tree_rows_forest(pool, viewer_iid, depth).await
    } else if depth == 1 && root_id > 0 {
        referral_tree_rows_direct_branch(pool, root_id).await
    } else {
        let mut start = if root_id > 0 { root_id } else { viewer_iid };
        if !wide && start != viewer_iid {
            let allowed = referral_descends_from(pool, viewer_iid, start).await;
            if !allowed {
                start = viewer_iid;
            }
        }
        referral_tree_rows_from_id(pool, start, depth).await
    };
    let nodes: Vec<ReferralTreeNode> = rows.into_iter().map(referral_tree_node_from_row).collect();
    let ids: Vec<i64> = nodes.iter().map(|n| n.identity_id).collect();
    let shares = referral_tree_shares(pool, &ids).await;
    ReferralTreeSlice {
        nodes,
        branch_shares: shares,
    }
}

pub async fn referral_share_set(
    pool: &PgPool,
    iid: i64,
    parent_uid: i64,
    child_uid: i64,
    percent: i32,
) -> Result<(), String> {
    let parent = if parent_uid > 0 { parent_uid } else { iid };
    if parent != iid {
        require_admin(pool, iid).await.map_err(|_| "forbidden".to_string())?;
    } else {
        let ok: bool = sqlx::query_scalar(
            "SELECT COALESCE(referred_by_iid, 0) = $1 FROM ai.identity WHERE id = $2 AND deleted_ts IS NULL",
        )
        .bind(parent)
        .bind(child_uid)
        .fetch_one(pool)
        .await
        .unwrap_or(false);
        if !ok {
            return Err("forbidden".into());
        }
    }
    let pct = percent.clamp(0, 35);
    sqlx::query(
        r#"
        INSERT INTO ai.referral_share (parent_iid, child_iid, share_percent, updated_ts)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (parent_iid, child_iid) DO UPDATE SET share_percent = EXCLUDED.share_percent, updated_ts = NOW()
        "#,
    )
    .bind(parent)
    .bind(child_uid)
    .bind(pct)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub async fn referral_code_list(pool: &PgPool, iid: i64) -> Vec<ReferralCodeDoc> {
    sqlx::query(
        r#"
        SELECT code, issued_by_iid, used_count,
               EXTRACT(EPOCH FROM expires_at) * 1000 AS expires_at_ms,
               COALESCE(meta, '{}'::jsonb) AS meta
        FROM ai.referral_code
        WHERE issued_by_iid = $1
        ORDER BY created_ts DESC
        LIMIT 50
        "#,
    )
    .bind(iid)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
    .into_iter()
    .map(|r| {
        referral_code_doc_from_row(
            &r.get::<String, _>("code"),
            r.get("issued_by_iid"),
            r.get("used_count"),
            r.get::<Option<f64>, _>("expires_at_ms").unwrap_or(0.0) as i64,
            r.try_get("meta").unwrap_or(serde_json::json!({})),
        )
    })
    .collect()
}

pub async fn referral_code_put(
    pool: &PgPool,
    iid: i64,
    doc: ReferralCodeDoc,
) -> Result<ReferralCodeDoc, String> {
    let code = normalize_code(&doc.code);
    if code.is_empty() {
        return Err("code required".into());
    }
    if code.len() > 64 {
        return Err("code too long".into());
    }
    let expires = if doc.expires_at_ms > 0 {
        chrono::DateTime::from_timestamp_millis(doc.expires_at_ms)
    } else {
        None
    };
    let meta = referral_code_meta_from_doc(&doc);
    sqlx::query(
        r#"
        INSERT INTO ai.referral_code (code, issued_by_iid, used_count, expires_at, meta)
        VALUES ($1, $2, COALESCE((SELECT used_count FROM ai.referral_code WHERE code = $1), 0), $3, $4::jsonb)
        ON CONFLICT (code) DO UPDATE SET expires_at = EXCLUDED.expires_at, meta = EXCLUDED.meta, updated_ts = NOW()
        WHERE ai.referral_code.issued_by_iid = $2
        "#,
    )
    .bind(&code)
    .bind(iid)
    .bind(expires)
    .bind(meta)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(ReferralCodeDoc {
        code,
        r#type: doc.r#type,
        name: doc.name,
        issued_by: iid,
        price_usd: doc.price_usd,
        duration_months: doc.duration_months,
        base_plan_slug: doc.base_plan_slug,
        max_uses: doc.max_uses,
        used_count: doc.used_count,
        expires_at_ms: doc.expires_at_ms,
    })
}

pub async fn referral_code_delete(pool: &PgPool, iid: i64, code: &str) -> Result<(), String> {
    let code = normalize_code(code);
    if code.is_empty() {
        return Err("code required".into());
    }
    let res = sqlx::query("DELETE FROM ai.referral_code WHERE code = $1 AND issued_by_iid = $2")
        .bind(&code)
        .bind(iid)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    if res.rows_affected() == 0 {
        return Err("code not found".into());
    }
    Ok(())
}

pub async fn referral_commission_simulate(
    pool: &PgPool,
    viewer_iid: i64,
    subject_iid: i64,
    purchase_amount: i64,
) -> Result<c35_proto::ResReferralCommissionSimulate, String> {
    if !referral_wide_access(pool, viewer_iid).await {
        return Err("forbidden".into());
    }
    let subject = if subject_iid > 0 { subject_iid } else { viewer_iid };
    commission_simulate(pool, subject, purchase_amount).await
}
