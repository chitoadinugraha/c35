//! Inst macros — phrase/trigger match for prompt steering.

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
    pub priority: i32,
}

pub const SCOPE_GLOBAL: &str = "global";
pub const SCOPE_ROLE_PERSONAL_ASSISTANT: &str = "role:personal_assistant";

pub fn inst_scopes_home() -> Vec<String> {
    vec![SCOPE_GLOBAL.into(), SCOPE_ROLE_PERSONAL_ASSISTANT.into()]
}

pub fn inst_scopes_channel() -> Vec<String> {
    vec![SCOPE_GLOBAL.into()]
}

pub struct InstMatchCtx<'a> {
    pub scopes: &'a [String],
    pub topic_id: &'a str,
    pub text: &'a str,
    pub mention_ids: &'a [String],
    pub signals: &'a [String],
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
        .map(|r| format!("[INST:{}]\n{}", r.id, r.inst.trim()))
        .collect::<Vec<_>>()
        .join("\n\n")
}

fn scope_applies(row_scope: &str, active: &[String]) -> bool {
    if row_scope == SCOPE_GLOBAL {
        return true;
    }
    active.iter().any(|s| s == row_scope)
}

fn inst_applies(row: &InstRow, ctx: &InstMatchCtx<'_>) -> bool {
    if !scope_applies(&row.scope, ctx.scopes) {
        return false;
    }
    match row.kind.as_str() {
        "topic" => row.topic_id == ctx.topic_id,
        "mention" => {
            let id = row.topic_id.trim();
            !id.is_empty() && ctx.mention_ids.iter().any(|m| m == id)
        }
        "trigger" => row.triggers.iter().any(|t| trigger_matches(t, ctx)),
        "task" => {
            if !topic_applies(&row.topics, ctx.topic_id) {
                return false;
            }
            let lower = ctx.text.trim().to_lowercase();
            row.phrases.is_empty() || row.phrases.iter().any(|p| lower.contains(&p.to_lowercase()))
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
        return ctx.topic_id == s;
    }
    ctx.signals.iter().any(|x| x == t)
}

fn topic_applies(topics: &[String], topic_id: &str) -> bool {
    topics.is_empty() || topics.iter().any(|t| t == topic_id || t == "*" || t == "general")
}

#[cfg(test)]
mod tests {
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
            priority: 1,
        }];
        let (inc, exc) = inst_tool_directives(&rows);
        assert_eq!(inc, vec!["consumption.today"]);
        assert_eq!(exc, vec!["img.generate"]);
    }

    #[test]
    fn inst_pick_web_phrases() {
        let rows = vec![row("inst.web_search", &["search the web", "cari"])];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            text: "cari info rust",
            mention_ids: &empty,
            signals: &empty,
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
            priority: 140,
        }];
        let empty: [String; 0] = [];
        let global_only = vec![SCOPE_GLOBAL.into()];
        let home = inst_scopes_home();
        let ctx_global = InstMatchCtx {
            scopes: &global_only,
            topic_id: "general",
            text: "track food",
            mention_ids: &empty,
            signals: &empty,
        };
        let ctx_home = InstMatchCtx {
            scopes: &home,
            topic_id: "general",
            text: "track food",
            mention_ids: &empty,
            signals: &empty,
        };
        assert!(inst_pick(&rows, &ctx_global).is_empty());
        assert_eq!(inst_pick(&rows, &ctx_home).len(), 1);
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
            priority: 200,
        }];
        let empty: [String; 0] = [];
        let scopes = vec![SCOPE_GLOBAL.into()];
        let ctx = InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            text: "hello",
            mention_ids: &empty,
            signals: &empty,
        };
        assert_eq!(inst_pick(&rows, &ctx).len(), 1);
        assert_eq!(inst_pick(&rows, &ctx)[0].id, "inst.core.assistant");
    }
}
