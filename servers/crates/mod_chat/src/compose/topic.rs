use crate::mention::MentionRow;

pub fn topic_resolve(explicit: &str, mention_ids: &[String], mentions: &[MentionRow]) -> String {
    let explicit = explicit.trim();
    if !explicit.is_empty() {
        return explicit.to_string();
    }
    for mid in mention_ids {
        if let Some(m) = mentions.iter().find(|m| &m.id == mid) {
            let tid = m.topic_id.trim();
            if !tid.is_empty() {
                return tid.to_string();
            }
        }
    }
    "general".into()
}

pub fn tool_topic_eligible(topics: &[String], active: &str) -> bool {
    topics.is_empty()
        || topics
            .iter()
            .any(|t| t == "*" || t == active || (active == "general" && t == "general"))
}
