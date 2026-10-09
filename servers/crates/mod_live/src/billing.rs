use std::time::Instant;

use anyhow::Result;
use async_nats::Client;
use c35_mod_billing::{
    billing_account_ensure, billing_deduct_personal_profile,
    billing_reservation_refund, billing_reservation_settle, billing_to_retail_usd, BillingRow,
};
use c35_mod_log::{log_put, LogPut};
use sqlx::PgPool;

use crate::catalog::{live_retail_usd_per_min, live_retail_video_usd_per_min, LiveOfferRow};

#[derive(Debug, Clone)]
pub struct VideoActivityTracker {
    pub video_stream_active: bool,
    pub video_last_frame: Option<Instant>,
    pub total_video_secs: f64,
}

impl Default for VideoActivityTracker {
    fn default() -> Self {
        Self {
            video_stream_active: false,
            video_last_frame: None,
            total_video_secs: 0.0,
        }
    }
}

impl VideoActivityTracker {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn on_frame(&mut self, now: Instant) {
        if let Some(last) = self.video_last_frame {
            let dt = (now - last).as_secs_f64();
            if self.video_stream_active && dt < 3.0 {
                self.total_video_secs += dt;
            }
        }
        self.video_stream_active = true;
        self.video_last_frame = Some(now);
    }

    pub fn current_video_secs(&self, now: Instant) -> f64 {
        let mut total = self.total_video_secs;
        if self.video_stream_active {
            if let Some(last) = self.video_last_frame {
                let dt = (now - last).as_secs_f64();
                if dt < 3.0 {
                    total += dt;
                }
            }
        }
        total
    }

    pub fn finalize(&mut self, now: Instant, total_duration_secs: f64) -> f64 {
        let total = self.current_video_secs(now);
        self.video_stream_active = false;
        total.clamp(0.0, total_duration_secs)
    }
}

pub fn live_accrued_retail_usd(offer: &LiveOfferRow, elapsed_secs: f64, video_secs: f64) -> f64 {
    (live_retail_usd_per_min(offer) / 60.0) * elapsed_secs
        + (live_retail_video_usd_per_min(offer) / 60.0) * video_secs
}

pub async fn live_user_available_funds_usd(
    pool: &PgPool,
    owner_iid: i64,
    account_id: i64,
    _offer: &LiveOfferRow,
) -> Result<f64> {
    let profile_row = c35_mod_billing::billing_profile_fetch(pool, owner_iid).await?;
    let allowance_rem = if let Some(profile) = profile_row {
        if c35_mod_billing::profile_has_rings(&profile) {
            let profile = c35_mod_billing::billing_profile_windows_roll(pool, profile).await?;
            let (_alien_rem, frontier_rem) = c35_mod_billing::profile_ring_remaining_usd(&profile.rings);
            frontier_rem
        } else {
            0.0
        }
    } else {
        let leg = sqlx::query_as::<_, (f64, f64, f64, f64)>(
            "SELECT alien_allow_5h_used, alien_allow_5h_limit, alien_allow_weekly_used, alien_allow_weekly_limit \
             FROM ai.billing_account WHERE id = $1",
        )
        .bind(account_id)
        .fetch_optional(pool)
        .await?;
        if let Some((u5, l5, uw, lw)) = leg {
            c35_mod_billing::allowance_remaining(u5, l5, uw, lw)
        } else {
            0.0
        }
    };

    let acct = sqlx::query_as::<_, (String, String, String, i64)>(
        "SELECT balance_usd::text, balance_idr::text, billing_currency, fx_micro_per_usd FROM ai.billing_account WHERE id = $1",
    )
    .bind(account_id)
    .fetch_optional(pool)
    .await?;

    let wallet_usd = if let Some((bal_usd, bal_idr, cur, fx_micro)) = acct {
        let (held_usd, held_idr) = c35_mod_billing::billing_held_totals(pool, account_id).await.unwrap_or((0.0, 0.0));
        if cur.eq_ignore_ascii_case("IDR") {
            let idr: f64 = bal_idr.parse().unwrap_or(0.0);
            let avail_idr = (idr - held_idr).max(0.0);
            c35_mod_billing::native_to_usd(avail_idr, fx_micro)
        } else {
            let usd: f64 = bal_usd.parse().unwrap_or(0.0);
            (usd - held_usd).max(0.0)
        }
    } else {
        0.0
    };

    Ok(allowance_rem + wallet_usd)
}

