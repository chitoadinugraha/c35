use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use c35_ctx::AppState;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct PresentationExportReq {
    pub slides_markdown: String,
    pub title: Option<String>,
    pub theme: Option<String>,
}

pub fn presentation_router() -> Router<AppState> {
    Router::new().route("/v1/presentation/export", post(presentation_export_handler))
}

async fn presentation_export_handler(
    State(state): State<AppState>,
    Json(req): Json<PresentationExportReq>,
) -> Response {
    let title = req.title.unwrap_or_else(|| "Presentation".to_string());
    let theme = req.theme.unwrap_or_else(|| "dark".to_string());
    match c35_mod_chat::presentation_export_exec(&state.pool, &req.slides_markdown, &title, &theme).await {
        Ok(res) => (StatusCode::OK, Json(res)).into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({ "ok": false, "error": e.to_string() })),
        )
            .into_response(),
    }
}
