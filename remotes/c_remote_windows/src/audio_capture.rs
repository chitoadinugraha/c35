//! Windows WASAPI Loopback Audio Capture.
//!
//! Captures system audio output (speakers/headphones) via the default multimedia endpoint.
//! Provides raw PCM audio packets that can be Opus-encoded and streamed over WebRTC.

use std::sync::atomic::{AtomicBool, Ordering};

use anyhow::{Context, Result};
use tracing::debug;
use windows::Win32::Media::Audio::{
    eConsole, eRender, IAudioCaptureClient, IAudioClient, IMMDevice, IMMDeviceEnumerator,
    MMDeviceEnumerator, AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_LOOPBACK,
};
use windows::Win32::System::Com::{
    CoCreateInstance, CoInitializeEx, CLSCTX_ALL, COINIT_MULTITHREADED,
};

static AUDIO_ACTIVE: AtomicBool = AtomicBool::new(false);

pub fn is_audio_active() -> bool {
    AUDIO_ACTIVE.load(Ordering::SeqCst)
}

pub struct WasapiAudioCapture {
    _device: IMMDevice,
    client: IAudioClient,
    capture_client: IAudioCaptureClient,
    pub channels: u16,
    pub sample_rate: u32,
    pub bits_per_sample: u16,
}

// Safety: COM interfaces in WasapiAudioCapture are used on the capture worker thread.
unsafe impl Send for WasapiAudioCapture {}

impl WasapiAudioCapture {
    /// Initialize loopback capture on the default render device.
    pub fn new() -> Result<Self> {
        unsafe {
            let _ = CoInitializeEx(None, COINIT_MULTITHREADED);

            let enumerator: IMMDeviceEnumerator = CoCreateInstance(
                &MMDeviceEnumerator,
                None,
                CLSCTX_ALL,
            )
            .context("failed to create MMDeviceEnumerator")?;

            let device = enumerator
                .GetDefaultAudioEndpoint(eRender, eConsole)
                .context("failed to get default audio endpoint (no audio output device?)")?;

            let client: IAudioClient = device
                .Activate(CLSCTX_ALL, None)
                .context("failed to activate IAudioClient")?;

            let pwfx = client
                .GetMixFormat()
                .context("failed to get audio mix format")?;

            let format = &*pwfx;
            let channels = format.nChannels;
            let sample_rate = format.nSamplesPerSec;
            let bits_per_sample = format.wBitsPerSample;
            let format_tag = format.wFormatTag;

            debug!(
                channels,
                sample_rate,
                bits_per_sample,
                format_tag,
                "WASAPI audio mix format"
            );

            // 100ms buffer duration (in 100-nanosecond units)
            let buffer_duration = 1_000_000i64;

            client
                .Initialize(
                    AUDCLNT_SHAREMODE_SHARED,
                    AUDCLNT_STREAMFLAGS_LOOPBACK,
                    buffer_duration,
                    0,
                    pwfx,
                    None,
                )
                .context("IAudioClient::Initialize loopback failed")?;

            let capture_client: IAudioCaptureClient = client
                .GetService()
                .context("failed to get IAudioCaptureClient")?;

            client.Start().context("failed to start IAudioClient")?;

            Ok(Self {
                _device: device,
                client,
                capture_client,
                channels,
                sample_rate,
                bits_per_sample,
            })
        }
    }

    /// Read available PCM audio packets.
    /// Returns raw PCM bytes and number of frames read.
    pub fn read_packet(&self) -> Result<Option<Vec<u8>>> {
        unsafe {
            let packet_size = self
                .capture_client
                .GetNextPacketSize()
                .context("GetNextPacketSize failed")?;

            if packet_size == 0 {
                return Ok(None);
            }

            let mut p_data: *mut u8 = std::ptr::null_mut();
            let mut num_frames_read: u32 = 0;
            let mut flags: u32 = 0;

            self.capture_client
                .GetBuffer(
                    &mut p_data,
                    &mut num_frames_read,
                    &mut flags,
                    None,
                    None,
                )
                .context("GetBuffer failed")?;

            let bytes_per_frame = (self.channels * (self.bits_per_sample / 8)) as usize;
            let total_bytes = (num_frames_read as usize) * bytes_per_frame;

            let result = if flags & 1 != 0 {
                // AUDCLNT_BUFFERFLAGS_SILENT: audio is silent
                vec![0u8; total_bytes]
            } else if !p_data.is_null() && total_bytes > 0 {
                let slice = std::slice::from_raw_parts(p_data, total_bytes);
                slice.to_vec()
            } else {
                Vec::new()
            };

            let _ = self.capture_client.ReleaseBuffer(num_frames_read);

            if result.is_empty() {
                Ok(None)
            } else {
                Ok(Some(result))
            }
        }
    }
}

impl Drop for WasapiAudioCapture {
    fn drop(&mut self) {
        unsafe {
            let _ = self.client.Stop();
        }
    }
}

/// Start background audio loopback capture thread.
pub fn start_audio_stream<F>(mut on_packet: F)
where
    F: FnMut(&[u8], u32, u16) + Send + 'static,
{
    if AUDIO_ACTIVE.swap(true, Ordering::SeqCst) {
        // Already active
        return;
    }
    std::thread::spawn(move || {
        let capture = match WasapiAudioCapture::new() {
            Ok(c) => c,
            Err(e) => {
                debug!("WASAPI audio loopback init unavailable: {e}");
                AUDIO_ACTIVE.store(false, Ordering::SeqCst);
                return;
            }
        };
        let sample_rate = capture.sample_rate;
        let channels = capture.channels;
        debug!(sample_rate, channels, "WASAPI audio capture streaming started");

        while AUDIO_ACTIVE.load(Ordering::Relaxed) {
            match capture.read_packet() {
                Ok(Some(pcm)) => {
                    on_packet(&pcm, sample_rate, channels);
                }
                Ok(None) => {
                    std::thread::sleep(std::time::Duration::from_millis(10));
                }
                Err(e) => {
                    debug!("WASAPI read packet error: {e}");
                    std::thread::sleep(std::time::Duration::from_millis(20));
                }
            }
        }
        debug!("WASAPI audio capture streaming stopped");
    });
}

/// Stop background audio loopback capture thread.
pub fn stop_audio_stream() {
    AUDIO_ACTIVE.store(false, Ordering::SeqCst);
}

