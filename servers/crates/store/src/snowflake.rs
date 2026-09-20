use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

const EPOCH_MS: u64 = 1_704_067_200_000;
const WORKER_BITS: u64 = 10;
const SEQ_BITS: u64 = 12;
const MAX_SEQ: u64 = (1 << SEQ_BITS) - 1;
const WORKER_MASK: u64 = (1 << WORKER_BITS) - 1;

static SEQ: AtomicU64 = AtomicU64::new(0);
static LAST_MS: AtomicU64 = AtomicU64::new(0);

pub fn snowflake_id() -> i64 {
    let worker = std::env::var("C35_WORKER_ID")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(1)
        & WORKER_MASK;
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
