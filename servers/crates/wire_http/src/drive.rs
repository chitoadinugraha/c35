use axum::extract::{DefaultBodyLimit, Query, State};
use axum::http::{header, HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_device::{agent_session_resolve, AgentSession};
use c35_mod_drive::{
    drive_changes_list, drive_file_delete, drive_file_put, drive_normalize_path,
    drive_path_updated_ts_ms, drive_storage_snapshot, drive_sync_cursor_ms, drive_tree_list,
    DriveFileOpResponse, DrivePutError,
};
use serde::Deserialize;

use crate::drive_notify::drive_mutation_notify;
use c35_mod_file::{upload_file_session_handler, CAS_UPLOAD_MAX_BYTES};
use c35_mod_identity::auth_session_caller_iid;
pub fn drive_router() -> Router<AppState> {
    Router::new()
        .route("/v1/agent/storage", get(agent_storage))
        .route("/v1/file/tree", get(file_tree))
        .route("/v1/file/changes", get(file_changes))
        .route("/v1/file/sync_cursor", get(file_sync_cursor))
        .route(
            "/v1/file/upload",
            post(file_upload).layer(DefaultBodyLimit::max(CAS_UPLOAD_MAX_BYTES)),
        )
        .route("/v1/file/delete", post(file_delete))
        .route("/v1/file/lock", post(file_lock))
        .route("/v1/drive/storage", get(drive_storage_user))
        .route("/v1/drive/tree", get(drive_tree_user))
        .route("/v1/drive/upload", post(drive_upload_user))
        .route("/v1/drive/delete", post(drive_delete_user))
}

fn session_key_from_headers(headers: &HeaderMap) -> Option<&str> {
    headers
        .get("X-Device-Session")
        .or_else(|| headers.get("x-device-session"))
        .and_then(|v| v.to_str().ok())
        .map(str::trim)
        .filter(|s| !s.is_empty())
}

async fn resolve_agent_owner(
    st: &AppState,
    headers: &HeaderMap,
) -> Result<AgentSession, (StatusCode, String)> {
    let session_key = session_key_from_headers(headers).unwrap_or("");
    match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => Ok(s),
        Ok(None) => Err((StatusCode::UNAUTHORIZED, "invalid session".into())),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, e)),
    }
}

