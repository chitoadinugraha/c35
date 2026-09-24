//! WebRTC peer sessions — signaling relay + `remote-fs` data channel.

use std::collections::HashMap;
use std::sync::Arc;

use bytes::Bytes;

use c35_proto::{
    pb_decode, pb_encode, RemoteConnectionMode, RemoteSessionPush, ReqRemoteCommand,
    ReqRemoteScreenshot, ReqRemoteSessionStart, ResRemoteCommand, ResRemoteScreenshot,
    RtcSignalAnswer, RtcSignalIce, RtcSignalOffer, WsReq, WsRes, ws_req, ws_res,
};
use tokio::sync::{mpsc, RwLock};
use tracing::{info, warn};
use webrtc::api::media_engine::MediaEngine;
use webrtc::api::APIBuilder;
use webrtc::data_channel::data_channel_message::DataChannelMessage;
use webrtc::ice_transport::ice_candidate::RTCIceCandidateInit;
use webrtc::ice_transport::ice_server::RTCIceServer;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::peer_connection_state::RTCPeerConnectionState;
use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use webrtc::peer_connection::RTCPeerConnection;
use webrtc::rtp_transceiver::rtp_codec::RTCRtpCodecCapability;
use webrtc::track::track_local::track_local_static_sample::TrackLocalStaticSample;
use webrtc::track::track_local::TrackLocal;

use super::fs::fs_dispatch;

type SessionMap = HashMap<String, Arc<WebrtcSession>>;

static ACTIVE_HUB: std::sync::RwLock<Option<std::sync::Weak<WebrtcHub>>> = std::sync::RwLock::new(None);

pub async fn notify_update_ready(version: i64) {
    let hub_opt = {
        ACTIVE_HUB.read().ok().and_then(|g| g.as_ref().and_then(|w| w.upgrade()))
    };
    if let Some(hub) = hub_opt {
        hub.broadcast_update_ready(version).await;
    }
}

pub struct WebrtcHub {
    device_iid: i64,
    out_tx: mpsc::UnboundedSender<Vec<u8>>,
    sessions: Arc<RwLock<SessionMap>>,
    dispatch_ctx: Arc<crate::skill_dispatch::DispatchCtx>,
}

struct WebrtcSession {
    pc: Arc<RTCPeerConnection>,
}

impl WebrtcHub {
    pub fn new(
        device_iid: i64,
        out_tx: mpsc::UnboundedSender<Vec<u8>>,
        dispatch_ctx: Arc<crate::skill_dispatch::DispatchCtx>,
    ) -> Arc<Self> {
        let hub = Arc::new(Self {
            device_iid,
            out_tx,
            sessions: Arc::new(RwLock::new(HashMap::new())),
            dispatch_ctx,
        });
        if let Ok(mut g) = ACTIVE_HUB.write() {
            *g = Some(Arc::downgrade(&hub));
        }
        hub
    }

    pub async fn broadcast_update_ready(&self, version: i64) {
        let s = self.sessions.read().await;
        for (sid, _) in s.iter() {
            let frame = WsRes {
                req_id: String::new(),
                body: Some(ws_res::Body::RemoteSessionPush(RemoteSessionPush {
                    device_iid: self.device_iid,
                    session_id: sid.clone(),
                    mode: RemoteConnectionMode::Unspecified as i32,
                    selected_ice: 0,
                    video_active: false,
                    webrtc_connected: true,
                    update_ready: true,
                    update_version: version,
                })),
            };
            let _ = self.out_tx.send(pb_encode(&frame));
        }
    }

    pub async fn handle_frame(&self, data: &[u8]) {
        if let Ok(req) = pb_decode::<WsReq>(data) {
            self.handle_req(req).await;
            return;
        }
        if let Ok(res) = pb_decode::<WsRes>(data) {
            self.handle_res(res).await;
            return;
        }
        if let Err(e) = crate::task_run::task_run_handle(data, &self.dispatch_ctx).await {
            warn!("task_run_handle: {e}");
        }
    }

