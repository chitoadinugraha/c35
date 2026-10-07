//! Inst macros — phrase/trigger match for prompt steering.

use c35_mod_admin::{staff_tool_eligible, StaffView};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InstRow {
    pub id: String,
    pub scope: String,
    pub kind: String,
    pub topic_id: String,
    pub topics: Vec<String>,
    pub inst: String,
    pub phrases: Vec<String>,
    pub triggers: Vec<String>,
    pub include_tools: Vec<String>,
    pub exclude_tools: Vec<String>,
    pub requires_global_roles: Vec<String>,
    pub priority: i32,
}

pub const SCOPE_GLOBAL: &str = "global";
pub const SCOPE_ROLE_PERSONAL_ASSISTANT: &str = "role:personal_assistant";
pub const SCOPE_ROLE_BOT: &str = "role:bot";

pub fn inst_scopes_home() -> Vec<String> {
    vec![SCOPE_GLOBAL.into(), SCOPE_ROLE_PERSONAL_ASSISTANT.into()]
}

/// In-memory mention ids for inst pick. Does not mutate the persisted list.
pub fn inst_mention_ids(mention_ids: &[String], talk: bool) -> Vec<String> {
    mention_ids.iter().cloned().chain(talk.then(|| "talk".to_string())).collect()
}

pub fn inst_scopes_channel() -> Vec<String> {
    vec![SCOPE_ROLE_BOT.into()]
}

/// Compose `extra_signals` entries; match `ai.inst` triggers (e.g. `model:alienai`).
pub const INST_SIGNAL_MODEL_ALIEN: &str = "model:alienai";
pub const INST_SIGNAL_MODEL_FRONTIER: &str = "model:frontier";

pub fn inst_pool_signal(model: &str) -> &'static str {
    if c35_mod_llm::model_is_alien(model) {
        INST_SIGNAL_MODEL_ALIEN
    } else {
        INST_SIGNAL_MODEL_FRONTIER
    }
}

pub struct InstMatchCtx<'a> {
    pub scopes: &'a [String],
    pub topic_id: &'a str,
    pub active_topics: &'a [String],
    pub text: &'a str,
    pub mention_ids: &'a [String],
    pub signals: &'a [String],
    pub staff: Option<&'a StaffView>,
}

const INST_SITE_CATALOG_STOCK: &str = "inst.site.catalog.stock";

/// Site create / builder wording (keep in sync with `inst.site.builder` phrases in inst.sql).
pub fn inst_text_site_builder_intent(text: &str) -> bool {
    let lower = text.trim().to_lowercase();
    [
        "buat situs",
        "bikin situs",
        "buatkan situs",
        "bikin web",
        "buat web",
        "bikin website",
        "buat website",
        "buatkan websitenya",
        "buatkan sitenya",
        "buatkan website",
        "bikin landing page",
        "buat landing page",
        "create site",
        "build website",
        "create website",
        "make website",
        "site builder",
        "website builder",
        "fitur pos",
    ]
    .iter()
    .any(|p| lower.contains(p))
}

/// Catalog/POS setup in chat — not personal nutrition logging.
pub fn inst_text_site_product_setup(text: &str) -> bool {
    let lower = text.trim().to_lowercase();
    let site_ctx = lower.contains("situs")
        || lower.contains("website")
        || lower.contains("fitur pos")
        || lower.contains("toko online")
        || inst_text_site_builder_intent(text);
    site_ctx && (lower.contains("produk") || lower.contains("katalog") || lower.contains("pos"))
}

fn inst_site_catalog_lookup_task(id: &str) -> bool {
    matches!(
        id,
        "inst.site.catalog" | "inst.site.catalog.price" | "inst.site.catalog.stock"
    )
}

/// Home-chat bot creation / draft-update wording (keep in sync with `inst.bot.draft` phrases in inst.sql).
pub fn inst_text_bot_draft_intent(text: &str) -> bool {
    let lower = text.trim().to_lowercase();
    [
        "buat chat bot",
        "bikin chat bot",
        "buat bot",
        "bikin bot",
        "create chat bot",
        "create a bot",
        "create bot",
        "new bot",
        "bot baru",
        "bot untuk",
        "spreadsheets/d/",
        "document/d/",
        "presentation/d/",
        "aktifkan bot",
        "hidupkan bot",
        "turn the bot on",
        "sambungkan whatsapp",
        "sambungkan telegram",
        "connect whatsapp",
        "connect telegram",
    ]
    .iter()
    .any(|p| lower.contains(p))
}

