use sqlx::PgPool;

use super::copy::{expense_summary_coach, format_idr_minor};
use super::day::{day_bounds_ms, multi_day_bounds_ms, period_label, resolve_day_id, today_day_id};
use super::store::{expense_list_day, spending_sum_day};
use super::types::{ExpenseCategoryBreakdown, ExpenseGlance, ExpenseRecent};

pub async fn expense_summary(
    pool: &PgPool,
    owner_iid: i64,
    locale: &str,
    day_id: Option<&str>,
    days: i32,
    category_path: Option<&str>,
    item_query: Option<&str>,
) -> Result<ExpenseGlance, String> {
    let end_day = day_id
        .filter(|s| !s.is_empty())
        .map(|s| resolve_day_id(s, locale))
        .unwrap_or_else(|| today_day_id(locale));
    let days_clamped = days.clamp(1, 30);
    let (start_ms, end_ms) = multi_day_bounds_ms(&end_day, days_clamped, locale).map_err(|e| e.to_string())?;
    let (total_minor, tx_count) = spending_sum_day(pool, owner_iid, start_ms, end_ms).await?;

    let cat_prefix = category_path.filter(|s| !s.trim().is_empty()).map(|s| s.trim());
    let item_q = item_query.filter(|s| !s.trim().is_empty()).map(|s| s.trim());

    let category_breakdown = category_breakdown_query(pool, owner_iid, start_ms, end_ms, cat_prefix).await?;
    let matched_total_minor = if item_q.is_some() || cat_prefix.is_some() {
        matched_total_query(pool, owner_iid, start_ms, end_ms, cat_prefix, item_q).await?
    } else {
        0
    };

    let receipts = expense_list_day(pool, owner_iid, start_ms, end_ms).await?;
    let recent: Vec<ExpenseRecent> = receipts
        .iter()
        .take(5)
        .map(|r| ExpenseRecent {
            tx_id: r.tx_id.clone(),
            label: r.headline.clone(),
            subtitle: r.subtitle.clone(),
            total_minor: r.total_minor,
            photo_hash: r.photo_hash.clone(),
        })
        .collect();

    let period_id = if days_clamped == 1 {
        end_day.clone()
    } else {
        let (range_start, _) = day_bounds_ms(&end_day, locale).map_err(|e| e.to_string())?;
        let start_day = {
            let off = super::day::offset_hours(super::day::timezone_from_locale(locale));
            let ms = range_start + off as i64 * 3_600_000;
            chrono::DateTime::from_timestamp_millis(ms)
                .map(|d| d.format("%Y-%m-%d").to_string())
                .unwrap_or(end_day.clone())
        };
        format!("{start_day}..{end_day}")
    };

    let glance = ExpenseGlance {
        period_id,
        period_label: period_label(&end_day, locale),
        coach: String::new(),
        total_minor,
        tx_count,
        currency: super::types::DEFAULT_CURRENCY.into(),
        matched_query: item_q.unwrap_or("").to_string(),
        matched_total_minor,
        category_breakdown,
        recent,
    };
    let coach = expense_summary_coach(&glance, locale);
    Ok(ExpenseGlance { coach, ..glance })
}

