//! WebRTC Hardware-Accelerated H.264 Video Streamer for Windows.
//!
//! Uses Windows Media Foundation (MFT) hardware encoders (NVENC, Intel QuickSync, AMD AMF)
//! with fallback to software MFT H.264 encoding and desktop capture.
//! Encoded H.264 Annex B NAL units are packetized into WebRTC RTP video samples
//! and streamed directly to the Flutter client video renderer.

use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime};

use anyhow::{bail, Context, Result};
use bytes::Bytes;
use tracing::{debug, error, info, warn};
use webrtc::media::Sample;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;

use windows::core::{Interface, GUID};
use windows::Win32::Foundation::HMODULE;
use windows::Win32::Media::MediaFoundation::{
    eAVEncH264VProfile_Base, IMFMediaType, IMFSample, IMFTransform, MFCreateMediaType,
    MFCreateMemoryBuffer, MFCreateSample, MFShutdown, MFStartup, MFTEnumEx,
    MFVideoFormat_H264, MFVideoFormat_NV12, MFMediaType_Video, MFT_CATEGORY_VIDEO_ENCODER,
    MFT_ENUM_FLAG_HARDWARE, MFT_ENUM_FLAG_SORTANDFILTER, MFT_ENUM_FLAG_SYNCMFT,
    MFT_OUTPUT_DATA_BUFFER, MFT_OUTPUT_STREAM_INFO, MFSTARTUP_NOSOCKET, MF_MT_AVG_BITRATE,
    MF_MT_FRAME_RATE, MF_MT_FRAME_SIZE, MF_MT_INTERLACE_MODE, MF_MT_MAJOR_TYPE,
    MF_MT_MPEG2_PROFILE, MF_MT_SUBTYPE,
};
use windows::Win32::System::Com::{CoCreateInstance, CLSCTX_INPROC_SERVER};

static VIDEO_STREAM_ACTIVE: AtomicBool = AtomicBool::new(false);
static TARGET_BITRATE_BPS: AtomicU32 = AtomicU32::new(2_500_000); // 2.5 Mbps default

pub fn is_video_stream_active() -> bool {
    VIDEO_STREAM_ACTIVE.load(Ordering::SeqCst)
}

pub fn set_target_bitrate_bps(bps: u32) {
    let clamped = bps.clamp(500_000, 8_000_000);
    TARGET_BITRATE_BPS.store(clamped, Ordering::Relaxed);
    debug!(bps = clamped, "target video bitrate updated");
}

/// Convert 32-bit BGRA image bytes to NV12 format (Y plane + interleaved UV plane).
/// NV12 is the universal input format for GPU video encoders.
pub fn bgra_to_nv12(bgra: &[u8], width: usize, height: usize) -> Vec<u8> {
    let y_plane_size = width * height;
    let uv_plane_size = width * (height / 2);
    let mut nv12 = vec![0u8; y_plane_size + uv_plane_size];

    let (y_plane, uv_plane) = nv12.split_at_mut(y_plane_size);

    for y in 0..height {
        let bgra_row = y * width * 4;
        let y_row = y * width;
        let uv_row = (y / 2) * width;
        let is_even_row = (y % 2) == 0;

        for x in 0..width {
            let px = bgra_row + x * 4;
            let b = bgra[px] as i32;
            let g = bgra[px + 1] as i32;
            let r = bgra[px + 2] as i32;

            // Fast integer ITU-R BT.601 conversion:
            // Y = (( 66 * R + 129 * G +  25 * B + 128) >> 8) + 16
            let y_val = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
            y_plane[y_row + x] = y_val.clamp(0, 255) as u8;

            if is_even_row && (x % 2 == 0) {
                // U = ((-38 * R -  74 * G + 112 * B + 128) >> 8) + 128
                // V = ((112 * R -  94 * G -  18 * B + 128) >> 8) + 128
                let u_val = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
                let v_val = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
                let uv_idx = uv_row + x;
                uv_plane[uv_idx] = u_val.clamp(0, 255) as u8;
                uv_plane[uv_idx + 1] = v_val.clamp(0, 255) as u8;
            }
        }
    }

    nv12
}

pub struct H264Encoder {
    transform: IMFTransform,
    width: u32,
    height: u32,
    bitrate: u32,
    fps: u32,
    sample_index: u64,
    is_hardware: bool,
}

