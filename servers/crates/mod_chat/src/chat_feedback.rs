use anyhow::{anyhow, Result};
use chrono::{DateTime, Utc};
use c35_proto::{
    ChatFeedbackAuthorRole, ChatFeedbackPost, ChatFeedbackReason, ChatFeedbackVote, ChatMsgFeedback,
    ReqChatFeedbackReasonList, ReqChatMsgFeedbackList, ReqChatMsgFeedbackPut, ResChatFeedbackReasonList,
    ResChatMsgFeedbackList, ResChatMsgFeedbackPut,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::inbox::ts_ms;

pub fn feedback_thanks(vote: &str, locale: &str) -> &'static str {
    let id = locale.trim().to_lowercase().starts_with("id");
    match (vote, id) {
        ("bad", true) => "Terima kasih. Catatanmu kami simpan untuk jawaban berikutnya.",
        ("bad", false) => "Thanks. We'll use this note on the next answer.",
        ("good", true) => "Terima kasih. Senang jawaban ini membantu.",
        ("good", false) => "Thanks. Glad this answer helped.",
        _ => "",
    }
}

pub fn feedback_comment_ok(slug: &str, comment: &str) -> bool {
    slug != "other" || !comment.trim().is_empty()
}

fn locale_is_id(locale: &str) -> bool {
    locale.trim().to_lowercase().starts_with("id")
}

fn vote_name(vote: i32) -> Option<&'static str> {
    match ChatFeedbackVote::try_from(vote).ok() {
        Some(ChatFeedbackVote::Good) => Some("good"),
        Some(ChatFeedbackVote::Bad) => Some("bad"),
        _ => None,
    }
}

fn vote_code(vote: &str) -> i32 {
    match vote {
        "good" => ChatFeedbackVote::Good as i32,
        "bad" => ChatFeedbackVote::Bad as i32,
        _ => ChatFeedbackVote::Unspecified as i32,
    }
}

fn author_role_code(role: &str) -> i32 {
    match role {
        "system" => ChatFeedbackAuthorRole::System as i32,
        "user" => ChatFeedbackAuthorRole::User as i32,
        "staff" => ChatFeedbackAuthorRole::Staff as i32,
        _ => ChatFeedbackAuthorRole::Unspecified as i32,
    }
}

pub async fn chat_feedback_reason_list(pool: &PgPool, req: ReqChatFeedbackReasonList) -> Result<ResChatFeedbackReasonList> {
    let vote = vote_name(req.vote);
    let rows = sqlx::query(
        r#"
        SELECT id, slug, vote, label_en, label_id, sort
        FROM ai.chat_feedback_reason
        WHERE active AND ($1::text IS NULL OR vote = $1)
        ORDER BY sort, id
        "#,
    )
    .bind(vote)
    .fetch_all(pool)
    .await?;
    let id_locale = locale_is_id(&req.locale);
    let reasons = rows
        .into_iter()
        .map(|r| {
            let label_en: String = r.get("label_en");
            let label_id: String = r.get("label_id");
            let id: i16 = r.get("id");
            ChatFeedbackReason {
                id: i32::from(id),
                slug: r.get("slug"),
                vote: vote_code(&r.get::<String, _>("vote")),
                label: if id_locale { label_id } else { label_en },
                sort: r.get("sort"),
            }
        })
        .collect();
    Ok(ResChatFeedbackReasonList { reasons })
}

struct MsgAnchor {
    req_id: String,
    owner_iid: i64,
}

async fn assistant_msg(pool: &PgPool, rater_iid: i64, msg_id: i64, chat_id: i64) -> Result<MsgAnchor> {
    let row = sqlx::query(
        r#"
        SELECT m.req_id, c.owner_iid
        FROM ai.chat_msg m
        JOIN ai.chat c ON c.id = m.chat_id
        JOIN ai.chat_member mem ON mem.chat_id = c.id AND mem.member_iid = $3 AND mem.deleted_ts IS NULL
        WHERE m.id = $1 AND m.chat_id = $2 AND m.role = 'assistant' AND m.deleted_ts IS NULL
        "#,
    )
    .bind(msg_id)
    .bind(chat_id)
    .bind(rater_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("message not found"))?;
    Ok(MsgAnchor {
        req_id: row.get("req_id"),
        owner_iid: row.get("owner_iid"),
    })
}

