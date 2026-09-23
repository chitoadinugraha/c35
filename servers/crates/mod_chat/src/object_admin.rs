use c35_mod_admin::{require_root, AdminError};
use c35_proto::{
    ObjectAliasDoc, ObjectNormalizerDoc, ReqObjectAliasList, ReqObjectAliasPut,
    ReqObjectNormalizerList, ResObjectAliasList, ResObjectAliasPut, ResObjectNormalizerList,
};
use sqlx::PgPool;

#[derive(Debug)]
pub struct ObjectAdminError {
    pub status_code: i32,
    pub message: String,
}

impl ObjectAdminError {
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
            message: "object alias not found".into(),
        }
    }
}

fn name_norm(raw: &str) -> String {
    raw.trim().to_lowercase()
}

fn limit_or(default: i32, req_limit: i32) -> i64 {
    if req_limit > 0 {
        req_limit as i64
    } else {
        default as i64
    }
}

fn opt_trim(s: Option<&String>) -> Option<String> {
    s.map(|v| v.trim())
        .filter(|v| !v.is_empty())
        .map(|v| v.to_string())
}

type ObjectAliasDbRow = (
    i64,
    i64,
    String,
    String,
    String,
    bool,
    bool,
    String,
);

fn object_alias_doc_map(
    (id, obj_id, lang, name, name_norm, is_canonical, verified, obj_path): ObjectAliasDbRow,
) -> ObjectAliasDoc {
    ObjectAliasDoc {
        id,
        obj_id,
        lang,
        name,
        name_norm,
        is_canonical,
        verified,
        obj_path,
    }
}

type ObjectNormalizerDbRow = (i64, String, Option<i64>, String, i16, String);

fn object_normalizer_doc_map(
    (id, slug, parent_id, path, depth, kind): ObjectNormalizerDbRow,
) -> ObjectNormalizerDoc {
    ObjectNormalizerDoc {
        id,
        slug,
        parent_id: parent_id.unwrap_or(0),
        path,
        depth: depth as i32,
        kind,
    }
}

pub async fn object_alias_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqObjectAliasList,
) -> Result<ResObjectAliasList, ObjectAdminError> {
    require_root(pool, viewer_iid)
        .await
        .map_err(ObjectAdminError::from_admin)?;

    let verified = req.verified;
    let lang = opt_trim(req.lang.as_ref());
    let q = opt_trim(req.q.as_ref());
    let limit = limit_or(200, req.limit);

    let rows = sqlx::query_as::<_, ObjectAliasDbRow>(
        "SELECT a.id, a.obj_id, a.lang, a.name, a.name_norm, a.is_canonical, a.verified, o.path AS obj_path \
         FROM ai.object_alias a \
         JOIN ai.object_normalizer o ON o.id = a.obj_id \
         WHERE ($1::bool IS NULL OR a.verified = $1) \
           AND ($2::text IS NULL OR a.lang = $2) \
           AND ($3::text IS NULL OR a.name_norm ILIKE '%' || $3 || '%') \
         ORDER BY a.verified ASC, a.created_ts DESC \
         LIMIT $4",
    )
    .bind(verified)
    .bind(lang)
    .bind(q)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(|e| ObjectAdminError::bad(e.to_string()))?;

    Ok(ResObjectAliasList {
        items: rows.into_iter().map(object_alias_doc_map).collect(),
    })
}

pub async fn object_alias_put(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqObjectAliasPut,
) -> Result<ResObjectAliasPut, ObjectAdminError> {
    require_root(pool, viewer_iid)
        .await
        .map_err(ObjectAdminError::from_admin)?;

    let doc = req.doc.unwrap_or_default();
    if doc.id <= 0 {
        return Err(ObjectAdminError::bad("id required"));
    }
    let name = doc.name.trim();
    if name.is_empty() {
        return Err(ObjectAdminError::bad("name required"));
    }
    let name_norm_val = name_norm(name);

    let row = sqlx::query_as::<_, ObjectAliasDbRow>(
        "UPDATE ai.object_alias a \
         SET verified = $2, name = $3, is_canonical = $4, name_norm = $5, updated_ts = NOW() \
         FROM ai.object_normalizer o \
         WHERE a.id = $1 AND o.id = a.obj_id \
         RETURNING a.id, a.obj_id, a.lang, a.name, a.name_norm, a.is_canonical, a.verified, o.path AS obj_path",
    )
    .bind(doc.id)
    .bind(doc.verified)
    .bind(name)
    .bind(doc.is_canonical)
    .bind(&name_norm_val)
    .fetch_optional(pool)
    .await
    .map_err(|e| ObjectAdminError::bad(e.to_string()))?;

    let saved = row.map(object_alias_doc_map).ok_or_else(ObjectAdminError::not_found)?;
    Ok(ResObjectAliasPut { doc: Some(saved) })
}

pub async fn object_normalizer_list(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqObjectNormalizerList,
) -> Result<ResObjectNormalizerList, ObjectAdminError> {
    require_root(pool, viewer_iid)
        .await
        .map_err(ObjectAdminError::from_admin)?;

    let q = opt_trim(req.q.as_ref());
    let limit = limit_or(100, req.limit);

    let rows = sqlx::query_as::<_, ObjectNormalizerDbRow>(
        "SELECT id, slug, parent_id, path, depth, kind \
         FROM ai.object_normalizer \
         WHERE ($1::text IS NULL OR path ILIKE $1 || '%') \
         ORDER BY path ASC \
         LIMIT $2",
    )
    .bind(q)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(|e| ObjectAdminError::bad(e.to_string()))?;

    Ok(ResObjectNormalizerList {
        items: rows.into_iter().map(object_normalizer_doc_map).collect(),
    })
}
