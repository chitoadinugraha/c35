use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;
use std::time::{SystemTime, UNIX_EPOCH};

/// 2026-01-01 00:00:00 UTC — aligned with CSA import epoch.
pub const SNOWFLAKE_EPOCH_MS: i64 = 1_767_225_600_000;

const EPOCH_MS: u64 = SNOWFLAKE_EPOCH_MS as u64;
const WORKER_BITS: u64 = 10;
const SEQ_BITS: u64 = 12;
const MAX_SEQ: u64 = (1 << SEQ_BITS) - 1;
const WORKER_MASK: u64 = (1 << WORKER_BITS) - 1;
const SNOWFLAKE_SHIFT: i64 = WORKER_BITS as i64 + SEQ_BITS as i64;

static SEQ: AtomicU64 = AtomicU64::new(0);
static LAST_MS: AtomicU64 = AtomicU64::new(0);

fn worker_id_from_origin(origin: &str) -> u64 {
    let mut h: u32 = 2166136261;
    for b in origin.as_bytes() {
        h ^= u32::from(*b);
        h = h.wrapping_mul(16777619);
    }
    let n = (h as u64) & WORKER_MASK;
    if n == 0 { 1 } else { n }
}

fn worker_id() -> u64 {
    static ID: OnceLock<u64> = OnceLock::new();
    *ID.get_or_init(|| {
        if let Ok(v) = std::env::var("C35_WORKER_ID") {
            if let Ok(n) = v.parse::<u64>() {
                return n & WORKER_MASK;
            }
        }
        let origin = std::env::var("POD_NAME")
            .or_else(|_| std::env::var("HOSTNAME"))
            .unwrap_or_else(|_| std::process::id().to_string());
        worker_id_from_origin(&origin)
    })
}

pub fn snowflake_min_at_ms(ms: i64) -> i64 {
    ((ms.saturating_sub(SNOWFLAKE_EPOCH_MS)).max(0)) << SNOWFLAKE_SHIFT
}

pub fn snowflake_max_at_ms(ms: i64) -> i64 {
    snowflake_min_at_ms(ms) | ((1_i64 << SNOWFLAKE_SHIFT) - 1)
}

pub fn snowflake_id() -> i64 {
    let worker = worker_id();
    loop {
        let ms = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_millis() as u64)
            .unwrap_or(EPOCH_MS)
            .saturating_sub(EPOCH_MS);
        let last = LAST_MS.load(Ordering::SeqCst);
        if ms > last {
            if LAST_MS
                .compare_exchange(last, ms, Ordering::SeqCst, Ordering::SeqCst)
                .is_ok()
            {
                SEQ.store(1, Ordering::SeqCst);
                return ((ms << (WORKER_BITS + SEQ_BITS)) | (worker << SEQ_BITS)) as i64;
            }
            continue;
        }
        if ms == last {
            let seq = SEQ.fetch_add(1, Ordering::SeqCst);
            if seq > MAX_SEQ {
                std::thread::sleep(std::time::Duration::from_millis(1));
                continue;
            }
            return ((ms << (WORKER_BITS + SEQ_BITS)) | (worker << SEQ_BITS) | seq) as i64;
        }
        std::thread::sleep(std::time::Duration::from_millis(1));
    }
}
