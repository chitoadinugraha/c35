use anyhow::{bail, Result};
use sqlx::PgPool;

pub async fn try_api_captions(_pool: &PgPool, _owner_iid: i64, _video_id: &str) -> Result<Vec<super::caption::Segment>> {
    bail!("youtube_api_captions: not configured (OAuth channel link required)")
}