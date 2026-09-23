//! Agent-side WebRTC data plane (signaling via agent WS, fs over SCTP).

mod fs;
mod session;

pub use session::{
    dispatch_input, dispatch_media_tracks, dispatch_screen_channel, dispatch_screenshot,
    notify_update_ready, set_input_handler, set_screen_handler, set_screenshot_handler,
    set_track_handler, InputHandler, ScreenHandler, ScreenshotHandler, TrackHandler, WebrtcHub,
};
