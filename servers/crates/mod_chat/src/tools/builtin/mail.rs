use anyhow::{anyhow, Result};
use c35_mod_file::cas_dir_default;
use c35_mod_mail::{ensure_personal_on_first_access, list_for_user, mail_access, MailCas, MailService};
use c35_proto::{
    MailAttachment, MailDirection, MailMailbox, MailMailboxAccess, MailMailboxKind, MailMessage, MailStatus,
};
use serde_json::{json, Value};

use crate::tool;
use crate::tools::ToolContext;

fn cas_secret_from_env() -> String {
    std::env::var("CAS_HMAC_SECRET").unwrap_or_else(|_| "dev".into())
}

fn mail_svc(ctx: &ToolContext) -> MailService {
    let cas = MailCas {
        pool: ctx.pool.clone(),
        cas_dir: cas_dir_default(),
        cas_secret: cas_secret_from_env(),
    };
    MailService::new(ctx.pool.clone(), Some(cas))
}

fn status_str(s: i32) -> &'static str {
    match s {
        x if x == MailStatus::Received as i32 => "received",
        x if x == MailStatus::Queued as i32 => "queued",
        x if x == MailStatus::Sent as i32 => "sent",
        x if x == MailStatus::Failed as i32 => "failed",
        _ => "unknown",
    }
}

fn dir_str(s: i32) -> &'static str {
    match s {
        x if x == MailDirection::In as i32 => "in",
        x if x == MailDirection::Out as i32 => "out",
        _ => "unknown",
    }
}

fn message_json(m: &MailMessage, full: bool) -> Value {
    let body_text = if full {
        m.body_text.clone()
    } else {
        m.body_text.chars().take(500).collect()
    };
    let body_html = if full && !m.body_html.is_empty() {
        let h = &m.body_html;
        if h.len() > 8192 {
            h.chars().take(8192).collect()
        } else {
            h.clone()
        }
    } else {
        String::new()
    };
    json!({
        "message_id": m.message_id,
        "direction": dir_str(m.direction),
        "from": m.from_addr,
        "to": m.to_addr,
        "subject": m.subject,
        "body_text": body_text,
        "body_html": body_html,
        "status": status_str(m.status),
        "error": m.error,
        "is_read": m.is_read,
        "is_archived": m.is_archived,
        "created_ts_ms": m.created_ts_ms,
        "sent_ts_ms": m.sent_ts_ms,
        "attachments_json": m.attachments_json,
    })
}

fn mailbox_json(mb: &MailMailbox) -> Value {
    let kind = match MailMailboxKind::try_from(mb.kind) {
        Ok(MailMailboxKind::Personal) => "personal",
        Ok(MailMailboxKind::Site) => "site",
        _ => "unknown",
    };
    let access = match MailMailboxAccess::try_from(mb.my_access) {
        Ok(MailMailboxAccess::Write) => "write",
        Ok(MailMailboxAccess::Read) => "read",
        _ => "unknown",
    };
    json!({
        "mailbox_id": mb.mailbox_id,
        "address": mb.address,
        "kind": kind,
        "site_iid": mb.site_iid,
        "site_name": mb.site_name,
        "label": mb.label,
        "my_access": access,
        "unread_count": mb.unread_count,
    })
}

fn parse_direction(args: &Value) -> Result<MailDirection> {
    let raw = args
        .get("direction")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("direction is required (in or out)"))?;
    match raw.to_lowercase().as_str() {
        "in" | "inbound" => Ok(MailDirection::In),
        "out" | "outbound" => Ok(MailDirection::Out),
        _ => Err(anyhow!("direction must be in or out")),
    }
}

fn mailbox_id_arg(args: &Value) -> i64 {
    args.get("mailbox_id").and_then(|v| v.as_i64()).unwrap_or(0)
}

fn parse_attachments(args: &Value) -> Vec<MailAttachment> {
    let arr = args
        .get("attachments")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    arr.iter()
        .filter_map(|a| {
            let path = a.get("path").and_then(|v| v.as_str()).unwrap_or("").trim();
            if path.is_empty() {
                return None;
            }
            Some(MailAttachment {
                path: path.to_string(),
                name: a.get("name").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                mime: a
                    .get("mime")
                    .and_then(|v| v.as_str())
                    .unwrap_or("application/octet-stream")
                    .to_string(),
                size: a.get("size").and_then(|v| v.as_i64()).unwrap_or(0),
            })
        })
        .collect()
}