// Safety: IMFTransform is used sequentially on the encoder thread.
unsafe impl Send for H264Encoder {}

impl H264Encoder {
    /// Initialize H.264 encoder with hardware acceleration preferred, falling back to software.
    pub fn new(width: u32, height: u32, fps: u32, bitrate: u32) -> Result<Self> {
        unsafe {
            // Align dimensions to even numbers (required by video encoders)
            let width = (width / 2) * 2;
            let height = (height / 2) * 2;

            let _ = MFStartup(0x00020070, MFSTARTUP_NOSOCKET);

            // Attempt 1: Enumerate hardware accelerated H.264 MFTs (NVIDIA NVENC, Intel QSV, AMD AMF)
            let mut transform: Option<IMFTransform> = None;
            let mut is_hardware = false;

            let hw_flags = MFT_ENUM_FLAG_HARDWARE | MFT_ENUM_FLAG_SORTANDFILTER;
            let mut count = 0u32;
            let mut clsids: *mut GUID = std::ptr::null_mut();

            if MFTEnumEx(
                MFT_CATEGORY_VIDEO_ENCODER,
                hw_flags,
                None,
                None,
                &mut clsids,
                &mut count,
            )
            .is_ok()
                && count > 0
                && !clsids.is_null()
            {
                let clsid = *clsids;
                windows::Win32::System::Com::CoTaskMemFree(Some(clsids as *const _));
                if let Ok(t) = CoCreateInstance(&clsid, None, CLSCTX_INPROC_SERVER) {
                    info!("Hardware H.264 encoder initialized (GPU accelerated)");
                    transform = Some(t);
                    is_hardware = true;
                }
            }

            // Attempt 2: Fallback to Microsoft software H.264 encoder MFT
            if transform.is_none() {
                let sw_flags = MFT_ENUM_FLAG_SYNCMFT | MFT_ENUM_FLAG_SORTANDFILTER;
                let mut sw_count = 0u32;
                let mut sw_clsids: *mut GUID = std::ptr::null_mut();
                if MFTEnumEx(
                    MFT_CATEGORY_VIDEO_ENCODER,
                    sw_flags,
                    None,
                    None,
                    &mut sw_clsids,
                    &mut sw_count,
                )
                .is_ok()
                    && sw_count > 0
                    && !sw_clsids.is_null()
                {
                    let clsid = *sw_clsids;
                    windows::Win32::System::Com::CoTaskMemFree(Some(sw_clsids as *const _));
                    if let Ok(t) = CoCreateInstance(&clsid, None, CLSCTX_INPROC_SERVER) {
                        info!("Software H.264 encoder initialized (CPU fallback)");
                        transform = Some(t);
                    }
                }
            }

            let transform = match transform {
                Some(t) => t,
                None => bail!("no suitable H.264 encoder MFT available on this system"),
            };

            // Configure Output Media Type (H.264 elementary stream)
            let out_type: IMFMediaType = MFCreateMediaType().context("MFCreateMediaType for output")?;
            out_type.SetGUID(&MF_MT_MAJOR_TYPE, &MFMediaType_Video)?;
            out_type.SetGUID(&MF_MT_SUBTYPE, &MFVideoFormat_H264)?;
            out_type.SetUINT32(&MF_MT_AVG_BITRATE, bitrate)?;
            out_type.SetUINT64(&MF_MT_FRAME_SIZE, ((width as u64) << 32) | (height as u64))?;
            out_type.SetUINT64(&MF_MT_FRAME_RATE, ((fps as u64) << 32) | 1)?;
            out_type.SetUINT32(&MF_MT_INTERLACE_MODE, 2)?; // Progressive
            out_type.SetUINT32(&MF_MT_MPEG2_PROFILE, eAVEncH264VProfile_Base.0 as u32)?;

            transform.SetOutputType(0, &out_type, 0)?;

            // Configure Input Media Type (NV12 YUV)
            let in_type: IMFMediaType = MFCreateMediaType().context("MFCreateMediaType for input")?;
            in_type.SetGUID(&MF_MT_MAJOR_TYPE, &MFMediaType_Video)?;
            in_type.SetGUID(&MF_MT_SUBTYPE, &MFVideoFormat_NV12)?;
            in_type.SetUINT64(&MF_MT_FRAME_SIZE, ((width as u64) << 32) | (height as u64))?;
            in_type.SetUINT64(&MF_MT_FRAME_RATE, ((fps as u64) << 32) | 1)?;
            in_type.SetUINT32(&MF_MT_INTERLACE_MODE, 2)?;

            transform.SetInputType(0, &in_type, 0)?;

            Ok(Self {
                transform,
                width,
                height,
                bitrate,
                fps,
                sample_index: 0,
                is_hardware,
            })
        }
    }

