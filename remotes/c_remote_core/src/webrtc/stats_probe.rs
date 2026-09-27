use std::sync::Arc;

use c35_proto::RemoteConnectionMode;
use webrtc::peer_connection::peer_connection_state::RTCPeerConnectionState;
use webrtc::peer_connection::RTCPeerConnection;

use webrtc::stats::StatsReportType;

pub async fn connection_mode_probe(pc: &Arc<RTCPeerConnection>) -> Option<RemoteConnectionMode> {
    for delay_ms in [400_u64, 800, 1500, 2500] {
        tokio::time::sleep(std::time::Duration::from_millis(delay_ms)).await;
        if pc.connection_state() != RTCPeerConnectionState::Connected {
            return None;
        }
        let stats = pc.get_stats().await;
        for report in stats.reports.values() {
            if let StatsReportType::CandidatePair(pair) = report {
                if !pair.nominated {
                    continue;
                }
                let relay = [pair.local_candidate_id.as_str(), pair.remote_candidate_id.as_str()]
                    .iter()
                    .filter_map(|id| stats.reports.get(*id))
                    .any(|c| candidate_is_relay(c));
                return Some(if relay {
                    RemoteConnectionMode::Relay
                } else {
                    RemoteConnectionMode::Direct
                });
            }
        }
    }
    None
}

fn candidate_is_relay(report: &StatsReportType) -> bool {
    match report {
        StatsReportType::LocalCandidate(c) => c.candidate_type == webrtc::ice::candidate::CandidateType::Relay,
        StatsReportType::RemoteCandidate(c) => c.candidate_type == webrtc::ice::candidate::CandidateType::Relay,
        _ => false,
    }
}