use c35_proto::{MailMailbox, MailMailboxAccess, MailMailboxKind};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::access;
use crate::domain;

pub const DEFAULT_SUBSCRIBER_LIMIT: i32 = 1000;

pub struct MailboxCtx {
    pub mailbox_id: i64,
    pub address: String,
    pub subscriber_limit: i32,
}

pub async fn ensure_personal_mailbox(pool: &PgPool, owner_iid: i64, address: &str) -> Result<i64, String> {
    if let Some(id) = sqlx::query_scalar(
        "SELECT id FROM mail.mailbox WHERE kind = 'personal' AND owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(owner_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())? {
        return Ok(id);
    }
    let mailbox_id = snowflake_id();
    sqlx::query(
        "INSERT INTO mail.mailbox (id, address, kind, owner_iid, label, subscriber_limit) VALUES ($1,$2,'personal',$3,'Personal',$4)",
    )
    .bind(mailbox_id)
    .bind(address.trim())
    .bind(owner_iid)
    .bind(DEFAULT_SUBSCRIBER_LIMIT)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query(
        "INSERT INTO mail.mailbox_member (mailbox_id, member_iid, access) VALUES ($1,$2,'write') ON CONFLICT DO NOTHING",
    )
    .bind(mailbox_id)
    .bind(owner_iid)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(mailbox_id)
}

pub async fn find_mailbox_by_address(pool: &PgPool, address: &str) -> Result<Option<i64>, String> {
    sqlx::query_scalar("SELECT id FROM mail.mailbox WHERE lower(address) = $1 AND deleted_ts IS NULL")
        .bind(address.trim().to_lowercase())
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())
}

pub async fn resolve_mailbox(pool: &PgPool, caller_iid: i64, mailbox_id: i64, need_write: bool) -> Result<MailboxCtx, String> {
    let mailbox_id = if mailbox_id > 0 {
        mailbox_id
    } else {
        let alien_id: String = sqlx::query_scalar("SELECT alien_id FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
            .bind(caller_iid)
            .fetch_optional(pool)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "alien_id required for mail".to_string())?;
        let host = domain::default_hostname(pool).await;
        ensure_personal_mailbox(pool, caller_iid, &format!("{}@{}", alien_id.trim(), host)).await?
    };
    let row = sqlx::query(
        "SELECT m.id, m.address, m.subscriber_limit, mm.access FROM mail.mailbox m
         JOIN mail.mailbox_member mm ON mm.mailbox_id = m.id AND mm.member_iid = $2
         WHERE m.id = $1 AND m.deleted_ts IS NULL",
    )
    .bind(mailbox_id)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "mailbox not found or forbidden".to_string())?;
    if need_write && row.get::<String, _>("access") != "write" {
        return Err("write access required".into());
    }
    Ok(MailboxCtx {
        mailbox_id: row.get("id"),
        address: row.get("address"),
        subscriber_limit: row.get::<i32, _>("subscriber_limit").max(1),
    })
}

pub async fn mailbox_unread_count(pool: &PgPool, mailbox_id: i64) -> Result<i32, String> {
    sqlx::query_scalar(
        "SELECT COUNT(*)::int FROM mail.message WHERE mailbox_id = $1 AND direction = 'in' AND read_ts IS NULL AND NOT is_archived",
    )
    .bind(mailbox_id)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())
}

pub async fn list_for_user(pool: &PgPool, caller_iid: i64) -> Result<Vec<MailMailbox>, String> {
    if !access::mail_access(pool, caller_iid).await? {
        return Err("forbidden".into());
    }
    let rows = sqlx::query(
        "SELECT m.id, m.address, m.kind, m.site_iid, m.label, m.subscriber_limit, mm.access AS member_access, si.name AS site_name
         FROM mail.mailbox m JOIN mail.mailbox_member mm ON mm.mailbox_id = m.id AND mm.member_iid = $1
         LEFT JOIN ai.identity si ON si.id = m.site_iid WHERE m.deleted_ts IS NULL ORDER BY m.address",
    )
    .bind(caller_iid)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    for row in rows {
        let id: i64 = row.get("id");
        let kind = match row.get::<String, _>("kind").as_str() {
            "personal" => MailMailboxKind::Personal,
            "site" => MailMailboxKind::Site,
            _ => MailMailboxKind::Unspecified,
        };
        let access = match row.get::<String, _>("member_access").as_str() {
            "write" => MailMailboxAccess::Write,
            "read" => MailMailboxAccess::Read,
            _ => MailMailboxAccess::Unspecified,
        };
        let limit: i32 = row.get("subscriber_limit");
        out.push(MailMailbox {
            mailbox_id: id,
            address: row.get("address"),
            kind: kind as i32,
            site_iid: row.try_get("site_iid").unwrap_or(0),
            site_name: row.try_get("site_name").unwrap_or_default(),
            label: row.get("label"),
            subscriber_limit: if limit > 0 { limit } else { DEFAULT_SUBSCRIBER_LIMIT },
            my_access: access as i32,
            unread_count: mailbox_unread_count(pool, id).await.unwrap_or(0),
            members: Vec::new(),
        });
    }
    Ok(out)
}

pub async fn ensure_personal_on_first_access(pool: &PgPool, caller_iid: i64) -> Result<(), String> {
    if !access::mail_access(pool, caller_iid).await? {
        return Err("forbidden".into());
    }
    let alien_id: String = sqlx::query_scalar("SELECT alien_id FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(caller_iid)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "alien_id required for mail".to_string())?;
    let host = domain::default_hostname(pool).await;
    ensure_personal_mailbox(pool, caller_iid, &format!("{}@{}", alien_id.trim(), host)).await?;
    Ok(())
}
