use c35_mod_chat::{
    instruction_auto_match, scope_instruction_build_trace, scope_instruction_prompt_block, ScopeInstructionRow, MODE_ALWAYS,
    MODE_AUTO, MODE_DISABLED,
};

#[test]
fn instruction_auto_match_requires_shared_token() {
    assert!(instruction_auto_match(
        "please update pricing menu",
        "Always mention our vegan options on the menu",
    ));
    assert!(!instruction_auto_match("hi", "Always mention vegan options"));
}

#[test]
fn scope_instruction_prompt_block_respects_mode() {
    let user = ScopeInstructionRow {
        id: 1,
        owner_iid: 99000,
        scope_kind: "user".into(),
        scope_iid: 99000,
        mode: MODE_ALWAYS.into(),
        body: "Be concise".into(),
    };
    let site = ScopeInstructionRow {
        id: 2,
        owner_iid: 99000,
        scope_kind: "site".into(),
        scope_iid: 111,
        mode: MODE_AUTO.into(),
        body: "Warung hours 9-5".into(),
    };
    let block = scope_instruction_prompt_block(
        "what are Warung hours?",
        Some(&user),
        &[("Warung A".into(), site.clone())],
    );
    assert!(block.contains("[USER INSTRUCTIONS]"));
    assert!(block.contains("Be concise"));
    assert!(block.contains("[SITE INSTRUCTIONS"));

    let site_off = ScopeInstructionRow {
        mode: MODE_DISABLED.into(),
        body: "hidden".into(),
        ..site
    };
    let block2 = scope_instruction_prompt_block("hello", Some(&user), &[("X".into(), site_off)]);
    assert!(!block2.contains("hidden"));
}
#[test]
fn scope_instruction_build_trace_marks_applied() {
    let user = ScopeInstructionRow {
        id: 1,
        owner_iid: 99000,
        scope_kind: "user".into(),
        scope_iid: 99000,
        mode: MODE_ALWAYS.into(),
        body: "Be concise".into(),
    };
    let block = scope_instruction_prompt_block("hi", Some(&user), &[]);
    let trace = scope_instruction_build_trace("hi", Some(&user), &[], &block);
    assert!(trace.injected);
    assert_eq!(trace.entries.len(), 1);
    assert!(trace.entries[0].applied);
    assert!(trace.block_preview.contains("USER INSTRUCTIONS"));
}
