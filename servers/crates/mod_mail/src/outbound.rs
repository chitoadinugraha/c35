//! Outbound relay ΓÇö SMTP (lettre) or Cloudflare Worker (`send_email`).

use base64::Engine;
use lettre::message::header::ContentType;
use lettre::message::{Attachment, MultiPart, SinglePart};
use lettre::transport::smtp::authentication::Credentials;
use lettre::transport::smtp::client::{Tls, TlsParameters};
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};

use crate::attachments::MailAttachmentMeta;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SmtpTlsMode {
    Wrapper,
    StartTls,
    None,
}

pub struct SmtpConfig {
    pub host: String,
    pub port: u16,
    pub user: String,
    pub pass: String,
    pub from: String,
    pub tls: SmtpTlsMode,
}

impl SmtpConfig {
    pub fn from_env() -> Option<Self> {
        let host = std::env::var("MAIL_SMTP_HOST").ok()?.trim().to_string();
        if host.is_empty() {
            return None;
        }
        let port = std::env::var("MAIL_SMTP_PORT")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(if host.contains("cloudflare") { 465 } else { 587 });
        let user = std::env::var("MAIL_SMTP_USER").unwrap_or_default();
        let pass = std::env::var("MAIL_SMTP_PASS")
            .ok()
            .filter(|s| !s.trim().is_empty())
            .or_else(|| std::env::var("CLOUDFLARE_API_TOKEN").ok())
            .unwrap_or_default();
        if !user.trim().is_empty() && pass.trim().is_empty() {
            return None;
        }
        let tls_raw = std::env::var("MAIL_SMTP_TLS").unwrap_or_default();
        let tls = parse_tls_mode(&tls_raw, port);
        let from = std::env::var("MAIL_SMTP_FROM")
            .ok()
            .filter(|s| !s.trim().is_empty())
            .unwrap_or_else(|| "noreply@alienai.id".to_string());
        Some(Self {
            host,
            port,
            user,
            pass,
            from,
            tls,
        })
    }
}

fn parse_tls_mode(raw: &str, port: u16) -> SmtpTlsMode {
    let key = raw.trim().to_lowercase();
    match key.as_str() {
        "wrapper" | "implicit" | "smtps" => SmtpTlsMode::Wrapper,
        "starttls" | "tls" | "required" => SmtpTlsMode::StartTls,
        "none" | "off" | "plain" => SmtpTlsMode::None,
        _ if port == 465 => SmtpTlsMode::Wrapper,
        _ => SmtpTlsMode::StartTls,
    }
}

fn build_mailer(cfg: &SmtpConfig) -> Result<AsyncSmtpTransport<Tokio1Executor>, String> {
    let mut builder = AsyncSmtpTransport::<Tokio1Executor>::relay(&cfg.host)
        .map_err(|e| e.to_string())?
        .port(cfg.port);
    match cfg.tls {
        SmtpTlsMode::Wrapper => {
            let tls = TlsParameters::new(cfg.host.clone()).map_err(|e| e.to_string())?;
            builder = builder.tls(Tls::Wrapper(tls));
        }
        SmtpTlsMode::StartTls => {
            let tls = TlsParameters::new(cfg.host.clone()).map_err(|e| e.to_string())?;
            builder = builder.tls(Tls::Required(tls));
        }
        SmtpTlsMode::None => {}
    }
    if !cfg.user.is_empty() {
        builder = builder.credentials(Credentials::new(cfg.user.clone(), cfg.pass.clone()));
    }
    Ok(builder.build())
}

/// Loaded attachment bytes for outbound MIME.
pub struct OutboundAttachment {
    pub name: String,
    pub mime: String,
    pub data: Vec<u8>,
}

