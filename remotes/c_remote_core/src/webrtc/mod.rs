//! Agent-side WebRTC data plane (signaling via agent WS, fs over SCTP).

mod fs;
mod ice_config;
mod ice_setting;
mod media;
mod session;
mod teach;
mod stats_probe;

#[cfg(windows)]
mod file_playback;

pub use media::{set_media_handler, MediaFrameKind};
#[cfg(windows)]
pub use file_playback::{is_file_media_active, register_media_handler, set_video_track};
pub use session::{
    dispatch_input, dispatch_media_tracks, dispatch_screen_channel, dispatch_screen_control,
    dispatch_screenshot, input_cursor_publish, notify_update_ready, set_command_handler,
    set_input_handler, set_screen_control_handler, set_screen_handler, set_screenshot_handler,
    set_track_handler, CommandHandler,
    set_webrtc_rtp_media_enabled, webrtc_rtp_media_enabled, InputHandler, ScreenControlHandler,
    ScreenHandler, ScreenshotHandler, TrackHandler, WebrtcHub,
};
