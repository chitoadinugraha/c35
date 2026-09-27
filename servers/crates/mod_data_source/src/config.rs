use std::time::Duration;

pub const SOURCE_KIND_GOOGLE_SHEET: &str = "google_sheet";

pub const DATA_SOURCE_SMALL_ROW_LIMIT: usize = 50;
pub const DATA_SOURCE_RETRIEVE_LIMIT: usize = 8;
pub const DATA_SOURCE_CHUNK_CANDIDATE_LIMIT: i64 = 48;
pub const EMBED_MIN_CHARS: usize = 8;
pub const EMBED_DIMS: i32 = 768;

pub fn data_source_sync_ttl_sec() -> i64 {
    std::env::var("DATA_SOURCE_SYNC_TTL_SEC")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(120)
}

pub fn data_source_retrieve_limit() -> usize {
    std::env::var("DATA_SOURCE_RETRIEVE_LIMIT")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(DATA_SOURCE_RETRIEVE_LIMIT)
}

pub fn data_source_retrieve_timeout() -> Duration {
    let sec = std::env::var("DATA_SOURCE_RETRIEVE_TIMEOUT_SEC")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(4);
    Duration::from_secs(sec.max(1))
}

pub const DATA_SOURCE_BG_TICK_SEC_DEFAULT: u64 = 30;
pub const DATA_SOURCE_BG_BATCH_DEFAULT: i64 = 8;
pub const DATA_SOURCE_BG_MAX_CONCURRENT_DEFAULT: usize = 2;
pub const DATA_SOURCE_SYNCING_STUCK_SEC: i64 = 300;

pub fn data_source_bg_enabled() -> bool {
    match std::env::var("DATA_SOURCE_BG_ENABLED").map(|s| s.trim().to_ascii_lowercase()) {
        Ok(v) if v == "0" || v == "false" || v == "no" => false,
        _ => true,
    }
}

pub fn data_source_bg_tick_sec() -> u64 {
    std::env::var("DATA_SOURCE_BG_TICK_SEC")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(DATA_SOURCE_BG_TICK_SEC_DEFAULT)
        .max(5)
}

pub fn data_source_bg_batch() -> i64 {
    std::env::var("DATA_SOURCE_BG_BATCH")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(DATA_SOURCE_BG_BATCH_DEFAULT)
        .clamp(1, 64)
}

pub fn data_source_bg_max_concurrent() -> usize {
    std::env::var("DATA_SOURCE_BG_MAX_CONCURRENT")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .unwrap_or(DATA_SOURCE_BG_MAX_CONCURRENT_DEFAULT)
        .clamp(1, 16)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bg_defaults_when_unset() {
        std::env::remove_var("DATA_SOURCE_BG_ENABLED");
        std::env::remove_var("DATA_SOURCE_BG_TICK_SEC");
        assert!(data_source_bg_enabled());
        assert_eq!(data_source_bg_tick_sec(), DATA_SOURCE_BG_TICK_SEC_DEFAULT);
    }
}