    async fn handle_req(&self, req: WsReq) {
        match req.body {
            Some(ws_req::Body::RemoteSessionStart(start)) => {
                self.session_start(start).await;
            }
            Some(ws_req::Body::RemoteSessionStop(stop)) => {
                self.session_stop(&stop.session_id).await;
            }
            Some(ws_req::Body::RtcSignalOffer(offer)) => {
                self.handle_offer(offer).await;
            }
            Some(ws_req::Body::RtcSignalIce(ice)) => {
                self.handle_ice(ice).await;
            }
            Some(ws_req::Body::ReqRemoteScreenshot(s)) => {
                self.handle_screenshot(req.req_id, s).await;
            }
            Some(ws_req::Body::ReqRemoteCommand(cmd)) => {
                self.handle_command(req.req_id, cmd).await;
            }
            _ => {}
        }
    }

    async fn handle_res(&self, res: WsRes) {
        match res.body {
            Some(ws_res::Body::RtcSignalOffer(offer)) => self.handle_offer(offer).await,
            Some(ws_res::Body::RtcSignalIce(ice)) => self.handle_ice(ice).await,
            _ => {}
        }
    }

    async fn handle_screenshot(&self, req_id: String, req: ReqRemoteScreenshot) {
        let max_w = if req.max_width == 0 { 1280 } else { req.max_width };
        let quality = if req.quality == 0 { 72 } else { req.quality.min(100) as u8 };
        let marker = if req.marker_x > 0.0 || req.marker_y > 0.0 {
            Some((req.marker_x, req.marker_y))
        } else {
            None
        };
        let res_body = match dispatch_screenshot(max_w, quality, marker, req.som) {
            Ok((w, h, bytes, axtree)) => ResRemoteScreenshot {
                ok: true,
                error: String::new(),
                width: w as u32,
                height: h as u32,
                jpeg_bytes: bytes,
                axtree_text: axtree,
            },
            Err(e) => ResRemoteScreenshot {
                ok: false,
                error: e.to_string(),
                width: 0,
                height: 0,
                jpeg_bytes: Vec::new(),
                axtree_text: String::new(),
            },
        };
        let res = WsRes {
            req_id,
            body: Some(ws_res::Body::ResRemoteScreenshot(res_body)),
        };
        let _ = self.out_tx.send(pb_encode(&res));
    }

    async fn handle_command(&self, req_id: String, req: ReqRemoteCommand) {
        let _task_guard = crate::update::task_start();
        let cmd = req.command.trim().to_string();
        let timeout_secs = if req.timeout_sec == 0 { 15 } else { req.timeout_sec.min(60) };

        let res_body = if cmd.is_empty() {
            ResRemoteCommand {
                ok: false,
                error: "empty command".into(),
                exit_code: -1,
                stdout: String::new(),
                stderr: String::new(),
            }
        } else {
            #[cfg(windows)]
            {
                let run_res = tokio::time::timeout(
                    std::time::Duration::from_secs(timeout_secs as u64),
                    tokio::task::spawn_blocking(move || {
                        std::process::Command::new("powershell")
                            .args(["-NoProfile", "-NonInteractive", "-Command", &cmd])
                            .output()
                    }),
                )
                .await;

                match run_res {
                    Ok(Ok(Ok(output))) => ResRemoteCommand {
                        ok: output.status.success(),
                        error: String::new(),
                        exit_code: output.status.code().unwrap_or(-1),
                        stdout: String::from_utf8_lossy(&output.stdout).to_string(),
                        stderr: String::from_utf8_lossy(&output.stderr).to_string(),
                    },
                    Ok(Ok(Err(e))) => ResRemoteCommand {
                        ok: false,
                        error: format!("process spawn error: {e}"),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    },
                    Ok(Err(e)) => ResRemoteCommand {
                        ok: false,
                        error: format!("task join error: {e}"),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    },
                    Err(_) => ResRemoteCommand {
                        ok: false,
                        error: format!("command execution timed out after {timeout_secs}s"),
                        exit_code: -1,
                        stdout: String::new(),
                        stderr: String::new(),
                    },
                }
            }
            #[cfg(not(windows))]
            {
                ResRemoteCommand {
                    ok: false,
                    error: "command execution only supported on Windows agent".into(),
                    exit_code: -1,
                    stdout: String::new(),
                    stderr: String::new(),
                }
            }
        };

        let res = WsRes {
            req_id,
            body: Some(ws_res::Body::ResRemoteCommand(res_body)),
        };
        let _ = self.out_tx.send(pb_encode(&res));
    }