async fn agent_storage(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session = match resolve_agent_owner(&st, &headers).await {
        Ok(s) => s,
        Err(e) => return e.into_response(),
    };
    match drive_storage_snapshot(&st.pool, session.owner_iid).await {
        Ok(snap) => Json(snap).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

async fn file_tree(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session = match resolve_agent_owner(&st, &headers).await {
        Ok(s) => s,
        Err(e) => return e.into_response(),
    };
    match drive_tree_list(&st.pool, session.owner_iid).await {
        Ok(items) => Json(items).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

#[derive(Debug, Deserialize)]
struct FileChangesQuery {
    since_ms: Option<i64>,
    limit: Option<i64>,
}

async fn file_changes(
    State(st): State<AppState>,
    headers: HeaderMap,
    Query(q): Query<FileChangesQuery>,
) -> impl IntoResponse {
    let session = match resolve_agent_owner(&st, &headers).await {
        Ok(s) => s,
        Err(e) => return e.into_response(),
    };
    let since_ms = q.since_ms.unwrap_or(0);
    let limit = q.limit.unwrap_or(500);
    match drive_changes_list(&st.pool, session.owner_iid, since_ms, limit).await {
        Ok(page) => Json(page).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

async fn file_sync_cursor(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session = match resolve_agent_owner(&st, &headers).await {
        Ok(s) => s,
        Err(e) => return e.into_response(),
    };
    match drive_sync_cursor_ms(&st.pool, session.owner_iid).await {
        Ok(ms) => Json(serde_json::json!({ "since_ms": ms })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

async fn file_upload(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    if session_key_from_headers(&headers).is_some() {
        if let Ok(session) = resolve_agent_owner(&st, &headers).await {
            return drive_upload_inner(&st, session.owner_iid, &headers, body, "agent").await;
        }
    }
    upload_file_session_handler(State(st), headers, body).await.into_response()
}

async fn file_delete(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let session = match resolve_agent_owner(&st, &headers).await {
        Ok(s) => s,
        Err(e) => return e.into_response(),
    };
    drive_delete_inner(&st, session.owner_iid, body, "agent").await
}


async fn file_lock() -> impl IntoResponse {
    StatusCode::OK
}

async fn drive_storage_user(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let owner_iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return (StatusCode::UNAUTHORIZED, "unauthorized").into_response(),
    };
    match drive_storage_snapshot(&st.pool, owner_iid).await {
        Ok(snap) => Json(snap).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}
async fn drive_tree_user(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let owner_iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return (StatusCode::UNAUTHORIZED, "unauthorized").into_response(),
    };
    match drive_tree_list(&st.pool, owner_iid).await {
        Ok(items) => Json(items).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

async fn drive_upload_user(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let owner_iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return (StatusCode::UNAUTHORIZED, "unauthorized").into_response(),
    };
    drive_upload_inner(&st, owner_iid, &headers, body, "app").await
}

async fn drive_delete_user(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let owner_iid = match auth_session_caller_iid(&st.pool, &headers, None).await {
        Some(id) if id > 0 => id,
        _ => return (StatusCode::UNAUTHORIZED, "unauthorized").into_response(),
    };
    drive_delete_inner(&st, owner_iid, body, "app").await
}

async fn drive_upload_inner(
    st: &AppState,
    owner_iid: i64,
    headers: &HeaderMap,
    body: axum::body::Bytes,
    source: &str,
) -> axum::response::Response {
    if body.is_empty() {
        return (StatusCode::BAD_REQUEST, "File body is empty").into_response();
    }
    let mime_type = headers
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("application/octet-stream");
    let file_path = headers
        .get("x-file-path")
        .or_else(|| headers.get("X-File-Path"))
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let file_name = headers
        .get("x-file-name")
        .or_else(|| headers.get("X-File-Name"))
        .and_then(|v| v.to_str().ok())
        .map(|s| urlencoding::decode(s).map(|c| c.into_owned()).unwrap_or_else(|_| s.to_string()));
    let path = file_path
        .or(file_name.map(|n| format!("/{n}")))
        .unwrap_or_default();
    let norm_path = drive_normalize_path(&path);
    match drive_file_put(
        &st.pool,
        &st.cas_dir,
        &st.cas_secret,
        &st.public_origin,
        owner_iid,
        &path,
        &body,
        mime_type,
    )
    .await
    {
        Ok(resp) => {
            if let Ok(since_ms) = drive_path_updated_ts_ms(&st.pool, owner_iid, &norm_path).await {
                drive_mutation_notify(st, owner_iid, &norm_path, since_ms, false, source).await;
            }
            Json(resp).into_response()
        }
        Err(DrivePutError::InvalidPath) => (StatusCode::BAD_REQUEST, "path required").into_response(),
        Err(DrivePutError::EmptyBody) => (StatusCode::BAD_REQUEST, "empty body").into_response(),
        Err(DrivePutError::Quota(q)) => (
            StatusCode::PAYLOAD_TOO_LARGE,
            Json(serde_json::json!({
                "error": "quota_exceeded",
                "storage_used_bytes": q.used_bytes,
                "storage_limit_bytes": q.limit_bytes,
            })),
        )
            .into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}

#[derive(Deserialize)]
struct FilePathBody {
    path: String,
}

async fn drive_delete_inner(
    st: &AppState,
    owner_iid: i64,
    body: axum::body::Bytes,
    source: &str,
) -> axum::response::Response {
    let req: FilePathBody = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(e) => return (StatusCode::BAD_REQUEST, format!("invalid json: {e}")).into_response(),
    };
    let norm_path = drive_normalize_path(&req.path);
    match drive_file_delete(&st.pool, owner_iid, &req.path).await {
        Ok(true) => {
            if let Ok(since_ms) = drive_path_updated_ts_ms(&st.pool, owner_iid, &norm_path).await {
                drive_mutation_notify(st, owner_iid, &norm_path, since_ms, true, source).await;
            }
            Json(DriveFileOpResponse {
                ok: true,
                path: norm_path,
            })
                .into_response()
        }
        Ok(false) => (StatusCode::NOT_FOUND, "file not found").into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response(),
    }
}
