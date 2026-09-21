use sqlx::PgPool;

pub async fn topic_inst_chain(pool: &PgPool, topic_id: &str) -> Vec<String> {
    let mut chain = Vec::new();
    let mut cur = topic_id.trim().to_string();
    let mut seen = std::collections::HashSet::new();
    while !cur.is_empty() && seen.insert(cur.clone()) {
        chain.push(cur.clone());
        cur = sqlx::query_scalar::<_, String>(
            "SELECT extend FROM ai.topic WHERE id = $1 AND enabled = true",
        )
        .bind(&cur)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        .unwrap_or_default();
    }
    chain
}

/// Merge topic `inst` fields along the extend chain (parent → child).
pub async fn topic_inst_block(pool: &PgPool, topic_id: &str) -> String {
    let chain = topic_inst_chain(pool, topic_id).await;
    let mut parts = Vec::new();
    for id in chain.iter().rev() {
        let inst = sqlx::query_scalar::<_, String>(
            "SELECT inst FROM ai.topic WHERE id = $1 AND enabled = true",
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
        .unwrap_or_default();
        if !inst.trim().is_empty() {
            parts.push(inst);
        }
    }
    parts.join("\n\n")
}
