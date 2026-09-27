use sqlx::PgPool;
use thiserror::Error;

pub const STORAGE_GIB: i64 = 1024 * 1024 * 1024;

pub const DRIVE_LIMIT_DEFAULT_BYTES: i64 = STORAGE_GIB;

pub fn drive_storage_limit_bytes_from_plan_slug(plan_slug: &str) -> i64 {
    match plan_slug.trim().to_ascii_lowercase().as_str() {
        "lite" => STORAGE_GIB,
        "plus" => 5 * STORAGE_GIB,
        "pro" => 10 * STORAGE_GIB,
        "ultra" => 15 * STORAGE_GIB,
        _ => DRIVE_LIMIT_DEFAULT_BYTES,
    }
}

#[derive(Debug, Error)]
#[error("drive storage quota exceeded: used {used_bytes} + delta {delta_bytes} > limit {limit_bytes}")]
pub struct DriveQuotaExceeded {
    pub used_bytes: i64,
    pub delta_bytes: i64,
    pub limit_bytes: i64,
}

pub async fn drive_plan_slug(pool: &PgPool, owner_iid: i64) -> Result<String, sqlx::Error> {
    let slug: Option<String> = sqlx::query_scalar(
        r#"
        SELECT COALESCE(bp.plan_tier, 'free')
        FROM ai.billing_profile bp
        WHERE bp.owner_iid = $1 AND bp.deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    Ok(slug.unwrap_or_else(|| "free".into()))
}

pub async fn drive_storage_limit_bytes(pool: &PgPool, owner_iid: i64) -> Result<i64, sqlx::Error> {
    let slug = drive_plan_slug(pool, owner_iid).await?;
    Ok(drive_storage_limit_bytes_from_plan_slug(&slug))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn limit_mapping_table() {
        let cases = [
            ("free", DRIVE_LIMIT_DEFAULT_BYTES),
            ("", DRIVE_LIMIT_DEFAULT_BYTES),
            ("lite", STORAGE_GIB),
            ("plus", 5 * STORAGE_GIB),
            ("pro", 10 * STORAGE_GIB),
            ("ultra", 15 * STORAGE_GIB),
            ("ULTRA", 15 * STORAGE_GIB),
            ("unknown_tier", DRIVE_LIMIT_DEFAULT_BYTES),
        ];
        for (slug, want) in cases {
            assert_eq!(
                drive_storage_limit_bytes_from_plan_slug(slug),
                want,
                "slug={slug}"
            );
        }
    }
}
