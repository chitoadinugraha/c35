pub mod bridge;
mod debounce;
mod disconnect;
mod dedup;
mod format;
mod hub;
mod inbound;
mod limit;
mod media;
pub mod outbound;
mod pair_fanout;
mod peer;
mod render;
pub mod store;
pub mod speech;
mod thought;
mod turn;
mod types;
pub mod typing;
mod webhook;

pub mod telegram;
pub mod whatsapp;

pub use bridge::start_channel_inbound_subscriber;
pub use disconnect::{bot_channels_disconnect_all, channel_disconnect};
pub use hub::{channel_hub, channel_hub_init};
pub use inbound::{channel_inbound_from_webhook, channel_inbound_handle, channel_runtime_init};
pub use pair_fanout::channel_pair_nats_fanout;
pub use telegram::channel_telegram_connect;
pub use whatsapp::{
    channel_whatsapp_meta_connect, channel_whatsapp_pair_abort, channel_whatsapp_pair_start,
    channel_whatsapp_pair_watch, pair_res_from_channel, pair_res_from_error,
};
pub use store::{
    bot_channel_external_taken, bot_channel_get, bot_channel_list, bot_channel_remove, bot_ensure,
    channel_external_key, channel_secret_generate, ChannelDoc,
};
pub use types::ChannelInboundMessage;
pub use webhook::channel_router;
