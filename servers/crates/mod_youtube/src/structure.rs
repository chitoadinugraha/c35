use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chapter {
    pub title: String,
    pub start_sec: u32,
    #[serde(default)]
    pub synthetic: bool,
}

pub fn chapters_from_description(desc: &str) -> Vec<Chapter> {
    let mut out = Vec::new();
    for line in desc.lines() {
        let line = line.trim();
        if line.len() < 4 {
            continue;
        }
        let (ts, title) = split_timestamp_prefix(line);
        if title.is_empty() {
            continue;
        }
        if let Some(sec) = ts {
            out.push(Chapter { title, start_sec: sec, synthetic: false });
        }
    }
    out
}

pub fn synthetic_chapters(duration_sec: u32, step_sec: u32) -> Vec<Chapter> {
    if duration_sec == 0 {
        return vec![];
    }
    let step = step_sec.max(60);
    let mut out = Vec::new();
    let mut t = 0u32;
    let mut n = 1u32;
    while t < duration_sec {
        out.push(Chapter { title: format!("Part {}", n), start_sec: t, synthetic: true });
        t += step;
        n += 1;
    }
    out
}

fn split_timestamp_prefix(line: &str) -> (Option<u32>, String) {
    let parts: Vec<&str> = line.splitn(2, char::is_whitespace).collect();
    if parts.is_empty() {
        return (None, String::new());
    }
    let head = parts[0];
    if !head.contains(':') {
        return (None, String::new());
    }
    let title = parts.get(1).map(|s| s.trim()).unwrap_or("").to_string();
    if title.is_empty() {
        return (None, String::new());
    }
    (parse_hms(head), title)
}

fn parse_hms(s: &str) -> Option<u32> {
    let bits: Vec<&str> = s.split(':').collect();
    match bits.len() {
        2 => {
            let m = bits[0].parse::<u32>().ok()?;
            let sec = bits[1].parse::<u32>().ok()?;
            Some(m * 60 + sec)
        }
        3 => {
            let h = bits[0].parse::<u32>().ok()?;
            let m = bits[1].parse::<u32>().ok()?;
            let sec = bits[2].parse::<u32>().ok()?;
            Some(h * 3600 + m * 60 + sec)
        }
        _ => None,
    }
}