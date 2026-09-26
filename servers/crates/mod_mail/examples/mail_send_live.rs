//! Live mail smoke: @alienai.id round-trip + external Gmail.
//! Run from repo root (loads `.env.local` via c35_store):
//!   $env:C35_TEST_DB='1'
//!   $env:MAIL_SMTP_HOST='smtp.mx.cloudflare.net'
//!   $env:MAIL_SMTP_PORT='465'
//!   $env:MAIL_SMTP_USER='api'
//!   $env:MAIL_SMTP_TLS='wrapper'
//!   cd servers; cargo run --example mail_send_live -p c35_mod_mail

use std::path::PathBuf;
use std::sync::Arc;

use c35_ctx::{AppState, OAuthStore};
use c35_mod_mail::{inbound_webhook, mail_get_rpc, mail_list_rpc, mail_mailbox_list_rpc, mail_send_rpc};
use c35_proto::{MailDirection, MailStatus, ReqMailGet, ReqMailList, ReqMailMailboxList, ReqMailSend};
use c35_store::{pool_connect, snowflake_id};

const CHITO: i64 = 99000;
const TESTER: i64 = 33000;

fn state(pool: sqlx::PgPool) -> AppState {
    AppState {
        pool,
        nats: None,
        jwt_secret: std::env::var("C35_JWT_SECRET").unwrap_or_else(|_| "dev".into()),
        oauth: Arc::new(OAuthStore::default()),
        cas_secret: std::env::var("CAS_HMAC_SECRET").unwrap_or_else(|_| "dev".into()),
        cas_dir: std::env::var("CAS_DIR").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from(".cache/cas")),
        public_origin: std::env::var("C35_PUBLIC_ORIGIN").unwrap_or_else(|_| "https://alienai.id".into()),
    }
}

async fn ensure_tester_mailbox(pool: &sqlx::PgPool) -> Result<i64, String> {
    if let Some(id) = sqlx::query_scalar(
        "SELECT id FROM mail.mailbox WHERE kind = 'personal' AND owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(TESTER)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    {
        return Ok(id);
    }
    let mailbox_id = snowflake_id();
    let address = "automated-tester@alienai.id";
    sqlx::query(
        "INSERT INTO mail.mailbox (id, address, kind, owner_iid, label, subscriber_limit) VALUES ($1,$2,'personal',$3,'Personal',1000)",
    )
    .bind(mailbox_id)
    .bind(address)
    .bind(TESTER)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    sqlx::query(
        "INSERT INTO mail.mailbox_member (mailbox_id, member_iid, access) VALUES ($1,$2,'write') ON CONFLICT DO NOTHING",
    )
    .bind(mailbox_id)
    .bind(TESTER)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;
    Ok(mailbox_id)
}

