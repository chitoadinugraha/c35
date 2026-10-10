//! Boost commerce tools after a transaction-list block in the prior turn.

#[derive(Clone, Debug)]
pub struct CommerceTxFollowup {
    pub inst_suffix: String,
    pub force_tools: Vec<String>,
    pub tool_exclude: Vec<String>,
}

pub fn commerce_tx_followup_boost(
    last_blocks_json: &str,
    user_text: &str,
) -> Option<CommerceTxFollowup> {
    if !commerce_items_sold_query(user_text) {
        return None;
    }
    if !last_blocks_has_tx_list(last_blocks_json) {
        return None;
    }
    let ctx = parse_tx_list_block(last_blocks_json);
    let range = ctx.range_key.as_deref().unwrap_or("today");
    let site = ctx.site_name.as_deref().unwrap_or("");
    Some(CommerceTxFollowup {
        inst_suffix: format!(
            "[COMMERCE TX FOLLOW-UP] User asks what items/products were sold. Call site.query.run query_id tx.top_products with params.range=\"{range}\". Use site from [SITE CONTEXTS] or site_name \"{site}\" when one site applies. Reply in the user language. Do not call web.search or web.visit."
        ),
        force_tools: vec!["site.query.run".into()],
        tool_exclude: vec!["web.search".into(), "web.visit".into()],
    })
}

fn commerce_items_sold_query(text: &str) -> bool {
    let t = text.trim().to_lowercase();
    t.contains("item yang dijual")
        || t.contains("apa saja item")
        || t.contains("barang apa")
        || t.contains("barang yang")
        || t.contains("produk apa")
        || t.contains("yang terjual")
        || t.contains("what was sold")
        || t.contains("what items")
}

fn last_blocks_has_tx_list(blocks_json: &str) -> bool {
    let arr: Vec<serde_json::Value> = serde_json::from_str(blocks_json).unwrap_or_default();
    arr.iter().any(|b| b.get("kind").and_then(|k| k.as_str()) == Some("site.tx_list"))
}

struct TxListCtx {
    range_key: Option<String>,
    site_name: Option<String>,
}

fn parse_tx_list_block(blocks_json: &str) -> TxListCtx {
    let arr: Vec<serde_json::Value> = serde_json::from_str(blocks_json).unwrap_or_default();
    for b in arr {
        if b.get("kind").and_then(|k| k.as_str()) != Some("site.tx_list") {
            continue;
        }
        let body = b.get("body").cloned().unwrap_or_default();
        return TxListCtx {
            range_key: body.get("range_key").and_then(|v| v.as_str()).map(str::to_string),
            site_name: body
                .get("site_name")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .map(str::to_string),
        };
    }
    TxListCtx {
        range_key: None,
        site_name: None,
    }
}

pub async fn chat_last_assistant_blocks(pool: &sqlx::PgPool, chat_id: i64) -> Option<String> {
    sqlx::query_scalar(
        r#"
        SELECT blocks_json::text FROM ai.chat_msg
        WHERE chat_id = $1 AND role = 'assistant' AND deleted_ts IS NULL AND status <> 'error'
        ORDER BY id DESC
        LIMIT 1
        "#,
    )
    .bind(chat_id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_items_sold_followup() {
        let blocks = r#"[{"kind":"site.tx_list","body":{"range_key":"today","site_name":"Gucicha"}}]"#;
        let f = commerce_tx_followup_boost(blocks, "apa saja item yang dijual").unwrap();
        assert!(f.inst_suffix.contains("tx.top_products"));
        assert!(f.tool_exclude.contains(&"web.visit".to_string()));
    }
}
