use std::sync::Arc;

#[cfg(windows)]
mod browser_video;

fn sctp_screen_enabled() -> bool {
    std::env::var("C35_BROWSER_SCTP_SCREEN").as_deref() == Ok("1")
}

pub fn register_handlers() {
    c_remote_core::webrtc::set_input_handler(Arc::new(crate::browser_input::execute));
    c_remote_core::webrtc::set_screenshot_handler(Arc::new(|max_w, q, m, som| {
        crate::browser_screenshot::webrtc_capture(max_w, q, m, som)
    }));

    if sctp_screen_enabled() {
        c_remote_core::webrtc::set_screen_handler(Arc::new(|dc| {
            crate::browser_stream::start_browser_screen_stream(dc);
        }));
        c_remote_core::webrtc::set_webrtc_rtp_media_enabled(false);
        return;
    }

    #[cfg(windows)]
    {
        c_remote_core::webrtc::set_track_handler(Arc::new(|v_track, _a_track| {
            c_remote_core::webrtc::set_video_track(v_track.clone());
            browser_video::start_browser_video_stream(v_track);
        }));
        c_remote_core::webrtc::set_webrtc_rtp_media_enabled(true);
    }

    #[cfg(not(windows))]
    {
        c_remote_core::webrtc::set_screen_handler(Arc::new(|dc| {
            crate::browser_stream::start_browser_screen_stream(dc);
        }));
        c_remote_core::webrtc::set_webrtc_rtp_media_enabled(false);
    }
}
