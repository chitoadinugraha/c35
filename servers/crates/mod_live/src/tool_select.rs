use c35_mod_admin::StaffView;
use c35_mod_chat::compose::{tool_mention_eligible, tool_staff_eligible};
use c35_mod_chat::{MentionContext, SiteCapabilityView, ToolDef};

pub const LIVE_TOOL_DECL_CAP: usize = 32;

/// Ends the live voice call when the user asks to hang up or say goodbye.
pub fn call_end_tool() -> ToolDef {
    ToolDef::new(
        "call.end".into(),
        "Ends the live voice call. Call when the user clearly wants to hang up, end the call, or say goodbye and disconnect.".into(),
        serde_json::json!({
            "type": "object",
            "properties": {
                "reason": {
                    "type": "string",
                    "description": "Brief reason the user wanted to end the call (optional)."
                }
            },
            "additionalProperties": false
        }),
    )
}

/// Standard Live tool to reset active topic back to general.
pub fn topic_reset_tool() -> ToolDef {
    ToolDef::new(
        "topic_reset".into(),
        "Resets the active topic or mention focus back to general conversation when the discussion naturally transitions away from the focused subject.".into(),
        serde_json::json!({
            "type": "object",
            "properties": {},
            "additionalProperties": false
        }),
    )
}

/// Tools declared to Gemini Live for one setup.
///
/// `offer_topics` empty means this offer declares no cluster tools.
/// Device topics are added when `mention.devices` is non-empty.
/// Site topics are added only when `mention.default_site_iid` is set.
/// When the offer includes topic `live`, `call.end` is declared so the user can hang up by voice.
/// When `has_active_mention` is true, the `topic_reset` tool is declared so the model can autonomously transition back to general conversation.
pub fn live_tool_select(
    tools: &[ToolDef],
    offer_topics: &[String],
    mention: &MentionContext,
    staff: &StaffView,
    caps: &SiteCapabilityView,
    has_active_mention: bool,
) -> Vec<ToolDef> {
    if offer_topics.is_empty() {
        return Vec::new();
    }
    let mut active: Vec<String> = offer_topics.to_vec();
    if !mention.devices.is_empty() {
        for topic in ["device", "computer_use"] {
            if !active.iter().any(|t| t == topic) {
                active.push(topic.to_string());
            }
        }
    }
    if mention.default_site_iid.is_some() {
        for topic in ["web.builder", "site.commerce"] {
            if !active.iter().any(|t| t == topic) {
                active.push(topic.to_string());
            }
        }
    }
    let general = active.iter().any(|t| t == "general");
    let live_session = active.iter().any(|t| t == "live");
    let mut out: Vec<ToolDef> = tools
        .iter()
        .filter(|t| t.requires_global_roles.is_empty())
        .filter(|t| tool_staff_eligible(t, staff))
        .filter(|t| tool_mention_eligible(t, mention, caps))
        .filter(|t| {
            if t.topics.is_empty() {
                return general;
            }
            t.topics.iter().any(|topic| active.iter().any(|a| a == topic))
        })
        .cloned()
        .collect();
    if live_session {
        out.push(call_end_tool());
    }
    if has_active_mention {
        out.push(topic_reset_tool());
    }
    out.sort_by(|a, b| a.name.cmp(&b.name));
    if out.len() > LIVE_TOOL_DECL_CAP {
        out.truncate(LIVE_TOOL_DECL_CAP);
        if live_session && !out.iter().any(|t| t.name == "call.end") {
            out.pop();
            out.push(call_end_tool());
        }
        if has_active_mention && !out.iter().any(|t| t.name == "topic_reset") {
            out.pop();
            out.push(topic_reset_tool());
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use c35_mod_chat::SiteContext;
    use serde_json::json;

    fn tool(name: &str, topics: &[&str], kinds: &[&str]) -> ToolDef {
        let mut t = ToolDef::new(name.into(), name.into(), json!({}));
        t.topics = topics.iter().map(|s| (*s).to_string()).collect();
        t.requires_kinds = kinds.iter().map(|s| (*s).to_string()).collect();
        t
    }

    fn staff() -> StaffView {
        StaffView::permit_all()
    }

    #[test]
    fn live_tool_select_empty_offer_declares_nothing() {
        let tools = vec![tool("web.search", &["general"], &[])];
        let out = live_tool_select(&tools, &[], &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        assert!(out.is_empty());
    }

    #[test]
    fn live_tool_select_general_keeps_web_and_memory_drops_presentation() {
        let tools = vec![
            tool("web.search", &["general"], &[]),
            tool("memory.save", &["general"], &[]),
            tool("presentation.create", &["presentation"], &[]),
        ];
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["memory.save", "web.search"]);
    }

    #[test]
    fn live_tool_select_adds_device_topics_when_devices_present() {
        let tools = vec![
            tool("web.search", &["general"], &[]),
            tool("device.screenshot", &["device"], &["device"]),
        ];
        let mut mention = MentionContext::empty();
        mention.devices.push(7);
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &mention, &staff(), &SiteCapabilityView::empty(), false);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["device.screenshot", "web.search"]);
    }

    #[test]
    fn live_tool_select_site_topics_only_when_default_site_set() {
        let tools = vec![tool("site.create", &["web.builder"], &["site"])];
        let topics = vec!["general".to_string()];
        let bare = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        assert!(bare.is_empty());
        let mention = MentionContext {
            sites: vec![SiteContext {
                site_iid: 9,
                alien_id: "shop".into(),
                name: "Shop".into(),
            }],
            devices: vec![],
            bots: vec![],
            default_site_iid: Some(9),
        };
        let out = live_tool_select(&tools, &topics, &mention, &staff(), &SiteCapabilityView::empty(), false);
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].name, "site.create");
    }

    #[test]
    fn live_tool_select_caps_at_32() {
        let tools: Vec<ToolDef> = (0..40).map(|i| tool(&format!("tool.{i:02}"), &["general"], &[])).collect();
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        assert_eq!(out.len(), LIVE_TOOL_DECL_CAP);
        assert_eq!(out[0].name, "tool.00");
        assert_eq!(out[31].name, "tool.31");
    }

    #[test]
    fn live_tool_select_includes_call_end_when_live_topic() {
        let tools = vec![tool("web.search", &["general"], &[])];
        let topics = vec!["general".to_string(), "live".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["call.end", "web.search"]);
    }

    #[test]
    fn live_tool_select_omits_call_end_without_live_topic() {
        let tools = vec![tool("web.search", &["general"], &[])];
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["web.search"]);
    }

    #[test]
    fn live_tool_select_includes_topic_reset_when_mention_active() {
        let tools = vec![tool("web.search", &["general"], &[])];
        let topics = vec!["general".to_string(), "live".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), true);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["call.end", "topic_reset", "web.search"]);
    }

    #[test]
    fn live_tool_select_omits_topic_reset_when_no_mention() {
        let tools = vec![tool("web.search", &["general"], &[])];
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty(), false);
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["web.search"]);
    }
}
