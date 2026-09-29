//! DATABASE_URL=... cargo run -p c35_mod_billing --example voucher_smoke
use c35_mod_billing::{billing_package_redeem, billing_voucher_issue, billing_voucher_list, billing_voucher_redeem_list, billing_voucher_void};
use c35_proto::{ReqBillingVoucherIssue, ReqBillingVoucherList, ReqBillingVoucherRedeemList, ReqBillingVoucherVoid};
use c35_store::pool_connect;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let pool = pool_connect().await?;
    let issuer = 99_000_i64;
    let buyer = 33_000_i64;
    let issue = billing_voucher_issue(&pool, issuer, ReqBillingVoucherIssue {
        kind: "credit".into(), plan_slug: String::new(), duration_months: 1, credit_idr: 1_000.0, face_value_idr: 1_000.0,
        max_uses: 1, expires_at_ms: 0, payment_ref: "smoke".into(), code: String::new(), name: "Smoke credit".into(),
        scope: "user".into(), billing_period: "monthly".into(), list_price_idr: 1_200.0,
        alien_pool_limit_idr: 0.0, frontier_pool_limit_idr: 0.0, quantity: 1,
    }).await?;
    let code = issue.code.clone();
    println!("issued {}", code);
    let list = billing_voucher_list(&pool, issuer, ReqBillingVoucherList {}).await?;
    if !list.items.iter().any(|v| v.code == code) { return Err("missing from voucher list".into()); }
    println!("list ok ({} items)", list.items.len());
    let redeem = billing_package_redeem(&pool, buyer, &code).await?;
    println!("redeemed tier={} ent={}", redeem.plan_tier, redeem.entitlement_id);
    let hist = billing_voucher_redeem_list(&pool, issuer, ReqBillingVoucherRedeemList { limit: 10 }).await?;
    if !hist.items.iter().any(|h| h.code == code) { return Err("missing from redeem history".into()); }
    println!("history ok");
    let void_issue = billing_voucher_issue(&pool, issuer, ReqBillingVoucherIssue {
        kind: "credit".into(), plan_slug: String::new(), duration_months: 1, credit_idr: 500.0, face_value_idr: 500.0,
        max_uses: 1, expires_at_ms: 0, payment_ref: "smoke-void".into(), code: String::new(), name: "Void smoke".into(),
        scope: "user".into(), billing_period: "monthly".into(), list_price_idr: 0.0,
        alien_pool_limit_idr: 0.0, frontier_pool_limit_idr: 0.0, quantity: 1,
    }).await?;
    billing_voucher_void(&pool, issuer, ReqBillingVoucherVoid { code: void_issue.code.clone() }).await?;
    println!("void ok {}", void_issue.code);
    println!("SMOKE PASS");
    Ok(())
}