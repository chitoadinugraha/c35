use serde_json::{json, Value};

pub fn expense_compact_for_llm(full: &Value) -> Value {
    json!({
        "ok": full.get("ok"),
        "saved": full.get("saved"),
        "duplicate": full.get("duplicate"),
        "tx_id": full.get("tx_id"),
        "headline": full.get("headline"),
        "coach": full.get("coach"),
        "total_minor": full.get("total_minor"),
        "payment_method": full.get("payment_method"),
        "today": full.get("today"),
        "items": full.get("items").and_then(|v| v.as_array()).map(|a| {
            a.iter().map(|i| json!({
                "name": i.get("name"),
                "name_id": i.get("name_id"),
                "qty": i.get("qty"),
                "price_minor": i.get("price_minor"),
                "total_minor": i.get("total_minor"),
                "obj_id": i.get("obj_id"),
            })).collect::<Vec<_>>()
        }),
    })
}

pub fn summary_compact_for_llm(full: &Value) -> Value {
    json!({
        "ok": full.get("ok"),
        "period_id": full.get("period_id"),
        "glance": full.get("glance"),
        "coach": full.get("coach"),
        "matched_query": full.get("matched_query"),
        "matched_total_minor": full.get("matched_total_minor"),
    })
}
