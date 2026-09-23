use crate::mention_registry::{mention_has_device, MentionResolved};

struct MentionToolRule {
    when_topic: &'static str,
    tools: &'static [&'static str],
}

const TOPIC_FORCE_TOOLS: &[MentionToolRule] = &[MentionToolRule {
    when_topic: "web.builder",
    tools: &[
        "site.draft_put",
        "site.publish",
        "site.product_put",
        "site.contact_put",
        "site.object_put",
    ],
}];

fn push_unique(out: &mut Vec<String>, tool: &str) {
    if !out.iter().any(|x| x == tool) {
        out.push(tool.to_string());
    }
}

pub fn mention_force_tools(resolved: &[MentionResolved]) -> Vec<String> {
    let mut out = Vec::new();
    if mention_has_device(resolved) {
        push_unique(&mut out, "device.screenshot");
    }
    for r in resolved {
        for rule in TOPIC_FORCE_TOOLS {
            if r.item.topic_id == rule.when_topic {
                for tool in rule.tools {
                    push_unique(&mut out, tool);
                }
            }
        }
    }
    out
}
