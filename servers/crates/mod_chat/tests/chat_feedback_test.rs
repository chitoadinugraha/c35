use c35_mod_chat::{
    chat_msg_feedback_list, chat_msg_feedback_put, feedback_comment_ok, feedback_thanks,
};
use c35_proto::{ChatFeedbackAuthorRole, ChatFeedbackVote, ReqChatMsgFeedbackList, ReqChatMsgFeedbackPut};
use c35_store::{migrate_apply, pool_connect, snowflake_id};
use sqlx::PgPool;

fn db_tests_enabled() -> bool {
    std::env::var("C35_TEST_DB").ok().as_deref() == Some("1")
}

async fn test_pool() -> PgPool {
    std::env::set_var("PG_MAX_CONNECTIONS", "4");
    pool_connect().await.expect("pool_connect (set YB_* in .env.local)")
}

async fn ensure_schema(pool: &PgPool) {
    let ready = sqlx::query_scalar::<_, bool>("SELECT to_regclass('ai.chat_msg_feedback') IS NOT NULL")
        .fetch_one(pool)
        .await
        .unwrap_or(false);
    if !ready {
        migrate_apply(pool).await.expect("migrate_apply");
    }
}

#[test]
fn thanks_id_and_en() {
    assert_eq!(
        feedback_thanks("bad", "id-ID"),
        "Terima kasih. Catatanmu kami simpan untuk jawaban berikutnya."
    );
    assert_eq!(feedback_thanks("good", "id-ID"), "Terima kasih. Senang jawaban ini membantu.");
    assert_eq!(
        feedback_thanks("bad", "en-US"),
        "Thanks. We'll use this note on the next answer."
    );
    assert_eq!(feedback_thanks("good", "en"), "Thanks. Glad this answer helped.");
}

#[test]
fn other_requires_comment() {
    assert!(!feedback_comment_ok("other", "  "));
    assert!(feedback_comment_ok("other", "harusnya 3 slide"));
    assert!(feedback_comment_ok("wrong", ""));
}

#[tokio::test]
async fn put_one_system_post_then_clear() {
    if !db_tests_enabled() {
        return;
    }
    let pool = test_pool().await;
    ensure_schema(&pool).await;
    let owner_iid = snowflake_id();
    let chat_id = snowflake_id();
    let msg_id = snowflake_id();
    let req_id = format!("fb-{}", snowflake_id());

    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, name, owner_iid, created_ts, updated_ts)
        VALUES ($1, 'user', '', 'feedback-test', $1, NOW(), NOW())
        "#,
    )
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert identity");
    sqlx::query(
        r#"
        INSERT INTO ai.chat (id, owner_iid, kind, title, created_ts, updated_ts)
        VALUES ($1, $2, 'prompt', 'feedback test', NOW(), NOW())
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert chat");
    sqlx::query(
        r#"
        INSERT INTO ai.chat_member (chat_id, member_iid, created_ts, updated_ts)
        VALUES ($1, $2, NOW(), NOW())
        "#,
    )
    .bind(chat_id)
    .bind(owner_iid)
    .execute(&pool)
    .await
    .expect("insert member");
    sqlx::query(
        r#"
        INSERT INTO ai.chat_msg (id, chat_id, owner_iid, req_id, sender_iid, role, source, content, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, $3, 'assistant', 'prompt', 'answer', NOW(), NOW())
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(owner_iid)
    .bind(&req_id)
    .execute(&pool)
    .await
    .expect("insert msg");

    let first = chat_msg_feedback_put(
        &pool,
        owner_iid,
        ReqChatMsgFeedbackPut {
            msg_id,
            chat_id,
            vote: ChatFeedbackVote::Bad as i32,
            reason_id: 8,
            comment: "missed the steps".into(),
            locale: "en".into(),
        },
    )
    .await
    .expect("put bad");
    let fb = first.feedback.expect("feedback");
    assert_eq!(fb.reason_slug, "ignored");
    assert_eq!(fb.posts.len(), 1);
    assert_eq!(fb.posts[0].author_iid, 0);
    assert_eq!(fb.posts[0].author_role, ChatFeedbackAuthorRole::System as i32);
    let live = live_system_posts(&pool, msg_id).await;
    assert_eq!(live, 1);

    let second = chat_msg_feedback_put(
        &pool,
        owner_iid,
        ReqChatMsgFeedbackPut {
            msg_id,
            chat_id,
            vote: ChatFeedbackVote::Bad as i32,
            reason_id: 8,
            comment: "still missed".into(),
            locale: "en".into(),
        },
    )
    .await
    .expect("put again");
    let fb2 = second.feedback.expect("feedback");
    assert_eq!(fb2.id, fb.id);
    assert_eq!(fb2.posts.len(), 1);
    assert_eq!(fb2.posts[0].id, fb.posts[0].id);
    assert_eq!(live_system_posts(&pool, msg_id).await, 1);

    let bad = chat_msg_feedback_put(
        &pool,
        owner_iid,
        ReqChatMsgFeedbackPut {
            msg_id,
            chat_id,
            vote: ChatFeedbackVote::Bad as i32,
            reason_id: 12,
            comment: "   ".into(),
            locale: "en".into(),
        },
    )
    .await;
    assert!(bad.is_err(), "other with empty comment must fail");

    let cleared = chat_msg_feedback_put(
        &pool,
        owner_iid,
        ReqChatMsgFeedbackPut {
            msg_id,
            chat_id,
            vote: ChatFeedbackVote::Unspecified as i32,
            reason_id: 0,
            comment: String::new(),
            locale: "en".into(),
        },
    )
    .await
    .expect("clear");
    assert!(cleared.feedback.is_none());
    let listed = chat_msg_feedback_list(
        &pool,
        owner_iid,
        ReqChatMsgFeedbackList {
            chat_id,
            locale: "en".into(),
        },
    )
    .await
    .expect("list");
    assert!(listed.feedback.is_empty());

    let _ = sqlx::query("DELETE FROM ai.chat WHERE id = $1").bind(chat_id).execute(&pool).await;
    let _ = sqlx::query("DELETE FROM ai.identity WHERE id = $1").bind(owner_iid).execute(&pool).await;
}

async fn live_system_posts(pool: &PgPool, msg_id: i64) -> i64 {
    sqlx::query_scalar(
        r#"
        SELECT COUNT(*)::bigint
        FROM ai.chat_feedback_post p
        JOIN ai.chat_msg_feedback f ON f.id = p.feedback_id
        WHERE f.msg_id = $1 AND p.author_role = 'system' AND p.deleted_ts IS NULL
        "#,
    )
    .bind(msg_id)
    .fetch_one(pool)
    .await
    .expect("count posts")
}
