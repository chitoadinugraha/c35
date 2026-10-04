use c35_mod_chat::{chat_messages, chat_search, ChatHistoryQuery};
use c35_store::{pool_connect, snowflake_id};
use chrono::{DateTime, Utc};
use sqlx::PgPool;

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    pool_connect().await.expect("pool_connect")
}

fn q(owner: i64, current: i64, query: &str, since: &str, until: &str, chat_id: i64) -> ChatHistoryQuery {
    ChatHistoryQuery {
        owner_iid: owner,
        current_chat_id: current,
        query: query.into(),
        since: since.into(),
        until: until.into(),
        chat_id,
        limit: 5,
        locale: "id-ID".into(),
        user_text: query.into(),
    }
}

#[tokio::test]
async fn search_finds_exact_user_line_in_jakarta_time() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    let _ = sqlx::query(
        r#"
        DELETE FROM ai.chat_msg WHERE owner_iid IN (SELECT id FROM ai.identity WHERE name = 'chat-history-test');
        DELETE FROM ai.chat WHERE owner_iid IN (SELECT id FROM ai.identity WHERE name = 'chat-history-test');
        DELETE FROM ai.identity WHERE name = 'chat-history-test';
        "#,
    )
    .execute(&pool)
    .await;
    let owner = snowflake_id();
    let other = snowflake_id();
    let chat_id = snowflake_id();
    let other_chat = snowflake_id();
    let msg_id = snowflake_id();
    let asked_at = DateTime::parse_from_rfc3339("2026-10-03T08:00:00Z").unwrap().with_timezone(&Utc);

    let insert_user = |id: i64| {
        sqlx::query(
            r#"
            INSERT INTO ai.identity (id, kind, type, name, owner_iid, locale, tz, created_ts, updated_ts)
            VALUES ($1, 'user', '', 'chat-history-test', $1, 'id-ID', 'Asia/Jakarta', NOW(), NOW())
            "#,
        )
        .bind(id)
        .execute(&pool)
    };
    insert_user(owner).await.expect("owner");
    insert_user(other).await.expect("other");

    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, owner_iid, kind, title, context_summary, last_msg_ts, created_ts, updated_ts)
        VALUES ($1, $2, 'prompt', 'Catalog cleanup', '', $3, $3, $3)
        "#,
    )
    .bind(chat_id)
    .bind(owner)
    .bind(asked_at)
    .execute(&pool)
    .await
    .expect("chat");

    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, sender_iid, role, source, content, created_ts, updated_ts)
        VALUES ($1, $2, $3, $3, 'user', 'prompt', 'please remove product A from the shop', $4, $4)
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner)
    .bind(asked_at)
    .execute(&pool)
    .await
    .expect("msg");

    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, owner_iid, kind, title, last_msg_ts, created_ts, updated_ts)
        VALUES ($1, $2, 'prompt', 'Other person', NOW(), NOW(), NOW())
        "#,
    )
    .bind(other_chat)
    .bind(other)
    .execute(&pool)
    .await
    .expect("other chat");
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, sender_iid, role, source, content, created_ts, updated_ts)
        VALUES ($1, $2, $3, $3, 'user', 'prompt', 'please remove product A from the shop', NOW(), NOW())
        "#,
    )
    .bind(snowflake_id())
    .bind(other_chat)
    .bind(other)
    .execute(&pool)
    .await
    .expect("other msg");

    let found = chat_search(&pool, &q(owner, 0, "when did I ask you to remove product A", "", "", 0))
        .await
        .expect("search");
    assert_eq!(found["ok"], true);
    assert_eq!(found["tz"], "Asia/Jakarta");
    assert_eq!(found["count"], 1);
    let hit = &found["chats"][0];
    assert_eq!(hit["chat_id"], chat_id.to_string());
    assert!(hit["time"].as_str().unwrap().contains("15:00"), "{}", hit["time"]);
    assert!(hit["snippet"]["text"].as_str().unwrap().contains("remove product A"));
    assert!(hit["snippet"]["time"].as_str().unwrap().contains("15:00"));
    assert!(hit.get("messages").is_some(), "empty summary should include recent lines");

    let exact = chat_messages(&pool, &q(owner, 0, "remove product A", "2026-10-03", "2026-10-03", chat_id))
        .await
        .expect("messages");
    assert_eq!(exact["ok"], true);
    assert_eq!(exact["count"], 1);
    assert!(exact["messages"][0]["text"].as_str().unwrap().contains("remove product A"));
    assert!(exact["messages"][0]["time"].as_str().unwrap().contains("WIB"));

    let hidden = chat_messages(&pool, &q(other, 0, "", "", "", chat_id)).await.expect("cross owner");
    assert_eq!(hidden["ok"], false);

    let missed = chat_messages(&pool, &q(owner, 0, "remove product A", "2026-10-04", "2026-10-04", chat_id))
        .await
        .expect("other day");
    assert_eq!(missed["count"], 0);

    sqlx::query("DELETE FROM ai.chat_msg WHERE owner_iid = ANY($1)")
        .bind(vec![owner, other])
        .execute(&pool)
        .await
        .ok();
    sqlx::query("DELETE FROM ai.chat WHERE owner_iid = ANY($1)")
        .bind(vec![owner, other])
        .execute(&pool)
        .await
        .ok();
    sqlx::query("DELETE FROM ai.identity WHERE id = ANY($1)")
        .bind(vec![owner, other])
        .execute(&pool)
        .await
        .ok();
}
