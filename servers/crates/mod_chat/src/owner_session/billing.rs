use c35_nats::BillingGateCached;

use super::state::OwnerPromptSession;

pub fn session_billing_snapshot(session: &OwnerPromptSession) -> Option<BillingGateCached> {
    session.read_state().billing.clone()
}

pub fn owner_session_apply_billing_cached(session: &OwnerPromptSession, entry: BillingGateCached) {
    let mut st = session.write_state();
    st.billing = Some(entry);
    session.bump_revision();
}
