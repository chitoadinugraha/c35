use anyhow::Result;
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, Row};

use super::caption::Segment;
use super::structure::Chapter;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheRow {
    pub video_id: String,
    pub lang: String,
    pub track_kind: String,
    pub source: String,
    pub title: String,
    pub duration_sec: i32,
    pub chapters: Vec<Chapter>,
    pub segments: Vec<Segment>,
    pub vtt_hash: String,
}

pub async fn cache_get_best(pool: &PgPool, video_id: &str) -> Result<Option<CacheRow>> {
    let row = sqlx::query(
        r#"
        SELECT video_id, lang, track_kind, source, title, duration_sec,
               chapters_json, segments_json, vtt_hash
        FROM ai.youtube_transcript_cache
        WHERE video_id = $1
        ORDER BY CASE lang WHEN 'en' THEN 0 WHEN 'id' THEN 1 ELSE 2 END, fetched_ts DESC
        LIMIT 1
        "#,
    )
    .bind(video_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|r| row_from_db(&r)))
}

pub async fn cache_upsert(pool: &PgPool, row: &CacheRow) -> Result<()> {
    let chapters_json = serde_json::to_value(&row.chapters)?;
    let segments_json = serde_json::to_value(&row.segments)?;
    sqlx::query(
        r#"
        INSERT INTO ai.youtube_transcript_cache (
            video_id, lang, track_kind, source, title, duration_sec,
            chapters_json, segments_json, vtt_hash, fetched_ts
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW())
        ON CONFLICT (video_id, lang, track_kind) DO UPDATE SET
            source = EXCLUDED.source,
            title = EXCLUDED.title,
            duration_sec = EXCLUDED.duration_sec,
            chapters_json = EXCLUDED.chapters_json,
            segments_json = EXCLUDED.segments_json,
            vtt_hash = EXCLUDED.vtt_hash,
            fetched_ts = NOW()
        "#,
    )
    .bind(&row.video_id)
    .bind(&row.lang)
    .bind(&row.track_kind)
    .bind(&row.source)
    .bind(&row.title)
    .bind(row.duration_sec)
    .bind(chapters_json)
    .bind(segments_json)
    .bind(&row.vtt_hash)
    .execute(pool)
    .await?;
    Ok(())
}

fn row_from_db(r: &sqlx::postgres::PgRow) -> CacheRow {
    let chapters_json: serde_json::Value = r.get("chapters_json");
    let segments_json: serde_json::Value = r.get("segments_json");
    let chapters: Vec<Chapter> = serde_json::from_value(chapters_json).unwrap_or_default();
    let segments: Vec<Segment> = serde_json::from_value(segments_json).unwrap_or_default();
    CacheRow {
        video_id: r.get("video_id"),
        lang: r.get("lang"),
        track_kind: r.get("track_kind"),
        source: r.get("source"),
        title: r.get("title"),
        duration_sec: r.get("duration_sec"),
        chapters,
        segments,
        vtt_hash: r.get("vtt_hash"),
    }
}