use c35_mod_admin::StaffView;
use c35_mod_chat::compose::{tool_mention_eligible, tool_staff_eligible};
use c35_mod_chat::{MentionContext, SiteCapabilityView, ToolDef};

pub const LIVE_TOOL_DECL_CAP: usize = 32;

/// Tools declared to Gemini Live for one setup.
///
/// `offer_topics` empty means this offer declares no cluster tools.
/// Device topics are added when `mention.devices` is non-empty.
/// Site topics are added only when `mention.default_site_iid` is set.
pub fn live_tool_select(
    tools: &[ToolDef],
    offer_topics: &[String],
    mention: &MentionContext,
    staff: &StaffView,
    caps: &SiteCapabilityView,
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
    out.sort_by(|a, b| a.name.cmp(&b.name));
    if out.len() > LIVE_TOOL_DECL_CAP {
        out.truncate(LIVE_TOOL_DECL_CAP);
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
        let out = live_tool_select(&tools, &[], &MentionContext::empty(), &staff(), &SiteCapabilityView::empty());
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
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty());
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
        let out = live_tool_select(&tools, &topics, &mention, &staff(), &SiteCapabilityView::empty());
        let names: Vec<_> = out.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(names, vec!["device.screenshot", "web.search"]);
    }

    #[test]
    fn live_tool_select_site_topics_only_when_default_site_set() {
        let tools = vec![tool("site.create", &["web.builder"], &["site"])];
        let topics = vec!["general".to_string()];
        let bare = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty());
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
        let out = live_tool_select(&tools, &topics, &mention, &staff(), &SiteCapabilityView::empty());
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].name, "site.create");
    }

    #[test]
    fn live_tool_select_caps_at_32() {
        let tools: Vec<ToolDef> = (0..40).map(|i| tool(&format!("tool.{i:02}"), &["general"], &[])).collect();
        let topics = vec!["general".to_string()];
        let out = live_tool_select(&tools, &topics, &MentionContext::empty(), &staff(), &SiteCapabilityView::empty());
        assert_eq!(out.len(), LIVE_TOOL_DECL_CAP);
        assert_eq!(out[0].name, "tool.00");
        assert_eq!(out[31].name, "tool.31");
    }
}
