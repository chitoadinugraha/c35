use anyhow::{anyhow, bail, Result};

use crate::mention_registry::{mention_bot_iids, mention_device_iids, mention_ref_parse, MentionRef, MentionResolved};
use crate::site_resolve::SiteContext;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MentionContext {
    pub sites: Vec<SiteContext>,
    pub devices: Vec<i64>,
    pub bots: Vec<i64>,
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
            bots: vec![],
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

pub fn mention_context_register_site(ctx: &mut MentionContext, site_iid: i64, alien_id: &str, name: &str) {
    if site_iid <= 0 {
        return;
    }
    if !ctx.sites.iter().any(|s| s.site_iid == site_iid) {
        ctx.sites.push(SiteContext {
            site_iid,
            alien_id: alien_id.to_string(),
            name: name.to_string(),
        });
    }
    ctx.default_site_iid = Some(site_iid);
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
    let bots = mention_bot_iids(resolved);
    let default_site_iid = (sites.len() == 1).then(|| sites[0].site_iid);
    MentionContext {
        sites,
        devices,
        bots,
        default_site_iid,
    }
}

pub fn mention_context_bots_block(ctx: &MentionContext) -> String {
    if ctx.bots.is_empty() {
        return String::new();
    }
    let lines: Vec<String> = ctx
        .bots
        .iter()
        .map(|iid| format!("- bot_iid={}", iid))
        .collect();
    format!("[BOT CONTEXTS]\n{}", lines.join("\n"))
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

fn device_iids_collect(mention: &MentionContext, mention_ids: &[String]) -> Vec<i64> {
    let devices: Vec<i64> = if !mention.devices.is_empty() {
        mention.devices.clone()
    } else {
        mention_ids
            .iter()
            .filter_map(|raw| match mention_ref_parse(raw) {
                Some(MentionRef::Iid(iid)) if iid > 0 => Some(iid),
                _ => None,
            })
            .collect()
    };
    devices
        .into_iter()
        .fold(Vec::new(), |mut acc, iid| {
            if !acc.contains(&iid) {
                acc.push(iid);
            }
            acc
        })
}

/// Parse snowflake id fields from tool args (`device_iid`, `site_iid`, …). IDs exceed JS `Number` precision — prefer string; ignore lossy floats.
pub fn json_device_iid_field(args: &serde_json::Value, key: &str) -> i64 {
    match args.get(key) {
        None => 0,
        Some(v) if v.is_string() => v
            .as_str()
            .and_then(|s| s.trim().parse::<i64>().ok())
            .filter(|i| *i > 0)
            .unwrap_or(0),
        Some(v) if v.is_i64() => v.as_i64().filter(|i| *i > 0).unwrap_or(0),
        Some(v) if v.is_u64() => v.as_u64().map(|u| u as i64).filter(|i| *i > 0).unwrap_or(0),
        Some(v) if v.is_f64() => {
            let f = v.as_f64().unwrap_or(0.0);
            if f <= 0.0 {
                0
            } else {
                let n = f as i64;
                if (n as f64) == f && n > 0 { n } else { 0 }
            }
        }
        _ => 0,
    }
}

pub fn device_iid_resolve(mention: &MentionContext, mention_ids: &[String], args_device_iid: i64) -> Result<i64> {
    let devices = device_iids_collect(mention, mention_ids);
    if devices.len() == 1 {
        return Ok(devices[0]);
    }
    if args_device_iid > 0 {
        if devices.is_empty() || devices.contains(&args_device_iid) {
            return Ok(args_device_iid);
        }
        bail!("device_iid is required — multiple devices mentioned, specify device_iid");
    }
    match devices.len() {
        0 => bail!("device_iid is required — mention the device or pass device_iid"),
        1 => Ok(devices[0]),
        _ => bail!("device_iid is required — multiple devices mentioned, specify device_iid"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn json_device_iid_field_parses_string_snowflake() {
        let args = json!({ "device_iid": "98348080882880512" });
        assert_eq!(json_device_iid_field(&args, "device_iid"), 98348080882880512);
    }

    #[test]
    fn json_device_iid_field_parses_string_site_iid() {
        let args = json!({ "site_iid": "101456339882426368" });
        assert_eq!(json_device_iid_field(&args, "site_iid"), 101456339882426368);
    }
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
