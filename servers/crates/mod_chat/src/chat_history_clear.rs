use anyhow::Result;
use c35_proto::{ReqChatHistoryClear, ResChatHistoryClear};
use sqlx::{PgPool, Row};

pub async fn chat_history_clear(pool: &PgPool, member_iid: i64, req: ReqChatHistoryClear) -> Result<ResChatHistoryClear> {
    let row = sqlx::query(
        r#"
        SELECT
          COUNT(*)::bigint AS msg_count,
          COUNT(DISTINCT m.chat_id)::bigint AS chat_count
        FROM ai.chat_msg m
        JOIN ai.chat c ON c.id = m.chat_id
        JOIN ai.chat_member mem ON mem.chat_id = c.id AND mem.member_iid = $1
        WHERE m.deleted_ts IS NULL
          AND c.kind = 'prompt'
          AND c.deleted_ts IS NULL
          AND mem.deleted_ts IS NULL
        "#,
    )
    .bind(member_iid)
    .fetch_one(pool)
    .await?;

    let msg_count: i64 = row.get("msg_count");
    let chat_count: i64 = row.get("chat_count");

    if req.dry_run {
        return Ok(ResChatHistoryClear {
            msgs_deleted: msg_count as i32,
            chats_affected: chat_count as i32,
        });
    }

    if msg_count == 0 {
        return Ok(ResChatHistoryClear {
            msgs_deleted: 0,
            chats_affected: 0,
        });
    }

    sqlx::query(
        r#"
        WITH affected AS (
          SELECT DISTINCT m.chat_id
          FROM ai.chat_msg m
          JOIN ai.chat c ON c.id = m.chat_id
          JOIN ai.chat_member mem ON mem.chat_id = c.id AND mem.member_iid = $1
          WHERE m.deleted_ts IS NULL
            AND c.kind = 'prompt'
            AND c.deleted_ts IS NULL
            AND mem.deleted_ts IS NULL
        ),
        cleared AS (
          UPDATE ai.chat_msg m
          SET deleted_ts = NOW(), updated_ts = NOW()
          FROM ai.chat c
          JOIN ai.chat_member mem ON mem.chat_id = c.id AND mem.member_iid = $1
          WHERE m.chat_id = c.id
            AND m.deleted_ts IS NULL
            AND c.kind = 'prompt'
            AND c.deleted_ts IS NULL
            AND mem.deleted_ts IS NULL
          RETURNING m.id
        )
        UPDATE ai.chat_member mem
        SET last_msg_preview = '',
            last_msg_ts = NULL,
            unread_count = 0,
            last_msg_status = 'done',
            updated_ts = NOW()
        FROM affected
        WHERE mem.chat_id = affected.chat_id
          AND mem.member_iid = $1
          AND mem.deleted_ts IS NULL
        "#,
    )
    .bind(member_iid)
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        UPDATE ai.chat c
        SET last_msg_preview = '',
            last_msg_ts = NULL,
            updated_ts = NOW()
        FROM ai.chat_member mem
        WHERE c.id = mem.chat_id
          AND mem.member_iid = $1
          AND c.kind = 'prompt'
          AND c.deleted_ts IS NULL
          AND mem.deleted_ts IS NULL
        "#,
    )
    .bind(member_iid)
    .execute(pool)
    .await?;

    Ok(ResChatHistoryClear {
        msgs_deleted: msg_count as i32,
        chats_affected: chat_count as i32,
    })
}
