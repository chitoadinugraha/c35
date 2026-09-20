use c35_store::snowflake_id;
use sqlx::PgPool;

const FX_MICRO_PER_USD: i64 = 17_630_000_000;

pub async fn billing_signup_credit(
    pool: &PgPool,
    owner_iid: i64,
    balance_usd: f64,
) -> Result<(), sqlx::Error> {
    let balance_idr = balance_usd * 17_630.0;
    let existing = sqlx::query_scalar::<_, i64>(
        "SELECT id FROM ai.billing_account WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await?;
    if let Some(id) = existing {
        sqlx::query(
            r#"
            UPDATE ai.billing_account SET
                balance_usd = GREATEST(balance_usd, $2),
                balance_idr = GREATEST(balance_idr, $3),
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(balance_usd)
        .bind(balance_idr)
        .execute(pool)
        .await?;
        return Ok(());
    }
    let id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.billing_account (id, owner_iid, balance_usd, balance_idr, plan_tier, billing_currency, fx_micro_per_usd)
        VALUES ($1, $2, $3, $4, 'free', 'IDR', $5)
        "#,
    )
    .bind(id)
    .bind(owner_iid)
    .bind(balance_usd)
    .bind(balance_idr)
    .bind(FX_MICRO_PER_USD)
    .execute(pool)
    .await?;
    Ok(())
}
