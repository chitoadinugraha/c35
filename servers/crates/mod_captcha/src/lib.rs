//! Cluster captcha solver (2Captcha) with device egress proxy alignment.

mod billing;
mod proxy;
mod twocaptcha;
mod types;

pub use billing::{captcha_retail_usd, captcha_wholesale_usd};
pub use proxy::build_twocaptcha_proxy_param;
pub use twocaptcha::{TwoCaptchaClient, TwoCaptchaConfig};
pub use types::{CaptchaKind, CaptchaSolveError, SolveRequest, SolveResult};
