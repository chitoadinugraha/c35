use async_nats::Client;
use c35_mod_admin::{require_admin, require_root, AdminError};
use c35_proto::{InstDoc, ReqInstDelete, ReqInstGet, ReqInstList, ReqInstPut, ResInstDelete, ResInstGet, ResInstList, ResInstPut};
use chrono::{DateTime, Utc};
use sqlx::PgPool;

pub const NATS_SUBJECT_PREFIX: &str = "c35.inst.";

#[derive(Debug)]
pub struct InstAdminError {
    pub status_code: i32,
    pub message: String,
}

impl InstAdminError {
    fn bad(msg: impl Into<String>) -> Self {
        Self {
            status_code: 400,
            message: msg.into(),
        }
    }

    fn from_admin(e: AdminError) -> Self {
        Self {
            status_code: e.status_code,
            message: e.message,
        }
    }

    fn not_found() -> Self {
        Self {
            status_code: 404,
            message: "inst not found".into(),
        }
    }
}

pub async fn inst_publish_invalidation(nats: Option<&Client>, inst_id: &str) {
    if inst_id.trim().is_empty() {
        return;
    }
    if let Some(nats) = nats {
        let subject = format!("{NATS_SUBJECT_PREFIX}{inst_id}");
        let _ = nats.publish(subject, inst_id.as_bytes().to_vec().into()).await;
    }
}

async fn viewer_is_root(pool: &PgPool, viewer_iid: i64) -> Result<bool, InstAdminError> {
    require_root(pool, viewer_iid)
        .await
        .map(|_| true)
        .or_else(|e| {
            if e.status_code == 403 {
                Ok(false)
            } else {
                Err(InstAdminError::from_admin(e))
            }
        })
}

fn partner_scope(viewer_iid: i64) -> String {
    format!("partner:{viewer_iid}")
}

fn scope_allowed(viewer_iid: i64, is_root: bool, scope: &str) -> bool {
    if is_root {
        return true;
    }
    scope == partner_scope(viewer_iid)
}

fn scope_requires_root(scope: &str) -> bool {
    scope == "global" || !scope.starts_with("partner:")
}

async fn require_scope_access(
    pool: &PgPool,
    viewer_iid: i64,
    scope: &str,
) -> Result<(), InstAdminError> {
    require_admin(pool, viewer_iid)
        .await
        .map_err(InstAdminError::from_admin)?;
    let is_root = viewer_is_root(pool, viewer_iid).await?;
    if scope_requires_root(scope) && !is_root {
        return Err(InstAdminError {
            status_code: 403,
            message: "root required for global scope".into(),
        });
    }
    if !scope_allowed(viewer_iid, is_root, scope) {
        return Err(InstAdminError {
            status_code: 403,
            message: "forbidden scope".into(),
        });
    }
    Ok(())
}

type InstAdminDbRow = (
    String,
    String,
    String,
    String,
    Vec<String>,
    String,
    Vec<String>,
    Vec<String>,
    Vec<String>,
    Vec<String>,
    i32,
    bool,
    String,
    DateTime<Utc>,
    DateTime<Utc>,
    Option<DateTime<Utc>>,
);

fn inst_doc_map(
    (
        id,
        scope,
        kind,
        topic_id,
        topics,
        inst,
        phrases,
        triggers,
        include_tools,
        exclude_tools,
        priority,
        enabled,
        def_hash,
        created_ts,
        updated_ts,
        deleted_ts,
    ): InstAdminDbRow,
) -> InstDoc {
    InstDoc {
        id,
        scope,
        kind,
        topic_id,
        topics,
        inst,
        phrases,
        triggers,
        include_tools,
        exclude_tools,
        priority,
        enabled: Some(enabled),
        def_hash,
        created_ts_ms: created_ts.timestamp_millis(),
        updated_ts_ms: updated_ts.timestamp_millis(),
        deleted_ts_ms: deleted_ts.map(|t| t.timestamp_millis()),
    }
}

async fn inst_fetch_doc(pool: &PgPool, id: &str) -> Result<InstDoc, InstAdminError> {
    let row = sqlx::query_as::<_, InstAdminDbRow>(
        "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
         FROM ai.inst WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(|e| InstAdminError::bad(e.to_string()))?;
    row.map(inst_doc_map).ok_or_else(InstAdminError::not_found)
}

pub async fn inst_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqInstList,
) -> Result<ResInstList, InstAdminError> {
    require_admin(pool, viewer_iid)
        .await
        .map_err(InstAdminError::from_admin)?;
    let is_root = viewer_is_root(pool, viewer_iid).await?;

    let scope_filter = req
        .scope
        .as_ref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .or_else(|| {
            if is_root {
                None
            } else {
                Some(partner_scope(viewer_iid))
            }
        });
    let kind_filter = req
        .kind
        .as_ref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string());

    let rows = match (scope_filter, kind_filter, req.enabled) {
        (Some(scope), Some(kind), Some(enabled)) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND scope = $2 AND kind = $3 AND enabled = $4 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(scope)
        .bind(kind)
        .bind(enabled)
        .fetch_all(pool)
        .await,
        (Some(scope), Some(kind), None) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND scope = $2 AND kind = $3 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(scope)
        .bind(kind)
        .fetch_all(pool)
        .await,
        (Some(scope), None, Some(enabled)) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND scope = $2 AND enabled = $3 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(scope)
        .bind(enabled)
        .fetch_all(pool)
        .await,
        (Some(scope), None, None) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND scope = $2 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(scope)
        .fetch_all(pool)
        .await,
        (None, Some(kind), Some(enabled)) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND kind = $2 AND enabled = $3 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(kind)
        .bind(enabled)
        .fetch_all(pool)
        .await,
        (None, Some(kind), None) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND kind = $2 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(kind)
        .fetch_all(pool)
        .await,
        (None, None, Some(enabled)) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) AND enabled = $2 \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .bind(enabled)
        .fetch_all(pool)
        .await,
        (None, None, None) => sqlx::query_as::<_, InstAdminDbRow>(
            "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, created_ts, updated_ts, deleted_ts \
             FROM ai.inst WHERE ($1::bool OR deleted_ts IS NULL) \
             ORDER BY priority DESC, id ASC",
        )
        .bind(req.include_deleted)
        .fetch_all(pool)
        .await,
    }
    .map_err(|e| InstAdminError::bad(e.to_string()))?;

    Ok(ResInstList {
        items: rows.into_iter().map(inst_doc_map).collect(),
    })
}

