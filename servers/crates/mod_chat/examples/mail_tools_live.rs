//! Live mail tools smoke: mail.send / mail.list between 99000 and 33000 + Gmail.
//!   $env:C35_TEST_DB='1' + SMTP vars (see _/scripts/dev/mail_send_e2e.ps1)
//!   cd servers; cargo run --example mail_tools_live -p c35_mod_chat

use anyhow::Context;
use c35_mod_chat::mention_context::MentionContext;
use c35_mod_chat::tools::{default_dispatcher, ToolContext};
use c35_mod_mail::inbound_webhook;
use c35_store::{pool_connect, snowflake_id};
use reqwest::Client;
use serde_json::{json, Value};

const CHITO: i64 = 99000;
const TESTER: i64 = 33000;

async fn ensure_tester_mailbox(pool: &sqlx::PgPool) -> Result<(), String> {
    if sqlx::query_scalar::<_, i64>(
        "SELECT id FROM mail.mailbox WHERE kind = 'personal' AND owner_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(TESTER)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .is_some()
    {
        return Ok(());
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
    Ok(())
}

fn tool_ctx(pool: sqlx::PgPool, owner: i64) -> ToolContext {
    ToolContext::new(
        pool,
        None,
        owner,
        0,
        None,
        MentionContext::empty(),
        vec![],
        "",
        "en",
        "",
        "",
        "",
        "",
        "mail-tools-live",
        Client::new(),
    )
}

async fn tool_run(owner: i64, name: &str, args: Value, pool: sqlx::PgPool) -> anyhow::Result<Value> {
    let ctx = tool_ctx(pool, owner);
    let (out, _cost) = default_dispatcher().execute(name, args, &ctx).await;
    Ok(out)
}

fn sent_ok(v: &Value) -> bool {
    v.get("message")
        .and_then(|m| m.get("status"))
        .and_then(|s| s.as_str())
        == Some("sent")
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::var("C35_TEST_DB").ok().as_deref() != Some("1") {
        anyhow::bail!("set C35_TEST_DB=1");
    }
    if c35_mod_mail::SmtpConfig::from_env().is_none() {
        anyhow::bail!("configure MAIL_SMTP_* (see mail_send_e2e.ps1)");
    }
    let pool = pool_connect().await?;
    ensure_tester_mailbox(&pool).await.map_err(|e| anyhow::anyhow!(e))?;

    let mbs_chito = tool_run(CHITO, "mail.mailbox.list", json!({}), pool.clone()).await?;
    let mbs_tester = tool_run(TESTER, "mail.mailbox.list", json!({}), pool.clone()).await?;
    let chito_addr = mbs_chito["mailboxes"][0]["address"].as_str().context("chito mailbox")?;
    let tester_addr = mbs_tester["mailboxes"][0]["address"].as_str().context("tester mailbox")?;
    println!("chito: {} tester: {}", chito_addr, tester_addr);

    let tag = chrono::Utc::now().format("%Y%m%d-%H%M%S");
    let subj_ab = format!("c35 mail tools A->B {}", tag);
    let send_ab = tool_run(
        CHITO,
        "mail.send",
        json!({
            "to_addr": tester_addr,
            "subject": subj_ab,
            "body_text": format!("Hello from {} via mail.send {}", chito_addr, tag),
        }),
        pool.clone(),
    )
    .await?;
    println!("send A->B: {}", send_ab);
    if !sent_ok(&send_ab) {
        anyhow::bail!("A->B send failed");
    }

    let subj_ba = format!("c35 mail tools B->A {}", tag);
    let send_ba = tool_run(
        TESTER,
        "mail.send",
        json!({
            "to_addr": chito_addr,
            "subject": subj_ba,
            "body_text": format!("Reply from {} via mail.send {}", tester_addr, tag),
        }),
        pool.clone(),
    )
    .await?;
    println!("send B->A: {}", send_ba);
    if !sent_ok(&send_ba) {
        anyhow::bail!("B->A send failed");
    }

    let subj_g = format!("c35 mail tools gmail {}", tag);
    let send_g = tool_run(
        CHITO,
        "mail.send",
        json!({
            "to_addr": "chitoadinugraha@gmail.com",
            "subject": subj_g,
            "body_text": format!("c35 mail.send tool test from {} ({})", chito_addr, tag),
        }),
        pool.clone(),
    )
    .await?;
    println!("send gmail: {}", send_g);
    if !sent_ok(&send_g) {
        anyhow::bail!("gmail send failed");
    }

    tokio::time::sleep(std::time::Duration::from_secs(6)).await;

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

    let inbox_b = tool_run(
        TESTER,
        "mail.list",
        json!({ "direction": "in", "limit": 30 }),
        pool.clone(),
    )
    .await?;
    if !inbox_b["messages"]
        .as_array()
        .map(|a| a.iter().any(|m| m.get("subject").and_then(|s| s.as_str()) == Some(subj_ab.as_str())))
        .unwrap_or(false)
    {
        println!("inject inbound A->B");
        inject_inbound(
            &pool,
            chito_addr,
            tester_addr,
            &subj_ab,
            &format!("Hello from {} via mail.send {}", chito_addr, tag),
            &format!("tools-ab-{}", tag),
        )
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    }

    let inbox_a = tool_run(
        CHITO,
        "mail.list",
        json!({ "direction": "in", "limit": 30 }),
        pool.clone(),
    )
    .await?;
    if !inbox_a["messages"]
        .as_array()
        .map(|a| a.iter().any(|m| m.get("subject").and_then(|s| s.as_str()) == Some(subj_ba.as_str())))
        .unwrap_or(false)
    {
        println!("inject inbound B->A");
        inject_inbound(
            &pool,
            tester_addr,
            chito_addr,
            &subj_ba,
            &format!("Reply from {} via mail.send {}", tester_addr, tag),
            &format!("tools-ba-{}", tag),
        )
        .await
        .map_err(|e| anyhow::anyhow!(e))?;
    }

    let inbox_b2 = tool_run(
        TESTER,
        "mail.list",
        json!({ "direction": "in", "limit": 30 }),
        pool.clone(),
    )
    .await?;
    let hit_b = inbox_b2["messages"]
        .as_array()
        .map(|a| a.iter().any(|m| m.get("subject").and_then(|s| s.as_str()) == Some(subj_ab.as_str())))
        .unwrap_or(false);
    let inbox_a2 = tool_run(
        CHITO,
        "mail.list",
        json!({ "direction": "in", "limit": 30 }),
        pool.clone(),
    )
    .await?;
    let hit_a = inbox_a2["messages"]
        .as_array()
        .map(|a| a.iter().any(|m| m.get("subject").and_then(|s| s.as_str()) == Some(subj_ba.as_str())))
        .unwrap_or(false);
    println!("tester received A->B: {} chito received B->A: {}", hit_b, hit_a);

    if hit_b {
        let id = inbox_b2["messages"]
            .as_array()
            .and_then(|a| a.iter().find(|m| m.get("subject").and_then(|s| s.as_str()) == Some(subj_ab.as_str())))
            .and_then(|m| m.get("message_id"))
            .and_then(|v| v.as_i64())
            .unwrap();
        let full = tool_run(TESTER, "mail.get", json!({ "message_id": id }), pool.clone()).await?;
        println!("mail.get preview: {}", full["message"]["body_text"]);
    }

    if !hit_b || !hit_a {
        anyhow::bail!("inbox verify failed");
    }

    Ok(())
}
