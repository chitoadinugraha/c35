use std::sync::{Arc, OnceLock};

use dashmap::DashMap;
use tokio::sync::Mutex;

use crate::debounce::ChatDebouncer;
use crate::limit::BotLimiter;

static HUB: OnceLock<Arc<ChannelHub>> = OnceLock::new();

pub fn channel_hub_init() -> Arc<ChannelHub> {
    HUB.get_or_init(|| Arc::new(ChannelHub::default())).clone()
}

pub fn channel_hub() -> Arc<ChannelHub> {
    channel_hub_init()
}

#[derive(Default)]
pub struct ChannelHub {
    pub debouncer: Mutex<ChatDebouncer>,
    pub bot_limits: DashMap<i64, Arc<BotLimiter>>,
}

impl ChannelHub {
    pub fn bot_limiter(&self, bot_iid: i64) -> Arc<BotLimiter> {
        self.bot_limits
            .entry(bot_iid)
            .or_insert_with(|| BotLimiter::new(bot_iid))
            .clone()
    }
}
