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
    pub owner_iid: i64,
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
        "SELECT m.id, m.address, m.subscriber_limit, m.owner_iid, mm.access FROM mail.mailbox m
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
    let limit: i32 = row.get("subscriber_limit");
    Ok(MailboxCtx {
        mailbox_id: row.get("id"),
        address: row.get("address"),
        subscriber_limit: if limit > 0 { limit } else { DEFAULT_SUBSCRIBER_LIMIT },
        owner_iid: row.try_get("owner_iid").unwrap_or(caller_iid),
    })
}

pub fn enforce_subscriber_limit(limit: i32, emails: &[String]) -> Result<Vec<String>, String> {
    if emails.len() > limit as usize {
        return Err(format!("subscriber limit exceeded ({}/{})", emails.len(), limit));
    }
    Ok(emails.to_vec())
}

/// Unread inbound messages across every mailbox the user is a member of.
pub async fn inbox_unread_total(pool: &PgPool, member_iid: i64) -> Result<i32, String> {
    sqlx::query_scalar(
        r#"SELECT COUNT(*)::int FROM mail.message msg
           INNER JOIN mail.mailbox_member mm ON mm.mailbox_id = msg.mailbox_id AND mm.member_iid = $1
           INNER JOIN mail.mailbox m ON m.id = msg.mailbox_id AND m.deleted_ts IS NULL
           WHERE msg.direction = 'in' AND msg.read_ts IS NULL AND NOT COALESCE(msg.is_archived, false)"#,
    )
    .bind(member_iid)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())
}

/// Avatar-menu mail badge: total unread + whether mail UI should be offered.
pub async fn nav_mail_snapshot(pool: &PgPool, caller_iid: i64) -> Result<(i32, bool), String> {
    let visible = access::mail_access(pool, caller_iid).await?;
    if !visible {
        return Ok((0, false));
    }
    let unread = inbox_unread_total(pool, caller_iid).await?;
    Ok((unread, true))
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

pub async fn admin_list(pool: &PgPool, viewer_iid: i64) -> Result<Vec<MailMailbox>, String> {
    if !access::is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let rows = sqlx::query(
        "SELECT m.id, m.address, m.kind, m.site_iid, m.label, m.subscriber_limit, si.name AS site_name
         FROM mail.mailbox m
         LEFT JOIN ai.identity si ON si.id = m.site_iid
         WHERE m.deleted_ts IS NULL
         ORDER BY m.kind, m.address",
    )
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    for row in rows {
        let id: i64 = row.get("id");
        let members = load_members(pool, id).await?;
        let unread = mailbox_unread_count(pool, id).await.unwrap_or(0);
        let mb = mailbox_row_to_proto(&row, MailMailboxAccess::Unspecified, unread);
        out.push(MailMailbox { members, ..mb });
    }
    Ok(out)
}

pub async fn admin_create(
    pool: &PgPool,
    viewer_iid: i64,
    kind: MailMailboxKind,
    site_iid: i64,
    address: &str,
    label: &str,
    subscriber_limit: i32,
    members: Vec<c35_proto::MailMailboxMember>,
) -> Result<MailMailbox, String> {
    if !access::is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let kind_str = match kind {
        MailMailboxKind::Personal => "personal",
        MailMailboxKind::Site => "site",
        _ => return Err("invalid mailbox kind".into()),
    };
    let limit = if subscriber_limit > 0 { subscriber_limit } else { DEFAULT_SUBSCRIBER_LIMIT };

    let (final_address, owner_iid, final_site_iid) = match kind {
        MailMailboxKind::Personal => {
            let addr = address.trim();
            if !addr.contains('@') {
                return Err("address required for personal mailbox".into());
            }
            let local = addr.split('@').next().unwrap_or("").trim();
            let oid: i64 = sqlx::query_scalar(
                "SELECT id FROM ai.identity WHERE lower(alien_id) = lower($1) AND deleted_ts IS NULL",
            )
            .bind(local)
            .fetch_optional(pool)
            .await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "user not found for address".to_string())?;
            (addr.to_string(), oid, None)
        }
        MailMailboxKind::Site => {
            if site_iid <= 0 {
                let addr = address.trim();
                if !addr.contains('@') {
                    return Err("email required when no site is selected".into());
                }
                (addr.to_string(), viewer_iid, None)
            } else {
                let site_row = sqlx::query(
                    "SELECT alien_id, owner_iid FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL",
                )
                .bind(site_iid)
                .fetch_optional(pool)
                .await
                .map_err(|e| e.to_string())?
                .ok_or_else(|| "site not found".to_string())?;
                let alien_id: String = site_row.get("alien_id");
                let oid: i64 = site_row.get("owner_iid");
                let host = domain::default_hostname(pool).await;
                let addr = if address.trim().is_empty() {
                    format!("{}@{}", alien_id.trim(), host)
                } else {
                    address.trim().to_string()
                };
                (addr, oid, Some(site_iid))
            }
        }
        _ => return Err("invalid kind".into()),
    };

    let email_domain = domain::parse_email_domain(&final_address).ok_or_else(|| "invalid mailbox address".to_string())?;
    if !domain::domain_allowed(pool, &email_domain).await? {
        return Err(format!("mail domain not allowed: {email_domain}"));
    }

    let mailbox_id = snowflake_id();
    sqlx::query(
        "INSERT INTO mail.mailbox (id, address, kind, owner_iid, site_iid, label, subscriber_limit) VALUES ($1,$2,$3,$4,$5,$6,$7)",
    )
    .bind(mailbox_id)
    .bind(&final_address)
    .bind(kind_str)
    .bind(owner_iid)
    .bind(final_site_iid)
    .bind(label.trim())
    .bind(limit)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let member_rows = if members.is_empty() && kind == MailMailboxKind::Personal {
        vec![c35_proto::MailMailboxMember {
            member_iid: owner_iid,
            access: MailMailboxAccess::Write as i32,
            name: String::new(),
            email: String::new(),
        }]
    } else {
        members
    };
    replace_members(pool, mailbox_id, &member_rows).await?;
    admin_get(pool, viewer_iid, mailbox_id).await
}

