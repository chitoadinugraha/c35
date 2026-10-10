use std::time::{Duration, Instant};

use serde_json::{json, Value};

pub const LIVE_SWAP_DEBOUNCE: Duration = Duration::from_secs(8);

#[derive(Debug, Default)]
pub struct LiveResume {
    pub handle: Option<String>,
}

impl LiveResume {
    /// True when Gemini announces the connection will close soon (`goAway`).
    /// The proxy answers with a make-before-break handover using [`Self::handle`].
    pub fn is_go_away(v: &Value) -> bool {
        v.get("goAway").is_some()
    }

    pub fn note_server_msg(&mut self, v: &Value) {
        let update = v.get("sessionResumptionUpdate").or_else(|| v.pointer("/sessionResumptionUpdate"));
        let Some(update) = update else {
            return;
        };
        if !update.get("resumable").and_then(|b| b.as_bool()).unwrap_or(false) {
            return;
        }
        let handle = update.get("newHandle").and_then(|h| h.as_str()).unwrap_or("").trim();
        if !handle.is_empty() {
            self.handle = Some(handle.to_string());
        }
    }

    pub fn setup_fields(&self) -> Value {
        let mut session_resumption = json!({});
        if let Some(handle) = &self.handle {
            session_resumption["handle"] = json!(handle);
        }
        json!({
            "sessionResumption": session_resumption,
            "contextWindowCompression": { "slidingWindow": {} }
        })
    }
}

pub fn live_swap_should_run(now: Instant, last: Option<Instant>, tool_inflight: bool, generation_open: bool) -> bool {
    if tool_inflight || generation_open {
        return false;
    }
    match last {
        Some(at) if now.duration_since(at) < LIVE_SWAP_DEBOUNCE => false,
        _ => true,
    }
}

/// Compact text turns for a fresh Live session. `assistant` maps to Gemini `model`.
pub fn live_text_seed(rows: &[(String, String)]) -> Vec<Value> {
    let mut out = Vec::new();
    let start = rows.len().saturating_sub(6);
    for (role, content) in rows.iter().skip(start) {
        let text = content.trim();
        if text.is_empty() {
            continue;
        }
        let text: String = text.chars().take(500).collect();
        let role = if role == "assistant" { "model" } else { "user" };
        out.push(json!({
            "clientContent": {
                "turns": [{ "role": role, "parts": [{ "text": text }] }],
                "turnComplete": true
            }
        }));
    }
    out
}

pub fn live_focus_pin(label: &str) -> Value {
    json!({
        "clientContent": {
            "turns": [{ "role": "user", "parts": [{ "text": format!("Now focused on: {}", label.trim()) }] }],
            "turnComplete": true
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn live_resume_stores_handle_only_when_resumable() {
        let mut resume = LiveResume::default();
        resume.note_server_msg(&json!({"sessionResumptionUpdate": {"resumable": false, "newHandle": "nope"}}));
        assert!(resume.handle.is_none());
        resume.note_server_msg(&json!({"sessionResumptionUpdate": {"resumable": true, "newHandle": "h1"}}));
        assert_eq!(resume.handle.as_deref(), Some("h1"));
        let fields = resume.setup_fields();
        assert_eq!(fields["sessionResumption"]["handle"], "h1");
        assert!(fields.get("contextWindowCompression").is_some());
    }

    #[test]
    fn live_go_away_detected() {
        assert!(LiveResume::is_go_away(&json!({"goAway": {"timeLeft": "50s"}})));
        assert!(!LiveResume::is_go_away(&json!({"serverContent": {}})));
    }

    #[test]
    fn live_text_seed_maps_assistant_and_trims() {
        let long = "x".repeat(600);
        let rows = vec![
            ("user".into(), " hello ".into()),
            ("assistant".into(), long),
        ];
        let seed = live_text_seed(&rows);
        assert_eq!(seed.len(), 2);
        assert_eq!(seed[0]["clientContent"]["turns"][0]["role"], "user");
        assert_eq!(seed[1]["clientContent"]["turns"][0]["role"], "model");
        let text = seed[1]["clientContent"]["turns"][0]["parts"][0]["text"].as_str().unwrap();
        assert_eq!(text.chars().count(), 500);
    }

    #[test]
    fn live_swap_should_run_gates() {
        let now = Instant::now();
        assert!(!live_swap_should_run(now, None, true, false));
        assert!(!live_swap_should_run(now, None, false, true));
        assert!(!live_swap_should_run(now, Some(now), false, false));
        assert!(live_swap_should_run(now, None, false, false));
        assert!(live_swap_should_run(now, Some(now - LIVE_SWAP_DEBOUNCE), false, false));
    }
}