    async fn session_start(&self, start: ReqRemoteSessionStart) {
        let session_id = start.session_id.trim().to_string();
        if session_id.is_empty() {
            return;
        }
        if self.sessions.read().await.contains_key(&session_id) {
            return;
        }
        match WebrtcSession::create(
            self.device_iid,
            session_id.clone(),
            self.out_tx.clone(),
            ice_servers_load(),
        )
        .await
        {
            Ok(sess) => {
                info!(session_id = %session_id, "==> [WEBRTC SESSION CREATED] Peer session initialized for viewer");
                crate::log_push::spawn_log_push(
                    self.dispatch_ctx.server_url.clone(),
                    self.dispatch_ctx.session_key.clone(),
                    "conn".into(),
                    "agent.webrtc".into(),
                    format!("webrtc session started sid={session_id}"),
                    Some(serde_json::json!({ "session_id": session_id, "device_iid": self.device_iid })),
                );
                let count = {
                    let mut w = self.sessions.write().await;
                    w.insert(session_id, Arc::new(sess));
                    w.len()
                };
                crate::update::active_sessions_set(count);
            }
            Err(e) => {
                warn!(session_id = %session_id, "==> [WEBRTC SESSION FAILED] Create error: {e}");
                crate::log_push::spawn_log_push(
                    self.dispatch_ctx.server_url.clone(),
                    self.dispatch_ctx.session_key.clone(),
                    "error".into(),
                    "agent.webrtc".into(),
                    format!("webrtc session create failed: {e}"),
                    Some(serde_json::json!({ "session_id": session_id, "device_iid": self.device_iid, "error": e.to_string() })),
                );
            }
        }
    }

    async fn session_stop(&self, session_id: &str) {
        let sid = session_id.trim();
        if sid.is_empty() {
            return;
        }
        let count = {
            let mut w = self.sessions.write().await;
            if let Some(sess) = w.remove(sid) {
                sess.close().await;
                push_connected(&self.out_tx, self.device_iid, sid, false, None);
                info!(session_id = %sid, "==> [WEBRTC SESSION STOPPED] Viewer disconnected");
                crate::log_push::spawn_log_push(
                    self.dispatch_ctx.server_url.clone(),
                    self.dispatch_ctx.session_key.clone(),
                    "conn".into(),
                    "agent.webrtc".into(),
                    format!("webrtc session stopped sid={sid}"),
                    Some(serde_json::json!({ "session_id": sid, "device_iid": self.device_iid })),
                );
            }
            w.len()
        };
        crate::update::active_sessions_set(count);
    }

    async fn session_get(&self, session_id: &str) -> Option<Arc<WebrtcSession>> {
        self.sessions.read().await.get(session_id).cloned()
    }

    async fn handle_offer(&self, offer: RtcSignalOffer) {
        let session_id = offer.session_id.trim().to_string();
        if session_id.is_empty() {
            return;
        }
        if self.session_get(&session_id).await.is_none() {
            self.session_start(
                ReqRemoteSessionStart {
                    device_iid: offer.device_iid,
                    session_id: session_id.clone(),
                },
            )
            .await;
        }
        let sess = match self.session_get(&session_id).await {
            Some(s) => s,
            None => return,
        };
        if let Err(e) = sess.apply_offer(&offer.sdp).await {
            warn!(session_id = %session_id, "apply offer failed: {e}");
            return;
        }
        match sess.create_answer().await {
            Ok(sdp) => send_answer(&self.out_tx, offer.device_iid, &session_id, sdp),
            Err(e) => warn!(session_id = %session_id, "create answer failed: {e}"),
        }
    }

