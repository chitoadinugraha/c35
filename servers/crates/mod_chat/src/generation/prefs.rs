use anyhow::{Context, Result};
use serde_json::{json, Value};
use sqlx::PgPool;

use super::provider::provider_normalize;

pub const GENERATION_DEFAULT: &str = "auto";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GenerationPrefs {
    pub image: String,
    pub video: String,
    pub music: String,
}

impl GenerationPrefs {
    pub fn defaults() -> Self {
        Self {
            image: GENERATION_DEFAULT.into(),
            video: GENERATION_DEFAULT.into(),
            music: GENERATION_DEFAULT.into(),
        }
    }
}

fn pref_from_meta(meta: &Value, key: &str) -> String {
    meta.pointer(&format!("/generation/{key}"))
        .and_then(|v| v.as_str())
        .map(provider_normalize)
        .unwrap_or_else(|| GENERATION_DEFAULT.into())
}

pub async fn generation_prefs_get(pool: &PgPool, owner_iid: i64) -> Result<GenerationPrefs> {
    if owner_iid <= 0 {
        return Ok(GenerationPrefs::defaults());
    }
    let meta: Value = sqlx::query_scalar(
        "SELECT COALESCE(meta, '{}'::jsonb) FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .context("generation_prefs_get")?
    .unwrap_or(json!({}));
    Ok(GenerationPrefs {
        image: pref_from_meta(&meta, "image"),
        video: pref_from_meta(&meta, "video"),
        music: pref_from_meta(&meta, "music"),
    })
}

pub fn generation_prefs_merge_json(image: &str, video: &str, music: &str) -> Value {
    let mut gen = json!({});
    if !image.trim().is_empty() {
        gen["image"] = json!(provider_normalize(image));
    }
    if !video.trim().is_empty() {
        gen["video"] = json!(provider_normalize(video));
    }
    if !music.trim().is_empty() {
        gen["music"] = json!(provider_normalize(music));
    }
    if gen.as_object().map(|o| o.is_empty()).unwrap_or(true) {
        return json!({});
    }
    json!({ "generation": gen })
}

pub async fn generation_prefs_put(pool: &PgPool, owner_iid: i64, image: &str, video: &str, music: &str) -> Result<()> {
    let patch = generation_prefs_merge_json(image, video, music);
    if patch.as_object().map(|o| o.is_empty()).unwrap_or(true) {
        return Ok(());
    }
    sqlx::query(
        r#"
        UPDATE ai.identity SET
            meta = COALESCE(meta, '{}'::jsonb) || $2::jsonb,
            updated_ts = NOW()
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(patch)
    .execute(pool)
    .await
    .context("generation_prefs_put")?;
    Ok(())
}

pub async fn generation_prefs_put_one(pool: &PgPool, owner_iid: i64, kind: &str, provider: &str) -> Result<()> {
    let p = provider_normalize(provider);
    let (image, video, music) = match kind {
        "image" => (p.as_str(), "", ""),
        "video" => ("", p.as_str(), ""),
        "music" => ("", "", p.as_str()),
        _ => return Ok(()),
    };
    generation_prefs_put(pool, owner_iid, image, video, music).await
}
