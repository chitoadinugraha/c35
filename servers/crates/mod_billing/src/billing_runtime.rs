use std::sync::OnceLock;

pub struct BillingRuntime {
    pub midtrans_server_key: String,
    pub midtrans_client_key: String,
    pub midtrans_is_production: bool,
    pub midtrans_usd_idr: f64,
    pub http: reqwest::Client,
}

static RUNTIME: OnceLock<BillingRuntime> = OnceLock::new();

pub fn billing_runtime_init(runtime: BillingRuntime) {
    let _ = RUNTIME.set(runtime);
}

pub fn billing_runtime() -> &'static BillingRuntime {
    RUNTIME.get().expect("billing_runtime_init must run at boot")
}

pub fn midtrans_is_production() -> bool {
    std::env::var("MIDTRANS_IS_PRODUCTION")
        .map(|v| matches!(v.to_lowercase().as_str(), "1" | "true" | "yes" | "production"))
        .unwrap_or(false)
}

pub fn midtrans_active_key(prod_var: &str, sandbox_var: &str) -> String {
    let prod = std::env::var(prod_var).unwrap_or_default();
    if midtrans_is_production() {
        return prod;
    }
    let sandbox = std::env::var(sandbox_var).unwrap_or_default();
    if sandbox.is_empty() { prod } else { sandbox }
}

pub fn midtrans_usd_idr_from_env() -> f64 {
    std::env::var("MIDTRANS_USD_IDR")
        .ok()
        .and_then(|v| v.parse().ok())
        .filter(|r: &f64| *r > 0.0)
        .unwrap_or(17_630.0)
}