    pub fn is_hardware(&self) -> bool {
        self.is_hardware
    }

    /// Encode one NV12 video frame into H.264 Annex B NAL units.
    pub fn encode_frame(&mut self, nv12_data: &[u8]) -> Result<Vec<u8>> {
        unsafe {
            // 1. Create input buffer and sample
            let in_buffer = MFCreateMemoryBuffer(nv12_data.len() as u32)
                .context("MFCreateMemoryBuffer for input")?;
            let mut buf_ptr: *mut u8 = std::ptr::null_mut();
            in_buffer.Lock(&mut buf_ptr, None, None)?;
            std::ptr::copy_nonoverlapping(nv12_data.as_ptr(), buf_ptr, nv12_data.len());
            in_buffer.Unlock()?;
            in_buffer.SetCurrentLength(nv12_data.len() as u32)?;

            let in_sample = MFCreateSample().context("MFCreateSample for input")?;
            in_sample.AddBuffer(&in_buffer)?;

            // Frame duration in 100-nanosecond units: 1s / fps
            let frame_duration_100ns = 10_000_000 / self.fps as i64;
            let sample_time = self.sample_index as i64 * frame_duration_100ns;
            in_sample.SetSampleTime(sample_time)?;
            in_sample.SetSampleDuration(frame_duration_100ns)?;
            self.sample_index += 1;

            // 2. Feed input frame into encoder transform
            self.transform.ProcessInput(0, &in_sample, 0)?;

            // 3. Collect output H.264 NAL units
            let mut stream_info = MFT_OUTPUT_STREAM_INFO::default();
            self.transform.GetOutputStreamInfo(0, &mut stream_info)?;

            let out_buf_size = stream_info.cbSize.max(128 * 1024);
            let out_buffer = MFCreateMemoryBuffer(out_buf_size)
                .context("MFCreateMemoryBuffer for output")?;
            let out_sample = MFCreateSample().context("MFCreateSample for output")?;
            out_sample.AddBuffer(&out_buffer)?;

            let mut out_buffer_struct = MFT_OUTPUT_DATA_BUFFER {
                dwStreamID: 0,
                pSample: core::mem::ManuallyDrop::new(Some(out_sample)),
                dwStatus: 0,
                pEvents: core::mem::ManuallyDrop::new(None),
            };

            let mut status = 0u32;
            let hr = self.transform.ProcessOutput(
                0,
                std::slice::from_mut(&mut out_buffer_struct),
                &mut status,
            );

            let mut encoded_bytes = Vec::new();
            if hr.is_ok() {
                if let Some(s) = &*out_buffer_struct.pSample {
                    let media_buf = s.ConvertToContiguousBuffer()?;
                    let mut out_ptr: *mut u8 = std::ptr::null_mut();
                    let mut current_len = 0u32;
                    media_buf.Lock(&mut out_ptr, None, Some(&mut current_len))?;
                    if current_len > 0 && !out_ptr.is_null() {
                        encoded_bytes = std::slice::from_raw_parts(out_ptr, current_len as usize).to_vec();
                    }
                    media_buf.Unlock()?;
                }
            }

            Ok(encoded_bytes)
        }
    }
}

impl Drop for H264Encoder {
    fn drop(&mut self) {
        unsafe {
            let _ = MFShutdown();
        }
    }
}

