use c35_mod_chat::compose::{compose_tools_and_inst, tool_mention_eligible};
use c35_mod_chat::inst_macro::{inst_scopes_channel, inst_scopes_home, InstRow, SCOPE_GLOBAL};
use c35_mod_chat::tool_rag::{tool_trim_ranked, ToolCandidate, DEFAULT_TOOL_SIM_GAP, DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_TOP_K};
use c35_mod_chat::{MentionContext, MentionRow, SiteCapabilityView, SiteContext};
use c35_mod_chat::tools::{cluster_tools, ToolDef};
use serde_json::json;
use std::collections::HashMap;

fn compose_default(
    inst_rows: &[InstRow],
    text: &str,
    tools: Vec<ToolDef>,
    skill_tools: &[String],
) -> c35_mod_chat::compose::ComposeOutput {
    compose_with_mention(inst_rows, text, tools, skill_tools, &MentionContext::empty())
}

fn compose_with_mention(
    inst_rows: &[InstRow],
    text: &str,
    tools: Vec<ToolDef>,
    skill_tools: &[String],
    mention: &MentionContext,
) -> c35_mod_chat::compose::ComposeOutput {
    let scopes = inst_scopes_home();
    compose_tools_and_inst(
        inst_rows,
        text,
        tools,
        skill_tools,
        &[],
        &["general".into()],
        "agent",
        &[],
        &scopes,
        mention,
        &SiteCapabilityView::empty(),
    )
}

