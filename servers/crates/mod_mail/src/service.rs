use chrono::{DateTime, Utc};
use c35_proto::{
    MailAccount, MailAttachment, MailDirection, MailGroup, MailMessage, MailStatus, ResMailAccountGet,
    ResMailGet, ResMailList, ResMailSend,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::access;
use crate::attachments::{attachments_to_json, inbound_from_base64, validate_and_normalize, MailCas};
use crate::client;
use crate::inbound::MailInboundPayload;
use crate::mailbox::{self, enforce_subscriber_limit, resolve_mailbox};
use crate::outbound::{load_outbound_attachments, send_mail, send_via_worker, SmtpConfig, WorkerConfig};

pub struct BroadcastResult {
    pub sent_count: i32,
    pub failures: Vec<(String, String)>,
}

const LIST_SEL: &str = "SELECT id, direction, from_addr, to_addr, subject,
 LEFT(COALESCE(NULLIF(TRIM(body_text), ''), body_html), 240) AS body_text, '' AS body_html,
 status, COALESCE(attachments_json::text,'[]') AS attachments_json, COALESCE(error,'') AS error,
 COALESCE(is_archived,false) AS is_archived, read_ts, created_ts, sent_ts";

pub struct MailService {
    pub pool: PgPool,
    pub cas: Option<MailCas>,
}

impl MailService {
    pub fn new(pool: PgPool, cas: Option<MailCas>) -> Self {
        Self { pool, cas }
    }

    pub async fn account_get(&self, caller: i64) -> Result<ResMailAccountGet, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        mailbox::ensure_personal_on_first_access(&self.pool, caller).await?;
        let row = sqlx::query(
            "SELECT m.id AS mailbox_id, m.address, m.created_ts FROM mail.mailbox m
             WHERE m.kind = 'personal' AND m.owner_iid = $1 AND m.deleted_ts IS NULL",
        )
        .bind(caller)
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "personal mailbox not found".to_string())?;
        let created: DateTime<Utc> = row.get("created_ts");
        Ok(ResMailAccountGet {
            account: Some(MailAccount {
                owner_iid: caller,
                address: row.get("address"),
                created_ts_ms: created.timestamp_millis(),
                mailbox_id: row.get("mailbox_id"),
            }),
        })
    }

    pub async fn list(
        &self,
        caller: i64,
        mailbox_id: i64,
        direction: MailDirection,
        limit: i32,
        before: i64,
        is_archived: bool,
    ) -> Result<ResMailList, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        mailbox::ensure_personal_on_first_access(&self.pool, caller).await?;
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        let dir = match direction { MailDirection::In => "in", MailDirection::Out => "out", _ => return Err("direction required".into()) };
        let limit = limit.clamp(1, 200);
        let arch = if is_archived { " AND is_archived = true" } else { " AND NOT is_archived" };
        let rows = if before > 0 {
            sqlx::query(&format!("{LIST_SEL} FROM mail.message WHERE mailbox_id=$1 AND direction=$2{arch} AND id < $3 ORDER BY id DESC LIMIT $4"))
                .bind(mb.mailbox_id).bind(dir).bind(before).bind(limit)
                .fetch_all(&self.pool).await
        } else {
            sqlx::query(&format!("{LIST_SEL} FROM mail.message WHERE mailbox_id=$1 AND direction=$2{arch} ORDER BY id DESC LIMIT $3"))
                .bind(mb.mailbox_id).bind(dir).bind(limit)
                .fetch_all(&self.pool).await
        }
        .map_err(|e| e.to_string())?;
        Ok(ResMailList { messages: rows.iter().map(|r| to_msg(r, false)).collect() })
    }

    pub async fn inbox_count_mailbox(&self, caller: i64, mailbox_id: i64) -> Result<i32, String> {
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        mailbox::mailbox_unread_count(&self.pool, mb.mailbox_id).await
    }

    pub async fn mark_read(&self, caller: i64, mailbox_id: i64, message_ids: &[i64], read: bool) -> Result<(i32, i32), String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        if message_ids.is_empty() {
            let unread = self.inbox_count_mailbox(caller, mb.mailbox_id).await?;
            return Ok((0, unread));
        }
        let res = if read {
            sqlx::query("UPDATE mail.message SET read_ts = NOW() WHERE mailbox_id = $1 AND id = ANY($2) AND direction = 'in' AND read_ts IS NULL")
                .bind(mb.mailbox_id).bind(message_ids).execute(&self.pool).await
        } else {
            sqlx::query("UPDATE mail.message SET read_ts = NULL WHERE mailbox_id = $1 AND id = ANY($2) AND direction = 'in' AND read_ts IS NOT NULL")
                .bind(mb.mailbox_id).bind(message_ids).execute(&self.pool).await
        }
        .map_err(|e| e.to_string())?;
        let unread = self.inbox_count_mailbox(caller, mb.mailbox_id).await?;
        Ok((res.rows_affected() as i32, unread))
    }

    pub async fn archive_messages(&self, caller: i64, mailbox_id: i64, message_ids: &[i64], archive: bool) -> Result<i32, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        if message_ids.is_empty() { return Ok(0); }
        let res = sqlx::query("UPDATE mail.message SET is_archived = $1 WHERE mailbox_id = $2 AND id = ANY($3)")
            .bind(archive).bind(mb.mailbox_id).bind(message_ids).execute(&self.pool).await.map_err(|e| e.to_string())?;
        Ok(res.rows_affected() as i32)
    }

    pub async fn group_list(&self, caller: i64, mailbox_id: i64) -> Result<Vec<MailGroup>, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        let rows = sqlx::query(
            "SELECT group_id, name, description, emails_json::text AS emails_json, created_ts, updated_ts
             FROM mail.group WHERE mailbox_id = $1 ORDER BY created_ts DESC",
        )
        .bind(mb.mailbox_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| e.to_string())?;
        Ok(rows.into_iter().map(|r| {
            let emails_json: String = r.get("emails_json");
            let emails: Vec<String> = serde_json::from_str(&emails_json).unwrap_or_default();
            let created: DateTime<Utc> = r.get("created_ts");
            let updated: DateTime<Utc> = r.get("updated_ts");
            MailGroup {
                group_id: r.get("group_id"),
                name: r.get("name"),
                description: r.get("description"),
                emails,
                created_ts_ms: created.timestamp_millis(),
                updated_ts_ms: updated.timestamp_millis(),
            }
        }).collect())
    }

    pub async fn group_upsert(&self, caller: i64, mailbox_id: i64, group: MailGroup) -> Result<MailGroup, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, true).await?;
        let group_id = if group.group_id.trim().is_empty() {
            format!("group_{}", snowflake_id())
        } else {
            group.group_id.trim().to_string()
        };
        let emails = enforce_subscriber_limit(mb.subscriber_limit, &group.emails)?;
        let emails_json = serde_json::to_string(&emails).unwrap_or_else(|_| "[]".to_string());
        sqlx::query(
            "INSERT INTO mail.group (group_id, owner_iid, mailbox_id, name, description, emails_json, updated_ts)
             VALUES ($1, $2, $3, $4, $5, $6::jsonb, NOW())
             ON CONFLICT (group_id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description,
               emails_json = EXCLUDED.emails_json, mailbox_id = EXCLUDED.mailbox_id, updated_ts = NOW()",
        )
        .bind(&group_id)
        .bind(mb.owner_iid)
        .bind(mb.mailbox_id)
        .bind(group.name.trim())
        .bind(group.description.trim())
        .bind(&emails_json)
        .execute(&self.pool)
        .await
        .map_err(|e| e.to_string())?;
        Ok(MailGroup {
            group_id,
            name: group.name,
            description: group.description,
            emails,
            created_ts_ms: group.created_ts_ms,
            updated_ts_ms: Utc::now().timestamp_millis(),
        })
    }

    pub async fn group_delete(&self, caller: i64, mailbox_id: i64, group_id: &str) -> Result<bool, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, true).await?;
        let res = sqlx::query("DELETE FROM mail.group WHERE mailbox_id = $1 AND group_id = $2")
            .bind(mb.mailbox_id).bind(group_id).execute(&self.pool).await.map_err(|e| e.to_string())?;
        Ok(res.rows_affected() > 0)
    }

    pub async fn broadcast_detailed(
        &self,
        caller: i64,
        mailbox_id: i64,
        group_id: &str,
        custom_emails: &[String],
        subject: &str,
        body_text: &str,
        body_html: &str,
        attachments: &[MailAttachment],
    ) -> Result<BroadcastResult, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, true).await?;
        let mut recipients: Vec<String> = custom_emails.to_vec();
        if !group_id.is_empty() {
            if let Some(row) = sqlx::query("SELECT emails_json::text AS emails_json FROM mail.group WHERE mailbox_id = $1 AND group_id = $2")
                .bind(mb.mailbox_id).bind(group_id).fetch_optional(&self.pool).await.map_err(|e| e.to_string())? {
                let emails_json: String = row.get("emails_json");
                recipients.extend(serde_json::from_str::<Vec<String>>(&emails_json).unwrap_or_default());
            }
        }
        recipients.retain(|e| !e.trim().is_empty() && e.contains('@'));
        recipients.sort();
        recipients.dedup();
        let _ = enforce_subscriber_limit(mb.subscriber_limit, &recipients)?;
        let mut sent_count = 0;
        let mut failures = Vec::new();
        for to in recipients {
            match self.send(caller, mb.mailbox_id, &to, subject, body_text, body_html, attachments).await {
                Ok(_) => sent_count += 1,
                Err(e) => failures.push((to, e)),
            }
        }
        Ok(BroadcastResult { sent_count, failures })
    }

    pub async fn get(&self, caller: i64, mailbox_id: i64, message_id: i64) -> Result<ResMailGet, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, false).await?;
        let row = sqlx::query(
            "SELECT id, direction, from_addr, to_addr, subject, body_text, body_html, status,
             COALESCE(attachments_json::text,'[]') AS attachments_json, COALESCE(error,'') AS error,
             COALESCE(is_archived,false) AS is_archived, read_ts, created_ts, sent_ts
             FROM mail.message WHERE mailbox_id=$1 AND id=$2",
        )
            .bind(mb.mailbox_id).bind(message_id).fetch_optional(&self.pool).await.map_err(|e| e.to_string())?
            .ok_or_else(|| "mail not found".to_string())?;
        if row.get::<String,_>("direction") == "in" && row.try_get::<Option<DateTime<Utc>>,_>("read_ts").unwrap_or(None).is_none() {
            sqlx::query("UPDATE mail.message SET read_ts=NOW() WHERE mailbox_id=$1 AND id=$2 AND read_ts IS NULL")
                .bind(mb.mailbox_id).bind(message_id).execute(&self.pool).await.map_err(|e| e.to_string())?;
        }
        Ok(ResMailGet { message: Some(to_msg(&row, true)) })
    }

    pub async fn send(&self, caller: i64, mailbox_id: i64, to: &str, subject: &str, text: &str, html: &str, atts: &[MailAttachment]) -> Result<ResMailSend, String> {
        if !access::mail_access(&self.pool, caller).await? { return Err("forbidden".into()); }
        let mb = resolve_mailbox(&self.pool, caller, mailbox_id, true).await?;
        let recipients = parse_addrs(to)?;
        let metas = if atts.is_empty() { Vec::new() } else { validate_and_normalize(self.cas.as_ref().ok_or("file store not configured")?, atts).await? };
        let id = snowflake_id();
        sqlx::query("INSERT INTO mail.message (id,mailbox_id,direction,from_addr,to_addr,subject,body_text,body_html,status,attachments_json,read_ts) VALUES ($1,$2,'out',$3,$4,$5,$6,$7,'queued',$8::jsonb,NOW())")
            .bind(id).bind(mb.mailbox_id).bind(&mb.address).bind(recipients.join(", ")).bind(subject).bind(text).bind(html).bind(attachments_to_json(&metas))
            .execute(&self.pool).await.map_err(|e| e.to_string())?;
        let outbound = load_outbound_attachments(self.cas.as_ref(), &metas).await?;
        let (status, err, sent): (String, String, Option<DateTime<Utc>>) = match SmtpConfig::from_env() {
            Some(cfg) => match send_mail(&cfg, &mb.address, &recipients, subject, text, html, &outbound).await {
                Ok(()) => ("sent".into(), String::new(), Some(Utc::now())),
                Err(e) => ("failed".into(), e, None),
            },
            None => match WorkerConfig::from_env() {
                Some(cfg) => match send_via_worker(&cfg, &mb.address, &recipients, subject, text, html, &outbound).await {
                    Ok(()) => ("sent".into(), String::new(), Some(Utc::now())),
                    Err(e) => ("failed".into(), e, None),
                },
                None => ("failed".into(), "outbound not configured".into(), None),
            },
        };
        sqlx::query("UPDATE mail.message SET status=$1, error=$2, sent_ts=$3 WHERE id=$4").bind(&status).bind(&err).bind(sent).bind(id).execute(&self.pool).await.map_err(|e| e.to_string())?;
        let row = sqlx::query(
            "SELECT id, direction, from_addr, to_addr, subject, body_text, body_html, status,
             COALESCE(attachments_json::text,'[]') AS attachments_json, COALESCE(error,'') AS error,
             COALESCE(is_archived,false) AS is_archived, read_ts, created_ts, sent_ts
             FROM mail.message WHERE id=$1",
        ).bind(id).fetch_one(&self.pool).await.map_err(|e| e.to_string())?;
        Ok(ResMailSend { message: Some(to_msg(&row, false)) })
    }

    pub async fn inbound(&self, payload: MailInboundPayload) -> Result<i64, String> {
        let to = norm(payload.to.unwrap_or_default());
        if to.is_empty() { return Err("missing to".into()); }
        let mailbox_id = mailbox::find_mailbox_by_address(&self.pool, &to).await?.ok_or_else(|| format!("unknown recipient: {to}"))?;
        if let Some(ext) = payload.external_id.as_deref().map(str::trim).filter(|s| !s.is_empty()) {
            if let Some(id) = sqlx::query_scalar::<_, i64>("SELECT id FROM mail.message WHERE external_id=$1").bind(ext).fetch_optional(&self.pool).await.map_err(|e| e.to_string())? { return Ok(id); }
        }
        let metas = inbound_from_base64(self.cas.as_ref(), &payload.attachments.unwrap_or_default()).await?;
        let id = snowflake_id();
        sqlx::query("INSERT INTO mail.message (id,mailbox_id,direction,from_addr,to_addr,subject,body_text,body_html,status,attachments_json,external_id) VALUES ($1,$2,'in',$3,$4,$5,$6,$7,'received',$8::jsonb,$9)")
            .bind(id).bind(mailbox_id).bind(payload.from.unwrap_or_default()).bind(&to).bind(payload.subject.unwrap_or_default())
            .bind(payload.text.unwrap_or_default()).bind(payload.html.unwrap_or_default()).bind(attachments_to_json(&metas)).bind(payload.external_id.as_deref())
            .execute(&self.pool).await.map_err(|e| e.to_string())?;
        let unread = mailbox::mailbox_unread_count(&self.pool, mailbox_id).await.unwrap_or(0);
        for iid in sqlx::query_scalar::<_, i64>("SELECT member_iid FROM mail.mailbox_member WHERE mailbox_id=$1").bind(mailbox_id).fetch_all(&self.pool).await.map_err(|e| e.to_string())? {
            client::mail_user_notify_json(iid, serde_json::json!({"event":"mail.message.received","message_id":id,"mailbox_id":mailbox_id,"inbox_count":unread}));
        }
        Ok(id)
    }
}

