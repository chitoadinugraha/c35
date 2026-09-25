use anyhow::Result;
use async_nats::Client;
use c35_mod_billing::{
    billing_account_ensure, billing_deduct_allowance, billing_gate_with_hold_custom,
    billing_reservation_refund, billing_reservation_settle, billing_to_retail_usd, BillingRow,
    RETAIL_MARKUP, VOICE_STT_HOLD_USD, VOICE_STT_USD_PER_MIN, VOICE_TTS_HOLD_USD,
    VOICE_TTS_USD_PER_1K_CHARS,
};
use c35_mod_log::{log_put, LogPut};
use sqlx::PgPool;

pub fn voice_req_id(prefix: &str, raw: &str) -> String {
    let raw = raw.trim();
    if raw.is_empty() {
        return String::new();
    }
    if raw.starts_with(prefix) {
        raw.to_string()
    } else {
        format!("{prefix}{raw}")
    }
}

pub fn estimate_stt_duration(audio: &[u8], mime: &str) -> f64 {
    if audio.is_empty() {
        return 0.0;
    }
    let m = mime.to_ascii_lowercase();
    if m.contains("wav") {
        let rate = wav_sample_rate_hz(audio).unwrap_or(16_000);
        let data_bytes = audio.len().saturating_sub(44).max(0) as f64;
        return data_bytes / (rate as f64 * 2.0);
    }
    let audio_len = audio.len();
    if m.contains("ogg") || m.contains("opus") {
        return audio_len as f64 / 4_000.0;
    }
    if m.contains("webm") {
        return audio_len as f64 / 6_000.0;
    }
    audio_len as f64 / 32_000.0
}

pub fn estimate_stt_cost_usd(audio: &[u8], mime: &str) -> f64 {
    let mins = estimate_stt_duration(audio, mime) / 60.0;
    mins * VOICE_STT_USD_PER_MIN
}

pub fn estimate_tts_cost_usd(text: &str) -> f64 {
    let chars = text.chars().count();
    if chars == 0 {
        return 0.0;
    }
    (chars as f64 / 1_000.0) * VOICE_TTS_USD_PER_1K_CHARS
}

pub fn voice_stt_wholesale_usd(audio: &[u8], mime: &str) -> f64 {
    estimate_stt_cost_usd(audio, mime) / RETAIL_MARKUP
}

pub fn voice_tts_wholesale_usd(text: &str) -> f64 {
    estimate_tts_cost_usd(text) / RETAIL_MARKUP
}

pub fn wav_sample_rate_hz(audio: &[u8]) -> Option<u32> {
    if audio.len() < 44 || !audio.starts_with(b"RIFF") || !audio.get(8..12).is_some_and(|s| s == b"WAVE") {
        return None;
    }
    let rate = u32::from_le_bytes([audio[24], audio[25], audio[26], audio[27]]);
    if rate > 0 && rate <= 192_000 {
        Some(rate)
    } else {
        None
    }
}

pub async fn voice_billing_gate(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    hold_usd: f64,
) -> Result<BillingRow> {
    let row = billing_account_ensure(pool, owner_iid).await?;
    billing_gate_with_hold_custom(pool, owner_iid, &row, req_id, hold_usd).await?;
    Ok(row)
}

pub async fn voice_billing_abort(pool: &PgPool, req_id: &str) -> Result<()> {
    billing_reservation_refund(pool, req_id).await
}

pub async fn voice_billing_settle(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    wholesale_usd: f64,
    topic: &str,
    text: &str,
    model: &str,
    duration_ms: i32,
    meta: serde_json::Value,
) -> Result<f64> {
    let cost_usd = billing_to_retail_usd(wholesale_usd);
    if cost_usd <= 0.0 {
        billing_reservation_refund(pool, req_id).await?;
        return Ok(0.0);
    }
    let log_id = log_put(
        pool,
        nats,
        LogPut {
            owner_iid,
            kind: "tool",
            topic,
            dv: "",
            req_id: Some(req_id),
            chat_id: None,
            task_id: None,
            device_iid: None,
            text,
            model,
            tokens_in: 0,
            tokens_out: 0,
            duration_ms,
            cost_usd,
            meta,
        },
    )
    .await?;
    let inserted = sqlx::query(
        r#"
        INSERT INTO ai.billing_usage_dedupe (owner_iid, req_id, cost_usd, cost_wholesale_usd, billing_account_id, log_id)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (owner_iid, req_id) DO NOTHING
        "#,
    )
    .bind(owner_iid)
    .bind(req_id)
    .bind(cost_usd)
    .bind(wholesale_usd)
    .bind(row.id)
    .bind(log_id)
    .execute(pool)
    .await?;
    if inserted.rows_affected() == 0 {
        billing_reservation_refund(pool, req_id).await?;
        return Ok(0.0);
    }
    let row_after = billing_deduct_allowance(pool, owner_iid, cost_usd).await?;
    let acct = sqlx::query_as::<_, (String, String, i64)>(
        "SELECT balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(row_after.id)
    .fetch_one(pool)
    .await?;
    let balance_idr = acct.0.parse().unwrap_or(0.0);
    billing_reservation_settle(
        pool,
        owner_iid,
        &row_after,
        req_id,
        cost_usd,
        balance_idr,
        &acct.1,
        acct.2,
    )
    .await?;
    c35_mod_billing::billing_notify_owner(pool, nats, owner_iid, None).await;
    Ok(cost_usd)
}

pub const VOICE_STT_HOLD: f64 = VOICE_STT_HOLD_USD;
pub const VOICE_TTS_HOLD: f64 = VOICE_TTS_HOLD_USD;
