use chrono::{NaiveDate, TimeZone, Utc};
use c35_mod_platform::{
    amount_to_usd, vendor_bill_mtd_window, vendor_bill_prev_month_window,
    vendor_bill_should_finalize_today, vendor_cost_upsert_batch, VendorCostLine,
};
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use sqlx::PgPool;
use tokio::sync::OnceCell;

static SCHEMA_READY: OnceCell<()> = OnceCell::const_new();

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

fn utc_at(y: i32, m: u32, d: u32, h: u32) -> chrono::DateTime<Utc> {
    Utc.with_ymd_and_hms(y, m, d, h, 0, 0).unwrap()
}

#[test]
fn mtd_window_mid_month_jakarta() {
    // 2026-09-24 10:00 UTC = 17:00 WIB same calendar day
    let now = utc_at(2026, 9, 24, 10);
    let (start, end) = vendor_bill_mtd_window(now);
    assert_eq!(start, NaiveDate::from_ymd_opt(2026, 9, 1).unwrap());
    assert_eq!(end, NaiveDate::from_ymd_opt(2026, 9, 23).unwrap());
}

#[test]
fn prev_month_window_mid_month_jakarta() {
    let now = utc_at(2026, 9, 24, 10);
    let (start, end) = vendor_bill_prev_month_window(now);
    assert_eq!(start, NaiveDate::from_ymd_opt(2026, 8, 1).unwrap());
    assert_eq!(end, NaiveDate::from_ymd_opt(2026, 8, 31).unwrap());
}

#[test]
fn mtd_window_first_of_month_jakarta() {
    // 2026-09-01 02:00 UTC = 09:00 WIB on the 1st
    let now = utc_at(2026, 9, 1, 2);
    let (start, end) = vendor_bill_mtd_window(now);
    assert_eq!(start, NaiveDate::from_ymd_opt(2026, 9, 1).unwrap());
    assert_eq!(end, NaiveDate::from_ymd_opt(2026, 8, 31).unwrap());
}

#[test]
fn finalize_today_matches_jakarta_day() {
    // 2026-10-01 20:00 UTC = 2026-10-02 03:00 WIB → day 2
    let now = utc_at(2026, 10, 1, 20);
    assert!(!vendor_bill_should_finalize_today(now, &[1, 3, 7, 14]));
    assert!(vendor_bill_should_finalize_today(now, &[2]));

    // 2026-10-06 18:00 UTC = 2026-10-07 01:00 WIB → day 7
    let now = utc_at(2026, 10, 6, 18);
    assert!(vendor_bill_should_finalize_today(now, &[1, 3, 7, 14]));
}

async fn platform_table_ready(pool: &PgPool) -> bool {
    sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.platform_vendor_cost') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false)
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    std::env::set_var("PG_ACQUIRE_TIMEOUT_SECS", "90");
    let pool = pool_connect().await.expect("pool_connect (set YB_* in .env.local)");
    SCHEMA_READY
        .get_or_init(|| async {
            if !platform_table_ready(&pool).await {
                migrate_apply(&pool).await.expect("migrate_apply");
            }
        })
        .await;
    pool
}

async fn ensure_fx_rate(pool: &PgPool) {
    let exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM ai.billing_fx_rate WHERE currency = 'IDR' AND micro_per_usd > 0)",
    )
    .fetch_one(pool)
    .await
    .expect("fx rate check");
    if exists {
        return;
    }
    sqlx::query(
        "INSERT INTO ai.billing_fx_rate (id, currency, micro_per_usd, effective_from) VALUES ($1, 'IDR', $2, NOW())",
    )
    .bind(snowflake_id())
    .bind(17_630_000_000_i64)
    .execute(pool)
    .await
    .expect("seed fx rate");
}

#[tokio::test]
async fn upsert_idempotent_when_db_available() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    if !platform_table_ready(&pool).await {
        eprintln!("skip upsert_idempotent: ai.platform_vendor_cost missing (Track A schema)");
        return;
    }
    ensure_fx_rate(&pool).await;

    let ext_ref = format!("test-oci-{}", snowflake_id());
    let period_start = NaiveDate::from_ymd_opt(2026, 9, 1).unwrap();
    let period_end = NaiveDate::from_ymd_opt(2026, 9, 23).unwrap();
    let make_line = || VendorCostLine {
        vendor: "oci",
        category: "compute",
        sku: "OKE".into(),
        description: "test line".into(),
        period_start,
        period_end,
        amount_native: 17_630.0,
        currency: "IDR".into(),
        source: "api",
        external_ref: ext_ref.clone(),
        status: "estimated",
        meta: serde_json::json!({}),
    };

    vendor_cost_upsert_batch(&pool, &[make_line()])
        .await
        .expect("first upsert");
    vendor_cost_upsert_batch(&pool, &[make_line()])
        .await
        .expect("second upsert");

    let count = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ai.platform_vendor_cost WHERE vendor = 'oci' AND external_ref = $1 AND deleted_ts IS NULL",
    )
    .bind(&ext_ref)
    .fetch_one(&pool)
    .await
    .expect("count");
    assert_eq!(count, 1);

    let amount_usd = sqlx::query_scalar::<_, f64>(
        "SELECT amount_usd::float8 FROM ai.platform_vendor_cost WHERE vendor = 'oci' AND external_ref = $1",
    )
    .bind(&ext_ref)
    .fetch_one(&pool)
    .await
    .expect("amount_usd");
    assert!((amount_usd - 1.0).abs() < 0.0001);

    let _ = sqlx::query("DELETE FROM ai.platform_vendor_cost WHERE external_ref = $1")
        .bind(&ext_ref)
        .execute(&pool)
        .await;
}

#[tokio::test]
async fn amount_to_usd_idr_when_db_available() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_fx_rate(&pool).await;
    let usd = amount_to_usd(&pool, 17_630.0, "IDR").await.expect("idr to usd");
    assert!((usd - 1.0).abs() < 0.0001);
    let passthrough = amount_to_usd(&pool, 42.5, "USD").await.expect("usd passthrough");
    assert!((passthrough - 42.5).abs() < 0.0001);
}
