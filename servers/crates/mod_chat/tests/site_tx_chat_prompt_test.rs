use c35_mod_chat::inst_macro::{inst_pick, inst_tool_directives, InstMatchCtx, InstRow};

fn commerce_row(id: &str, phrases: &[&str], include: &[&str]) -> InstRow {
    InstRow {
        id: id.into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![
            "web.builder".into(),
            "site.commerce".into(),
            "general".into(),
        ],
        inst: format!("body:{id}"),
        phrases: phrases.iter().map(|s| (*s).to_string()).collect(),
        triggers: vec!["tool_include:site.query.run".into()],
        include_tools: include.iter().map(|s| (*s).to_string()).collect(),
        exclude_tools: vec!["web.search".into()],
        requires_global_roles: vec![],
        priority: 140,
    }
}

fn pick(text: &str) -> Vec<String> {
    let scopes = vec!["global".to_string()];
    let topics = vec!["general".to_string()];
    let ctx = InstMatchCtx {
        scopes: &scopes,
        topic_id: "general",
        active_topics: &topics,
        text,
        mention_ids: &[],
        signals: &[],
        staff: None,
    };
    inst_pick(
        &[
            commerce_row(
                "inst.site.report",
                &["omzet", "untung hari ini", "berapa transaksi"],
                &["site.query.run"],
            ),
            commerce_row(
                "inst.site.tx_browse",
                &["daftar transaksi", "apa saja transaksi"],
                &["site.query.run"],
            ),
            commerce_row(
                "inst.site.period_compare",
                &["dibanding kemarin", "vs kemarin"],
                &["site.query.run"],
            ),
            commerce_row(
                "inst.site.catalog.stock",
                &["stok", "berapa stock"],
                &["site.query.run"],
            ),
            commerce_row(
                "inst.site.stock_report",
                &["daftar stok", "kartu stok"],
                &["site.query.run"],
            ),
        ],
        &ctx,
    )
    .into_iter()
    .map(|r| r.id)
    .collect()
}

#[test]
fn prompt_r01_omzet_hari_ini() {
    let ids = pick("berapa omzet hari ini");
    assert!(ids.iter().any(|id| id == "inst.site.report"));
}

#[test]
fn prompt_b01_daftar_transaksi() {
    let ids = pick("daftar transaksi hari ini");
    assert!(ids.iter().any(|id| id == "inst.site.tx_browse"));
    assert!(!ids.iter().any(|id| id == "inst.site.report"));
}

#[test]
fn prompt_c01_compare_kemarin() {
    let ids = pick("berapa omzet hari ini dibanding kemarin");
    assert!(ids.iter().any(|id| id == "inst.site.period_compare"));
}

#[test]
fn prompt_x01_stock_not_browse() {
    let ids = pick("berapa stok susu");
    assert!(ids.iter().any(|id| id == "inst.site.catalog.stock"));
    assert!(!ids.iter().any(|id| id == "inst.site.tx_browse"));
}

#[test]
fn tx_browse_parse_unit() {
    assert!(c35_mod_chat::tx_browse_parse("daftar transaksi hari ini").is_some());
}

#[test]
fn report_includes_site_query_tool() {
    let scopes = vec!["global".to_string()];
    let picked = inst_pick(
        &[commerce_row("inst.site.report", &["untung"], &["site.query.run"])],
        &InstMatchCtx {
            scopes: &scopes,
            topic_id: "general",
            active_topics: &["general".to_string()],
            text: "untung hari ini",
            mention_ids: &[],
            signals: &[],
            staff: None,
        },
    );
    let (inc, _) = inst_tool_directives(&picked);
    assert!(inc.iter().any(|t| t == "site.query.run"));
}