async fn category_breakdown_query(
    pool: &PgPool,
    owner_iid: i64,
    start_ms: i64,
    end_ms: i64,
    category_path: Option<&str>,
) -> Result<Vec<ExpenseCategoryBreakdown>, String> {
    let id_min = super::day::snowflake_min_at_ms(start_ms);
    let id_max = super::day::snowflake_max_at_ms(end_ms);
    let rows = if let Some(prefix) = category_path {
        sqlx::query_as::<_, (String, String, i64)>(
            "SELECT COALESCE(n.slug, 'other'), COALESCE(n.path, ''), COALESCE(SUM(ti.total_net), 0)
             FROM site.tx t
             JOIN site.tx_item ti ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id AND ti.deleted_ts IS NULL
             LEFT JOIN ai.object_normalizer n ON n.id = ti.obj_id
             WHERE t.site_iid = $1 AND t.owner_iid = $1 AND t.ty = 'purchase' AND t.state = 'ok'
               AND t.deleted_ts IS NULL AND t.tx_id >= $2 AND t.tx_id <= $3
               AND n.path LIKE $4
             GROUP BY n.slug, n.path
             ORDER BY 3 DESC LIMIT 10",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(format!("{prefix}%"))
        .fetch_all(pool)
        .await
        .map_err(|e| e.to_string())?
    } else {
        sqlx::query_as::<_, (String, String, i64)>(
            "SELECT COALESCE(n.slug, 'other'), COALESCE(n.path, ''), COALESCE(SUM(ti.total_net), 0)
             FROM site.tx t
             JOIN site.tx_item ti ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id AND ti.deleted_ts IS NULL
             LEFT JOIN ai.object_normalizer n ON n.id = ti.obj_id AND ti.obj_id > 0
             WHERE t.site_iid = $1 AND t.owner_iid = $1 AND t.ty = 'purchase' AND t.state = 'ok'
               AND t.deleted_ts IS NULL AND t.tx_id >= $2 AND t.tx_id <= $3
             GROUP BY n.slug, n.path
             ORDER BY 3 DESC LIMIT 10",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .fetch_all(pool)
        .await
        .map_err(|e| e.to_string())?
    };

    Ok(rows
        .into_iter()
        .map(|(slug, path, total)| {
            let label = slug
                .split('_')
                .map(|w| {
                    let mut c = w.chars();
                    match c.next() {
                        None => String::new(),
                        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
                    }
                })
                .collect::<Vec<_>>()
                .join(" ");
            ExpenseCategoryBreakdown {
                label: if label.is_empty() { "Other".into() } else { label },
                path,
                total_minor: total,
            }
        })
        .collect())
}

async fn matched_total_query(
    pool: &PgPool,
    owner_iid: i64,
    start_ms: i64,
    end_ms: i64,
    category_path: Option<&str>,
    item_query: Option<&str>,
) -> Result<i64, String> {
    let id_min = super::day::snowflake_min_at_ms(start_ms);
    let id_max = super::day::snowflake_max_at_ms(end_ms);
    let q = item_query.map(|s| format!("%{}%", s.to_ascii_lowercase()));
    let cat = category_path.map(|s| format!("{s}%"));

    let row = if cat.is_some() && q.is_some() {
        sqlx::query_scalar::<_, i64>(
            "SELECT COALESCE(SUM(ti.total_net), 0)
             FROM site.tx t
             JOIN site.tx_item ti ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id AND ti.deleted_ts IS NULL
             LEFT JOIN ai.object_normalizer n ON n.id = ti.obj_id
             WHERE t.site_iid = $1 AND t.owner_iid = $1 AND t.ty = 'purchase' AND t.state = 'ok'
               AND t.deleted_ts IS NULL AND t.tx_id >= $2 AND t.tx_id <= $3
               AND n.path LIKE $4 AND LOWER(ti.note) LIKE $5",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(cat.unwrap())
        .bind(q.unwrap())
        .fetch_one(pool)
        .await
    } else if cat.is_some() {
        sqlx::query_scalar::<_, i64>(
            "SELECT COALESCE(SUM(ti.total_net), 0)
             FROM site.tx t
             JOIN site.tx_item ti ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id AND ti.deleted_ts IS NULL
             LEFT JOIN ai.object_normalizer n ON n.id = ti.obj_id
             WHERE t.site_iid = $1 AND t.owner_iid = $1 AND t.ty = 'purchase' AND t.state = 'ok'
               AND t.deleted_ts IS NULL AND t.tx_id >= $2 AND t.tx_id <= $3
               AND n.path LIKE $4",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(cat.unwrap())
        .fetch_one(pool)
        .await
    } else if q.is_some() {
        sqlx::query_scalar::<_, i64>(
            "SELECT COALESCE(SUM(ti.total_net), 0)
             FROM site.tx t
             JOIN site.tx_item ti ON ti.site_iid = t.site_iid AND ti.tx_id = t.tx_id AND ti.deleted_ts IS NULL
             WHERE t.site_iid = $1 AND t.owner_iid = $1 AND t.ty = 'purchase' AND t.state = 'ok'
               AND t.deleted_ts IS NULL AND t.tx_id >= $2 AND t.tx_id <= $3
               AND LOWER(ti.note) LIKE $4",
        )
        .bind(owner_iid)
        .bind(id_min)
        .bind(id_max)
        .bind(q.unwrap())
        .fetch_one(pool)
        .await
    } else {
        return Ok(0);
    }
    .map_err(|e| e.to_string())?;
    Ok(row)
}

pub fn glance_coach_with_match(glance: &ExpenseGlance, locale: &str) -> String {
    let base = expense_summary_coach(glance, locale);
    if glance.matched_query.is_empty() || glance.matched_total_minor == 0 {
        return base;
    }
    let id = locale.to_lowercase().starts_with("id");
    if id {
        format!("{base} — {} untuk \"{}\"", format_idr_minor(glance.matched_total_minor), glance.matched_query)
    } else {
        format!("{base} — {} matched \"{}\"", format_idr_minor(glance.matched_total_minor), glance.matched_query)
    }
}