pub async fn admin_update(
    pool: &PgPool,
    viewer_iid: i64,
    mailbox_id: i64,
    label: &str,
    subscriber_limit: i32,
    members: Vec<c35_proto::MailMailboxMember>,
) -> Result<MailMailbox, String> {
    if !access::is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    if mailbox_id <= 0 {
        return Err("mailbox_id required".into());
    }
    if subscriber_limit > 0 {
        sqlx::query("UPDATE mail.mailbox SET label = $2, subscriber_limit = $3, updated_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL")
            .bind(mailbox_id)
            .bind(label.trim())
            .bind(subscriber_limit)
            .execute(pool)
            .await
            .map_err(|e| e.to_string())?;
    } else if !label.trim().is_empty() {
        sqlx::query("UPDATE mail.mailbox SET label = $2, updated_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL")
            .bind(mailbox_id)
            .bind(label.trim())
            .execute(pool)
            .await
            .map_err(|e| e.to_string())?;
    }
    if !members.is_empty() {
        replace_members(pool, mailbox_id, &members).await?;
    }
    admin_get(pool, viewer_iid, mailbox_id).await
}

pub async fn admin_delete(pool: &PgPool, viewer_iid: i64, mailbox_id: i64) -> Result<bool, String> {
    if !access::is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let kind: Option<String> = sqlx::query_scalar("SELECT kind FROM mail.mailbox WHERE id = $1 AND deleted_ts IS NULL")
        .bind(mailbox_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
    if kind.as_deref() == Some("personal") {
        return Err("cannot delete personal mailbox".into());
    }
    let res = sqlx::query("UPDATE mail.mailbox SET deleted_ts = NOW() WHERE id = $1 AND deleted_ts IS NULL")
        .bind(mailbox_id)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    Ok(res.rows_affected() > 0)
}

async fn admin_get(pool: &PgPool, viewer_iid: i64, mailbox_id: i64) -> Result<MailMailbox, String> {
    if !access::is_mail_admin(pool, viewer_iid).await? {
        return Err("forbidden".into());
    }
    let row = sqlx::query(
        "SELECT m.id, m.address, m.kind, m.site_iid, m.label, m.subscriber_limit, si.name AS site_name
         FROM mail.mailbox m
         LEFT JOIN ai.identity si ON si.id = m.site_iid
         WHERE m.id = $1 AND m.deleted_ts IS NULL",
    )
    .bind(mailbox_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "mailbox not found".to_string())?;
    let members = load_members(pool, mailbox_id).await?;
    let unread = mailbox_unread_count(pool, mailbox_id).await.unwrap_or(0);
    let mb = mailbox_row_to_proto(&row, MailMailboxAccess::Unspecified, unread);
    Ok(MailMailbox { members, ..mb })
}

async fn replace_members(pool: &PgPool, mailbox_id: i64, members: &[c35_proto::MailMailboxMember]) -> Result<(), String> {
    sqlx::query("DELETE FROM mail.mailbox_member WHERE mailbox_id = $1")
        .bind(mailbox_id)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    for m in members {
        if m.member_iid <= 0 {
            continue;
        }
        let access = match MailMailboxAccess::try_from(m.access).unwrap_or(MailMailboxAccess::Unspecified) {
            MailMailboxAccess::Write => "write",
            MailMailboxAccess::Read => "read",
            _ => "read",
        };
        sqlx::query("INSERT INTO mail.mailbox_member (mailbox_id, member_iid, access) VALUES ($1, $2, $3)")
            .bind(mailbox_id)
            .bind(m.member_iid)
            .bind(access)
            .execute(pool)
            .await
            .map_err(|e| e.to_string())?;
    }
    Ok(())
}

async fn load_members(pool: &PgPool, mailbox_id: i64) -> Result<Vec<c35_proto::MailMailboxMember>, String> {
    let rows = sqlx::query(
        "SELECT mm.member_iid, mm.access,
                COALESCE(NULLIF(TRIM(i.name), ''), '') AS name,
                COALESCE(ie.email, '') AS email
         FROM mail.mailbox_member mm
         JOIN ai.identity i ON i.id = mm.member_iid
         LEFT JOIN LATERAL (
           SELECT p.identifier AS email FROM ai.identity_provider p
           WHERE p.identity_iid = mm.member_iid AND p.kind = 'email' AND btrim(p.identifier) <> '' LIMIT 1
         ) ie ON true
         WHERE mm.mailbox_id = $1
         ORDER BY mm.access DESC, i.name",
    )
    .bind(mailbox_id)
    .fetch_all(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(rows
        .iter()
        .map(|r| c35_proto::MailMailboxMember {
            member_iid: r.get("member_iid"),
            name: r.get("name"),
            email: r.get("email"),
            access: access_to_proto(&r.get::<String, _>("access")) as i32,
        })
        .collect())
}

fn mailbox_row_to_proto(row: &sqlx::postgres::PgRow, my_access: MailMailboxAccess, unread: i32) -> MailMailbox {
    let kind = match row.get::<String, _>("kind").as_str() {
        "personal" => MailMailboxKind::Personal,
        "site" => MailMailboxKind::Site,
        _ => MailMailboxKind::Unspecified,
    };
    let limit: i32 = row.get("subscriber_limit");
    MailMailbox {
        mailbox_id: row.get("id"),
        address: row.get("address"),
        kind: kind as i32,
        site_iid: row.try_get("site_iid").unwrap_or(0),
        site_name: row.try_get("site_name").unwrap_or_default(),
        label: row.get("label"),
        subscriber_limit: if limit > 0 { limit } else { DEFAULT_SUBSCRIBER_LIMIT },
        my_access: my_access as i32,
        unread_count: unread,
        members: Vec::new(),
    }
}

fn access_to_proto(access: &str) -> MailMailboxAccess {
    match access.trim().to_lowercase().as_str() {
        "write" | "edit" => MailMailboxAccess::Write,
        "read" => MailMailboxAccess::Read,
        _ => MailMailboxAccess::Unspecified,
    }
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
