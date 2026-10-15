//! Shared guest storefront context builder for guest chat and guest live call.
//!
//! Provides a canonical loader for published and draft site context,
//! system prompt assembly, and tool declarations.

use c35_mod_site::{
    site_draft_meta_json, site_guest_product_prompt_block, site_published, site_published_meta_json,
};
use serde_json::Value;
#[cfg(test)]
use serde_json::json;
use sqlx::{PgPool, Row};

use crate::bot_meta::BOT_WEB_TOOL_EXCLUDE;
use crate::compose::{compose_tools_and_inst_async, ComposeTurnOpts};
use crate::inst_cache::inst_list_for_turn;
use crate::inst_macro::{inst_pool_signal, inst_scopes_site_guest};
use crate::mention_context::MentionContext;
use crate::mention_registry::mention_ref_iid;
use crate::prompt::time::{time_prompt_block, time_timezone_resolve};
use crate::site_capability::SiteCapabilityView;
use crate::site_resolve::{site_context_block, SiteContext};
use crate::tools::{cluster_tool_def, http_client, ToolDef};

pub const GUEST_KNOWLEDGE_MAX_ITEMS: usize = 50;
pub const GUEST_KNOWLEDGE_MAX_CHARS: usize = 30_000;

pub const SITE_GUEST_LIVE_VOICE_INSTRUCTIONS: &str = "\
[VOICE INTERACTION & TOOLS]
You are in a live voice call with a storefront visitor. Speak naturally, warmly, and concisely in the visitor's language. Keep spoken answers brief, conversational, and helpful. You can answer questions about the store, products, and services using the provided site context. Use cart tools when the visitor asks about or wants to modify their cart. When using tools, summarize the result verbally and conversationally — never read raw JSON aloud.";

pub type ToolDeclaration = ToolDef;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GuestSiteDataMode {
    Published,
    Draft,
}

pub fn guest_site_data_mode_from_boot_mode(raw: Option<&str>) -> GuestSiteDataMode {
    match raw.map(|s| s.trim().to_lowercase()) {
        Some(s) if s == "draft" => GuestSiteDataMode::Draft,
        _ => GuestSiteDataMode::Published,
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GuestContextError {
    InvalidSiteId,
    SiteNotFound,
    SiteNotPublished,
    OwnerNotConfigured,
    ChatDisabled,
    CallDisabled,
    Database(String),
}

impl std::fmt::Display for GuestContextError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidSiteId => write!(f, "site_iid required"),
            Self::SiteNotFound => write!(f, "site not found"),
            Self::SiteNotPublished => write!(f, "site not published"),
            Self::OwnerNotConfigured => write!(f, "site owner not configured"),
            Self::ChatDisabled => write!(f, "guest chat disabled"),
            Self::CallDisabled => write!(f, "guest call disabled"),
            Self::Database(msg) => write!(f, "database error: {msg}"),
        }
    }
}

impl std::error::Error for GuestContextError {}

impl From<sqlx::Error> for GuestContextError {
    fn from(err: sqlx::Error) -> Self {
        GuestContextError::Database(err.to_string())
    }
}

impl From<anyhow::Error> for GuestContextError {
    fn from(err: anyhow::Error) -> Self {
        GuestContextError::Database(err.to_string())
    }
}

#[derive(Debug, Clone)]
pub struct GuestSiteContext {
    pub site: SiteContext,
    pub owner_iid: i64,
    pub meta: Value,
    pub data_mode: GuestSiteDataMode,
    pub caps: SiteCapabilityView,
    pub commerce: bool,
    pub chat_enabled: bool,
    pub call_enabled: bool,
    pub site_context_block: String,
    pub knowledge_block: String,
    pub products_block: String,
    pub chat_intro: Option<String>,
    pub call_intro: Option<String>,
}

impl GuestSiteContext {
    pub fn ensure_chat_enabled(&self) -> Result<(), GuestContextError> {
        if !self.chat_enabled {
            return Err(GuestContextError::ChatDisabled);
        }
        Ok(())
    }

