//! Optional Playwright command path — registered by `alienai_remote_browser` only.

use std::future::Future;
use std::pin::Pin;
use std::sync::{Arc, OnceLock};

use anyhow::Result;
use serde_json::Value;

type PlaywrightMethodFn = Arc<
    dyn Fn(
            String,
            Value,
        ) -> Pin<Box<dyn Future<Output = Result<Value>> + Send>>
        + Send
        + Sync,
>;

type PlaywrightTabFn = Arc<
    dyn Fn(Value) -> Pin<Box<dyn Future<Output = Result<Value>> + Send>> + Send + Sync,
>;

static METHOD: OnceLock<PlaywrightMethodFn> = OnceLock::new();
static TAB: OnceLock<PlaywrightTabFn> = OnceLock::new();

pub fn register_playwright_handlers(
    method: PlaywrightMethodFn,
    tab: PlaywrightTabFn,
) {
    let _ = METHOD.set(method);
    let _ = TAB.set(tab);
}

pub fn playwright_available() -> bool {
    METHOD.get().is_some()
}

pub async fn invoke_method(method: &str, params: Value) -> Result<Value> {
    let hook = METHOD
        .get()
        .ok_or_else(|| anyhow::anyhow!("Playwright browser_engine is not available on this binary"))?;
    hook(method.to_string(), params).await
}

pub async fn invoke_tab_ws(body: Value) -> Result<Value> {
    let hook = TAB
        .get()
        .ok_or_else(|| anyhow::anyhow!("Playwright browser_engine is not available on this binary"))?;
    hook(body).await
}

type ScreencastIdleFn = Arc<
    dyn Fn(bool) -> Pin<Box<dyn Future<Output = ()> + Send>> + Send + Sync,
>;
type PlaywrightInputFn = Arc<
    dyn Fn(Value) -> Pin<Box<dyn Future<Output = ()> + Send>> + Send + Sync,
>;

static SCREENCAST_IDLE: OnceLock<ScreencastIdleFn> = OnceLock::new();
static PLAYWRIGHT_INPUT: OnceLock<PlaywrightInputFn> = OnceLock::new();

pub fn register_playwright_idle(screencast: ScreencastIdleFn, input: PlaywrightInputFn) {
    let _ = SCREENCAST_IDLE.set(screencast);
    let _ = PLAYWRIGHT_INPUT.set(input);
}

pub async fn screencast_idle(active: bool) {
    if let Some(h) = SCREENCAST_IDLE.get() {
        h(active).await;
    }
}

pub async fn playwright_input(payload: Value) {
    if let Some(h) = PLAYWRIGHT_INPUT.get() {
        h(payload).await;
    }
}