async fn require_mail(ctx: &ToolContext) -> Result<()> {
    if !mail_access(&ctx.pool, ctx.owner_iid).await.map_err(|e| anyhow!(e))? {
        anyhow::bail!("forbidden");
    }
    ensure_personal_on_first_access(&ctx.pool, ctx.owner_iid)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(())
}

pub async fn mail_mailbox_list_exec(ctx: &ToolContext, _args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let mailboxes = list_for_user(&ctx.pool, ctx.owner_iid).await.map_err(|e| anyhow!(e))?;
    Ok(json!({
        "mailboxes": mailboxes.iter().map(mailbox_json).collect::<Vec<_>>(),
    }))
}

pub async fn mail_list_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let direction = parse_direction(args)?;
    let mailbox_id = mailbox_id_arg(args);
    let limit = args.get("limit").and_then(|v| v.as_i64()).unwrap_or(50) as i32;
    let before = args.get("before_message_id").and_then(|v| v.as_i64()).unwrap_or(0);
    let is_archived = args.get("is_archived").and_then(|v| v.as_bool()).unwrap_or(false);
    let res = mail_svc(ctx)
        .list(ctx.owner_iid, mailbox_id, direction, limit, before, is_archived)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(json!({
        "messages": res.messages.iter().map(|m| message_json(m, false)).collect::<Vec<_>>(),
    }))
}

pub async fn mail_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let message_id = args
        .get("message_id")
        .and_then(|v| v.as_i64())
        .filter(|id| *id > 0)
        .ok_or_else(|| anyhow!("message_id is required"))?;
    let mailbox_id = mailbox_id_arg(args);
    let res = mail_svc(ctx)
        .get(ctx.owner_iid, mailbox_id, message_id)
        .await
        .map_err(|e| anyhow!(e))?;
    let msg = res.message.ok_or_else(|| anyhow!("message not found"))?;
    Ok(json!({ "message": message_json(&msg, true) }))
}

pub async fn mail_send_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let to_addr = args
        .get("to_addr")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("to_addr is required"))?;
    let subject = args
        .get("subject")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .unwrap_or("");
    let body_text = args
        .get("body_text")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("body_text is required"))?;
    let body_html = args.get("body_html").and_then(|v| v.as_str()).unwrap_or("").to_string();
    let mailbox_id = mailbox_id_arg(args);
    let attachments = parse_attachments(args);
    let res = mail_svc(ctx)
        .send(ctx.owner_iid, mailbox_id, to_addr, subject, body_text, &body_html, &attachments)
        .await
        .map_err(|e| anyhow!(e))?;
    let msg = res.message.ok_or_else(|| anyhow!("send returned no message"))?;
    Ok(json!({ "message": message_json(&msg, false) }))
}

pub async fn mail_mark_read_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let mailbox_id = mailbox_id_arg(args);
    let read = args.get("read").and_then(|v| v.as_bool()).unwrap_or(true);
    let ids: Vec<i64> = args
        .get("message_ids")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_i64()).collect())
        .unwrap_or_else(|| {
            args.get("message_id")
                .and_then(|v| v.as_i64())
                .map(|id| vec![id])
                .unwrap_or_default()
        });
    let (count, inbox_unread_count) = mail_svc(ctx)
        .mark_read(ctx.owner_iid, mailbox_id, &ids, read)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(json!({ "updated": count, "inbox_unread_count": inbox_unread_count }))
}

pub async fn mail_archive_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    require_mail(ctx).await?;
    let mailbox_id = mailbox_id_arg(args);
    let archive = args.get("archive").and_then(|v| v.as_bool()).unwrap_or(true);
    let ids: Vec<i64> = args
        .get("message_ids")
        .and_then(|v| v.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_i64()).collect())
        .unwrap_or_else(|| {
            args.get("message_id")
                .and_then(|v| v.as_i64())
                .map(|id| vec![id])
                .unwrap_or_default()
        });
    if ids.is_empty() {
        anyhow::bail!("message_id or message_ids required");
    }
    let count = mail_svc(ctx)
        .archive_messages(ctx.owner_iid, mailbox_id, &ids, archive)
        .await
        .map_err(|e| anyhow!(e))?;
    Ok(json!({ "updated": count }))
}

