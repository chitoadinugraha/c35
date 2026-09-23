//! Fast GPU Screen Capture using DXGI Desktop Duplication (Direct3D 11).
//!
//! Provides ultra-low latency (<1ms) frame grabbing directly from GPU VRAM.
//! Automatically recovers from display mode/resolution changes and desktop switches.

use anyhow::{bail, Context, Result};
use tracing::{debug, warn};
use windows::core::Interface;
use windows::Win32::Foundation::HMODULE;
use windows::Win32::Graphics::Direct3D::{
    D3D_DRIVER_TYPE_HARDWARE, D3D_FEATURE_LEVEL_11_0,
};
use windows::Win32::Graphics::Direct3D11::{
    D3D11CreateDevice, ID3D11Device, ID3D11DeviceContext, ID3D11Texture2D,
    D3D11_CPU_ACCESS_READ, D3D11_CREATE_DEVICE_FLAG,
    D3D11_MAPPED_SUBRESOURCE, D3D11_MAP_READ, D3D11_TEXTURE2D_DESC,
    D3D11_USAGE_STAGING,
};
use windows::Win32::Graphics::Dxgi::Common::{
    DXGI_FORMAT_B8G8R8A8_UNORM, DXGI_SAMPLE_DESC,
};
use windows::Win32::Graphics::Dxgi::{
    IDXGIAdapter1, IDXGIDevice, IDXGIOutput, IDXGIOutput1,
    IDXGIOutputDuplication, IDXGIResource, DXGI_ERROR_ACCESS_LOST,
    DXGI_ERROR_INVALID_CALL, DXGI_ERROR_WAIT_TIMEOUT, DXGI_OUTDUPL_FRAME_INFO,
};

pub struct DxgiCapturer {
    device: ID3D11Device,
    context: ID3D11DeviceContext,
    duplication: IDXGIOutputDuplication,
    staging_texture: Option<ID3D11Texture2D>,
    width: u32,
    height: u32,
    display_index: u32,
}

// Safety: COM pointers in DxgiCapturer are used sequentially within a thread or mutex.
unsafe impl Send for DxgiCapturer {}

impl DxgiCapturer {
    /// Attempt to initialize DXGI Desktop Duplication on the primary display (index 0).
    pub fn new() -> Result<Self> {
        Self::new_with_display(0)
    }

    /// Attempt to initialize DXGI Desktop Duplication on a specific display index.
    pub fn new_with_display(display_index: u32) -> Result<Self> {
        unsafe {
            let mut device: Option<ID3D11Device> = None;
            let mut context: Option<ID3D11DeviceContext> = None;
            let mut feature_level = D3D_FEATURE_LEVEL_11_0;

            D3D11CreateDevice(
                None,
                D3D_DRIVER_TYPE_HARDWARE,
                HMODULE::default(),
                D3D11_CREATE_DEVICE_FLAG(0),
                Some(&[D3D_FEATURE_LEVEL_11_0]),
                windows::Win32::Graphics::Direct3D11::D3D11_SDK_VERSION,
                Some(&mut device),
                Some(&mut feature_level),
                Some(&mut context),
            )
            .context("failed to create D3D11 device for DXGI capture")?;

            let device = device.context("D3D11 device was None")?;
            let context = context.context("D3D11 context was None")?;

            let dxgi_device: IDXGIDevice = device.cast().context("cast to IDXGIDevice")?;
            let adapter: IDXGIAdapter1 = dxgi_device
                .GetAdapter()?
                .cast()
                .context("cast to IDXGIAdapter1")?;
            let output: IDXGIOutput = adapter.EnumOutputs(display_index).context("EnumOutputs(display_index)")?;
            let output1: IDXGIOutput1 = output.cast().context("cast to IDXGIOutput1")?;

            let duplication = output1
                .DuplicateOutput(&device)
                .context("DuplicateOutput failed (unsupported or session locked)")?;

            debug!(display_index, "DXGI desktop duplication initialized successfully");

            Ok(Self {
                device,
                context,
                duplication,
                staging_texture: None,
                width: 0,
                height: 0,
                display_index,
            })
        }
    }

    /// Reinitialize duplication after access lost (e.g. resolution change, UAC prompt).
    fn reinitialize(&mut self) -> Result<()> {
        unsafe {
            self.staging_texture = None;
            let dxgi_device: IDXGIDevice = self.device.cast()?;
            let adapter: IDXGIAdapter1 = dxgi_device.GetAdapter()?.cast()?;
            let output: IDXGIOutput = adapter.EnumOutputs(self.display_index)?;
            let output1: IDXGIOutput1 = output.cast()?;
            self.duplication = output1.DuplicateOutput(&self.device)?;
            debug!(display_index = self.display_index, "DXGI desktop duplication reinitialized");
            Ok(())
        }
    }