    async fn handle_ice(&self, ice: RtcSignalIce) {
        let session_id = ice.session_id.trim();
        if session_id.is_empty() {
            return;
        }
        let sess = match self.session_get(session_id).await {
            Some(s) => s,
            None => return,
        };
        if ice.candidate.is_empty() {
            return;
        }
        let init = RTCIceCandidateInit {
            candidate: ice.candidate,
            sdp_mid: if ice.sdp_mid.is_empty() {
                None
            } else {
                Some(ice.sdp_mid)
            },
            sdp_mline_index: Some(ice.sdp_mline_index as u16),
            username_fragment: None,
        };
        if let Err(e) = sess.pc.add_ice_candidate(init).await {
            warn!(session_id = %session_id, "add ice candidate failed: {e}");
        }
    }
}

impl WebrtcSession {
    async fn create(
        device_iid: i64,
        session_id: String,
        out_tx: mpsc::UnboundedSender<Vec<u8>>,
        ice_servers: Vec<RTCIceServer>,
    ) -> anyhow::Result<Self> {
        let mut media_engine = MediaEngine::default();
        media_engine.register_default_codecs()?;
        let api = APIBuilder::new().with_media_engine(media_engine).build();
        let config = RTCConfiguration {
            ice_servers,
            ..Default::default()
        };
        let pc = Arc::new(api.new_peer_connection(config).await?);

        let video_track = Arc::new(TrackLocalStaticSample::new(
            RTCRtpCodecCapability {
                mime_type: "video/VP8".to_owned(),
                ..Default::default()
            },
            "screen".to_owned(),
            "c35-screen".to_owned(),
        ));
        let _ = pc.add_track(Arc::clone(&video_track) as Arc<dyn TrackLocal + Send + Sync>);

        let audio_track = Arc::new(TrackLocalStaticSample::new(
            RTCRtpCodecCapability {
                mime_type: "audio/opus".to_owned(),
                ..Default::default()
            },
            "audio".to_owned(),
            "c35-audio".to_owned(),
        ));
        let _ = pc.add_track(Arc::clone(&audio_track) as Arc<dyn TrackLocal + Send + Sync>);

        let connected_pushed = Arc::new(RwLock::new(false));
        let sid = session_id.clone();
        let dev = device_iid;
        let out = out_tx.clone();
        let pushed = Arc::clone(&connected_pushed);
        let v_track = Arc::clone(&video_track);
        let a_track = Arc::clone(&audio_track);

        pc.on_peer_connection_state_change(Box::new(move |state| {
            let out = out.clone();
            let pushed = Arc::clone(&pushed);
            let sid = sid.clone();
            let v_track = Arc::clone(&v_track);
            let a_track = Arc::clone(&a_track);
            Box::pin(async move {
                info!(session_id = %sid, ?state, "==> [WEBRTC STATE] PC state changed: {:?}", state);
                if state == RTCPeerConnectionState::Connected {
                    let already = *pushed.read().await;
                    if !already {
                        *pushed.write().await = true;
                        info!(session_id = %sid, "==> [WEBRTC CONNECTED] Remote viewer is streaming desktop live");
                        push_connected(&out, dev, &sid, true, Some(RemoteConnectionMode::Direct));
                        dispatch_media_tracks(v_track, Some(a_track));
                    }
                } else if state == RTCPeerConnectionState::Failed
                    || state == RTCPeerConnectionState::Closed
                    || state == RTCPeerConnectionState::Disconnected
                {
                    *pushed.write().await = false;
                    warn!(session_id = %sid, ?state, "==> [WEBRTC DISCONNECTED] Peer connection ended");
                    push_connected(&out, dev, &sid, false, None);
                }
            })
        }));

        let out_ice = out_tx.clone();
        let dev_ice = device_iid;
        let sid_ice = session_id.clone();
        pc.on_ice_candidate(Box::new(move |c| {
            let out = out_ice.clone();
            let sid = sid_ice.clone();
            Box::pin(async move {
                if let Some(cand) = c {
                    if let Ok(json) = cand.to_json() {
                        send_ice(
                            &out,
                            dev_ice,
                            &sid,
                            json.candidate,
                            json.sdp_mid.unwrap_or_default(),
                            json.sdp_mline_index.unwrap_or(0) as u32,
                        );
                    }
                }
            })
        }));

        let sid_dc = session_id.clone();
        pc.on_data_channel(Box::new(move |dc| {
            let label = dc.label();
            info!(session_id = %sid_dc, label = %label, "==> [WEBRTC DATA CHANNEL OPENED] Channel '{}' ready", label);
            if label == "remote-fs" {
                wire_fs_channel(dc);
            } else if label == "remote-input" {
                wire_input_channel(dc);
            } else if label == "remote-screen" {
                wire_screen_channel(dc);
            }
            Box::pin(async {})
        }));

        Ok(Self { pc })
    }