async fn member_chat(pool: &PgPool, rater_iid: i64, chat_id: i64) -> Result<()> {
    let ok = sqlx::query_scalar::<_, i32>(
        r#"
        SELECT 1
        FROM ai.chat c
        JOIN ai.chat_member mem ON mem.chat_id = c.id AND mem.member_iid = $1 AND mem.deleted_ts IS NULL
        WHERE c.id = $2
        "#,
    )
    .bind(rater_iid)
    .bind(chat_id)
    .fetch_optional(pool)
    .await?;
    ok.map(|_| ()).ok_or_else(|| anyhow!("chat not found"))
}

pub async fn chat_msg_feedback_put(pool: &PgPool, rater_iid: i64, req: ReqChatMsgFeedbackPut) -> Result<ResChatMsgFeedbackPut> {
    if req.msg_id == 0 {
        return Err(anyhow!("msg_id required"));
    }
    if req.chat_id == 0 {
        return Err(anyhow!("chat_id required"));
    }
    let anchor = assistant_msg(pool, rater_iid, req.msg_id, req.chat_id).await?;
    let Some(vote) = vote_name(req.vote) else {
        if ChatFeedbackVote::try_from(req.vote).ok() != Some(ChatFeedbackVote::Unspecified) {
            return Err(anyhow!("vote required"));
        }
        clear_feedback(pool, req.msg_id, rater_iid).await?;
        return Ok(ResChatMsgFeedbackPut { feedback: None });
    };

    let reason_id = i16::try_from(req.reason_id).map_err(|_| anyhow!("reason not found"))?;
    let reason = sqlx::query(
        r#"
        SELECT slug, vote FROM ai.chat_feedback_reason WHERE id = $1 AND active
        "#,
    )
    .bind(reason_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("reason not found"))?;
    let slug: String = reason.get("slug");
    let reason_vote: String = reason.get("vote");
    if reason_vote != vote {
        return Err(anyhow!("reason vote mismatch"));
    }
    let comment = req.comment.trim().to_string();
    if !feedback_comment_ok(&slug, &comment) {
        return Err(anyhow!("comment required"));
    }

    let mut tx = pool.begin().await?;
    let existing: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.chat_msg_feedback WHERE msg_id = $1 AND rater_iid = $2
        "#,
    )
    .bind(req.msg_id)
    .bind(rater_iid)
    .fetch_optional(&mut *tx)
    .await?;
    let feedback_id = if let Some(id) = existing {
        sqlx::query(
            r#"
            UPDATE ai.chat_msg_feedback
            SET vote = $2, reason_id = $3, comment = $4, updated_ts = NOW(), deleted_ts = NULL
            WHERE id = $1
            "#,
        )
        .bind(id)
        .bind(vote)
        .bind(reason_id)
        .bind(&comment)
        .execute(&mut *tx)
        .await?;
        id
    } else {
        let id = snowflake_id();
        sqlx::query(
            r#"
            INSERT INTO ai.chat_msg_feedback (
                id, msg_id, chat_id, owner_iid, rater_iid, req_id, vote, reason_id, comment, created_ts, updated_ts
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
            "#,
        )
        .bind(id)
        .bind(req.msg_id)
        .bind(req.chat_id)
        .bind(anchor.owner_iid)
        .bind(rater_iid)
        .bind(&anchor.req_id)
        .bind(vote)
        .bind(reason_id)
        .bind(&comment)
        .execute(&mut *tx)
        .await?;
        id
    };

    let thanks = feedback_thanks(vote, &req.locale);
    let live_post: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.chat_feedback_post
        WHERE feedback_id = $1 AND author_role = 'system' AND deleted_ts IS NULL
        "#,
    )
    .bind(feedback_id)
    .fetch_optional(&mut *tx)
    .await?;
    if let Some(post_id) = live_post {
        sqlx::query("UPDATE ai.chat_feedback_post SET text = $2 WHERE id = $1")
            .bind(post_id)
            .bind(thanks)
            .execute(&mut *tx)
            .await?;
    } else {
        sqlx::query(
            r#"
            INSERT INTO ai.chat_feedback_post (id, feedback_id, author_iid, author_role, text, created_ts)
            VALUES ($1, $2, NULL, 'system', $3, NOW())
            "#,
        )
        .bind(snowflake_id())
        .bind(feedback_id)
        .bind(thanks)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;

    let feedback = feedback_load(pool, rater_iid, req.chat_id, Some(feedback_id), &req.locale).await?;
    Ok(ResChatMsgFeedbackPut {
        feedback: feedback.into_iter().next(),
    })
}

