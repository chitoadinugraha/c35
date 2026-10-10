//! Wayland screen capture via xdg-desktop-portal ScreenCast + PipeWire.

use std::os::fd::OwnedFd;
use std::sync::{Mutex, OnceLock};

use anyhow::{Context, Result, bail};
use ashpd::desktop::screencast::{
    CursorMode, Screencast, SelectSourcesOptions, SourceType,
};
use ashpd::desktop::{PersistMode, session::CreateSessionOptions};
use enumflags2::make_bitflags;
use pipewire as pw;
use pw::properties::properties;
use pw::spa::pod::Pod;
use pw::spa::{self, param::video::VideoInfoRaw};
use tracing::{info, warn};

struct PortalFrame {
    w: u32,
    h: u32,
    bgra: Vec<u8>,
}

struct StreamUserData {
    format: Mutex<VideoInfoRaw>,
}

static LATEST: OnceLock<Mutex<Option<PortalFrame>>> = OnceLock::new();
static SESSION_STARTED: OnceLock<Mutex<bool>> = OnceLock::new();

fn latest_mutex() -> &'static Mutex<Option<PortalFrame>> {
    LATEST.get_or_init(|| Mutex::new(None))
}

fn started_mutex() -> &'static Mutex<bool> {
    SESSION_STARTED.get_or_init(|| Mutex::new(false))
}

fn store_frame(w: u32, h: u32, bgra: Vec<u8>) {
    if let Ok(mut g) = latest_mutex().lock() {
        *g = Some(PortalFrame { w, h, bgra });
    }
}

fn copy_bgrx_frame(
    bytes: &[u8],
    offset: usize,
    stride: usize,
    w: u32,
    h: u32,
) -> Option<Vec<u8>> {
    if w == 0 || h == 0 {
        return None;
    }
    let row_bytes = (w as usize) * 4;
    let mut bgra = vec![0u8; row_bytes * h as usize];
    for y in 0..h as usize {
        let src_start = offset + y * stride;
        let src_end = src_start + row_bytes;
        if src_end > bytes.len() {
            return None;
        }
        let dst_start = y * row_bytes;
        for x in 0..w as usize {
            let si = src_start + x * 4;
            let di = dst_start + x * 4;
            bgra[di] = bytes[si];
            bgra[di + 1] = bytes[si + 1];
            bgra[di + 2] = bytes[si + 2];
            bgra[di + 3] = 255;
        }
    }
    Some(bgra)
}

async fn ensure_portal_session() -> Result<()> {
    let mut started = started_mutex()
        .lock()
        .map_err(|e| anyhow::anyhow!("portal session lock: {e}"))?;
    if *started {
        return Ok(());
    }

    info!("opening Wayland ScreenCast portal session (PipeWire)");
    let proxy = Screencast::new().await.context("Screencast proxy")?;
    let session = proxy
        .create_session(CreateSessionOptions::default())
        .await
        .context("create_session")?;

    proxy
        .select_sources(
            &session,
            SelectSourcesOptions::default()
                .set_cursor_mode(CursorMode::Embedded)
                .set_sources(make_bitflags!(SourceType::{ Monitor }))
                .set_persist_mode(PersistMode::DoNot),
        )
        .await
        .context("select_sources request")?
        .response()
        .context("select_sources")?;

    let streams = proxy
        .start(&session, None, Default::default())
        .await
        .context("screencast start request")?
        .response()
        .context("screencast start")?;

    let stream = streams
        .streams()
        .first()
        .context("no screencast stream from portal")?;
    let node_id = stream.pipe_wire_node_id();
    let fd = proxy
        .open_pipe_wire_remote(&session, Default::default())
        .await
        .context("open_pipe_wire_remote")?;

    std::thread::spawn(move || {
        if let Err(e) = pipewire_reader_thread(fd, node_id) {
            warn!("portal PipeWire reader exited: {e:#}");
        }
    });

    *started = true;
    Ok(())
}

