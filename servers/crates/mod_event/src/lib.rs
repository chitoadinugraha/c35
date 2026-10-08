mod catalog;
mod emit;
mod render;
mod subject;

pub use catalog::{catalog_list, event_by_kind, EventClass, EventDef, EventScope};
pub use emit::{event_emit, event_spawn, EventCtx};

pub mod kinds {
    pub const USER_SIGN_IN: &str = "user.sign_in";
    pub const USER_SIGN_OUT: &str = "user.sign_out";
    pub const USER_SIGN_IN_FAILED: &str = "user.sign_in_failed";
    pub const USER_CONNECTED: &str = "user.connected";
    pub const USER_DISCONNECTED: &str = "user.disconnected";
    pub const USER_NOTIFIED: &str = "user.notified";
    pub const CONSUMPTION_MEAL_LOGGED: &str = "consumption.meal_logged";
    pub const CONSUMPTION_MEAL_UPDATED: &str = "consumption.meal_updated";
    pub const CONSUMPTION_MEAL_DELETED: &str = "consumption.meal_deleted";
    pub const CHANNEL_CONNECTED: &str = "channel.connected";
    pub const CHANNEL_DISCONNECTED: &str = "channel.disconnected";
    pub const DEVICE_AGENT_CONNECTED: &str = "device.agent_connected";
    pub const DEVICE_AGENT_DISCONNECTED: &str = "device.agent_disconnected";
    pub const DEVICE_UNPAIRED: &str = "device.unpaired";
    pub const ADMIN_USER_PROFILE_UPDATED: &str = "admin.user_profile_updated";
    pub const ADMIN_USER_REFERRER_UPDATED: &str = "admin.user_referrer_updated";
    pub const ADMIN_USER_ROLES_UPDATED: &str = "admin.user_roles_updated";
    pub const DRIVE_FILE_UPDATED: &str = "drive.file_updated";
    pub const DRIVE_FILE_DELETED: &str = "drive.file_deleted";
}