tool! {
    struct: MailMailboxListTool,
    name: "mail.mailbox.list",
    aliases: ["mail_mailbox_list"],
    description: "List platform mail inboxes the caller can access: personal {alien_id}@alienai.id plus any site/shared mailboxes where they are a member.",
    topics: ["mail", "general"],
    rag_phrases: [
        "email saya", "alamat email alienai", "my email address", "which mailboxes",
        "daftar inbox", "list mailboxes",
    ],
    readonly: true,
    parameters: {},
    execute: |args, ctx| {
        mail_mailbox_list_exec(ctx, &args).await
    }
}

tool! {
    struct: MailListTool,
    name: "mail.list",
    aliases: ["mail_list"],
    description: "List messages in a mailbox. direction in (inbox) or out (sent). Body preview is truncated; use mail.get for full text.",
    topics: ["mail", "general"],
    rag_phrases: [
        "baca email", "cek inbox", "email terbaru", "unread mail", "read my email",
        "list emails", "kotak masuk", "pesan masuk",
    ],
    readonly: true,
    parameters: {
        direction: (string, "in or out", required),
        mailbox_id: (integer, "Mailbox id; 0 = default personal mailbox", optional),
        limit: (integer, "Max rows (1-200, default 50)", optional),
        before_message_id: (integer, "Pagination cursor", optional),
        is_archived: (boolean, "List archived only when true", optional),
    },
    execute: |args, ctx| {
        mail_list_exec(ctx, &args).await
    }
}

tool! {
    struct: MailGetTool,
    name: "mail.get",
    aliases: ["mail_get"],
    description: "Fetch one mail message by message_id (marks inbound as read). Returns full body_text and capped body_html.",
    topics: ["mail", "general"],
    rag_phrases: ["buka email", "open email", "read message", "isi email"],
    readonly: true,
    parameters: {
        message_id: (integer, "mail.message id", required),
        mailbox_id: (integer, "Mailbox id; 0 = resolve default", optional),
    },
    execute: |args, ctx| {
        mail_get_exec(ctx, &args).await
    }
}

tool! {
    struct: MailSendTool,
    name: "mail.send",
    aliases: ["mail_send"],
    description: "Send email from a mailbox the caller can write to. Uses platform SMTP when configured. attachments: [{path,name,mime,size}] with /fs/ CAS paths.",
    topics: ["mail", "general"],
    rag_phrases: [
        "kirim email", "send email", "email ke", "compose email", "balas email",
    ],
    readonly: false,
    parameters: {
        to_addr: (string, "Recipient email (comma-separated allowed)", required),
        subject: (string, "Subject line", required),
        body_text: (string, "Plain text body", required),
        body_html: (string, "Optional HTML body", optional),
        mailbox_id: (integer, "From mailbox; 0 = personal", optional),
        attachments: (array, "Attachment objects with path /fs/...", optional),
    },
    execute: |args, ctx| {
        mail_send_exec(ctx, &args).await
    }
}

tool! {
    struct: MailMarkReadTool,
    name: "mail.mark_read",
    aliases: ["mail_mark_read"],
    description: "Mark inbound message(s) read or unread.",
    topics: ["mail"],
    readonly: false,
    parameters: {
        message_id: (integer, "Single message id", optional),
        message_ids: (array, "Multiple message ids", optional),
        mailbox_id: (integer, "Mailbox id; 0 = default", optional),
        read: (boolean, "true = read, false = unread (default true)", optional),
    },
    execute: |args, ctx| {
        mail_mark_read_exec(ctx, &args).await
    }
}

tool! {
    struct: MailArchiveTool,
    name: "mail.archive",
    aliases: ["mail_archive"],
    description: "Archive or unarchive message(s) in a mailbox.",
    topics: ["mail"],
    readonly: false,
    parameters: {
        message_id: (integer, "Single message id", optional),
        message_ids: (array, "Multiple message ids", optional),
        mailbox_id: (integer, "Mailbox id; 0 = default", optional),
        archive: (boolean, "true = archive, false = restore (default true)", optional),
    },
    execute: |args, ctx| {
        mail_archive_exec(ctx, &args).await
    }
}
