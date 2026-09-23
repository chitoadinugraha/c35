use c35_mod_admin::{require_root, AdminError};
use c35_mod_hint::hint_invalidate_all;
use c35_proto::{ReqTranslationPut, ResTranslationPut};
use sqlx::PgPool;

#[derive(Debug)]
pub struct TranslationAdminError {
    pub status_code: i32,
    pub message: String,
}

impl TranslationAdminError {
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
}

fn affects_hints(category: &str, key: &str) -> bool {
    category == "hint" || key.starts_with("hint.")
}

pub async fn translation_put(
    pool: &PgPool,
    viewer_iid: i64,
    req: ReqTranslationPut,
) -> Result<ResTranslationPut, TranslationAdminError> {
    require_root(pool, viewer_iid)
        .await
        .map_err(TranslationAdminError::from_admin)?;

    let lang = req.lang.trim();
    let key = req.key.trim();
    let category = req.category.trim();
    let text = req.text.trim();
    if lang.is_empty() || key.is_empty() || category.is_empty() || text.is_empty() {
        return Err(TranslationAdminError::bad("lang, key, category, and text are required"));
    }

    let row = sqlx::query_scalar::<_, chrono::DateTime<chrono::Utc>>(
        r#"
        INSERT INTO ai.translation (lang, key, category, text, updated_ts)
        VALUES ($1, $2, $3, $4, NOW())
        ON CONFLICT (lang, key) DO UPDATE SET
            category = EXCLUDED.category,
            text = EXCLUDED.text,
            updated_ts = NOW()
        RETURNING updated_ts
        "#,
    )
    .bind(lang)
    .bind(key)
    .bind(category)
    .bind(text)
    .fetch_one(pool)
    .await
    .map_err(|e| TranslationAdminError::bad(e.to_string()))?;

    if affects_hints(category, key) {
        let _ = hint_invalidate_all(pool).await;
    }

    Ok(ResTranslationPut {
        updated_ts_ms: row.timestamp_millis(),
    })
}