pub fn inst_pick(rows: &[InstRow], ctx: &InstMatchCtx<'_>) -> Vec<InstRow> {
    let mut picked: Vec<InstRow> = rows.iter().filter(|r| inst_applies(r, ctx)).cloned().collect();
    picked.sort_by(|a, b| b.priority.cmp(&a.priority).then_with(|| a.id.cmp(&b.id)));
    picked.dedup_by(|a, b| a.id == b.id);
    picked
}

pub fn inst_tool_directives(rows: &[InstRow]) -> (Vec<String>, Vec<String>) {
    let mut include = Vec::new();
    let mut exclude = Vec::new();
    for row in rows {
        for t in &row.include_tools {
            if !t.is_empty() {
                include.push(t.clone());
            }
        }
        for t in &row.exclude_tools {
            if !t.is_empty() {
                exclude.push(t.clone());
            }
        }
        for t in &row.triggers {
            if let Some(rest) = t.strip_prefix("tool_include:") {
                if !rest.is_empty() {
                    include.push(rest.to_string());
                }
            } else if let Some(rest) = t.strip_prefix("tool_exclude:") {
                if !rest.is_empty() {
                    exclude.push(rest.to_string());
                }
            }
        }
    }
    include.sort();
    exclude.sort();
    include.dedup();
    exclude.dedup();
    (include, exclude)
}

pub fn inst_matched_prompt(matched: &[InstRow]) -> String {
    matched
        .iter()
        .map(|r| format!("### {}\n{}", r.id, r.inst.trim()))
        .collect::<Vec<_>>()
        .join("\n\n")
}

fn scope_applies(row_scope: &str, active: &[String]) -> bool {
    if row_scope == SCOPE_GLOBAL {
        return true;
    }
    active.iter().any(|s| s == row_scope)
}

fn inst_staff_eligible(row: &InstRow, ctx: &InstMatchCtx<'_>) -> bool {
    if row.requires_global_roles.is_empty() {
        return true;
    }
    match ctx.staff {
        Some(staff) => staff_tool_eligible(staff, &row.requires_global_roles),
        None => staff_tool_eligible(&StaffView::default(), &row.requires_global_roles),
    }
}

fn inst_applies(row: &InstRow, ctx: &InstMatchCtx<'_>) -> bool {
    if !inst_staff_eligible(row, ctx) {
        return false;
    }
    if ctx.topic_id == "bot" && row.scope == SCOPE_GLOBAL && row.kind != "trigger" {
        return false;
    }
    if !scope_applies(&row.scope, ctx.scopes) {
        return false;
    }
    match row.kind.as_str() {
        "topic" => {
            let id = row.topic_id.trim();
            !id.is_empty() && (id == ctx.topic_id || ctx.active_topics.iter().any(|t| t == id))
        }
        "mention" => {
            let id = row.topic_id.trim();
            !id.is_empty() && ctx.mention_ids.iter().any(|m| m == id)
        }
        "trigger" => row.triggers.iter().any(|t| trigger_matches(t, ctx)),
        "task" => {
            if !topic_applies(&row.topics, ctx.topic_id, ctx.active_topics) {
                return false;
            }
            if row.id == INST_SITE_CATALOG_STOCK && inst_text_bot_draft_intent(ctx.text) {
                return false;
            }
            if inst_text_site_builder_intent(ctx.text)
                && (row.id == "inst.consumption_coach" || inst_site_catalog_lookup_task(&row.id))
            {
                return false;
            }
            if row.id == "inst.consumption_coach" && inst_text_site_product_setup(ctx.text) {
                return false;
            }
            let lower = ctx.text.trim().to_lowercase();
            let phrase_hit = row.phrases.is_empty()
                || row.phrases.iter().any(|p| lower.contains(&p.to_lowercase()));
            phrase_hit
                || (row.id == "inst.site.builder" && inst_text_site_builder_intent(ctx.text))
        }
        _ => false,
    }
}

