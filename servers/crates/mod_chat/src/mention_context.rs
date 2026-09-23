use anyhow::{anyhow, bail, Result};

use crate::mention_registry::{mention_device_iids, MentionResolved};
use crate::site_resolve::SiteContext;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MentionContext {
    pub sites: Vec<SiteContext>,
    pub devices: Vec<i64>,
    pub default_site_iid: Option<i64>,
}

impl MentionContext {
    pub fn empty() -> Self {
        Self::default()
    }

    pub fn from_site(site: SiteContext) -> Self {
        Self {
            sites: vec![site.clone()],
            devices: vec![],
            default_site_iid: Some(site.site_iid),
        }
    }

    pub fn site_iids(&self) -> Vec<i64> {
        self.sites.iter().map(|s| s.site_iid).collect()
    }
}

fn site_context_from_resolved(r: &MentionResolved) -> Option<SiteContext> {
    if r.identity_kind.as_deref() != Some("site") {
        return None;
    }
    let site_iid = r.identity_iid.filter(|i| *i > 0)?;
    let alien_id = r
        .item
        .search_terms
        .iter()
        .find(|t| {
            !t.is_empty()
                && *t != &site_iid.to_string()
                && t.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
                && !t.chars().all(|c| c.is_ascii_digit())
        })
        .cloned()
        .unwrap_or_default();
    Some(SiteContext {
        site_iid,
        alien_id,
        name: r.item.title.clone(),
    })
}

pub fn mention_context_build(resolved: &[MentionResolved]) -> MentionContext {
    let mut sites: Vec<SiteContext> = Vec::new();
    for r in resolved {
        if let Some(site) = site_context_from_resolved(r) {
            if !sites.iter().any(|s: &SiteContext| s.site_iid == site.site_iid) {
                sites.push(site);
            }
        }
    }
    let devices = mention_device_iids(resolved);
    let default_site_iid = (sites.len() == 1).then(|| sites[0].site_iid);
    MentionContext {
        sites,
        devices,
        default_site_iid,
    }
}

pub fn mention_context_sites_block(ctx: &MentionContext) -> String {
    if ctx.sites.is_empty() {
        return String::new();
    }
    let lines: Vec<String> = ctx
        .sites
        .iter()
        .map(|s| format!("- site_iid={} alien_id={} name={}", s.site_iid, s.alien_id, s.name))
        .collect();
    format!("[SITE CONTEXTS]\n{}", lines.join("\n"))
}

pub fn site_iid_resolve(
    mention: &MentionContext,
    fallback_site_iid: Option<i64>,
    args_site_iid: Option<i64>,
) -> Result<i64> {
    if let Some(iid) = args_site_iid.filter(|i| *i > 0) {
        return Ok(iid);
    }
    match mention.sites.len() {
        0 => fallback_site_iid
            .filter(|i| *i > 0)
            .ok_or_else(|| anyhow!("site_iid is required — mention @alien_id or site name")),
        1 => Ok(mention.default_site_iid.unwrap_or(mention.sites[0].site_iid)),
        _ => bail!("site_iid is required — multiple sites mentioned, specify which site"),
    }
}
