use axum::extract::{Path, Query, State};
use axum::routing::get;
use axum::{Json, Router};
use c35_ctx::AppState;
use c35_mod_chat::{mention_list, topic_list, translation_get, translation_rev};
use serde::Deserialize;
use serde_json::{json, Value};

#[derive(Debug, Deserialize)]
struct TranslationQuery {
    category: Option<String>,
}

pub fn catalog_router() -> Router<AppState> {
    Router::new()
        .route("/v1/translations/{lang}", get(translations_handler))
        .route("/v1/catalog/mentions", get(mentions_handler))
        .route("/v1/catalog/topics", get(topics_handler))
}

async fn translations_handler(
    State(st): State<AppState>,
    Path(lang): Path<String>,
    Query(q): Query<TranslationQuery>,
) -> Json<Value> {
    let categories: Vec<String> = q
        .category
        .as_deref()
        .unwrap_or("tool,mention,topic")
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    let translations = translation_get(&st.pool, &lang, &categories).await;
    let rev = translation_rev(&st.pool).await;
    Json(json!({ "lang": lang, "rev": rev, "translations": translations }))
}

async fn mentions_handler(State(st): State<AppState>) -> Json<Value> {
    let mentions = mention_list(&st.pool).await;
    Json(json!({ "mentions": mentions }))
}

async fn topics_handler(State(st): State<AppState>) -> Json<Value> {
    let topics = topic_list(&st.pool).await;
    Json(json!({ "topics": topics }))
}
