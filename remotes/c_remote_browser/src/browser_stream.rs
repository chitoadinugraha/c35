use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use bytes::Bytes;
use tokio::time::{Duration, MissedTickBehavior};
use tracing::info;
use webrtc::data_channel::RTCDataChannel;

const SCTP_MAX: usize = 60_000;
const CHUNK_PAYLOAD: usize = 48_000;

static STREAM_ACTIVE: AtomicBool = AtomicBool::new(false);

fn make_screen_packet(w: u16, h: u16, ts_ms: u64, jpeg: &[u8]) -> Vec<u8> {
    let mut packet = Vec::with_capacity(16 + jpeg.len());
    packet.extend_from_slice(b"CS35");
    packet.extend_from_slice(&w.to_be_bytes());
    packet.extend_from_slice(&h.to_be_bytes());
    packet.extend_from_slice(&ts_ms.to_be_bytes());
    packet.extend_from_slice(jpeg);
    packet
}

fn make_screen_chunks(frame_id: u32, w: u16, h: u16, ts_ms: u64, jpeg: &[u8]) -> Vec<Vec<u8>> {
    let total_chunks = ((jpeg.len() + CHUNK_PAYLOAD - 1) / CHUNK_PAYLOAD).max(1) as u16;
    let mut chunks = Vec::with_capacity(total_chunks as usize);
    for (idx, slice) in jpeg.chunks(CHUNK_PAYLOAD).enumerate() {
        let mut packet = Vec::with_capacity(24 + slice.len());
        packet.extend_from_slice(b"CS36");
        packet.extend_from_slice(&frame_id.to_be_bytes());
        packet.extend_from_slice(&(idx as u16).to_be_bytes());
        packet.extend_from_slice(&total_chunks.to_be_bytes());
        packet.extend_from_slice(&w.to_be_bytes());
        packet.extend_from_slice(&h.to_be_bytes());
        packet.extend_from_slice(&ts_ms.to_be_bytes());
        packet.extend_from_slice(slice);
        chunks.push(packet);
    }
    chunks
}

pub fn start_browser_screen_stream(dc: std::sync::Arc<RTCDataChannel>) {
    tokio::spawn(async move {
        STREAM_ACTIVE.store(true, Ordering::SeqCst);
        info!("browser remote-screen SCTP stream started");
        let mut interval = tokio::time::interval(Duration::from_millis(1000 / 20));
        interval.set_missed_tick_behavior(MissedTickBehavior::Skip);
        let mut frame_id: u32 = 0;
        while STREAM_ACTIVE.load(Ordering::SeqCst) {
            interval.tick().await;
            let st = crate::browser_state::global();
            let frame = st.and_then(|s| s.take_frame());
            let frame = match frame {
                Some(f) => f,
                None => continue,
            };
            let ts_ms = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis() as u64;
            let send = if frame.jpeg.len() + 16 <= SCTP_MAX {
                let packet = make_screen_packet(frame.width, frame.height, ts_ms, &frame.jpeg);
                dc.send(&Bytes::from(packet)).await.map(|_| ()).map_err(|e| e.to_string())
            } else {
                frame_id += 1;
                let chunks = make_screen_chunks(frame_id, frame.width, frame.height, ts_ms, &frame.jpeg);
                let mut ok = Ok(());
                for c in chunks {
                    if let Err(e) = dc.send(&Bytes::from(c)).await {
                        ok = Err(e.to_string());
                        break;
                    }
                }
                ok
            };
            if let Err(e) = send {
                tracing::debug!("browser screen send: {e}");
            }
        }
    });
}