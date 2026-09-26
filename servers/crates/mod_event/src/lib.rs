mod catalog;
mod emit;
mod render;
mod subject;

pub use catalog::{event_by_kind, EventClass, EventDef, EventScope};
pub use emit::{event_emit, event_spawn, EventCtx};

pub mod kinds {
    pub const USER_SIGN_IN: &str = "user.sign_in";
    pub const USER_SIGN_OUT: &str = "user.sign_out";
    pub const USER_SIGN_IN_FAILED: &str = "user.sign_in_failed";
    pub const USER_CONNECTED: &str = "user.connected";
    pub const USER_DISCONNECTED: &str = "user.disconnected";
    pub const CONSUMPTION_MEAL_LOGGED: &str = "consumption.meal_logged";
    pub const CONSUMPTION_MEAL_UPDATED: &str = "consumption.meal_updated";
    pub const CONSUMPTION_MEAL_DELETED: &str = "consumption.meal_deleted";
    pub const CHANNEL_CONNECTED: &str = "channel.connected";
    pub const CHANNEL_DISCONNECTED: &str = "channel.disconnected";
    pub const DEVICE_AGENT_CONNECTED: &str = "device.agent_connected";
    pub const DEVICE_AGENT_DISCONNECTED: &str = "device.agent_disconnected";
    pub const DEVICE_UNPAIRED: &str = "device.unpaired";
}