async fn clear_feedback(pool: &PgPool, msg_id: i64, rater_iid: i64) -> Result<()> {
    let mut tx = pool.begin().await?;
    let id: Option<i64> = sqlx::query_scalar(
        r#"
        UPDATE ai.chat_msg_feedback
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE msg_id = $1 AND rater_iid = $2 AND deleted_ts IS NULL
        RETURNING id
        "#,
    )
    .bind(msg_id)
    .bind(rater_iid)
    .fetch_optional(&mut *tx)
    .await?;
    if let Some(id) = id {
        sqlx::query(
            r#"
            UPDATE ai.chat_feedback_post SET deleted_ts = NOW()
            WHERE feedback_id = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(id)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}

pub async fn chat_msg_feedback_list(pool: &PgPool, rater_iid: i64, req: ReqChatMsgFeedbackList) -> Result<ResChatMsgFeedbackList> {
    if req.chat_id == 0 {
        return Err(anyhow!("chat_id required"));
    }
    member_chat(pool, rater_iid, req.chat_id).await?;
    let feedback = feedback_load(pool, rater_iid, req.chat_id, None, &req.locale).await?;
    Ok(ResChatMsgFeedbackList { feedback })
}

async fn feedback_load(
    pool: &PgPool,
    rater_iid: i64,
    chat_id: i64,
    only_id: Option<i64>,
    locale: &str,
) -> Result<Vec<ChatMsgFeedback>> {
    let rows = sqlx::query(
        r#"
        SELECT f.id, f.msg_id, f.chat_id, f.vote, f.reason_id, f.comment, f.updated_ts,
               r.slug, r.label_en, r.label_id
        FROM ai.chat_msg_feedback f
        JOIN ai.chat_feedback_reason r ON r.id = f.reason_id
        WHERE f.chat_id = $1 AND f.rater_iid = $2 AND f.deleted_ts IS NULL
          AND ($3::bigint IS NULL OR f.id = $3)
        ORDER BY f.msg_id, f.id
        "#,
    )
    .bind(chat_id)
    .bind(rater_iid)
    .bind(only_id)
    .fetch_all(pool)
    .await?;
    if rows.is_empty() {
        return Ok(Vec::new());
    }
    let ids: Vec<i64> = rows.iter().map(|r| r.get("id")).collect();
    let posts = sqlx::query(
        r#"
        SELECT id, feedback_id, author_iid, author_role, text, created_ts
        FROM ai.chat_feedback_post
        WHERE feedback_id = ANY($1) AND deleted_ts IS NULL
        ORDER BY created_ts, id
        "#,
    )
    .bind(&ids)
    .fetch_all(pool)
    .await?;
    let id_locale = locale_is_id(locale);
    let mut out = Vec::with_capacity(rows.len());
    for row in rows {
        let id: i64 = row.get("id");
        let label_en: String = row.get("label_en");
        let label_id: String = row.get("label_id");
        let reason_id: i16 = row.get("reason_id");
        let updated: Option<DateTime<Utc>> = row.get("updated_ts");
        let mut msg_posts = Vec::new();
        for post in &posts {
            let feedback_id: i64 = post.get("feedback_id");
            if feedback_id != id {
                continue;
            }
            let created: Option<DateTime<Utc>> = post.get("created_ts");
            let author: Option<i64> = post.get("author_iid");
            msg_posts.push(ChatFeedbackPost {
                id: post.get("id"),
                feedback_id,
                author_iid: author.unwrap_or(0),
                author_role: author_role_code(&post.get::<String, _>("author_role")),
                text: post.get("text"),
                created_ts_ms: ts_ms(created),
            });
        }
        out.push(ChatMsgFeedback {
            id,
            msg_id: row.get("msg_id"),
            chat_id: row.get("chat_id"),
            vote: vote_code(&row.get::<String, _>("vote")),
            reason_id: i32::from(reason_id),
            reason_slug: row.get("slug"),
            reason_label: if id_locale { label_id } else { label_en },
            comment: row.get("comment"),
            updated_ts_ms: ts_ms(updated),
            posts: msg_posts,
        });
    }
    Ok(out)
}