fn inst_core_assistant() -> InstRow {
    InstRow {
        id: "inst.core.assistant".into(),
        scope: SCOPE_GLOBAL.into(),
        kind: "trigger".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "You are Alien AI".into(),
        phrases: vec![],
        triggers: vec!["always".into()],
        priority: 200,
    }
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

fn inst_consumption_coach() -> InstRow {
    InstRow {
        id: "inst.consumption_coach".into(),
        scope: "role:personal_assistant".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "nutrition".into(),
        phrases: vec!["nutrition recap".into()],
        triggers: vec!["tool_include:consumption.today".into(), "tool_exclude:img.generate".into()],
        priority: 135,
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
        phrases: vec![
            "catat konsumsi".into(),
            "track food".into(),
            "berapa kalori".into(),
            "how many calories".into(),
        ],
        triggers: vec!["tool_include:consumption.add".into(), "tool_exclude:img.generate".into()],
        priority: 140,
    }
}

fn inst_consumption_delete() -> InstRow {
    InstRow {
        id: "inst.consumption_delete".into(),
        scope: "role:personal_assistant".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "delete meal".into(),
        phrases: vec![
            "hapus catatan makan".into(),
            "hapus makanan".into(),
            "delete meal".into(),
            "cancel meal".into(),
        ],
        triggers: vec!["tool_include:consumption.delete".into(), "tool_exclude:img.generate".into()],
        priority: 140,
    }
}

fn health_catalog() -> Vec<ToolDef> {
    vec![
        ToolDef {
            name: "web.search".into(),
            description: "Search web".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: true,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "img.generate".into(),
            description: "Generate images".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "web.visit".into(),
            description: "Visit a URL".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "consumption.add".into(),
            description: "Log food consumption from a photo hash".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec!["health".into()],
            always: vec!["general".into(), "health".into()],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "consumption.today".into(),
            description: "Daily nutrition summary".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec!["health".into()],
            always: vec!["general".into(), "health".into()],
            readonly: true,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "web.research".into(),
            description: "Deep research".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "consumption.update".into(),
            description: "Update meal".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec!["health".into()],
            always: vec!["general".into(), "health".into()],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
        ToolDef {
            name: "consumption.delete".into(),
            description: "Delete meal".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec!["health".into()],
            always: vec!["general".into(), "health".into()],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
    ]
}

#[test]
fn compose_food_delete_forces_consumption_delete() {
    let out = compose_default(
        &[inst_consumption_delete()],
        "hapus catatan makan tadi",
        health_catalog(),
        &[],
    );
    assert!(out.matched_ids.contains(&"inst.consumption_delete".into()));
    assert!(out.tools.iter().any(|t| t.name == "consumption.delete"));
    assert!(!out.tools.iter().any(|t| t.name == "img.generate"));
}

#[test]
fn compose_search_query_includes_web_search() {
    let out = compose_default(&[], "search the web for rust docs", pa_catalog(), &[]);
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}

#[test]
fn compose_small_catalog_skips_rag() {
    let small = pa_catalog().into_iter().take(2).collect::<Vec<_>>();
    let out = compose_default(&[], "hello", small, &[]);
    assert_eq!(out.tools.len(), 2);
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
fn compose_calorie_photo_query_excludes_img_generate() {
    let out = compose_default(
        &[inst_consumption()],
        "berapa kalori makanan ini ?",
        health_catalog(),
        &[],
    );
    assert!(out.tools.iter().any(|t| t.name == "consumption.add"));
    assert!(!out.tools.iter().any(|t| t.name == "img.generate"));
}

#[test]
fn compose_calorie_photo_query_prefers_consumption_add_over_coach() {
    let out = compose_default(
        &[inst_consumption(), inst_consumption_coach()],
        "berapa kalori makanan ini ?",
        health_catalog(),
        &[],
    );
    assert!(out.matched_ids.contains(&"inst.consumption_add".into()));
    assert!(out.tools.iter().any(|t| t.name == "consumption.add"));
    assert!(!out.tools.iter().any(|t| t.name == "img.generate"));
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
fn compose_always_inst_applies_on_empty_text() {
    let out = compose_default(&[inst_core_assistant()], "hello", pa_catalog(), &[]);
    assert!(out.matched_ids.contains(&"inst.core.assistant".into()));
    assert!(out.inst_block.contains("[INST:inst.core.assistant]"));
}

#[test]
fn compose_scope_filters_personal_assistant_inst() {
    let channel_scopes = inst_scopes_channel();
    let out = compose_tools_and_inst(
        &[inst_consumption()],
        "catat konsumsi makan siang",
        pa_catalog(),
        &[],
        &[],
        &["general".into()],
        "agent",
        &[],
        &channel_scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    );
    assert!(!out.matched_ids.contains(&"inst.consumption_add".into()));
    let home_scopes = inst_scopes_home();
    let out_home = compose_tools_and_inst(
        &[inst_consumption()],
        "catat konsumsi makan siang",
        pa_catalog(),
        &[],
        &[],
        &["general".into()],
        "agent",
        &[],
        &home_scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    );
    assert!(out_home.matched_ids.contains(&"inst.consumption_add".into()));
}

#[test]
fn compose_ask_mode_no_write_tools() {
    let scopes = inst_scopes_home();
    let out = compose_tools_and_inst(
        &[],
        "hello",
        pa_catalog(),
        &[],
        &[],
        &["general".into()],
        "ask",
        &[],
        &scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    );
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
        requires_kinds: vec![],
        requires_capability: None,
    });
    let scopes = inst_scopes_home();
    let out = compose_tools_and_inst(
        &[],
        "how many calories today",
        catalog,
        &[],
        &[],
        &["health".into()],
        "ask",
        &[],
        &scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    );
    assert!(out.tools.iter().any(|t| t.name == "consumption.today"));
    assert!(!out.tools.iter().any(|t| t.name == "consumption.add"));
}

fn inst_mention_research() -> InstRow {
    InstRow {
        id: "inst.mention.research".into(),
        scope: SCOPE_GLOBAL.into(),
        kind: "mention".into(),
        topic_id: "research".into(),
        topics: vec![],
        inst: "research".into(),
        phrases: vec![],
        triggers: vec![
            "tool_include:web.research".into(),
            "tool_include:web.visit".into(),
            "tool_include:web.search".into(),
        ],
        priority: 125,
    }
}

#[test]
fn compose_research_mention_includes_web_research() {
    let mentions = vec![MentionRow { id: "research".into(), topic_id: "research".into() }];
    let scopes = inst_scopes_home();
    let out = compose_tools_and_inst(
        &[inst_mention_research()],
        "compare rust web frameworks",
        cluster_tools(),
        &[],
        &["research".into()],
        &["research".into()],
        "agent",
        &mentions,
        &scopes,
        &MentionContext::empty(),
        &SiteCapabilityView::empty(),
    );
    assert!(out.tools.iter().any(|t| t.name == "web.research"));
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}

fn inst_referral_put() -> InstRow {
    InstRow {
        id: "inst.referral_put".into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: String::new(),
        topics: vec![],
        inst: "[REFERRAL] create code".into(),
        phrases: vec!["buat referral code".into(), "referral code untuk".into()],
        triggers: vec!["tool_include:referral.code.put".into()],
        priority: 130,
    }
}

fn inst_referral_list() -> InstRow {
    InstRow {
        id: "inst.referral_list".into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: String::new(),
        topics: vec![],
        inst: "[REFERRAL] list codes".into(),
        phrases: vec!["daftar referral code".into(), "list referral codes".into()],
        triggers: vec!["tool_include:referral.code.list".into()],
        priority: 125,
    }
}

fn referral_catalog() -> Vec<ToolDef> {
    vec![
        ToolDef::new(
            "referral.code.put".into(),
            "Create or update a referral signup or package code for the caller. Examples: buat referral code untuk Chito, create referral code named Partner-A.".into(),
            json!({}),
        ),
        ToolDef::new(
            "referral.code.list".into(),
            "List referral and package codes issued by the caller. Examples: daftar referral code, list my referral codes.".into(),
            json!({}),
        ),
        ToolDef::new(
            "referral.code.delete".into(),
            "Delete a referral or package code owned by the caller.".into(),
            json!({}),
        ),
        ToolDef::new(
            "referral.tree.get".into(),
            "Fetch referral downline tree nodes. Examples: lihat downline, referral tree.".into(),
            json!({}),
        ),
        ToolDef::new("web.search".into(), "Search the web".into(), json!({})),
    ]
}

#[test]
fn compose_referral_create_forces_put_tool() {
    let out = compose_default(
        &[inst_referral_put()],
        "buat referral code untuk Chito",
        referral_catalog(),
        &[],
    );
    assert!(out.matched_ids.contains(&"inst.referral_put".into()));
    assert!(out.tools.iter().any(|t| t.name == "referral.code.put"));
}

#[test]
fn compose_referral_list_forces_list_tool() {
    let out = compose_default(
        &[inst_referral_list()],
        "daftar referral code",
        referral_catalog(),
        &[],
    );
    assert!(out.matched_ids.contains(&"inst.referral_list".into()));
    assert!(out.tools.iter().any(|t| t.name == "referral.code.list"));
}

#[test]
fn compose_referral_list_lexical_without_inst() {
    let out = compose_default(&[], "daftar kode referral saya", referral_catalog(), &[]);
    assert!(out.tools.iter().any(|t| t.name == "referral.code.list"));
}

fn site_mention_ctx(site_iid: i64) -> MentionContext {
    MentionContext::from_site(SiteContext {
        site_iid,
        alien_id: "warung-a".into(),
        name: "Warung A".into(),
    })
}

fn site_catalog() -> Vec<ToolDef> {
    vec![
        ToolDef {
            name: "site.product_put".into(),
            description: "Upsert product".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec!["web.builder".into()],
            always: vec![],
            readonly: false,
            requires_kinds: vec!["site".into()],
            requires_capability: None,
        },
        ToolDef {
            name: "web.search".into(),
            description: "Search the web".into(),
            parameters: json!({}),
            aliases: vec![],
            topics: vec![],
            always: vec![],
            readonly: false,
            requires_kinds: vec![],
            requires_capability: None,
        },
    ]
}

#[test]
fn compose_requires_kinds_drops_site_tools_without_mention() {
    let out = compose_default(&[], "add product nasi goreng", site_catalog(), &[]);
    assert!(!out.tools.iter().any(|t| t.name == "site.product_put"));
    assert!(out.tools.iter().any(|t| t.name == "web.search"));
}

#[test]
fn compose_requires_kinds_keeps_site_tools_with_site_mention() {
    let mention = site_mention_ctx(111);
    let scopes = inst_scopes_home();
    let out = compose_tools_and_inst(
        &[],
        "add product nasi goreng",
        site_catalog(),
        &[],
        &[],
        &["web.builder".into()],
        "agent",
        &[],
        &scopes,
        &mention,
        &SiteCapabilityView::empty(),
    );
    assert!(out.tools.iter().any(|t| t.name == "site.product_put"));
}

#[test]
fn tool_mention_eligible_requires_site_kind() {
    let site_tool = site_catalog()[0].clone();
    let caps = SiteCapabilityView::empty();
    assert!(!tool_mention_eligible(&site_tool, &MentionContext::empty(), &caps));
    assert!(tool_mention_eligible(&site_tool, &site_mention_ctx(111), &caps));
}

#[test]
fn tool_mention_capability_read_needs_any_site() {
    let tool = ToolDef {
        name: "site.query.run".into(),
        description: "Run site query".into(),
        parameters: json!({}),
        aliases: vec![],
        topics: vec!["site.commerce".into()],
        always: vec![],
        readonly: true,
        requires_kinds: vec!["site".into()],
        requires_capability: Some("commerce".into()),
    };
    let caps = SiteCapabilityView::from_map(HashMap::from([
        (111, json!({ "commerce": true })),
        (222, json!({ "commerce": false })),
    ]));
    let two_sites = MentionContext {
        sites: vec![
            SiteContext {
                site_iid: 111,
                alien_id: "a".into(),
                name: "A".into(),
            },
            SiteContext {
                site_iid: 222,
                alien_id: "b".into(),
                name: "B".into(),
            },
        ],
        devices: vec![],
        default_site_iid: None,
    };
    assert!(tool_mention_eligible(&tool, &two_sites, &caps));
}

#[test]
fn tool_mention_capability_write_needs_default_site() {
    let tool = ToolDef {
        name: "site.tx.put".into(),
        description: "Write tx".into(),
        parameters: json!({}),
        aliases: vec![],
        topics: vec!["site.commerce".into()],
        always: vec![],
        readonly: false,
        requires_kinds: vec!["site".into()],
        requires_capability: Some("commerce".into()),
    };
    let caps = SiteCapabilityView::from_map(HashMap::from([(111, json!({ "commerce": true }))]));
    let multi_site = MentionContext {
        sites: vec![
            SiteContext {
                site_iid: 111,
                alien_id: "a".into(),
                name: "A".into(),
            },
            SiteContext {
                site_iid: 222,
                alien_id: "b".into(),
                name: "B".into(),
            },
        ],
        devices: vec![],
        default_site_iid: None,
    };
    assert!(!tool_mention_eligible(&tool, &multi_site, &caps));
    assert!(tool_mention_eligible(&tool, &site_mention_ctx(111), &caps));
}

fn inst_img_edit() -> InstRow {
    InstRow {
        id: "inst.task.img_edit".into(),
        scope: "global".into(),
        kind: "task".into(),
        topic_id: "".into(),
        topics: vec![],
        inst: "edit".into(),
        phrases: vec!["remove background".into(), "edit gambar".into()],
        triggers: vec!["tool_include:img.edit".into(), "tool_exclude:img.generate".into()],
        priority: 145,
    }
}

fn inst_mention_image_high() -> InstRow {
    InstRow {
        id: "inst.mention.image_high".into(),
        scope: "global".into(),
        kind: "mention".into(),
        topic_id: "image_high".into(),
        topics: vec![],
        inst: "hd".into(),
        phrases: vec![],
        triggers: vec!["tool_include:img.generate".into()],
        priority: 130,
    }
}

fn image_catalog() -> Vec<ToolDef> {
    vec![
        ToolDef::new("img.generate".into(), "Generate images".into(), json!({})),
        ToolDef::new("img.edit".into(), "Edit images".into(), json!({})),
    ]
}

#[test]
fn compose_img_edit_phrase_includes_edit_tool() {
    let out = compose_default(&[inst_img_edit()], "edit gambar hapus background", image_catalog(), &[]);
    assert!(out.matched_ids.contains(&"inst.task.img_edit".into()));
    assert!(out.tools.iter().any(|t| t.name == "img.edit"));
    assert!(!out.tools.iter().any(|t| t.name == "img.generate"));
}

#[test]
fn compose_mention_image_high_matched() {
    let mention = MentionContext::empty();
    let out = compose_tools_and_inst(
        &[inst_mention_image_high()],
        "buat logo minimarket",
        image_catalog(),
        &[],
        &["image_high".into()],
        &["image".into()],
        "agent",
        &[],
        &inst_scopes_home(),
        &mention,
        &SiteCapabilityView::empty(),
    );
    assert!(out.matched_ids.contains(&"inst.mention.image_high".into()));
    assert!(out.tools.iter().any(|t| t.name == "img.generate"));
}

#[test]
fn tool_trim_ranked_drops_low_sim_gap() {
    let ranked = vec![
        ToolCandidate { tool_id: "consumption.add".into(), sim: 0.95 },
        ToolCandidate { tool_id: "expense.add".into(), sim: 0.33 },
        ToolCandidate { tool_id: "web.search".into(), sim: 0.33 },
    ];
    let trimmed = tool_trim_ranked(&ranked, &[], DEFAULT_TOOL_SIM_THRESHOLD, DEFAULT_TOOL_SIM_GAP);
    assert_eq!(trimmed.len(), 1);
    assert_eq!(trimmed[0].tool_id, "consumption.add");
}
