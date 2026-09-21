use c35_mod_chat::compose::compose_tools_and_inst;
use c35_mod_chat::inst_macro::InstRow;
use c35_mod_chat::tool_rag::DEFAULT_TOOL_TOP_K;
use c35_mod_chat::MentionRow;
use c35_mod_chat::tools::{cluster_tools, ToolDef};
use serde_json::json;

fn compose_default(
    inst_rows: &[InstRow],
    text: &str,
    tools: Vec<ToolDef>,
    skill_tools: &[String],
) -> c35_mod_chat::compose::ComposeOutput {
    compose_tools_and_inst(inst_rows, text, tools, skill_tools, &[], "general", "agent", &[])
}

fn pa_catalog() -> Vec<ToolDef> {
    vec![
        ToolDef::new("web.search".into(), "Search the live web".into(), json!({})),
        ToolDef::new("web.visit".into(), "Visit a URL".into(), json!({})),
        ToolDef::new("img.generate".into(), "Generate images".into(), json!({})),
        ToolDef::new("consumption.add".into(), "Log food consumption".into(), json!({})),
        ToolDef::new("expense.add".into(), "Log expense".into(), json!({})),
        ToolDef::new("reminder.set".into(), "Set reminder".into(), json!({})),
    ]
}

fn inst_web_search() -> InstRow {
    InstRow {
        id: "inst.web_search".into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "web".into(),
        phrases: vec!["search the web".into(), "cari".into()],
        triggers: vec!["tool_include:web.search".into()],
        priority: 100,
    }
}

fn inst_consumption() -> InstRow {
    InstRow {
        id: "inst.consumption_add".into(),
        scope: "role:personal_assistant".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "food".into(),
        phrases: vec!["catat konsumsi".into(), "track food".into()],
        triggers: vec!["tool_include:consumption.add".into()],
        priority: 140,
    }
}

#[test]
fn compose_search_query_includes_web_search() {
    let out = compose_default(&[], "search the web for rust docs", pa_catalog(), &[]);
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}

#[test]
fn compose_small_catalog_skips_rag() {
    let small = pa_catalog().into_iter().take(3).collect::<Vec<_>>();
    let out = compose_default(&[], "hello", small, &[]);
    assert_eq!(out.tools.len(), 3);
    assert!(out.trace.rag_skipped);
    assert_eq!(out.trace.rag_skip_reason, "few_tools");
}

#[test]
fn compose_inst_exclude_drops_web_search() {
    let inst = InstRow {
        id: "inst.no_web".into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "no web".into(),
        phrases: vec!["offline only".into()],
        triggers: vec!["tool_exclude:web.search".into()],
        priority: 50,
    };
    let out = compose_default(&[inst], "offline only please", pa_catalog(), &[]);
    assert!(!out.tools.iter().any(|t| t.name == "web.search"));
}

#[test]
fn compose_inst_web_search_matched() {
    let out = compose_default(&[inst_web_search()], "cari info terbaru", pa_catalog(), &[]);
    assert!(out.matched_ids.contains(&"inst.web_search".into()));
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}

#[test]
fn compose_food_query_forces_consumption_add() {
    let out = compose_default(&[inst_consumption()], "catat konsumsi makan siang", pa_catalog(), &[]);
    assert!(out.tools.iter().any(|t| t.name == "consumption.add"));
}

#[test]
fn compose_force_plus_lexical_within_top_k() {
    let out = compose_default(&[inst_consumption()], "track food", pa_catalog(), &[]);
    assert!(out.tools.iter().any(|t| t.name == "consumption.add"));
    assert!(out.tools.len() <= DEFAULT_TOOL_TOP_K + 3);
}

#[test]
fn compose_ask_mode_no_write_tools() {
    let out = compose_tools_and_inst(&[], "hello", pa_catalog(), &[], &[], "general", "ask", &[]);
    assert!(out.tools.is_empty());
    assert_eq!(out.trace.rag_skip_reason, "ask_mode");
}

#[test]
fn compose_ask_mode_keeps_readonly_consumption_today() {
    let mut catalog = pa_catalog();
    catalog.push(ToolDef {
        name: "consumption.today".into(),
        description: "Daily nutrition summary".into(),
        parameters: json!({}),
        aliases: vec![],
        topics: vec!["health".into()],
        always: vec!["general".into()],
        readonly: true,
    });
    let out = compose_tools_and_inst(&[], "how many calories today", catalog, &[], &[], "health", "ask", &[]);
    assert!(out.tools.iter().any(|t| t.name == "consumption.today"));
    assert!(!out.tools.iter().any(|t| t.name == "consumption.add"));
}

#[test]
fn compose_research_mention_includes_web_research() {
    let mentions = vec![MentionRow { id: "research".into(), topic_id: "research".into() }];
    let out = compose_tools_and_inst(
        &[],
        "compare rust web frameworks",
        cluster_tools(),
        &[],
        &["research".into()],
        "",
        "agent",
        &mentions,
    );
    assert!(out.tools.iter().any(|t| t.name == "web.research"));
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}