fn pipewire_reader_thread(fd: OwnedFd, node_id: u32) -> Result<()> {
    let mainloop = pw::main_loop::MainLoop::new(None).context("pipewire mainloop")?;
    let context = pw::context::Context::new(&mainloop).context("pipewire context")?;
    let core = context.connect_fd(fd, None).context("pipewire connect_fd")?;

    let user_data = StreamUserData {
        format: Mutex::new(VideoInfoRaw::default()),
    };

    let stream = pw::stream::Stream::new(
        &core,
        "alienai-screencast",
        properties! {
            *pw::keys::MEDIA_TYPE => "Video",
            *pw::keys::MEDIA_CATEGORY => "Capture",
            *pw::keys::MEDIA_ROLE => "Screen",
        },
    )
    .context("pipewire stream")?;

    let _listener = stream
        .add_local_listener_with_user_data(user_data)
        .param_changed(|_stream, user_data, id, param| {
            if id != spa::param::ParamType::Format {
                return;
            }
            if let Some((info, _)) = VideoInfoRaw::parse_param(param) {
                if let Ok(mut g) = user_data.format.lock() {
                    *g = info;
                }
            }
        })
        .process(|stream, user_data| {
            let Some(mut buffer) = stream.dequeue_buffer() else {
                return;
            };
            let datas = buffer.datas_mut();
            if datas.is_empty() {
                return;
            }
            let data = &mut datas[0];
            let Some(bytes) = data.data() else {
                return;
            };
            let chunk = data.chunk();
            let offset = chunk.offset() as usize;
            let stride = chunk.stride() as usize;
            let format = user_data.format.lock().ok();
            let (w, h) = format
                .map(|f| (f.size().width, f.size().height))
                .filter(|(w, h)| *w > 0 && *h > 0)
                .unwrap_or_else(|| {
                    let w = (stride / 4).max(1) as u32;
                    let h = (chunk.size() / stride.max(1)).max(1) as u32;
                    (w, h)
                });
            if let Some(bgra) = copy_bgrx_frame(bytes, offset, stride, w, h) {
                store_frame(w, h, bgra);
            }
        })
        .register()
        .context("pipewire listener")?;

    let obj = pw::spa::pod::object!(
        pw::spa::utils::SpaTypes::ObjectParamFormat,
        pw::spa::param::ParamType::EnumFormat,
        pw::spa::pod::property!(
            pw::spa::param::format::FormatProperties::MediaType,
            Id,
            pw::spa::param::format::MediaType::Video
        ),
        pw::spa::pod::property!(
            pw::spa::param::format::FormatProperties::MediaSubtype,
            Id,
            pw::spa::param::format::MediaSubtype::Raw
        ),
        pw::spa::pod::property!(
            pw::spa::param::format::FormatProperties::VideoFormat,
            Choice,
            Enum,
            Id,
            pw::spa::param::video::VideoFormat::BGRx,
            pw::spa::param::video::VideoFormat::BGRx,
        ),
    );
    let values: Vec<u8> = pw::spa::pod::serialize::PodSerializer::serialize(
        std::io::Cursor::new(Vec::new()),
        &pw::spa::pod::Value::Object(obj),
    )
    .context("pipewire format pod")?
    .0
    .into_inner();

    let mut params = [Pod::from_bytes(&values).context("pipewire pod bytes")?];

    stream.connect(
        spa::utils::Direction::Input,
        Some(node_id),
        pw::stream::StreamFlags::AUTOCONNECT | pw::stream::StreamFlags::MAP_BUFFERS,
        &mut params,
    )
    .context("pipewire stream connect")?;

    mainloop.run();
    Ok(())
}

fn block_on_portal<F: std::future::Future>(f: F) -> F::Output {
    if let Ok(handle) = tokio::runtime::Handle::try_current() {
        return tokio::task::block_in_place(|| handle.block_on(f));
    }
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("tokio runtime for portal");
    rt.block_on(f)
}

pub fn capture_primary_bgra() -> Result<(u32, u32, Vec<u8>)> {
    block_on_portal(async {
        ensure_portal_session().await?;
        for _ in 0..50 {
            if let Ok(guard) = latest_mutex().lock() {
                if let Some(st) = guard.as_ref() {
                    return Ok((st.w, st.h, st.bgra.clone()));
                }
            }
            tokio::time::sleep(std::time::Duration::from_millis(20)).await;
        }
        bail!(
            "portal screencast: no frame received (approve Screen Share on the desktop or check PipeWire / xdg-desktop-portal)"
        )
    })
}

pub fn desktop_width_cap() -> u32 {
    latest_mutex()
        .lock()
        .ok()
        .and_then(|g| g.as_ref().map(|s| s.w))
        .filter(|w| *w > 0)
        .unwrap_or(0)
}