    async fn apply_offer(&self, sdp: &str) -> anyhow::Result<()> {
        let offer = RTCSessionDescription::offer(sdp.to_string())?;
        self.pc.set_remote_description(offer).await?;
        Ok(())
    }

    async fn create_answer(&self) -> anyhow::Result<String> {
        let answer = self.pc.create_answer(None).await?;
        self.pc.set_local_description(answer).await?;
        Ok(self
            .pc
            .local_description()
            .await
            .map(|d| d.sdp)
            .unwrap_or_default())
    }

    async fn close(&self) {
        let _ = self.pc.close().await;
    }
}

pub type InputHandler = Arc<dyn Fn(&c35_proto::RemoteInputEvent) + Send + Sync>;
static INPUT_HANDLER: std::sync::OnceLock<InputHandler> = std::sync::OnceLock::new();

pub fn set_input_handler(handler: InputHandler) {
    let _ = INPUT_HANDLER.set(handler);
}

pub fn dispatch_input(evt: &c35_proto::RemoteInputEvent) {
    if let Some(h) = INPUT_HANDLER.get() {
        h(evt);
    }
}

pub type ScreenHandler = Arc<dyn Fn(Arc<webrtc::data_channel::RTCDataChannel>) + Send + Sync>;
static SCREEN_HANDLER: std::sync::OnceLock<ScreenHandler> = std::sync::OnceLock::new();

pub fn set_screen_handler(handler: ScreenHandler) {
    let _ = SCREEN_HANDLER.set(handler);
}

pub fn dispatch_screen_channel(dc: Arc<webrtc::data_channel::RTCDataChannel>) {
    if let Some(h) = SCREEN_HANDLER.get() {
        h(dc);
    }
}

pub type TrackHandler = Arc<
    dyn Fn(Arc<TrackLocalStaticSample>, Option<Arc<TrackLocalStaticSample>>) + Send + Sync,
>;
static TRACK_HANDLER: std::sync::OnceLock<TrackHandler> = std::sync::OnceLock::new();

pub fn set_track_handler(handler: TrackHandler) {
    let _ = TRACK_HANDLER.set(handler);
}

pub fn dispatch_media_tracks(
    video: Arc<TrackLocalStaticSample>,
    audio: Option<Arc<TrackLocalStaticSample>>,
) {
    if let Some(h) = TRACK_HANDLER.get() {
        h(video, audio);
    }
}

pub type ScreenshotHandler = Arc<
    dyn Fn(u32, u8, Option<(f64, f64)>, bool) -> anyhow::Result<(u16, u16, Vec<u8>, String)>
        + Send
        + Sync,
>;
static SCREENSHOT_HANDLER: std::sync::OnceLock<ScreenshotHandler> = std::sync::OnceLock::new();

pub fn set_screenshot_handler(handler: ScreenshotHandler) {
    let _ = SCREENSHOT_HANDLER.set(handler);
}

pub fn dispatch_screenshot(
    max_w: u32,
    quality: u8,
    marker: Option<(f64, f64)>,
    som: bool,
) -> anyhow::Result<(u16, u16, Vec<u8>, String)> {
    if let Some(h) = SCREENSHOT_HANDLER.get() {
        h(max_w, quality, marker, som)
    } else {
        anyhow::bail!("screenshot handler not registered on this device agent")
    }
}

