#[cfg(windows)]
pub fn register() {
    use std::sync::Arc;

    use c_remote_browser_core::browser_video::{BrowserH264Encoder, register_browser_video_hooks};
    use c_remote_windows::video_stream::{bgra_to_nv12_scaled, H264Encoder};

    struct WinEncoder(H264Encoder);

    impl BrowserH264Encoder for WinEncoder {
        fn width(&self) -> u32 {
            self.0.width
        }
        fn height(&self) -> u32 {
            self.0.height
        }
        fn bitrate(&self) -> u32 {
            self.0.bitrate
        }
        fn is_hardware(&self) -> bool {
            self.0.is_hardware()
        }
        fn encode_frame(&mut self, nv12: &[u8]) -> anyhow::Result<Vec<u8>> {
            self.0.encode_frame(nv12)
        }
    }

    register_browser_video_hooks(
        Arc::new(|w, h, fps, br| {
            Ok(Box::new(WinEncoder(H264Encoder::new(w, h, fps, br)?))
                as Box<dyn BrowserH264Encoder>)
        }),
        Arc::new(|bgra, sw, sh, tw, th| bgra_to_nv12_scaled(bgra, sw, sh, tw, th)),
    );
}

#[cfg(not(windows))]
pub fn register() {}
