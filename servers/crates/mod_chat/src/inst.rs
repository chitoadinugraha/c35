use sqlx::PgPool;

use crate::inst_macro::InstRow;

pub async fn inst_list_enabled(pool: &PgPool) -> Vec<InstRow> {
    let rows = sqlx::query_as::<_, (
        String, String, String, String, Vec<String>, String, Vec<String>, Vec<String>, i32,
    )>(
        "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, priority \
         FROM ai.inst WHERE enabled = true AND deleted_ts IS NULL ORDER BY priority DESC, id ASC",
    )
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.into_iter()
        .map(|(id, scope, kind, topic_id, topics, inst, phrases, triggers, priority)| InstRow {
            id,
            scope,
            kind,
            topic_id,
            topics,
            inst,
            phrases,
            triggers,
            priority,
        })
        .collect()
}
