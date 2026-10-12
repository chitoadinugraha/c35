use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use c35_mod_chat::owner_session::{
    owner_session_attach_for_live, owner_session_attach_for_prompt, owner_session_get,
    owner_session_register_warmup_for_session, owner_session_supersede, owner_session_teardown,
    ChatLru, OwnerPromptSession, TurnContinuity, TURN_CONTINUITY_INITIAL,
};

#[test]
fn continuity_decays_on_user_messages() {
    let mut c = TurnContinuity::fresh();
    c.apply_hints(vec!["web.search".into()], "follow up".into());
    assert_eq!(c.turns_remaining, TURN_CONTINUITY_INITIAL);
    for _ in 0..TURN_CONTINUITY_INITIAL {
        c.on_user_message();
    }
    assert_eq!(c.turns_remaining, 0);
    assert!(!c.active());
    assert!(c.force_tools.is_empty());
}

#[test]
fn chat_lru_evicts_oldest() {
    let mut lru = ChatLru::new(2);
    lru.touch(1);
    lru.touch(2);
    lru.touch(3);
    assert_eq!(lru.len(), 2);
    assert!(lru.get_readonly(1).is_none());
    assert!(lru.get_readonly(2).is_some());
    assert!(lru.get_readonly(3).is_some());
    let order = lru.eviction_order();
    assert_eq!(order[0], 2);
}

#[test]
fn revision_increments_monotonically() {
    let s = OwnerPromptSession::new(42, "c".into());
    assert_eq!(s.revision(), 0);
    let r1 = s.bump_revision();
    let r2 = s.bump_revision();
    assert_eq!(r1, 1);
    assert_eq!(r2, 2);
    assert_eq!(s.revision(), 2);
}

#[tokio::test]
async fn supersede_aborts_registered_warmup() {
    let owner = 99001_i64;
    let _ = owner_session_teardown("orphan");
    let sess = owner_session_supersede(owner, "conn-a".into());
    let finished = Arc::new(AtomicBool::new(false));
    let flag = finished.clone();
    let handle = tokio::spawn(async move {
        tokio::time::sleep(Duration::from_secs(30)).await;
        flag.store(true, Ordering::SeqCst);
    });
    owner_session_register_warmup_for_session(&sess, handle.abort_handle());

    let _new = owner_session_supersede(owner, "conn-b".into());
    tokio::time::sleep(Duration::from_millis(30)).await;
    assert!(!finished.load(Ordering::SeqCst));
    assert!(sess.is_superseded());
    assert!(owner_session_get(owner).is_some());
    owner_session_teardown("conn-b");
    assert!(owner_session_get(owner).is_none());
}

#[test]
fn attach_for_prompt_reuses_live_ws_session() {
    let owner = 98_765_432_101_i64;
    let _ = owner_session_teardown("headless-prompt-98765432101");
    let app = owner_session_supersede(owner, "app-conn-mcp-test".into());
    let rev = app.revision();
    let (attached, new_headless) = owner_session_attach_for_prompt(owner);
    assert!(!new_headless);
    assert_eq!(attached.revision(), rev);
    assert!(Arc::ptr_eq(&app, &attached));
    owner_session_teardown("app-conn-mcp-test");
}

#[test]
fn attach_for_live_reuses_app_ws_session() {
    let owner = 98_765_432_102_i64;
    let app = owner_session_supersede(owner, "app-conn-live-test".into());
    let rev = app.revision();
    let (attached, new_headless) = owner_session_attach_for_live(owner);
    assert!(!new_headless);
    assert_eq!(attached.revision(), rev);
    assert!(Arc::ptr_eq(&app, &attached));
    owner_session_teardown("app-conn-live-test");
}