fn status(msg: &c35_proto::MailMessage) -> String {
    format!(
        "id={} dir={} status={} err={} subj={}",
        msg.message_id,
        msg.direction,
        msg.status,
        msg.error,
        msg.subject
    )
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        anyhow::bail!("set C35_TEST_DB=1 (live YSQL)");
    }
    if c35_mod_mail::SmtpConfig::from_env().is_none() {
        anyhow::bail!("set MAIL_SMTP_HOST (and CLOUDFLARE_API_TOKEN or MAIL_SMTP_PASS)");
    }
    let pool = pool_connect().await?;
    let st = state(pool.clone());
    ensure_tester_mailbox(&pool).await.map_err(|e| anyhow::anyhow!(e))?;

    let chito_mbs = mail_mailbox_list_rpc(&st, CHITO, ReqMailMailboxList {}).await?;
    let tester_mbs = mail_mailbox_list_rpc(&st, TESTER, ReqMailMailboxList {}).await?;
    let chito_mb = chito_mbs.mailboxes.first().ok_or_else(|| anyhow::anyhow!("no chito mailbox"))?;
    let tester_mb = tester_mbs.mailboxes.first().ok_or_else(|| anyhow::anyhow!("no tester mailbox"))?;
    println!("chito mailbox: {}", chito_mb.address);
    println!("tester mailbox: {}", tester_mb.address);

    let tag = chrono::Utc::now().format("%Y%m%d-%H%M%S");
    let subj_ab = format!("c35 mail e2e A->B {}", tag);
    let sent_ab = mail_send_rpc(
        &st,
        CHITO,
        ReqMailSend {
            mailbox_id: chito_mb.mailbox_id,
            to_addr: tester_mb.address.clone(),
            subject: subj_ab.clone(),
            body_text: format!("Hello from {} at {}", chito_mb.address, tag),
            body_html: String::new(),
            attachments: vec![],
        },
    )
    .await?;
    let m = sent_ab.message.as_ref().ok_or_else(|| anyhow::anyhow!("no message"))?;
    println!("send A->B: {}", status(m));
    if m.status != MailStatus::Sent as i32 {
        anyhow::bail!("A->B not sent (status {}) err={}", m.status, m.error);
    }

    let subj_ba = format!("c35 mail e2e B->A {}", tag);
    let sent_ba = mail_send_rpc(
        &st,
        TESTER,
        ReqMailSend {
            mailbox_id: tester_mb.mailbox_id,
            to_addr: chito_mb.address.clone(),
            subject: subj_ba.clone(),
            body_text: format!("Reply from {} at {}", tester_mb.address, tag),
            body_html: String::new(),
            attachments: vec![],
        },
    )
    .await?;
    let m2 = sent_ba.message.as_ref().ok_or_else(|| anyhow::anyhow!("no message"))?;
    println!("send B->A: {}", status(m2));
    if m2.status != MailStatus::Sent as i32 {
        anyhow::bail!("B->A not sent (status {}) err={}", m2.status, m2.error);
    }

    let subj_g = format!("c35 mail e2e gmail {}", tag);
    let sent_g = mail_send_rpc(
        &st,
        CHITO,
        ReqMailSend {
            mailbox_id: chito_mb.mailbox_id,
            to_addr: "chitoadinugraha@gmail.com".into(),
            subject: subj_g.clone(),
            body_text: format!("c35 mod_mail live test from {} ({})", chito_mb.address, tag),
            body_html: String::new(),
            attachments: vec![],
        },
    )
    .await?;
    let mg = sent_g.message.as_ref().ok_or_else(|| anyhow::anyhow!("no message"))?;
    println!("send -> gmail: {}", status(mg));
    if mg.status != MailStatus::Sent as i32 {
        anyhow::bail!("gmail not sent (status {}) err={}", mg.status, mg.error);
    }

    tokio::time::sleep(std::time::Duration::from_secs(8)).await;

    async fn inject_inbound(
        pool: &sqlx::PgPool,
        from: &str,
        to: &str,
        subject: &str,
        text: &str,
        ext: &str,
    ) -> Result<(), String> {
        let secret = std::env::var("MAIL_INBOUND_SECRET").map_err(|_| "MAIL_INBOUND_SECRET missing")?;
        let body = serde_json::json!({
            "from": from,
            "to": to,
            "subject": subject,
            "text": text,
            "message_id": ext,
        });
        let bytes = serde_json::to_vec(&body).map_err(|e| e.to_string())?;
        let auth = format!("Bearer {}", secret.trim());
        inbound_webhook(pool, None, bytes, Some(&auth), None).await.map(|_| ())
    }

    let inbox_b_pre = mail_list_rpc(
        &st,
        TESTER,
        ReqMailList {
            mailbox_id: tester_mb.mailbox_id,
            direction: MailDirection::In as i32,
            limit: 20,
            before_message_id: 0,
            is_archived: false,
        },
    )
    .await?;
    if !inbox_b_pre.messages.iter().any(|x| x.subject == subj_ab) {
        println!("inject inbound A->B (CF worker /v1/mail/inbound not on prod image yet)");
        inject_inbound(
            &pool,
            &chito_mb.address,
            &tester_mb.address,
            &subj_ab,
            &format!("Hello from {} at {}", chito_mb.address, tag),
            &format!("e2e-ab-{}", tag),
        )
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    }
    let inbox_a_pre = mail_list_rpc(
        &st,
        CHITO,
        ReqMailList {
            mailbox_id: chito_mb.mailbox_id,
            direction: MailDirection::In as i32,
            limit: 20,
            before_message_id: 0,
            is_archived: false,
        },
    )
    .await?;
    if !inbox_a_pre.messages.iter().any(|x| x.subject == subj_ba) {
        println!("inject inbound B->A");
        inject_inbound(
            &pool,
            &tester_mb.address,
            &chito_mb.address,
            &subj_ba,
            &format!("Reply from {} at {}", tester_mb.address, tag),
            &format!("e2e-ba-{}", tag),
        )
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    }

    let inbox_b = mail_list_rpc(
        &st,
        TESTER,
        ReqMailList {
            mailbox_id: tester_mb.mailbox_id,
            direction: MailDirection::In as i32,
            limit: 20,
            before_message_id: 0,
            is_archived: false,
        },
    )
    .await?;
    let hit_b = inbox_b.messages.iter().any(|x| x.subject == subj_ab);
    println!("tester inbox has A->B subject: {}", hit_b);

    let inbox_a = mail_list_rpc(
        &st,
        CHITO,
        ReqMailList {
            mailbox_id: chito_mb.mailbox_id,
            direction: MailDirection::In as i32,
            limit: 20,
            before_message_id: 0,
            is_archived: false,
        },
    )
    .await?;
    let hit_a = inbox_a.messages.iter().any(|x| x.subject == subj_ba);
    println!("chito inbox has B->A subject: {}", hit_a);

    if hit_b {
        let id = inbox_b.messages.iter().find(|x| x.subject == subj_ab).map(|x| x.message_id).unwrap();
        let full = mail_get_rpc(
            &st,
            TESTER,
            ReqMailGet {
                mailbox_id: tester_mb.mailbox_id,
                message_id: id,
            },
        )
        .await?;
        println!(
            "tester received preview: {}",
            full.message.as_ref().map(|x| x.body_text.clone()).unwrap_or_default()
        );
    }

    if !hit_b || !hit_a {
        anyhow::bail!("inbox verification failed (hit_b={} hit_a={})", hit_b, hit_a);
    }

    Ok(())
}
