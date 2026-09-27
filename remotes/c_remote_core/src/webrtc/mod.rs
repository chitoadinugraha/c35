//! Agent-side WebRTC data plane (signaling via agent WS, fs over SCTP).

mod fs;
mod media;
mod session;

#[cfg(windows)]
mod file_playback;

pub use media::{set_media_handler, MediaFrameKind};
#[cfg(windows)]
pub use file_playback::{is_file_media_active, register_media_handler, set_video_track};
pub use session::{
    dispatch_input, dispatch_media_tracks, dispatch_screen_channel, dispatch_screenshot,
    input_cursor_publish, notify_update_ready, set_input_handler, set_screen_handler,
    set_screenshot_handler, set_track_handler, set_webrtc_rtp_media_enabled, webrtc_rtp_media_enabled,
    InputHandler, ScreenHandler, ScreenshotHandler, TrackHandler, WebrtcHub,
};
