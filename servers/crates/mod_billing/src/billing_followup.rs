use anyhow::Result;
use sqlx::PgPool;

#[derive(Debug, Clone, Copy)]
pub struct FollowupCaps {
    pub queue_max: i32,
    pub steer_max: i32,
}

pub async fn billing_followup_caps(pool: &PgPool, owner_iid: i64) -> Result<FollowupCaps> {
    let row = sqlx::query_as::<_, (Option<i32>, Option<i32>, String)>(
        r#"
        SELECT
            (p.caps_json->>'prompt_followup_queue_max')::int,
            (p.caps_json->>'prompt_followup_steer_max')::int,
            COALESCE(s.plan_slug, 'lite')
        FROM ai.billing_subscription s
        JOIN ai.billing_plan p ON p.slug = s.plan_slug
        WHERE s.scope = 'user' AND s.scope_iid = $1 AND s.deleted_ts IS NULL
          AND (s.expires_ts IS NULL OR s.expires_ts > NOW())
        ORDER BY s.updated_ts DESC
        LIMIT 1
        "#,
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;

    let (queue_raw, steer_raw, slug) = row.unwrap_or((None, None, "lite".into()));
    let defaults = caps_defaults(&slug);
    Ok(FollowupCaps {
        queue_max: queue_raw.unwrap_or(defaults.queue_max),
        steer_max: steer_raw.unwrap_or(defaults.steer_max),
    })
}

fn caps_defaults(slug: &str) -> FollowupCaps {
    match slug.trim().to_lowercase().as_str() {
        "lite" => FollowupCaps { queue_max: 0, steer_max: 3 },
        "plus" | "pro" | "ultra" => FollowupCaps { queue_max: 5, steer_max: 20 },
        _ => FollowupCaps { queue_max: 5, steer_max: 20 },
    }
}