pub async fn inst_get(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqInstGet,
) -> Result<ResInstGet, InstAdminError> {
    let id = req.id.trim();
    if id.is_empty() {
        return Err(InstAdminError::bad("id required"));
    }
    require_admin(pool, viewer_iid)
        .await
        .map_err(InstAdminError::from_admin)?;
    let doc = inst_fetch_doc(pool, id).await?;
    let is_root = viewer_is_root(pool, viewer_iid).await?;
    if !scope_allowed(viewer_iid, is_root, &doc.scope) {
        return Err(InstAdminError {
            status_code: 403,
            message: "forbidden".into(),
        });
    }
    Ok(ResInstGet { item: Some(doc) })
}

pub async fn inst_put(
    pool: &PgPool,
    nats: Option<&Client>,
    viewer_iid: i64,
    req: ReqInstPut,
) -> Result<ResInstPut, InstAdminError> {
    let doc = req.doc.unwrap_or_default();
    let id = doc.id.trim();
    if id.is_empty() {
        return Err(InstAdminError::bad("id required"));
    }
    if doc.inst.trim().is_empty() {
        return Err(InstAdminError::bad("inst body required"));
    }
    let scope = if doc.scope.trim().is_empty() {
        "global".to_string()
    } else {
        doc.scope.trim().to_string()
    };
    require_scope_access(pool, viewer_iid, &scope).await?;

    let kind = if doc.kind.trim().is_empty() {
        "task".to_string()
    } else {
        doc.kind.trim().to_string()
    };
    let enabled = doc.enabled.unwrap_or(true);

    sqlx::query(
        r#"
        INSERT INTO ai.inst (
            id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority, enabled, def_hash, updated_ts, deleted_ts
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NULL
        )
        ON CONFLICT (id) DO UPDATE SET
            scope = EXCLUDED.scope,
            kind = EXCLUDED.kind,
            topic_id = EXCLUDED.topic_id,
            topics = EXCLUDED.topics,
            inst = EXCLUDED.inst,
            phrases = EXCLUDED.phrases,
            triggers = EXCLUDED.triggers,
            include_tools = EXCLUDED.include_tools,
            exclude_tools = EXCLUDED.exclude_tools,
            priority = EXCLUDED.priority,
            enabled = EXCLUDED.enabled,
            def_hash = EXCLUDED.def_hash,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(id)
    .bind(&scope)
    .bind(&kind)
    .bind(doc.topic_id.trim())
    .bind(&doc.topics)
    .bind(doc.inst.trim())
    .bind(&doc.phrases)
    .bind(&doc.triggers)
    .bind(&doc.include_tools)
    .bind(&doc.exclude_tools)
    .bind(doc.priority)
    .bind(enabled)
    .bind(doc.def_hash.trim())
    .execute(pool)
    .await
    .map_err(|e| InstAdminError::bad(e.to_string()))?;

    inst_publish_invalidation(nats, id).await;
    let saved = inst_fetch_doc(pool, id).await?;
    Ok(ResInstPut { doc: Some(saved) })
}

pub async fn inst_delete(
    pool: &PgPool,
    nats: Option<&Client>,
    viewer_iid: i64,
    req: ReqInstDelete,
) -> Result<ResInstDelete, InstAdminError> {
    let id = req.id.trim();
    if id.is_empty() {
        return Err(InstAdminError::bad("id required"));
    }
    require_admin(pool, viewer_iid)
        .await
        .map_err(InstAdminError::from_admin)?;

    let existing = inst_fetch_doc(pool, id).await?;
    let is_root = viewer_is_root(pool, viewer_iid).await?;
    if !scope_allowed(viewer_iid, is_root, &existing.scope) {
        return Err(InstAdminError {
            status_code: 403,
            message: "forbidden".into(),
        });
    }
    if scope_requires_root(&existing.scope) && !is_root {
        return Err(InstAdminError {
            status_code: 403,
            message: "root required for global scope".into(),
        });
    }

    let updated = sqlx::query(
        "UPDATE ai.inst SET deleted_ts = NOW(), updated_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(id)
    .execute(pool)
    .await
    .map_err(|e| InstAdminError::bad(e.to_string()))?;
    if updated.rows_affected() == 0 {
        return Err(InstAdminError::not_found());
    }

    inst_publish_invalidation(nats, id).await;
    Ok(ResInstDelete {})
}