    pub fn ensure_call_enabled(&self) -> Result<(), GuestContextError> {
        if !self.call_enabled {
            return Err(GuestContextError::CallDisabled);
        }
        Ok(())
    }
}

pub fn guest_chat_enabled(meta: &Value) -> bool {
    let ai = meta.get("ai_assistant");
    if ai.is_none() {
        return true;
    }
    let ai = ai.unwrap();
    if ai.get("configured") == Some(&Value::Bool(false)) {
        return true;
    }
    if let Some(v) = ai.get("chat_enabled") {
        return v.as_bool().unwrap_or(true);
    }
    if let Some(v) = ai.get("floating_bubble") {
        return v.as_bool().unwrap_or(true);
    }
    true
}

pub fn guest_call_enabled(meta: &Value) -> bool {
    let ai = meta.get("ai_assistant");
    if ai.is_none() {
        return false;
    }
    let ai = ai.unwrap();
    if ai.get("configured") == Some(&Value::Bool(false)) {
        return false;
    }
    ai.get("call_enabled").and_then(|v| v.as_bool()).unwrap_or(false)
}

pub fn knowledge_prompt_block(meta: &Value) -> String {
    let rows = meta
        .get("knowledge")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let mut out = String::from("[SITE KNOWLEDGE]\n");
    let mut chars = out.len();
    let mut count = 0usize;
    for row in rows {
        if count >= GUEST_KNOWLEDGE_MAX_ITEMS {
            break;
        }
        let title = row.get("title").and_then(|v| v.as_str()).unwrap_or("").trim();
        let content = row.get("content").and_then(|v| v.as_str()).unwrap_or("").trim();
        if title.is_empty() && content.is_empty() {
            continue;
        }
        let line = if title.is_empty() {
            format!("- {}\n", content)
        } else if content.is_empty() {
            format!("- {}\n", title)
        } else {
            format!("- {}: {}\n", title, content)
        };
        if chars + line.len() > GUEST_KNOWLEDGE_MAX_CHARS {
            break;
        }
        out.push_str(&line);
        chars += line.len();
        count += 1;
    }
    if count == 0 {
        String::new()
    } else {
        out.trim_end().to_string()
    }
}

pub fn site_guest_tool_catalog(commerce: bool) -> Vec<ToolDef> {
    let mut names = vec!["site.guest.cart.get", "site.guest.cart.patch"];
    if commerce {
        names.push("site.tx.preview");
    }
    names
        .into_iter()
        .filter_map(cluster_tool_def)
        .collect()
}

pub fn site_guest_live_tool_catalog(ctx: &GuestSiteContext) -> Vec<ToolDeclaration> {
    site_guest_tool_catalog(ctx.commerce)
}

pub fn site_guest_chat_system_prompt(
    ctx: &GuestSiteContext,
    inst_block: &str,
    time_block: &str,
) -> String {
    let mut system = String::new();
    system.push_str(&ctx.site_context_block);
    if !ctx.knowledge_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(&ctx.knowledge_block);
    }
    if ctx.commerce && !ctx.products_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(&ctx.products_block);
    }
    if let Some(intro) = &ctx.chat_intro {
        system.push_str("\n\n[CHAT INTRO]\n");
        system.push_str(intro);
    }
    if !inst_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(inst_block);
    }
    if !time_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(time_block);
    }
    system
}

pub fn site_guest_live_system_prompt(
    ctx: &GuestSiteContext,
    inst_block: &str,
    time_block: &str,
) -> String {
    let mut system = String::new();
    system.push_str(&ctx.site_context_block);
    if !ctx.knowledge_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(&ctx.knowledge_block);
    }
    if ctx.commerce && !ctx.products_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(&ctx.products_block);
    }
    if let Some(intro) = &ctx.call_intro {
        system.push_str("\n\n[CALL INTRO]\n");
        system.push_str(intro);
    } else if let Some(intro) = &ctx.chat_intro {
        system.push_str("\n\n[CHAT INTRO]\n");
        system.push_str(intro);
    }
    if !inst_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(inst_block);
    }
    if !time_block.is_empty() {
        system.push_str("\n\n");
        system.push_str(time_block);
    }
    system.push_str("\n\n");
    system.push_str(SITE_GUEST_LIVE_VOICE_INSTRUCTIONS);
    system
}