pub async fn send_mail(
    cfg: &SmtpConfig,
    from_display: &str,
    to: &[String],
    subject: &str,
    body_text: &str,
    body_html: &str,
    attachments: &[OutboundAttachment],
) -> Result<(), String> {
    if to.is_empty() {
        return Err("no recipients".into());
    }
    let from_addr = if from_display.contains('@') {
        from_display.to_string()
    } else {
        format!("{from_display} <{}>", cfg.from)
    };

    let body_part = if body_html.trim().is_empty() {
        MultiPart::mixed().singlepart(
            SinglePart::builder()
                .header(ContentType::TEXT_PLAIN)
                .body(body_text.to_string()),
        )
    } else {
        MultiPart::alternative()
            .singlepart(
                SinglePart::builder()
                    .header(ContentType::TEXT_PLAIN)
                    .body(body_text.to_string()),
            )
            .singlepart(
                SinglePart::builder()
                    .header(ContentType::TEXT_HTML)
                    .body(body_html.to_string()),
            )
    };

    let multipart = if attachments.is_empty() {
        body_part
    } else {
        let mut mixed = MultiPart::mixed().multipart(body_part);
        for a in attachments {
            let ct = ContentType::parse(if a.mime.trim().is_empty() {
                "application/octet-stream"
            } else {
                a.mime.trim()
            })
            .unwrap_or(ContentType::TEXT_PLAIN);
            let name = if a.name.trim().is_empty() {
                "attachment".to_string()
            } else {
                a.name.trim().to_string()
            };
            mixed = mixed.singlepart(Attachment::new(name).body(a.data.clone(), ct));
        }
        mixed
    };

    let mut builder = Message::builder()
        .from(from_addr.parse().map_err(|e: lettre::address::AddressError| e.to_string())?);
    for addr in to {
        builder = builder.to(addr.parse().map_err(|e: lettre::address::AddressError| e.to_string())?);
    }
    let email = builder
        .subject(subject)
        .multipart(multipart)
        .map_err(|e| e.to_string())?;

    let mailer = build_mailer(cfg)?;
    mailer.send(email).await.map_err(|e| e.to_string())?;
    Ok(())
}

pub struct WorkerConfig {
    pub url: String,
    pub secret: String,
}

impl WorkerConfig {
    pub fn from_env() -> Option<Self> {
        let url = std::env::var("MAIL_OUTBOUND_WORKER_URL")
            .ok()?
            .trim()
            .to_string();
        if url.is_empty() {
            return None;
        }
        let secret = std::env::var("MAIL_INBOUND_SECRET")
            .ok()?
            .trim()
            .to_string();
        if secret.is_empty() {
            return None;
        }
        Some(Self { url, secret })
    }
}

pub async fn send_via_worker(
    cfg: &WorkerConfig,
    from: &str,
    to: &[String],
    subject: &str,
    body_text: &str,
    body_html: &str,
    attachments: &[OutboundAttachment],
) -> Result<(), String> {
    if to.is_empty() {
        return Err("no recipients".into());
    }
    let to_header = to.join(", ");
    let atts: Vec<serde_json::Value> = attachments
        .iter()
        .map(|a| {
            serde_json::json!({
                "name": a.name,
                "mime": a.mime,
                "data": base64::engine::general_purpose::STANDARD.encode(&a.data),
            })
        })
        .collect();
    let client = reqwest::Client::new();
    for envelope_to in to {
        let res = client
            .post(&cfg.url)
            .header("Authorization", format!("Bearer {}", cfg.secret))
            .json(&serde_json::json!({
                "from": from,
                "to": envelope_to,
                "to_header": to_header,
                "subject": subject,
                "text": body_text,
                "html": body_html,
                "attachments": atts,
            }))
            .send()
            .await
            .map_err(|e| e.to_string())?;
        if res.status().is_success() {
            continue;
        }
        let status = res.status();
        let body = res.text().await.unwrap_or_default();
        return Err(format!("worker outbound {}: {}", status, body.trim()));
    }
    Ok(())
}

pub async fn load_outbound_attachments(
    cas: Option<&crate::attachments::MailCas>,
    metas: &[MailAttachmentMeta],
) -> Result<Vec<OutboundAttachment>, String> {
    if metas.is_empty() {
        return Ok(Vec::new());
    }
    let Some(cas) = cas else {
        return Err("file store not configured".into());
    };
    let mut out = Vec::with_capacity(metas.len());
    for m in metas {
        let (mime, data) = crate::attachments::load_bytes(cas, m).await?;
        out.push(OutboundAttachment {
            name: m.name.clone(),
            mime,
            data,
        });
    }
    Ok(out)
}
