use sqlx::PgPool;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MentionRow {
    pub id: String,
    pub topic_id: String,
}

pub async fn mention_list_enabled(pool: &PgPool) -> Vec<MentionRow> {
    let rows = sqlx::query_as::<_, (String, Option<String>)>(
        "SELECT id, topic_id FROM ai.mention WHERE enabled = true ORDER BY sort ASC, id ASC",
    )
    .fetch_all(pool)
    .await
    .unwrap_or_default();
    rows.into_iter()
        .map(|(id, topic_id)| MentionRow {
            id,
            topic_id: topic_id.unwrap_or_default(),
        })
        .collect()
}