pub async fn site_guest_live_system_prompt_build(
    pool: &PgPool,
    ctx: &GuestSiteContext,
    model: &str,
) -> String {
    let mention = MentionContext::from_site(ctx.site.clone());
    let caps = ctx.caps.clone();
    let mention_ids = [mention_ref_iid(ctx.site.site_iid)];
    let inst_rows = inst_list_for_turn(pool).await;
    let inst_scopes = inst_scopes_site_guest();
    let http = http_client(std::time::Duration::from_secs(30));
    let tool_catalog = site_guest_live_tool_catalog(ctx);
    let extra_exclude: Vec<String> = BOT_WEB_TOOL_EXCLUDE
        .iter()
        .map(|s| s.to_string())
        .collect();
    let compose_signals = [inst_pool_signal(model).to_string()];
    let compose_opts = ComposeTurnOpts {
        extra_signals: &compose_signals,
        extra_tool_exclude: &extra_exclude,
        skip_tool_rag: false,
        ..ComposeTurnOpts::default()
    };
    let composed = compose_tools_and_inst_async(
        pool,
        &http,
        &inst_rows,
        "",
        tool_catalog,
        &[],
        &mention_ids,
        &["site.guest".to_string()],
        "agent",
        &[],
        &inst_scopes,
        &mention,
        &caps,
        compose_opts,
        ctx.owner_iid,
        "",
        None,
    )
    .await;

    let tz = time_timezone_resolve("", "", "");
    let time_block = time_prompt_block(&tz);
    site_guest_live_system_prompt(ctx, &composed.inst_block, &time_block)
}