fn wire_screen_channel(dc: Arc<webrtc::data_channel::RTCDataChannel>) {
    dc.on_open(Box::new({
        let dc = Arc::clone(&dc);
        move || {
            let dc = Arc::clone(&dc);
            Box::pin(async move {
                dispatch_screen_channel(dc);
            })
        }
    }));
}

fn wire_input_channel(dc: Arc<webrtc::data_channel::RTCDataChannel>) {
    dc.on_message(Box::new(|msg: DataChannelMessage| {
        let data = msg.data.to_vec();
        Box::pin(async move {
            if let Ok(evt) = pb_decode::<c35_proto::RemoteInputEvent>(&data) {
                dispatch_input(&evt);
            }
        })
    }));
}

fn wire_fs_channel(dc: Arc<webrtc::data_channel::RTCDataChannel>) {
    dc.on_message(Box::new({
        let dc = Arc::clone(&dc);
        move |msg: DataChannelMessage| {
            let data = msg.data.to_vec();
            let ch = Arc::clone(&dc);
            Box::pin(async move {
                let resp = fs_dispatch(&data);
                if let Err(e) = ch.send(&Bytes::from(resp)).await {
                    warn!("remote-fs send failed: {e}");
                }
            })
        }
    }));
}

fn ice_servers_load() -> Vec<RTCIceServer> {
    let fallback = vec![RTCIceServer {
        urls: vec![
            "stun:stun.alienai.id:3479".to_string(),
            "stun:turn.alienai.id:3479".to_string(),
            "stun:stun.l.google.com:19302".to_string(),
        ],
        username: String::new(),
        credential: String::new(),
        credential_type: Default::default(),
    }];
    let raw = std::env::var("C35_ICE_SERVERS").unwrap_or_default();
    if raw.trim().is_empty() {
        return fallback;
    }
    #[derive(serde::Deserialize)]
    struct IceEntry {
        urls: Vec<String>,
        username: Option<String>,
        credential: Option<String>,
    }
    match serde_json::from_str::<Vec<IceEntry>>(&raw) {
        Ok(entries) if !entries.is_empty() => entries
            .into_iter()
            .map(|e| RTCIceServer {
                urls: e.urls,
                username: e.username.unwrap_or_default(),
                credential: e.credential.unwrap_or_default(),
                credential_type: Default::default(),
            })
            .collect(),
        _ => {
            warn!("C35_ICE_SERVERS invalid JSON; using default STUN");
            fallback
        }
    }
}

fn send_answer(out_tx: &mpsc::UnboundedSender<Vec<u8>>, device_iid: i64, session_id: &str, sdp: String) {
    let frame = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::RtcSignalAnswer(RtcSignalAnswer {
            device_iid,
            session_id: session_id.to_string(),
            sdp,
        })),
    };
    let _ = out_tx.send(pb_encode(&frame));
}

fn send_ice(
    out_tx: &mpsc::UnboundedSender<Vec<u8>>,
    device_iid: i64,
    session_id: &str,
    candidate: String,
    sdp_mid: String,
    sdp_mline_index: u32,
) {
    let frame = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::RtcSignalIce(RtcSignalIce {
            device_iid,
            session_id: session_id.to_string(),
            candidate,
            sdp_mid,
            sdp_mline_index,
        })),
    };
    let _ = out_tx.send(pb_encode(&frame));
}

fn push_connected(
    out_tx: &mpsc::UnboundedSender<Vec<u8>>,
    device_iid: i64,
    session_id: &str,
    webrtc_connected: bool,
    mode: Option<RemoteConnectionMode>,
) {
    let staged = crate::update::update_staged_version();
    let frame = WsRes {
        req_id: String::new(),
        body: Some(ws_res::Body::RemoteSessionPush(RemoteSessionPush {
            device_iid,
            session_id: session_id.to_string(),
            mode: mode.map(|m| m as i32).unwrap_or(RemoteConnectionMode::Unspecified as i32),
            selected_ice: 0,
            video_active: false,
            webrtc_connected,
            update_ready: staged.is_some(),
            update_version: staged.unwrap_or(0),
        })),
    };
    let _ = out_tx.send(pb_encode(&frame));
}