fn norm(s: String) -> String {
    let t = if let (Some(a), Some(b)) = (s.find('<'), s.find('>')) { s[a+1..b].trim() } else { s.trim() };
    t.to_lowercase()
}

fn parse_addrs(raw: &str) -> Result<Vec<String>, String> {
    let mut out: Vec<String> = raw.split([',',';']).filter_map(|p| {
        let a = norm(p.to_string());
        if a.is_empty() || !a.contains('@') { None } else { Some(a) }
    }).collect();
    if out.is_empty() { return Err("to_addr required".into()); }
    out.sort(); out.dedup(); Ok(out)
}

fn to_msg(row: &sqlx::postgres::PgRow, force_read: bool) -> MailMessage {
    let dir: String = row.get("direction");
    let read = row.try_get::<Option<DateTime<Utc>>,_>("read_ts").unwrap_or(None).is_some();
    let created: DateTime<Utc> = row.get("created_ts");
    let sent: Option<DateTime<Utc>> = row.try_get("sent_ts").unwrap_or(None);
    MailMessage {
        message_id: row.get("id"),
        direction: if dir == "in" { MailDirection::In as i32 } else { MailDirection::Out as i32 },
        from_addr: row.get("from_addr"), to_addr: row.get("to_addr"), subject: row.get("subject"),
        body_text: row.get("body_text"), body_html: row.try_get("body_html").unwrap_or_default(),
        status: match row.get::<String,_>("status").as_str() { "received" => MailStatus::Received as i32, "queued" => MailStatus::Queued as i32, "sent" => MailStatus::Sent as i32, "failed" => MailStatus::Failed as i32, _ => MailStatus::Unspecified as i32 },
        attachments_json: row.get("attachments_json"), error: row.get("error"),
        created_ts_ms: created.timestamp_millis(), sent_ts_ms: sent.map(|t| t.timestamp_millis()).unwrap_or(0),
        is_archived: row.try_get("is_archived").unwrap_or(false), is_read: force_read || read || dir == "out",
    }
}