fn trigger_matches(t: &str, ctx: &InstMatchCtx<'_>) -> bool {
    if t.starts_with("tool_include:") || t.starts_with("tool_exclude:") {
        return false;
    }
    if t == "always" {
        return true;
    }
    if let Some(s) = t.strip_prefix("mention:") {
        return ctx.mention_ids.iter().any(|x| x == s);
    }
    if let Some(s) = t.strip_prefix("topic:") {
        return ctx.topic_id == s || ctx.active_topics.iter().any(|t| t == s);
    }
    ctx.signals.iter().any(|x| x == t)
}

fn topic_applies(topics: &[String], topic_id: &str, active_topics: &[String]) -> bool {
    topics.is_empty()
        || topics.iter().any(|t| {
            t == "*"
                || t == topic_id
                || active_topics.iter().any(|a| a == t)
                || (t == "general" && (topic_id == "general" || active_topics.iter().any(|a| a == "general")))
        })
}

#[cfg(test)]
mod tests {
    use std::collections::HashSet;

    use super::*;

    fn row(id: &str, phrases: &[&str]) -> InstRow {
        InstRow {
            id: id.into(),
            scope: "global".into(),
            kind: "task".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: format!("body:{id}"),
            phrases: phrases.iter().map(|s| (*s).to_string()).collect(),
            triggers: vec![],
            include_tools: vec!["web.search".into()],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 100,
        }
    }

    #[test]
    fn inst_tool_directives_include_tools_column() {
        let rows = vec![InstRow {
            id: "inst.test".into(),
            scope: "global".into(),
            kind: "task".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "x".into(),
            phrases: vec![],
            triggers: vec![],
            include_tools: vec!["consumption.today".into()],
            exclude_tools: vec!["img.generate".into()],
            requires_global_roles: vec![],
            priority: 1,
        }];
        let (inc, exc) = inst_tool_directives(&rows);
        assert_eq!(inc, vec!["consumption.today"]);
        assert_eq!(exc, vec!["img.generate"]);
    }

    #[test]
    fn inst_pick_site_builder_suppresses_catalog_price_and_consumption_coach() {
        let rows = vec![
            InstRow {
                id: "inst.site.builder".into(),
                scope: SCOPE_GLOBAL.into(),
                kind: "task".into(),
                topic_id: "".into(),
                topics: vec![],
                inst: "builder".into(),
                phrases: vec!["buat situs".into()],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 150,
            },
            InstRow {
                id: "inst.site.catalog.price".into(),
                scope: SCOPE_GLOBAL.into(),
                kind: "task".into(),
                topic_id: "".into(),
                topics: vec!["general".into()],
                inst: "price".into(),
                phrases: vec!["harga".into()],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 130,
            },
            InstRow {
                id: "inst.consumption_coach".into(),
                scope: SCOPE_ROLE_PERSONAL_ASSISTANT.into(),
                kind: "task".into(),
                topic_id: "".into(),
                topics: vec![],
                inst: "coach".into(),
                phrases: vec!["mie".into()],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 135,
            },
        ];
        let empty: [String; 0] = [];
        let scopes = inst_scopes_home();
        let text = "buat situs testing test-site dengan fitur POS, produk indomie harga 20rb, mie goreng 15rb";
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text,
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        let picked = inst_pick(&rows, &ctx);
        assert!(picked.iter().any(|r| r.id == "inst.site.builder"));
        assert!(!picked.iter().any(|r| r.id == "inst.site.catalog.price"));
        assert!(!picked.iter().any(|r| r.id == "inst.consumption_coach"));
    }

    #[test]
    fn inst_pick_bot_draft_suppresses_catalog_stock() {
        let rows = vec![
            row("inst.bot.draft", &["buat chat bot"]),
            InstRow {
                id: INST_SITE_CATALOG_STOCK.into(),
                scope: SCOPE_GLOBAL.into(),
                kind: "task".into(),
                topic_id: "".into(),
                topics: vec![],
                inst: "stock".into(),
                phrases: vec!["stock".into()],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 128,
            },
        ];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "buat chat bot \"Test Stock\"",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        let picked = inst_pick(&rows, &ctx);
        assert!(picked.iter().any(|r| r.id == "inst.bot.draft"));
        assert!(!picked.iter().any(|r| r.id == INST_SITE_CATALOG_STOCK));
    }

