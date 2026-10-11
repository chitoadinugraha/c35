//! Suppress forced / prefetched web when the turn already has enough local context.

use crate::prompt::tool_loop::user_wants_search;

/// Do not force web.search on hop 1 or run Rust web prefetch when enrich or self-identity inst applies
/// and the user is not clearly asking for live external data.
pub fn compose_suppress_web_when_context_ready(
    matched_ids: &[String],
    enrich_keys: &[String],
    user_text: &str,
) -> bool {
    if user_text.trim().is_empty() {
        return false;
    }
    if user_explicit_web_intent(user_text) {
        return false;
    }
    if matched_ids.iter().any(|id| id == "inst.me") {
        return true;
    }
    if !enrich_keys.is_empty() {
        return true;
    }
    false
}

pub fn compose_skip_web_prefetch_for_context(
    matched_ids: &[String],
    enrich_keys: &[String],
    user_text: &str,
) -> bool {
    compose_suppress_web_when_context_ready(matched_ids, enrich_keys, user_text)
}

/// Stronger than `user_wants_search` — explicit search verbs only (not bare "harga" on a form-filling turn).
fn user_explicit_web_intent(text: &str) -> bool {
    let t = text.to_ascii_lowercase();
    [
        "search ",
        "search the",
        "cari ",
        "google ",
        "googling",
        "browse the web",
        "look up ",
        "web.search",
    ]
    .iter()
    .any(|k| t.contains(k))
        || user_wants_search(text)
}
