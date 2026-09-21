use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc;
use std::time::Duration;

use sqlx::PgPool;
use tokio::time::Instant;

pub const BOT_BUSY_REPLY: &str =
    "Maaf, saat ini terlalu banyak permintaan masuk sekaligus. Coba kirim lagi dalam 1–2 menit ya 🙏";

const BOT_QUEUE_WAIT: Duration = Duration::from_secs(30);

pub struct BotTurnGuard {
    limiter: Arc<BotLimiter>,
}

impl Drop for BotTurnGuard {
    fn drop(&mut self) {
        self.limiter.active.fetch_sub(1, Ordering::SeqCst);
    }
}

pub struct BotLimiter {
    bot_iid: i64,
    active: AtomicU32,
    max_concurrent: AtomicU32,
    outbound_gap_ms: AtomicU32,
    outbound_last: tokio::sync::Mutex<Instant>,
}

impl BotLimiter {
    pub fn new(bot_iid: i64) -> Arc<Self> {
        Arc::new(Self {
            bot_iid,
            active: AtomicU32::new(0),
            max_concurrent: AtomicU32::new(3),
            outbound_gap_ms: AtomicU32::new(1000),
            outbound_last: tokio::sync::Mutex::new(Instant::now() - Duration::from_secs(1)),
        })
    }

    pub async fn acquire_turn(self: &Arc<Self>, pool: &PgPool) -> Result<BotTurnGuard, ()> {
        let limits = bot_limits_load(pool, self.bot_iid).await;
        self.max_concurrent.store(limits.concurrent.max(1) as u32, Ordering::SeqCst);
        self.outbound_gap_ms.store((1000 / limits.outbound_per_sec.max(1) as u32).max(125), Ordering::SeqCst);
        let deadline = Instant::now() + BOT_QUEUE_WAIT;
        loop {
            let cur = self.active.load(Ordering::SeqCst);
            let max = self.max_concurrent.load(Ordering::SeqCst).max(1);
            if cur < max && self.active.compare_exchange(cur, cur + 1, Ordering::SeqCst, Ordering::SeqCst).is_ok() {
                return Ok(BotTurnGuard { limiter: Arc::clone(self) });
            }
            if Instant::now() >= deadline {
                return Err(());
            }
            tokio::time::sleep(Duration::from_millis(250)).await;
        }
    }

    pub async fn outbound_pace(&self) {
        let gap = Duration::from_millis(self.outbound_gap_ms.load(Ordering::SeqCst).max(125) as u64);
        loop {
            let mut last = self.outbound_last.lock().await;
            let elapsed = last.elapsed();
            if elapsed >= gap {
                *last = Instant::now();
                return;
            }
            let wait = gap - elapsed;
            drop(last);
            tokio::time::sleep(wait).await;
        }
    }
}

struct BotLimits {
    concurrent: i32,
    outbound_per_sec: i32,
}

async fn bot_limits_load(pool: &PgPool, bot_iid: i64) -> BotLimits {
    let row = sqlx::query_as::<_, (i32, i32)>(
        r#"
        SELECT COALESCE(p.concurrent_limit, 3),
               COALESCE((p.caps_json->>'outbound_per_sec')::int,
                   CASE p.slug WHEN 'bot.large' THEN 8 WHEN 'bot.medium' THEN 3 ELSE 1 END)
        FROM ai.billing_subscription s
        JOIN ai.billing_plan p ON p.slug = s.plan_slug
        WHERE s.scope = 'bot' AND s.scope_iid = $1 AND s.deleted_ts IS NULL
          AND (s.expires_ts IS NULL OR s.expires_ts > NOW())
        LIMIT 1
        "#,
    )
    .bind(bot_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    if let Some((c, r)) = row {
        return BotLimits { concurrent: c.max(1), outbound_per_sec: r.max(1) };
    }
    BotLimits { concurrent: 1, outbound_per_sec: 1 }
}