    #[test]
    fn inst_pick_requires_global_roles() {
        let rows = vec![InstRow {
            id: "inst.staff.root_chat".into(),
            scope: SCOPE_GLOBAL.into(),
            kind: "task".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "root chat".into(),
            phrases: vec!["chat terakhir chito".into()],
            triggers: vec![],
            include_tools: vec!["admin.chat.search".into()],
            exclude_tools: vec![],
            requires_global_roles: vec!["root".into()],
            priority: 145,
        }];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let staff_user = StaffView::default();
        let staff_root = StaffView {
            is_root: true,
            global_roles: HashSet::new(),
        };
        let ctx_user = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "apa chat terakhir chito",
            mention_ids: &empty,
            signals: &empty,
            staff: Some(&staff_user),
        };
        let ctx_root = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "apa chat terakhir chito",
            mention_ids: &empty,
            signals: &empty,
            staff: Some(&staff_root),
        };
        assert!(inst_pick(&rows, &ctx_user).is_empty());
        assert_eq!(inst_pick(&rows, &ctx_root).len(), 1);
    }

    #[test]
    fn inst_pick_web_phrases() {
        let rows = vec![row("inst.web_search", &["search the web", "cari"])];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "cari info rust",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        assert_eq!(inst_pick(&rows, &ctx).len(), 1);
    }

    #[test]
    fn inst_scope_role_requires_active_scope() {
        let rows = vec![InstRow {
            id: "inst.consumption_add".into(),
            scope: SCOPE_ROLE_PERSONAL_ASSISTANT.into(),
            kind: "task".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "food".into(),
            phrases: vec!["track food".into()],
            triggers: vec![],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 140,
        }];
        let empty: [String; 0] = [];
        let global_only = vec![SCOPE_GLOBAL.into()];
        let home = inst_scopes_home();
        let ctx_global = InstMatchCtx {
            scopes: &global_only,
            topic_id: "general",
            active_topics: &[],
            text: "track food",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        let ctx_home = InstMatchCtx {
            scopes: &home,
            topic_id: "general",
            active_topics: &[],
            text: "track food",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        assert!(inst_pick(&rows, &ctx_global).is_empty());
        assert_eq!(inst_pick(&rows, &ctx_home).len(), 1);
    }

    #[test]
    fn inst_pick_multitask_delegate_phrase() {
        let rows = vec![InstRow {
            id: "inst.task.multitask_delegate".into(),
            scope: SCOPE_GLOBAL.into(),
            kind: "task".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "multitask".into(),
            phrases: vec!["multitask".into(), "parallel".into()],
            triggers: vec!["tool_include:delegate.run".into()],
            include_tools: vec!["delegate.run".into()],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 127,
        }];
        let empty: [String; 0] = [];
        let scopes = inst_scopes_home();
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "can you multitask 2 times",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        let picked = inst_pick(&rows, &ctx);
        assert_eq!(picked.len(), 1);
        assert_eq!(picked[0].id, "inst.task.multitask_delegate");
        let (inc, _) = inst_tool_directives(&picked);
        assert!(inc.iter().any(|t| t == "delegate.run"));
    }

    #[test]
    fn inst_pool_signal_triggers() {
        let alien = InstRow {
            id: "inst.pool.alien".into(),
            scope: SCOPE_ROLE_PERSONAL_ASSISTANT.into(),
            kind: "trigger".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "alien pool".into(),
            phrases: vec![],
            triggers: vec![INST_SIGNAL_MODEL_ALIEN.into()],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 180,
        };
        let frontier = InstRow {
            id: "inst.pool.frontier".into(),
            scope: SCOPE_ROLE_PERSONAL_ASSISTANT.into(),
            kind: "trigger".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "frontier pool".into(),
            phrases: vec![],
            triggers: vec![INST_SIGNAL_MODEL_FRONTIER.into()],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 180,
        };
        let scopes = inst_scopes_home();
        let ctx_alien = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "hi",
            mention_ids: &[],
            signals: &[INST_SIGNAL_MODEL_ALIEN.into()],
            staff: None,
        };
        let ctx_frontier = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "hi",
            mention_ids: &[],
            signals: &[INST_SIGNAL_MODEL_FRONTIER.into()],
            staff: None,
        };
        assert!(inst_pick(&[alien.clone(), frontier.clone()], &ctx_alien).iter().any(|r| r.id == "inst.pool.alien"));
        assert!(!inst_pick(&[alien.clone(), frontier.clone()], &ctx_alien).iter().any(|r| r.id == "inst.pool.frontier"));
        assert!(inst_pick(&[alien.clone(), frontier.clone()], &ctx_frontier).iter().any(|r| r.id == "inst.pool.frontier"));
    }

    #[test]
    fn inst_always_trigger_applies() {
        let rows = vec![InstRow {
            id: "inst.core.assistant".into(),
            scope: SCOPE_GLOBAL.into(),
            kind: "trigger".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "baseline".into(),
            phrases: vec![],
            triggers: vec!["always".into()],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 200,
        }];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "hello",
            mention_ids: &empty,
            signals: &empty,
            staff: None,
        };
        assert_eq!(inst_pick(&rows, &ctx).len(), 1);
        assert_eq!(inst_pick(&rows, &ctx)[0].id, "inst.core.assistant");
    }

    fn talk_row() -> InstRow {
        InstRow {
            id: "inst.talk.brief".into(),
            scope: SCOPE_GLOBAL.into(),
            kind: "trigger".into(),
            topic_id: "".into(),
            topics: vec![],
            inst: "short spoken sentences".into(),
            phrases: vec![],
            triggers: vec!["mention:talk".into()],
            include_tools: vec![],
            exclude_tools: vec![],
            requires_global_roles: vec![],
            priority: 80,
        }
    }

    #[test]
    fn inst_talk_brief_matches_mention_talk() {
        let rows = vec![talk_row()];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let persisted = vec!["web.builder".to_string()];
        let with_talk = inst_mention_ids(&persisted, true);
        let without = inst_mention_ids(&persisted, false);
        // Persisted mention list is unchanged; talk is only on the inst-match copy.
        assert_eq!(persisted, vec!["web.builder".to_string()]);
        assert_eq!(without, vec!["web.builder".to_string()]);
        assert_eq!(with_talk, vec!["web.builder".to_string(), "talk".to_string()]);
        let ctx_on = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "hello",
            mention_ids: &with_talk,
            signals: &[],
            staff: None,
        };
        let ctx_off = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &[],
            text: "hello",
            mention_ids: &without,
            signals: &[],
            staff: None,
        };
        assert!(inst_pick(&rows, &ctx_on).iter().any(|r| r.id == "inst.talk.brief"));
        assert!(inst_pick(&rows, &ctx_off).iter().all(|r| r.id != "inst.talk.brief"));
    }

    #[test]
    fn inst_multi_topic_and_general_topic_filtering() {
        let rows = vec![
            InstRow {
                id: "inst.site.commerce".into(),
                scope: SCOPE_GLOBAL.into(),
                kind: "topic".into(),
                topic_id: "site.commerce".into(),
                topics: vec![],
                inst: "commerce mode".into(),
                phrases: vec![],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 100,
            },
            InstRow {
                id: "inst.general_only".into(),
                scope: SCOPE_GLOBAL.into(),
                kind: "task".into(),
                topic_id: "".into(),
                topics: vec!["general".into()],
                inst: "general prompt".into(),
                phrases: vec!["say hi".into()],
                triggers: vec![],
                include_tools: vec![],
                exclude_tools: vec![],
                requires_global_roles: vec![],
                priority: 90,
            },
        ];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let active = vec!["web.builder".to_string(), "site.commerce".to_string()];
        let ctx_multi = InstMatchCtx {
            scopes: &scopes,
            topic_id: "web.builder",
            active_topics: &active,
            text: "say hi",
            mention_ids: &[],
            signals: &[],
            staff: None,
        };
        let picked = inst_pick(&rows, &ctx_multi);
        // inst.site.commerce matches because site.commerce is in active_topics
        assert!(picked.iter().any(|r| r.id == "inst.site.commerce"));
        // inst.general_only does NOT match because neither primary nor active topics is "general"
        assert!(!picked.iter().any(|r| r.id == "inst.general_only"));
    }
}
