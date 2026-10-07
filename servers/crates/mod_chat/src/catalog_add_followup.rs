//! One-turn boost when the user confirms a catalog-add question from the prior assistant message.

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CatalogAddFollowup {
    pub inst_suffix: String,
    pub force_tools: Vec<String>,
}

pub fn catalog_add_followup_boost(last_assistant: &str, user_text: &str) -> Option<CatalogAddFollowup> {
    if !catalog_add_user_affirms(user_text) {
        return None;
    }
    if !catalog_add_assistant_asked_confirm(last_assistant) {
        return None;
    }
    Some(CatalogAddFollowup {
        inst_suffix: "[PENDING CATALOG ADD] The user confirmed the prior question. Call site.product_put with the product name from that question and site_iid from [SITE CONTEXTS] when exactly one site is listed. Do not call web.search.".into(),
        force_tools: vec!["site.product_put".into()],
    })
}

fn catalog_add_user_affirms(text: &str) -> bool {
    let t = text.trim().to_lowercase();
    if t.is_empty() || t.len() > 32 {
        return false;
    }
    matches!(
        t.as_str(),
        "ya" | "iya" | "y" | "ok" | "oke" | "okay" | "setuju" | "benar" | "sip" | "yes" | "yep" | "sure" | "betul"
            | "bener" | "lanjut" | "gas" | "go"
    )
}

fn catalog_add_assistant_asked_confirm(assistant: &str) -> bool {
    let lower = assistant.to_lowercase();
    if !lower.contains('?') {
        return false;
    }
    lower.contains("tambah")
        || lower.contains("add ")
        || lower.contains("add to")
        || lower.contains("di situs")
        || lower.contains("which site")
        || lower.contains("situs mana")
}

pub async fn chat_last_assistant_content(pool: &sqlx::PgPool, chat_id: i64) -> Option<String> {
    sqlx::query_scalar(
        r#"
        SELECT content FROM ai.chat_msg
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
    fn affirm_after_tambah_confirm_boosts() {
        let boost = catalog_add_followup_boost("Tambah Indomie Goreng di situs Warung A?", "ya");
        assert!(boost.is_some());
        assert!(boost.unwrap().force_tools.contains(&"site.product_put".into()));
    }

    #[test]
    fn bare_ya_without_prior_confirm_none() {
        assert!(catalog_add_followup_boost("Halo, ada yang bisa dibantu?", "ya").is_none());
    }

    #[test]
    fn long_user_text_not_affirm() {
        assert!(catalog_add_followup_boost("Tambah X di situs Y?", "ya tambahkan sekarang juga").is_none());
    }
}
