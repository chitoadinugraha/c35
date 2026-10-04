use c35_ctx::AppState;
use c35_mod_drive::{drive_sync_nats_subject, drive_sync_nudge_bytes};
use c35_mod_event::{event_emit, kinds, EventCtx};
use serde_json::json;
use tracing::warn;

pub async fn drive_mutation_notify(
    st: &AppState,
    owner_iid: i64,
    path: &str,
    since_ms: i64,
    deleted: bool,
    source: &str,
) {
    let kind = if deleted {
        kinds::DRIVE_FILE_DELETED
    } else {
        kinds::DRIVE_FILE_UPDATED
    };
    let ctx = EventCtx::for_owner(owner_iid, "c35-server");
    let meta = json!({
        "path": path,
        "source": source,
        "since_ms": since_ms,
    });
    let _ = event_emit(&st.pool, st.nats.as_ref(), ctx, kind, meta).await;

    if let Some(nats) = st.nats.as_ref() {
        let subject = drive_sync_nats_subject(owner_iid);
        let payload = drive_sync_nudge_bytes(since_ms);
        if let Err(e) = nats.publish(subject, payload.into()).await {
            warn!(error = %e, owner_iid, "drive_sync nats publish failed");
        }
    }
}