    /// Ensure staging texture matches required dimensions.
    unsafe fn ensure_staging_texture(&mut self, width: u32, height: u32) -> Result<&ID3D11Texture2D> {
        if self.staging_texture.is_some() && self.width == width && self.height == height {
            return Ok(self.staging_texture.as_ref().unwrap());
        }

        let desc = D3D11_TEXTURE2D_DESC {
            Width: width,
            Height: height,
            MipLevels: 1,
            ArraySize: 1,
            Format: DXGI_FORMAT_B8G8R8A8_UNORM,
            SampleDesc: DXGI_SAMPLE_DESC {
                Count: 1,
                Quality: 0,
            },
            Usage: D3D11_USAGE_STAGING,
            BindFlags: 0,
            CPUAccessFlags: D3D11_CPU_ACCESS_READ.0 as u32,
            MiscFlags: 0,
        };

        let mut tex: Option<ID3D11Texture2D> = None;
        self.device
            .CreateTexture2D(&desc, None, Some(&mut tex))
            .context("failed to create D3D11 staging texture")?;

        self.staging_texture = tex;
        self.width = width;
        self.height = height;
        Ok(self.staging_texture.as_ref().unwrap())
    }

    /// Capture a frame from the desktop.
    ///
    /// Returns:
    /// - `Ok(Some((w, h, bgra_data)))` if a new frame was captured.
    /// - `Ok(None)` if no update occurred within timeout (screen is static).
    /// - `Err(e)` on unrecoverable DXGI error.
    pub fn capture_frame(&mut self, timeout_ms: u32) -> Result<Option<(u32, u32, Vec<u8>)>> {
        unsafe {
            let mut frame_info = DXGI_OUTDUPL_FRAME_INFO::default();
            let mut resource: Option<IDXGIResource> = None;

            let hr = self.duplication.AcquireNextFrame(
                timeout_ms,
                &mut frame_info,
                &mut resource,
            );

            if let Err(e) = hr {
                if e.code() == DXGI_ERROR_WAIT_TIMEOUT {
                    // No frame change within timeout; screen is idle
                    return Ok(None);
                }
                if e.code() == DXGI_ERROR_ACCESS_LOST || e.code() == DXGI_ERROR_INVALID_CALL {
                    warn!("DXGI access lost, attempting reinitialization: {e}");
                    if let Err(reinit_err) = self.reinitialize() {
                        bail!("DXGI reinit failed: {reinit_err}");
                    }
                    return Ok(None);
                }
                bail!("DXGI AcquireNextFrame error: {e}");
            }

            let resource = match resource {
                Some(r) => r,
                None => {
                    let _ = self.duplication.ReleaseFrame();
                    return Ok(None);
                }
            };

            let desktop_tex: ID3D11Texture2D = resource.cast().context("cast resource to texture2D")?;
            let mut desc = D3D11_TEXTURE2D_DESC::default();
            desktop_tex.GetDesc(&mut desc);

            let width = desc.Width;
            let height = desc.Height;

            let staging_tex = match self.ensure_staging_texture(width, height) {
                Ok(t) => t.clone(),
                Err(e) => {
                    let _ = self.duplication.ReleaseFrame();
                    return Err(e);
                }
            };

            // Copy from GPU desktop surface to CPU-readable staging texture
            self.context.CopyResource(&staging_tex, &desktop_tex);
            // Release frame as quickly as possible so Desktop Window Manager continues
            let _ = self.duplication.ReleaseFrame();

            // Map staging texture to read BGRA pixel bytes
            let mut mapped = D3D11_MAPPED_SUBRESOURCE::default();
            self.context
                .Map(&staging_tex, 0, D3D11_MAP_READ, 0, Some(&mut mapped))
                .context("failed to map staging texture")?;

            let row_bytes = (width * 4) as usize;
            let src_pitch = mapped.RowPitch as usize;
            let src_ptr = mapped.pData as *const u8;

            let mut bgra_buf = vec![0u8; (width * height * 4) as usize];
            for y in 0..height as usize {
                let src_row = std::slice::from_raw_parts(src_ptr.add(y * src_pitch), row_bytes);
                let dst_offset = y * row_bytes;
                bgra_buf[dst_offset..dst_offset + row_bytes].copy_from_slice(src_row);
            }

            self.context.Unmap(&staging_tex, 0);

            Ok(Some((width, height, bgra_buf)))
        }
    }
}