pub async fn live_check_quota_exhausted(
    pool: &PgPool,
    owner_iid: i64,
    account_id: i64,
    offer: &LiveOfferRow,
    elapsed_secs: f64,
    video_secs: f64,
) -> Result<bool> {
    let accrued_retail_usd = live_accrued_retail_usd(offer, elapsed_secs, video_secs);
    let initial_hold = live_hold_retail_usd(offer);
    let available_funds = live_user_available_funds_usd(pool, owner_iid, account_id, offer).await.unwrap_or(0.0);
    if accrued_retail_usd > initial_hold + available_funds + 0.05 {
        tracing::warn!(
            owner_iid,
            accrued = accrued_retail_usd,
            initial_hold,
            available = available_funds,
            "live session billing quota exhausted"
        );
        return Ok(true);
    }
    Ok(false)
}

pub fn live_req_id(raw: &str, sid: &str) -> String {
    let raw = raw.trim();
    if !raw.is_empty() {
        return if raw.starts_with("live-") {
            raw.to_string()
        } else {
            format!("live-{raw}")
        };
    }
    format!("live-{sid}")
}

pub fn live_hold_retail_usd(offer: &LiveOfferRow) -> f64 {
    (live_retail_usd_per_min(offer) * 2.0).max(0.05)
}

pub fn live_wholesale_usd(offer: &LiveOfferRow, duration_secs: f64) -> f64 {
    live_wholesale_usd_with_video(offer, duration_secs, 0.0)
}

pub fn live_wholesale_usd_with_video(offer: &LiveOfferRow, voice_secs: f64, video_secs: f64) -> f64 {
    let voice_mins = (voice_secs / 60.0).max(0.0);
    let video_mins = (video_secs / 60.0).max(0.0);
    voice_mins * (offer.input_usd_per_min + offer.output_usd_per_min) + video_mins * offer.video_usd_per_min
}

pub async fn live_billing_gate(
    pool: &PgPool,
    owner_iid: i64,
    req_id: &str,
    offer: &LiveOfferRow,
) -> Result<BillingRow> {
    let row = billing_account_ensure(pool, owner_iid).await?;
    let hold = live_hold_retail_usd(offer);
    c35_mod_billing::billing_gate_with_hold_model(pool, owner_iid, &row, req_id, hold, Some(&offer.provider_model)).await?;
    Ok(row)
}

pub async fn live_billing_abort(pool: &PgPool, req_id: &str) -> Result<()> {
    billing_reservation_refund(pool, req_id).await
}

pub async fn live_billing_settle(
    pool: &PgPool,
    nats: Option<&Client>,
    owner_iid: i64,
    row: &BillingRow,
    req_id: &str,
    offer: &LiveOfferRow,
    duration_secs: f64,
    video_secs: f64,
) -> Result<()> {
    let wholesale = live_wholesale_usd_with_video(offer, duration_secs, video_secs);
    let duration_ms = (duration_secs * 1000.0).round().clamp(0.0, i32::MAX as f64) as i32;
    let topic = "live.session";
    let text = format!("Live call {} ({duration_secs:.1}s)", offer.id);
    let meta = serde_json::json!({
        "offer_id": offer.id,
        "wholesale_usd": wholesale,
        "duration_secs": duration_secs,
        "video_secs": video_secs,
    });
    let _ = voice_style_settle(
        pool,
        nats,
        owner_iid,
        row,
        req_id,
        wholesale,
        topic,
        &text,
        &offer.provider_model,
        duration_ms,
        meta,
    )
    .await?;
    Ok(())
}

