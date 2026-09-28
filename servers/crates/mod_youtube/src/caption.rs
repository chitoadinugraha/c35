use anyhow::{bail, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Segment {
    pub start_sec: f64,
    pub end_sec: f64,
    pub text: String,
}

pub fn parse_vtt_or_srt(body: &str) -> Result<Vec<Segment>> {
    let body = body.trim();
    if body.is_empty() {
        bail!("empty caption file");
    }
    if body.starts_with("WEBVTT") || body.contains("-->") {
        return Ok(parse_vtt(body));
    }
    parse_srt(body)
}

fn parse_vtt(body: &str) -> Vec<Segment> {
    let mut out = Vec::new();
    let lines: Vec<&str> = body.lines().collect();
    let mut i = 0;
    while i < lines.len() {
        let line = lines[i].trim();
        if line.contains("-->") {
            let (start, end) = parse_range(line);
            i += 1;
            let mut text = String::new();
            while i < lines.len() {
                let l = lines[i].trim();
                if l.is_empty() || l.contains("-->") {
                    break;
                }
                if !text.is_empty() {
                    text.push(' ');
                }
                text.push_str(l);
                i += 1;
            }
            if !text.is_empty() {
                out.push(Segment { start_sec: start, end_sec: end, text });
            }
            continue;
        }
        i += 1;
    }
    out
}

fn parse_srt(body: &str) -> Result<Vec<Segment>> {
    let mut out = Vec::new();
    for block in body.split("\n\n") {
        let lines: Vec<&str> = block.lines().map(str::trim).filter(|l| !l.is_empty()).collect();
        if lines.len() < 2 {
            continue;
        }
        let time_line = if lines[0].chars().all(|c| c.is_ascii_digit()) && lines.len() > 2 { lines[1] } else { lines[0] };
        if !time_line.contains("-->") {
            continue;
        }
        let (start, end) = parse_range(time_line);
        let text_start = if lines[0].chars().all(|c| c.is_ascii_digit()) { 2 } else { 1 };
        let text = lines[text_start..].join(" ");
        if !text.is_empty() {
            out.push(Segment { start_sec: start, end_sec: end, text });
        }
    }
    Ok(out)
}

fn parse_range(line: &str) -> (f64, f64) {
    let parts: Vec<&str> = line.split("-->").collect();
    if parts.len() != 2 {
        return (0.0, 0.0);
    }
    (parse_ts(parts[0].trim()), parse_ts(parts[1].trim().split_whitespace().next().unwrap_or("")))
}

fn parse_ts(s: &str) -> f64 {
    let s = s.replace(',', ".");
    let bits: Vec<&str> = s.split(':').collect();
    if bits.len() == 3 {
        let h = bits[0].parse::<f64>().unwrap_or(0.0);
        let m = bits[1].parse::<f64>().unwrap_or(0.0);
        let sec = bits[2].parse::<f64>().unwrap_or(0.0);
        return h * 3600.0 + m * 60.0 + sec;
    }
    if bits.len() == 2 {
        let m = bits[0].parse::<f64>().unwrap_or(0.0);
        let sec = bits[1].parse::<f64>().unwrap_or(0.0);
        return m * 60.0 + sec;
    }
    0.0
}

pub fn segments_text_range(segments: &[Segment], start_sec: f64, end_sec: f64, max_chars: usize) -> String {
    let mut out = String::new();
    for seg in segments {
        if seg.end_sec < start_sec || seg.start_sec > end_sec {
            continue;
        }
        let line = format!("[{:.0}s] {}\n", seg.start_sec, seg.text.trim());
        if out.chars().count() + line.chars().count() > max_chars {
            break;
        }
        out.push_str(&line);
    }
    out.trim().to_string()
}