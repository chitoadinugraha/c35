use c35_ctx::AppState;
use c35_mod_event::{event_spawn, kinds, EventCtx};
use serde_json::json;

pub fn auth_sign_in_emit(st: &AppState, owner_iid: i64, sess_id: i64, method: &str) {
    let mut ctx = EventCtx::for_owner(owner_iid, "c35-server");
    ctx.sess_id = Some(sess_id);
    event_spawn(
        st.pool.clone(),
        st.nats.clone(),
        ctx,
        kinds::USER_SIGN_IN,
        json!({ "method": method }),
    );
}

pub fn auth_sign_out_emit(st: &AppState, owner_iid: i64) {
    event_spawn(
        st.pool.clone(),
        st.nats.clone(),
        EventCtx::for_owner(owner_iid, "c35-server"),
        kinds::USER_SIGN_OUT,
        json!({}),
    );
}

pub fn auth_sign_in_failed_emit(st: &AppState, owner_iid: i64, method: &str) {
    event_spawn(
        st.pool.clone(),
        st.nats.clone(),
        EventCtx::for_owner(owner_iid, "c35-server"),
        kinds::USER_SIGN_IN_FAILED,
        json!({ "method": method }),
    );
}