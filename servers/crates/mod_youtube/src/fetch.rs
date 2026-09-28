use anyhow::{bail, Context, Result};
use c35_mod_file::{cas_dir_default, cas_put};
use serde_json::json;
use sqlx::PgPool;
use std::time::Duration;
use tokio::time::timeout;

use super::api::try_api_captions;
use super::cache::{cache_get_best, cache_upsert, CacheRow};
use super::caption::{parse_vtt_or_srt, segments_text_range};
use super::structure::{chapters_from_description, synthetic_chapters};
use super::url::youtube_video_id;
use super::ytdlp::{ytdlp_fetch_vtt, ytdlp_meta};

pub const EXTRACT_DEFAULT_MAX_CHARS: usize = 14_000;
const FETCH_TIMEOUT_SEC: u64 = 90;

pub async fn youtube_transcript_ensure(pool: &PgPool, url_or_id: &str, owner_iid: i64) -> Result<CacheRow> {
    let video_id = youtube_video_id(url_or_id)
        .or_else(|| {
            let s = url_or_id.trim();
            if s.len() == 11 { Some(s.to_string()) } else { None }
        })
        .context("invalid youtube url or video_id")?;
    if let Some(row) = cache_get_best(pool, &video_id).await? {
        if !row.segments.is_empty() {
            return Ok(row);
        }
    }
    let url = if url_or_id.contains("http") {
        url_or_id.to_string()
    } else {
        format!("https://www.youtube.com/watch?v={}", video_id)
    };
    let fetch = timeout(Duration::from_secs(FETCH_TIMEOUT_SEC), fetch_via_ytdlp(pool, &url, &video_id));
    match fetch.await {
        Ok(Ok(row)) => return Ok(row),
        Ok(Err(e)) => tracing::warn!("[youtube] yt-dlp failed video_id={}: {e:#}", video_id),
        Err(_) => tracing::warn!("[youtube] yt-dlp timeout video_id={}", video_id),
    }
    if owner_iid > 0 {
        if let Ok(segments) = try_api_captions(pool, owner_iid, &video_id).await {
            let row = CacheRow {
                video_id: video_id.clone(),
                lang: "en".into(),
                track_kind: "manual".into(),
                source: "youtube_api".into(),
                title: String::new(),
                duration_sec: 0,
                chapters: vec![],
                segments,
                vtt_hash: String::new(),
            };
            cache_upsert(pool, &row).await?;
            return Ok(row);
        }
    }
    bail!("could not fetch youtube captions for {}", video_id)
}

async fn fetch_via_ytdlp(pool: &PgPool, url: &str, video_id: &str) -> Result<CacheRow> {
    let meta = ytdlp_meta(url).await?;
    let tmp = std::env::temp_dir().join(format!("c35-ytdlp-{}", video_id));
    std::fs::create_dir_all(&tmp).context("temp dir")?;
    let vtt_path = ytdlp_fetch_vtt(url, &tmp).await?;
    let vtt_bytes = std::fs::read(&vtt_path).context("read vtt")?;
    let _ = std::fs::remove_dir_all(&tmp);
    let segments = parse_vtt_or_srt(&String::from_utf8_lossy(&vtt_bytes))?;
    if segments.is_empty() {
        bail!("empty captions");
    }
    let secret = cas_secret();
    let put = cas_put(pool, &cas_dir_default(), &secret, &vtt_bytes, "text/vtt").await.context("cas_put vtt")?;
    let mut chapters = meta.chapters;
    if chapters.is_empty() {
        chapters = chapters_from_description(&meta.description);
    }
    if chapters.is_empty() && meta.duration_sec > 0 {
        chapters = synthetic_chapters(meta.duration_sec, 300);
    }
    let row = CacheRow {
        video_id: video_id.to_string(),
        lang: "en".into(),
        track_kind: "auto".into(),
        source: "yt_dlp".into(),
        title: meta.title,
        duration_sec: meta.duration_sec as i32,
        chapters,
        segments,
        vtt_hash: put.hash,
    };
    cache_upsert(pool, &row).await?;
    Ok(row)
}

fn cas_secret() -> String {
    ["CAS_HMAC_SECRET", "C35_JWT_SECRET", "AGENT_SECRET_KEY"]
        .into_iter()
        .find_map(|k| std::env::var(k).ok())
        .unwrap_or_default()
}

pub async fn video_structure_json(pool: &PgPool, url_or_id: &str, owner_iid: i64) -> Result<serde_json::Value> {
    let row = youtube_transcript_ensure(pool, url_or_id, owner_iid).await?;
    Ok(json!({
        "ok": true,
        "video_id": row.video_id,
        "title": row.title,
        "duration_sec": row.duration_sec,
        "lang": row.lang,
        "track_kind": row.track_kind,
        "source": row.source,
        "chapters": row.chapters,
        "segment_count": row.segments.len(),
    }))
}

pub async fn video_extract_json(
    pool: &PgPool,
    video_id: &str,
    start_sec: f64,
    end_sec: f64,
    max_chars: usize,
    owner_iid: i64,
) -> Result<serde_json::Value> {
    let row = youtube_transcript_ensure(pool, video_id, owner_iid).await?;
    let max_chars = max_chars.clamp(500, 32_000);
    let text = segments_text_range(&row.segments, start_sec, end_sec, max_chars);
    Ok(json!({
        "ok": true,
        "video_id": row.video_id,
        "start_sec": start_sec,
        "end_sec": end_sec,
        "char_count": text.chars().count(),
        "text": text,
    }))
}

pub async fn video_structure_cached_only(pool: &PgPool, video_id: &str) -> Option<serde_json::Value> {
    let row = cache_get_best(pool, video_id).await.ok().flatten()?;
    if row.segments.is_empty() {
        return None;
    }
    Some(json!({
        "ok": true,
        "video_id": row.video_id,
        "title": row.title,
        "duration_sec": row.duration_sec,
        "lang": row.lang,
        "track_kind": row.track_kind,
        "source": row.source,
        "chapters": row.chapters,
        "segment_count": row.segments.len(),
        "cached": true,
    }))
}