async fn voice_style_settle(
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
            class: None,
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
    let deduct_model = if model.trim().is_empty() || model.eq_ignore_ascii_case("alienai") {
        "frontier"
    } else {
        model
    };
    let row_after = billing_deduct_personal_profile(pool, owner_iid, deduct_model, cost_usd).await?;
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    #[test]
    fn test_video_activity_tracker_accumulation() {
        let mut tracker = VideoActivityTracker::new();
        let t0 = Instant::now();

        // Initial frame
        tracker.on_frame(t0);
        assert!(tracker.video_stream_active);
        assert_eq!(tracker.total_video_secs, 0.0);

        // Frame 1 second later (< 3s)
        let t1 = t0 + Duration::from_secs(1);
        tracker.on_frame(t1);
        assert!((tracker.total_video_secs - 1.0).abs() < 1e-4);

        // Frame 1.5 seconds later (< 3s)
        let t2 = t1 + Duration::from_millis(1500);
        tracker.on_frame(t2);
        assert!((tracker.total_video_secs - 2.5).abs() < 1e-4);

        // Gap of 5 seconds (>= 3s idle/stopped)
        let t3 = t2 + Duration::from_secs(5);
        tracker.on_frame(t3);
        // Gap should NOT be accumulated
        assert!((tracker.total_video_secs - 2.5).abs() < 1e-4);

        // Finalize 1 second after t3 with total duration 10.0s
        let t4 = t3 + Duration::from_secs(1);
        let final_secs = tracker.finalize(t4, 10.0);
        assert!((final_secs - 3.5).abs() < 1e-4);
    }

    #[test]
    fn test_video_activity_tracker_clamp() {
        let mut tracker = VideoActivityTracker::new();
        let t0 = Instant::now();
        tracker.on_frame(t0);
        let t1 = t0 + Duration::from_secs(10);
        tracker.on_frame(t1);

        // Finalize clamping to total_duration_secs
        let final_secs = tracker.finalize(t1, 5.0);
        assert!(final_secs <= 5.0);
    }

    #[test]
    fn test_live_wholesale_usd_with_video() {
        let offer = LiveOfferRow {
            id: "live.alienai".into(),
            family: "alienai".into(),
            label_key: "live.alienai.label".into(),
            provider: "google".into(),
            provider_model: "gemini-3.8-live".into(),
            inst_id: "inst.general".into(),
            input_usd_per_min: 0.005,
            output_usd_per_min: 0.018,
            video_usd_per_min: 0.00155,
            enabled: true,
            sort: 10,
            tool_topics: vec![],
        };

        // 60s voice + 60s video
        let wholesale = live_wholesale_usd_with_video(&offer, 60.0, 60.0);
        assert!((wholesale - (0.023 + 0.00155)).abs() < 1e-6);

        // 60s voice + 0s video
        let voice_only = live_wholesale_usd_with_video(&offer, 60.0, 0.0);
        assert!((voice_only - 0.023).abs() < 1e-6);
    }

    #[test]
    fn test_live_accrued_retail_usd() {
        let offer = LiveOfferRow {
            id: "live.alienai".into(),
            family: "alienai".into(),
            label_key: "live.alienai.label".into(),
            provider: "google".into(),
            provider_model: "gemini-3.8-live".into(),
            inst_id: "inst.general".into(),
            input_usd_per_min: 0.005,
            output_usd_per_min: 0.018,
            video_usd_per_min: 0.00155,
            enabled: true,
            sort: 10,
            tool_topics: vec![],
        };

        let retail = live_accrued_retail_usd(&offer, 60.0, 30.0);
        let expected = (0.023 * 1.50) + ((0.023 + 0.00155) * 1.50 * 0.5);
        assert!((retail - expected).abs() < 1e-6);
    }
}
