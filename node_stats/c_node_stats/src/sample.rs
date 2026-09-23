use std::collections::HashMap;
use std::time::{Duration, Instant};

#[derive(Clone, Debug, Default)]
pub struct IoSample {
    pub read_bytes: u64,
    pub write_bytes: u64,
}

#[derive(Clone, Debug, Default)]
pub struct NetSample {
    pub in_bytes: u64,
    pub out_bytes: u64,
}

#[derive(Clone, Debug)]
pub struct SampleSnapshot {
    pub at: Instant,
    pub disks: HashMap<String, IoSample>,
    pub net: NetSample,
}

impl SampleSnapshot {
    pub fn new(at: Instant, disks: HashMap<String, IoSample>, net: NetSample) -> Self {
        Self { at, disks, net }
    }

    pub fn elapsed(&self, prev: &Self) -> Duration {
        self.at.duration_since(prev.at)
    }
}

pub fn disk_bps(prev: &IoSample, cur: &IoSample, dt: Duration) -> (f64, f64) {
    let secs = dt.as_secs_f64();
    if secs <= 0.0 {
        return (0.0, 0.0);
    }
    (
        cur.read_bytes.saturating_sub(prev.read_bytes) as f64 / secs,
        cur.write_bytes.saturating_sub(prev.write_bytes) as f64 / secs,
    )
}

pub fn net_bps(prev: &NetSample, cur: &NetSample, dt: Duration) -> (f64, f64) {
    let secs = dt.as_secs_f64();
    if secs <= 0.0 {
        return (0.0, 0.0);
    }
    (
        cur.in_bytes.saturating_sub(prev.in_bytes) as f64 / secs,
        cur.out_bytes.saturating_sub(prev.out_bytes) as f64 / secs,
    )
}
