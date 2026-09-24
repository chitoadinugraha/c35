use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use chrono::{NaiveDate, Utc};
use c35_mod_fetch::{FetchCtx, FetchTask};
use c35_mod_platform::{
    env_enabled, parse_finalize_days, vendor_bill_mtd_window, GcpVendorSource,
    VendorBillFetchTask, VendorBillSource, VendorCostLine,
};
use c35_store::{migrate_apply, pool_connect};
use sqlx::PgPool;
use tokio::sync::OnceCell;

static SCHEMA_READY: OnceCell<()> = OnceCell::const_new();

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

#[test]
fn stub_sources_expose_vendor_ids() {
    assert_eq!(GcpVendorSource::default().vendor(), "gcp");
}

#[test]
fn env_enabled_reads_truthy_values() {
    std::env::set_var("TEST_VENDOR_BILL_FLAG", "1");
    assert!(env_enabled("TEST_VENDOR_BILL_FLAG"));
    std::env::set_var("TEST_VENDOR_BILL_FLAG", "true");
    assert!(env_enabled("TEST_VENDOR_BILL_FLAG"));
    std::env::set_var("TEST_VENDOR_BILL_FLAG", "0");
    assert!(!env_enabled("TEST_VENDOR_BILL_FLAG"));
    std::env::remove_var("TEST_VENDOR_BILL_FLAG");
    assert!(!env_enabled("TEST_VENDOR_BILL_FLAG"));
}

#[test]
fn parse_finalize_days_defaults_and_custom() {
    std::env::remove_var("VENDOR_BILL_FINALIZE_DAYS");
    assert_eq!(parse_finalize_days(), vec![1, 3, 7, 14]);

    std::env::set_var("VENDOR_BILL_FINALIZE_DAYS", "1,7,21");
    assert_eq!(parse_finalize_days(), vec![1, 7, 21]);
    std::env::remove_var("VENDOR_BILL_FINALIZE_DAYS");
}

struct MockVendorSource {
    vendor: &'static str,
    windows: Arc<Mutex<Vec<(NaiveDate, NaiveDate)>>>,
    line_amount: f64,
}

impl MockVendorSource {
    fn new(vendor: &'static str, line_amount: f64) -> Self {
        Self {
            vendor,
            windows: Arc::new(Mutex::new(Vec::new())),
            line_amount,
        }
    }
}

#[async_trait]
impl VendorBillSource for MockVendorSource {
    fn vendor(&self) -> &'static str {
        self.vendor
    }

    async fn fetch_lines(
        &self,
        _ctx: &FetchCtx,
        window: (NaiveDate, NaiveDate),
    ) -> anyhow::Result<Vec<VendorCostLine>> {
        self.windows.lock().unwrap().push(window);
        let ext_ref = format!(
            "mock-{}-{}-{}",
            self.vendor,
            window.0,
            window.1
        );
        Ok(vec![VendorCostLine {
            vendor: self.vendor,
            category: "compute",
            sku: "mock".into(),
            description: "mock vendor line".into(),
            period_start: window.0,
            period_end: window.1,
            amount_native: self.line_amount,
            currency: "USD".into(),
            source: "api",
            external_ref: ext_ref,
            status: "estimated",
            meta: serde_json::json!({}),
        }])
    }
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

async fn fetch_ctx(pool: PgPool) -> Option<FetchCtx> {
    let nats = match async_nats::connect("nats://127.0.0.1:4222").await {
        Ok(c) => c,
        Err(e) => {
            eprintln!("skip fetch task integration: nats unavailable: {e}");
            return None;
        }
    };
    Some(FetchCtx {
        pool,
        nats,
        http: reqwest::Client::new(),
    })
}

#[tokio::test]
async fn vendor_bill_fetch_task_upserts_mock_lines_when_db_available() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    if !platform_table_ready(&pool).await {
        eprintln!("skip vendor_bill_fetch_task: ai.platform_vendor_cost missing (Track A schema)");
        return;
    }
    let Some(ctx) = fetch_ctx(pool).await else {
        return;
    };

    std::env::set_var("VENDOR_BILL_MTD_ENABLED", "1");
    std::env::remove_var("VENDOR_BILL_FINALIZE_DAYS");

    let source = MockVendorSource::new("oci", 12.5);
    let windows = source.windows.clone();
    let task = VendorBillFetchTask::new(Box::new(source), 0);

    let outcome = task.run(&ctx).await.expect("vendor bill fetch run");
    assert!(outcome.changed);
    assert!(outcome.nats_subject.is_none());
    assert!(outcome.nats_payload.is_none());

    let now = Utc::now();
    let mtd = vendor_bill_mtd_window(now);
    let called = windows.lock().unwrap().clone();
    assert!(called.iter().any(|w| *w == mtd));

    let ext_prefix = format!("mock-oci-{}-{}", mtd.0, mtd.1);
    let count = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ai.platform_vendor_cost WHERE vendor = 'oci' AND external_ref LIKE $1 AND deleted_ts IS NULL",
    )
    .bind(format!("{ext_prefix}%"))
    .fetch_one(&ctx.pool)
    .await
    .expect("count");
    assert_eq!(count, 1);

    let _ = sqlx::query("DELETE FROM ai.platform_vendor_cost WHERE vendor = 'oci' AND external_ref LIKE $1")
        .bind(format!("{ext_prefix}%"))
        .execute(&ctx.pool)
        .await;
}

#[tokio::test]
async fn mock_vendor_source_returns_lines() {
    let pool = PgPool::connect_lazy("postgres://127.0.0.1:1/invalid").expect("lazy pool");
    let Some(ctx) = fetch_ctx(pool).await else {
        return;
    };
    let source = MockVendorSource::new("oci", 3.0);
    let window = (
        NaiveDate::from_ymd_opt(2026, 9, 1).unwrap(),
        NaiveDate::from_ymd_opt(2026, 9, 23).unwrap(),
    );
    let lines = source.fetch_lines(&ctx, window).await.expect("fetch_lines");
    assert_eq!(lines.len(), 1);
    assert_eq!(lines[0].vendor, "oci");
    assert_eq!(lines[0].amount_native, 3.0);
}

#[test]
fn vendor_bill_fetch_task_name_and_interval() {
    let task = VendorBillFetchTask::new(Box::new(MockVendorSource::new("gcp", 1.0)), 15);
    assert_eq!(task.name(), "vendor_bill_gcp");
    assert_eq!(task.stagger_mins, 15);
    std::env::set_var("VENDOR_BILL_FETCH_INTERVAL_SECS", "7200");
    assert_eq!(task.interval().as_secs(), 7200);
    std::env::remove_var("VENDOR_BILL_FETCH_INTERVAL_SECS");
}