pub async fn site_guest_context_prepare(
    pool: &PgPool,
    site_iid: i64,
    data_mode: GuestSiteDataMode,
) -> Result<GuestSiteContext, GuestContextError> {
    if site_iid <= 0 {
        return Err(GuestContextError::InvalidSiteId);
    }
    if data_mode == GuestSiteDataMode::Published && !site_published(pool, site_iid).await? {
        return Err(GuestContextError::SiteNotPublished);
    }
    let id_row = sqlx::query(
        r#"
        SELECT COALESCE(alien_id, '') AS alien_id, COALESCE(name, '') AS name
        FROM ai.identity
        WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or(GuestContextError::SiteNotFound)?;

    let owner_iid: i64 = sqlx::query_scalar(
        "SELECT owner_iid FROM site.config WHERE site_iid = $1",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .unwrap_or(0);

    if owner_iid <= 0 {
        return Err(GuestContextError::OwnerNotConfigured);
    }

    let meta = match data_mode {
        GuestSiteDataMode::Published => site_published_meta_json(pool, site_iid).await,
        GuestSiteDataMode::Draft => site_draft_meta_json(pool, site_iid).await,
    };

    let chat_enabled = guest_chat_enabled(&meta);
    let call_enabled = guest_call_enabled(&meta);

    let site = SiteContext {
        site_iid,
        alien_id: id_row.get("alien_id"),
        name: id_row.get("name"),
    };
    let site_context_block = site_context_block(&site);

    let caps = SiteCapabilityView::load(pool, &[site_iid]).await;
    let commerce = caps.has(site_iid, "commerce");

    let knowledge_block = knowledge_prompt_block(&meta);

    let products_block = if commerce {
        site_guest_product_prompt_block(pool, site_iid).await
    } else {
        String::new()
    };

    let chat_intro = meta
        .get("ai_assistant")
        .and_then(|v| v.get("chat_intro"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string);

    let call_intro = meta
        .get("ai_assistant")
        .and_then(|v| v.get("call_intro"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string);

    Ok(GuestSiteContext {
        site,
        owner_iid,
        meta,
        data_mode,
        caps,
        commerce,
        chat_enabled,
        call_enabled,
        site_context_block,
        knowledge_block,
        products_block,
        chat_intro,
        call_intro,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn knowledge_prompt_block_caps_items() {
        let mut rows = Vec::new();
        for i in 0..60 {
            rows.push(json!({ "title": format!("t{i}"), "content": "x" }));
        }
        let block = knowledge_prompt_block(&json!({ "knowledge": rows }));
        assert!(block.contains("[SITE KNOWLEDGE]"));
        assert!(block.lines().count() <= GUEST_KNOWLEDGE_MAX_ITEMS + 1);
    }

    #[test]
    fn guest_chat_disabled_when_configured_off() {
        let meta = json!({
            "ai_assistant": { "configured": true, "chat_enabled": false }
        });
        assert!(!guest_chat_enabled(&meta));
    }

    #[test]
    fn guest_call_enabled_when_configured_on() {
        let meta = json!({
            "ai_assistant": { "configured": true, "call_enabled": true }
        });
        assert!(guest_call_enabled(&meta));
    }

    #[test]
    fn guest_call_disabled_by_default() {
        let meta = json!({});
        assert!(!guest_call_enabled(&meta));
    }

    #[test]
    fn guest_call_disabled_when_configured_off() {
        let meta = json!({
            "ai_assistant": { "configured": true, "call_enabled": false }
        });
        assert!(!guest_call_enabled(&meta));
    }

    #[test]
    fn guest_site_data_mode_parses_draft() {
        assert_eq!(
            guest_site_data_mode_from_boot_mode(Some("draft")),
            GuestSiteDataMode::Draft
        );
        assert_eq!(
            guest_site_data_mode_from_boot_mode(Some("published")),
            GuestSiteDataMode::Published
        );
        assert_eq!(
            guest_site_data_mode_from_boot_mode(None),
            GuestSiteDataMode::Published
        );
    }

    #[test]
    fn site_guest_tool_catalog_includes_cart_only_by_default() {
        let tools = site_guest_tool_catalog(false);
        let names: Vec<_> = tools.iter().map(|t| t.name.clone()).collect();
        assert!(names.contains(&"site.guest.cart.get".to_string()));
        assert!(!names.iter().any(|n| n == "site.tx.preview"));
        assert!(!names.iter().any(|n| n.starts_with("web.")));
    }

    #[test]
    fn site_guest_tool_catalog_adds_preview_when_commerce() {
        let tools = site_guest_tool_catalog(true);
        let names: Vec<_> = tools.iter().map(|t| t.name.clone()).collect();
        assert!(names.iter().any(|n| n == "site.tx.preview"));
        assert!(!names.iter().any(|n| n.starts_with("web.")));
    }

    #[test]
    fn site_guest_live_system_prompt_structure() {
        let ctx = GuestSiteContext {
            site: SiteContext {
                site_iid: 42,
                alien_id: "testshop".to_string(),
                name: "Test Shop".to_string(),
            },
            owner_iid: 100,
            meta: json!({}),
            data_mode: GuestSiteDataMode::Published,
            caps: SiteCapabilityView::empty(),
            commerce: true,
            chat_enabled: true,
            call_enabled: true,
            site_context_block: "[SITE CONTEXT] site_iid=42 alien_id=testshop name=Test Shop".to_string(),
            knowledge_block: "[SITE KNOWLEDGE]\n- Coffee: Best in town".to_string(),
            products_block: "[SITE PRODUCTS]\n- Espresso: $3".to_string(),
            chat_intro: Some("Welcome to Test Shop!".to_string()),
            call_intro: Some("Thanks for calling Test Shop!".to_string()),
        };

        let prompt = site_guest_live_system_prompt(&ctx, "INST_BLOCK", "TIME_BLOCK");
        assert!(prompt.contains("[SITE CONTEXT] site_iid=42"));
        assert!(prompt.contains("[SITE KNOWLEDGE]\n- Coffee: Best in town"));
        assert!(prompt.contains("[SITE PRODUCTS]\n- Espresso: $3"));
        assert!(prompt.contains("[CALL INTRO]\nThanks for calling Test Shop!"));
        assert!(!prompt.contains("[CHAT INTRO]")); // Preferred call_intro
        assert!(prompt.contains("INST_BLOCK"));
        assert!(prompt.contains("TIME_BLOCK"));
        assert!(prompt.contains("[VOICE INTERACTION & TOOLS]"));
    }

    #[test]
    fn site_guest_live_system_prompt_falls_back_to_chat_intro() {
        let ctx = GuestSiteContext {
            site: SiteContext {
                site_iid: 42,
                alien_id: "testshop".to_string(),
                name: "Test Shop".to_string(),
            },
            owner_iid: 100,
            meta: json!({}),
            data_mode: GuestSiteDataMode::Published,
            caps: SiteCapabilityView::empty(),
            commerce: false,
            chat_enabled: true,
            call_enabled: true,
            site_context_block: "[SITE CONTEXT] site_iid=42 alien_id=testshop name=Test Shop".to_string(),
            knowledge_block: String::new(),
            products_block: "[SITE PRODUCTS]\n- Espresso: $3".to_string(),
            chat_intro: Some("Welcome to chat!".to_string()),
            call_intro: None,
        };

        let prompt = site_guest_live_system_prompt(&ctx, "", "");
        assert!(prompt.contains("[CHAT INTRO]\nWelcome to chat!"));
        // Since commerce is false, products_block is omitted
        assert!(!prompt.contains("[SITE PRODUCTS]"));
        assert!(prompt.contains("[VOICE INTERACTION & TOOLS]"));
    }

    #[test]
    fn site_guest_live_tool_catalog_matches_commerce() {
        let ctx_no_comm = GuestSiteContext {
            site: SiteContext {
                site_iid: 1,
                alien_id: "s1".into(),
                name: "S1".into(),
            },
            owner_iid: 10,
            meta: json!({}),
            data_mode: GuestSiteDataMode::Draft,
            caps: SiteCapabilityView::empty(),
            commerce: false,
            chat_enabled: true,
            call_enabled: true,
            site_context_block: "".into(),
            knowledge_block: "".into(),
            products_block: "".into(),
            chat_intro: None,
            call_intro: None,
        };
        let tools_no_comm = site_guest_live_tool_catalog(&ctx_no_comm);
        assert!(!tools_no_comm.iter().any(|t| t.name == "site.tx.preview"));

        let mut ctx_comm = ctx_no_comm.clone();
        ctx_comm.commerce = true;
        let tools_comm = site_guest_live_tool_catalog(&ctx_comm);
        assert!(tools_comm.iter().any(|t| t.name == "site.tx.preview"));
    }

    #[test]
    fn guest_site_data_mode_selection_unit() {
        let published_meta = json!({
            "title": "Published Version",
            "ai_assistant": { "call_enabled": true }
        });
        let draft_meta = json!({
            "title": "Draft Version",
            "ai_assistant": { "call_enabled": false }
        });

        let select_meta = |mode: GuestSiteDataMode| -> &Value {
            match mode {
                GuestSiteDataMode::Published => &published_meta,
                GuestSiteDataMode::Draft => &draft_meta,
            }
        };

        assert_eq!(select_meta(GuestSiteDataMode::Published)["title"], "Published Version");
        assert!(guest_call_enabled(select_meta(GuestSiteDataMode::Published)));

        assert_eq!(select_meta(GuestSiteDataMode::Draft)["title"], "Draft Version");
        assert!(!guest_call_enabled(select_meta(GuestSiteDataMode::Draft)));
    }
}
