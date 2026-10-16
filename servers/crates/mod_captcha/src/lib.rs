//! Cluster captcha solver (2Captcha) with device egress proxy alignment.

mod billing;
mod fetch_task;
mod proxy;
mod rates_cache;
mod rates_parse;
mod rates_reload;
mod rates_store;
mod twocaptcha;
mod types;

pub use billing::{captcha_retail_usd, captcha_wholesale_usd, compiled_wholesale_usd};
pub use fetch_task::{captcha_rates_sync_enabled, captcha_rates_sync_interval_secs, CaptchaRatesFetchTask};
pub use proxy::build_twocaptcha_proxy_param;
pub use rates_reload::{captcha_rates_init, captcha_rates_nats_subscribe};
pub use rates_store::{CaptchaWholesaleConfig, CONFIG_KEY, NATS_SUBJECT};
pub use twocaptcha::{TwoCaptchaClient, TwoCaptchaConfig};
pub use types::{CaptchaKind, CaptchaSolveError, SolveRequest, SolveResult};
