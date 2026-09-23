use crate::mention_context::MentionContext;
use crate::site_capability::SiteCapabilityView;
use crate::tools::ToolDef;

fn mention_kind_present(mention: &MentionContext, kind: &str) -> bool {
    match kind {
        "site" => !mention.sites.is_empty(),
        "device" => !mention.devices.is_empty(),
        _ => false,
    }
}

pub fn tool_mention_kinds_eligible(def: &ToolDef, mention: &MentionContext) -> bool {
    if def.requires_kinds.is_empty() {
        return true;
    }
    def.requires_kinds
        .iter()
        .all(|kind| mention_kind_present(mention, kind))
}

pub fn tool_mention_capability_eligible(
    def: &ToolDef,
    mention: &MentionContext,
    caps: &SiteCapabilityView,
) -> bool {
    let capability = def.requires_capability.as_deref();
    if capability.is_none() {
        return true;
    }
    let capability = capability.unwrap();
    if mention.sites.is_empty() {
        return false;
    }
    if def.readonly {
        return mention
            .sites
            .iter()
            .any(|site| caps.has(site.site_iid, capability));
    }
    mention
        .default_site_iid
        .map(|site_iid| caps.has(site_iid, capability))
        .unwrap_or(false)
}

pub fn tool_mention_eligible(def: &ToolDef, mention: &MentionContext, caps: &SiteCapabilityView) -> bool {
    tool_mention_kinds_eligible(def, mention) && tool_mention_capability_eligible(def, mention, caps)
}
