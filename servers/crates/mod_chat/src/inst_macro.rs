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
    pub priority: i32,
}

pub struct InstMatchCtx<'a> {
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

fn inst_applies(row: &InstRow, ctx: &InstMatchCtx<'_>) -> bool {
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
            triggers: vec!["tool_include:web.search".into()],
            priority: 100,
        }
    }

    #[test]
    fn inst_pick_web_phrases() {
        let rows = vec![row("inst.web_search", &["search the web", "cari"])];
        let empty: [String; 0] = [];
        let ctx = InstMatchCtx { topic_id: "general", text: "cari info rust", mention_ids: &empty, signals: &empty };
        assert_eq!(inst_pick(&rows, &ctx).len(), 1);
    }
}
