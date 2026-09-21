use anyhow::Result;
use c35_proto::{BotUsageModelRow, ResBotUsageStats};
use sqlx::PgPool;

pub async fn bot_usage_stats(pool: &PgPool, owner_iid: i64, bot_iid: i64) -> Result<ResBotUsageStats, String> {
    let owner_ok = sqlx::query_scalar::<_, i64>(
        "SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'bot' AND deleted_ts IS NULL",
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .unwrap_or(0);
    if owner_ok != owner_iid {
        return Err("forbidden".into());
    }

    let rows = sqlx::query_as::<_, (String, String, i64, i64, i64)>(
        r#"
        SELECT l.model, COALESCE(l.meta->>'plan_slug', '') AS plan_slug,
               COUNT(*)::bigint,
               COALESCE(SUM(l.tokens_in), 0)::bigint,
               COALESCE(SUM(l.tokens_out), 0)::bigint
        FROM ai.log l
        JOIN ai.chat c ON c.id = l.chat_id
        WHERE c.bot_iid = $1 AND l.kind = 'llm' AND l.deleted_ts IS NULL
        GROUP BY l.model, COALESCE(l.meta->>'plan_slug', '')
        ORDER BY l.model
        "#,
    )
    .bind(bot_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;

    let cost_rows = sqlx::query_as::<_, (String, String)>(
        r#"
        SELECT l.model, COALESCE(SUM(l.cost_usd), 0)::text
        FROM ai.log l
        JOIN ai.chat c ON c.id = l.chat_id
        WHERE c.bot_iid = $1 AND l.kind = 'llm' AND l.deleted_ts IS NULL
        GROUP BY l.model
        "#,
    )
    .bind(bot_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let cost_map: std::collections::HashMap<String, f64> = cost_rows
        .into_iter()
        .map(|(m, c)| (m, c.parse().unwrap_or(0.0)))
        .collect();

    let mut total_cost = 0.0;
    let mut total_in: i64 = 0;
    let mut total_out: i64 = 0;
    let mut by_model = Vec::new();
    for (model, plan_slug, turns, tin, tout) in rows {
        let cost_usd = cost_map.get(&model).copied().unwrap_or(0.0);
        total_cost += cost_usd;
        total_in += tin;
        total_out += tout;
        by_model.push(BotUsageModelRow {
            model,
            plan_slug,
            turns: turns as i32,
            tokens_in: tin as i32,
            tokens_out: tout as i32,
            cost_usd,
        });
    }

    let (msgs_used, msgs_limit, plan_slug) = sqlx::query_as::<_, (i32, i32, String)>(
        r#"
        SELECT msgs_used, msgs_limit, plan_slug
        FROM ai.billing_subscription
        WHERE scope = 'bot' AND scope_iid = $1 AND deleted_ts IS NULL
          AND (expires_ts IS NULL OR expires_ts > NOW())
        LIMIT 1
        "#,
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .unwrap_or((0, 0, String::new()));

    Ok(ResBotUsageStats {
        bot_iid,
        plan_slug,
        msgs_used,
        msgs_limit,
        total_cost_usd: total_cost,
        total_tokens_in: total_in as i32,
        total_tokens_out: total_out as i32,
        by_model,
    })
}
