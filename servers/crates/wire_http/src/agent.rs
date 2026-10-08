use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_device::{
    agent_log_put, agent_presence_put, agent_profile_get, agent_session_resolve, remote_ice_config,
    AgentVersionReport,
};
use c35_proto::ReqRemoteIceConfig;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct AgentLogBody {
    pub kind: String,
    pub topic: String,
    pub text: String,
    #[serde(default)]
    pub meta: Option<serde_json::Value>,
}

pub fn agent_router() -> Router<AppState> {
    Router::new()
        .route("/v1/agent/log", post(agent_log))
        .route("/v1/agent/profile", get(agent_profile))
        .route("/v1/agent/ice", get(agent_ice))
        .route("/v1/agent/task/progress", post(agent_task_progress))
        .route("/v1/agent/task/done", post(agent_task_done))
        .route("/v1/skill/put", post(agent_skill_put))
}

fn session_key_from_headers(headers: &HeaderMap) -> Option<&str> {
    headers
        .get("X-Device-Session")
        .or_else(|| headers.get("x-device-session"))
        .and_then(|v| v.to_str().ok())
        .map(str::trim)
        .filter(|s| !s.is_empty())
}

async fn agent_ice(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    let agent_build = sqlx::query_scalar::<_, i64>(
        r#"SELECT COALESCE((meta->>'agent_build')::bigint, 0) FROM ai.identity WHERE id = $1"#,
    )
    .bind(session.device_iid)
    .fetch_optional(&st.pool)
    .await
    .ok()
    .flatten()
    .unwrap_or(0);

    let cfg = remote_ice_config(session.owner_iid, ReqRemoteIceConfig {});
    let servers: Vec<_> = cfg
        .ice_servers
        .into_iter()
        .filter_map(|mut s| {
            if agent_build < 31 {
                // Build 30 and earlier agents default credential_type to Unspecified,
                // causing Rust webrtc new_peer_connection to fail on TURN URLs.
                s.urls.retain(|u| !u.starts_with("turn:") && !u.starts_with("turns:"));
            }
            if s.urls.is_empty() {
                None
            } else {
                Some(serde_json::json!({
                    "urls": s.urls,
                    "username": s.username,
                    "credential": s.credential,
                }))
            }
        })
        .collect();

    let body = serde_json::json!({
        "ice_servers": servers,
        "ttl_sec": cfg.ttl_sec,
    });
    Json(body).into_response()
}

async fn agent_profile(State(st): State<AppState>, headers: HeaderMap) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    match agent_profile_get(&st.pool, &session).await {
        Ok(profile) => Json(profile).into_response(),
        Err(e) => (StatusCode::NOT_FOUND, e).into_response(),
    }
}

async fn agent_log(
    State(st): State<AppState>,
    headers: HeaderMap,
    Json(body): Json<AgentLogBody>,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };

    let presence_online = body.topic == "agent.ws" && body.text == "connected";
    let presence_offline = body.topic == "agent.ws" && body.text == "disconnected";
    if presence_online || presence_offline {
        let version = if presence_online {
            let build = body
                .meta
                .as_ref()
                .and_then(|m| m.get("agent_build"))
                .and_then(|v| v.as_i64())
                .unwrap_or(0);
            let version_name = body
                .meta
                .as_ref()
                .and_then(|m| m.get("agent_version_name"))
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            if build > 0 {
                Some(AgentVersionReport {
                    build,
                    version_name,
                })
            } else {
                None
            }
        } else {
            None
        };
        let _ = agent_presence_put(
            &st.pool,
            st.nats.as_ref(),
            session.device_iid,
            presence_online,
            version,
        )
        .await;
    }

    match agent_log_put(
        &st.pool,
        st.nats.as_ref(),
        session.device_iid,
        session.owner_iid,
        &body.kind,
        &body.topic,
        &body.text,
        body.meta,
    )
    .await
    {
        Ok(_) => StatusCode::OK.into_response(),
        Err(e) => (StatusCode::BAD_REQUEST, e).into_response(),
    }
}

async fn agent_task_progress(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    let ev: c35_proto::EvDeviceTaskProgress = match c35_proto::pb_decode(&body) {
        Ok(ev) => ev,
        Err(e) => return (StatusCode::BAD_REQUEST, format!("decode: {e}")).into_response(),
    };
    let meta: serde_json::Value = serde_json::from_str(&ev.meta_json).unwrap_or(serde_json::json!({}));
    c35_mod_task::task_run_progress_store(&st.pool, ev.run_id, &meta, &ev.text, ev.step_index).await;
    if let Some(run) = c35_mod_task::task_run_get(&st.pool, session.owner_iid, ev.run_id).await {
        c35_mod_task::task_run_push(st.nats.as_ref(), session.owner_iid, &run);
    }
    StatusCode::OK.into_response()
}

async fn agent_task_done(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    let session = match agent_session_resolve(&st.pool, session_key).await {
        Ok(Some(s)) => s,
        Ok(None) => return (StatusCode::UNAUTHORIZED, "invalid session").into_response(),
        Err(e) => return (StatusCode::INTERNAL_SERVER_ERROR, e).into_response(),
    };
    let ev: c35_proto::EvDeviceTaskDone = match c35_proto::pb_decode(&body) {
        Ok(ev) => ev,
        Err(e) => return (StatusCode::BAD_REQUEST, format!("decode: {e}")).into_response(),
    };
    let status = match ev.status {
        4 => c35_proto::TaskRunStatus::Done,
        5 => c35_proto::TaskRunStatus::Failed,
        6 => c35_proto::TaskRunStatus::Cancelled,
        _ => if ev.error.is_empty() { c35_proto::TaskRunStatus::Done } else { c35_proto::TaskRunStatus::Failed },
    };
    c35_mod_task::task_run_finish_rpc(
        &st.pool,
        st.nats.as_ref(),
        session.owner_iid,
        ev.run_id,
        status,
        &ev.summary,
        &ev.error,
    ).await;
    StatusCode::OK.into_response()
}

async fn agent_skill_put(
    State(st): State<AppState>,
    headers: HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    let session_key = session_key_from_headers(&headers).unwrap_or("");
    if agent_session_resolve(&st.pool, session_key).await.ok().flatten().is_none() {
        return (StatusCode::UNAUTHORIZED, "invalid session").into_response();
    }
    let req: c35_proto::ReqSkillPut = match c35_proto::pb_decode(&body) {
        Ok(r) => r,
        Err(e) => return (StatusCode::BAD_REQUEST, format!("decode: {e}")).into_response(),
    };
    let res = c35_proto::ResSkillPut { skill: req.skill };
    let bytes = c35_proto::pb_encode(&res);
    (
        [(axum::http::header::CONTENT_TYPE, "application/x-protobuf")],
        bytes,
    ).into_response()
}
