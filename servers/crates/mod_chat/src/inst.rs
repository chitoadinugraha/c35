use sqlx::PgPool;

use crate::inst_macro::InstRow;

type InstDbRow = (
    String,
    String,
    String,
    String,
    Vec<String>,
    String,
    Vec<String>,
    Vec<String>,
    Vec<String>,
    Vec<String>,
    i32,
);

fn inst_row_map(
    (id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority): InstDbRow,
) -> InstRow {
    InstRow {
        id,
        scope,
        kind,
        topic_id,
        topics,
        inst,
        phrases,
        triggers,
        include_tools,
        exclude_tools,
        priority,
    }
}

pub async fn inst_fetch_enabled(pool: &PgPool) -> Vec<InstRow> {
    let rows = sqlx::query_as::<_, InstDbRow>(
        "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority \
         FROM ai.inst WHERE enabled = true AND deleted_ts IS NULL ORDER BY priority DESC, id ASC",
    )
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.into_iter().map(inst_row_map).collect()
}

pub async fn inst_fetch_one(pool: &PgPool, id: &str) -> Option<InstRow> {
    sqlx::query_as::<_, InstDbRow>(
        "SELECT id, scope, kind, topic_id, topics, inst, phrases, triggers, include_tools, exclude_tools, priority \
         FROM ai.inst WHERE id = $1 AND enabled = true AND deleted_ts IS NULL",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .map(inst_row_map)
}