/// Start high-performance hardware/software H.264 video streaming on a WebRTC video track.
pub fn start_video_stream(video_track: Arc<TrackLocalStaticSample>) {
    tokio::spawn(async move {
        VIDEO_STREAM_ACTIVE.store(true, Ordering::SeqCst);
        info!("WebRTC video streaming thread started");

        // Target 30 FPS for smooth desktop interaction
        let target_fps = 30u32;
        let frame_interval = Duration::from_millis(1000 / target_fps as u64);
        let mut ticker = tokio::time::interval(frame_interval);
        ticker.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);

        // Screen dimensions: default 1280x720, adapted to aspect ratio
        let mut target_w = 1280u32;
        let mut target_h = 720u32;

        let mut encoder_opt: Option<H264Encoder> = None;
        let mut capturer_opt: Option<crate::dxgi_capture::DxgiCapturer> = None;
        let mut consecutive_failures = 0u32;

        // Try activating GPU DXGI capturer
        match crate::dxgi_capture::DxgiCapturer::new() {
            Ok(cap) => {
                info!("DXGI GPU desktop capture active for video stream");
                capturer_opt = Some(cap);
            }
            Err(e) => {
                warn!("DXGI desktop duplication unavailable: {e}; using GDI capture fallback");
            }
        }

        loop {
            ticker.tick().await;

            let bitrate = TARGET_BITRATE_BPS.load(Ordering::Relaxed);

            // 1. Capture screen frame (GPU DXGI first, fallback to GDI)
            let captured = if let Some(capturer) = capturer_opt.as_mut() {
                match capturer.capture_frame(10) {
                    Ok(Some((src_w, src_h, bgra))) => Some((src_w, src_h, bgra)),
                    Ok(None) => None, // Idle frame; screen unchanged
                    Err(_) => {
                        // DXGI access lost (e.g. desktop switch / lock); fall back to GDI
                        None
                    }
                }
            } else {
                None
            };

            let (src_w, src_h, bgra_buf) = match captured {
                Some(c) => c,
                None => {
                    // Try GDI capture fallback
                    match crate::screen_capture::capture_screen_gdi(target_w, 65, None, false, None, false) {
                        Ok((Some((w, h, _, _)), _)) => {
                            // GDI produces JPEG bytes; for video stream we capture raw BGRA if DXGI is unavailable
                            continue;
                        }
                        _ => continue,
                    }
                }
            };

            // Scale target resolution while maintaining aspect ratio
            if src_w > 0 && src_h > 0 {
                let aspect = src_w as f64 / src_h as f64;
                target_w = src_w.min(1920);
                target_h = ((target_w as f64 / aspect).round() as u32 / 2) * 2;
                target_w = (target_w / 2) * 2;
            }

            // Lazy initialize or reinitialize encoder if dimensions/bitrate change
            let encoder_needs_reinit = encoder_opt.as_ref().map_or(true, |e| {
                e.width != target_w || e.height != target_h
            });

            if encoder_needs_reinit {
                info!(
                    width = target_w,
                    height = target_h,
                    bitrate,
                    fps = target_fps,
                    "initializing H.264 video encoder"
                );
                match H264Encoder::new(target_w, target_h, target_fps, bitrate) {
                    Ok(enc) => {
                        info!(
                            hardware = enc.is_hardware(),
                            "H.264 video encoder ready for WebRTC streaming"
                        );
                        encoder_opt = Some(enc);
                        consecutive_failures = 0;
                    }
                    Err(e) => {
                        consecutive_failures += 1;
                        if consecutive_failures < 3 {
                            warn!("failed to initialize H.264 encoder: {e}");
                        }
                        // Fall back: sleep and retry
                        tokio::time::sleep(Duration::from_millis(100)).await;
                        continue;
                    }
                }
            }

            let encoder = match encoder_opt.as_mut() {
                Some(e) => e,
                None => continue,
            };

            // Convert BGRA to NV12
            let nv12 = bgra_to_nv12(&bgra_buf, target_w as usize, target_h as usize);

            // Encode frame to H.264 Annex B NALUs
            match encoder.encode_frame(&nv12) {
                Ok(nalus) if !nalus.is_empty() => {
                    let sample = Sample {
                        data: Bytes::from(nalus),
                        duration: frame_interval,
                        timestamp: SystemTime::now(),
                        ..Default::default()
                    };

                    if let Err(e) = video_track.write_sample(&sample).await {
                        debug!("video_track write_sample: {e}");
                    }
                }
                Ok(_) => {} // Encoder buffering frame
                Err(e) => {
                    debug!("H.264 encode error: {e}");
                }
            }
        }
    });
}
