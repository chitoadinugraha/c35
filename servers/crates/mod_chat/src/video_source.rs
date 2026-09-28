use std::time::Duration;

use c35_mod_youtube::{video_structure_cached_only, video_structure_json, youtube_urls_in_text, youtube_video_id};
use sqlx::PgPool;
use tokio::time::timeout;

const ENRICH_FETCH_MS: u64 = 2500;

pub async fn presentation_youtube_enrich(pool: &PgPool, user_text: &str, owner_iid: i64) -> Option<String> {
    let urls = youtube_urls_in_text(user_text);
    let url = urls.first()?;
    let video_id = youtube_video_id(url)?;
    if let Some(v) = video_structure_cached_only(pool, &video_id).await {
        return Some(v.to_string());
    }
    let fut = video_structure_json(pool, url, owner_iid);
    match timeout(Duration::from_millis(ENRICH_FETCH_MS), fut).await {
        Ok(Ok(v)) => Some(v.to_string()),
        _ => Some(serde_json::json!({"ok":false,"video_id":video_id,"hint":"retry or use presentation.source.video_structure"}).to_string()),
    }
}