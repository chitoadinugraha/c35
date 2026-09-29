//! One-off: DATABASE_URL=... cargo run -p c35_mod_billing --example redeem_once -- TEST3300PKG
use c35_mod_billing::billing_package_redeem;
use c35_store::pool_connect;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let code = std::env::args().nth(1).unwrap_or_else(|| "TEST3300PKG".into());
    let iid: i64 = std::env::var("OWNER_IID")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(33000);
    let pool = pool_connect().await?;
    let res = billing_package_redeem(&pool, iid, &code).await?;
    println!("ok owner_iid={} code={} plan_tier={} entitlement_id={}", iid, code, res.plan_tier, res.entitlement_id);
    Ok(())
}