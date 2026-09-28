use anyhow::{bail, Context, Result};
use serde_json::Value;
use std::path::{Path, PathBuf};
use std::process::Stdio;
use tokio::process::Command;

use super::proxy::proxy_env;
use super::structure::Chapter;

pub struct YtdlpMeta {
    pub title: String,
    pub duration_sec: u32,
    pub description: String,
    pub chapters: Vec<Chapter>,
}

pub async fn ytdlp_meta(url: &str) -> Result<YtdlpMeta> {
    let bin = ytdlp_bin();
    let mut cmd = Command::new(&bin);
    cmd.arg("--skip-download")
        .arg("--dump-single-json")
        .arg("--no-playlist")
        .arg(url)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    apply_proxy(&mut cmd);
    let out = cmd.output().await.context("yt-dlp meta spawn")?;
    if !out.status.success() {
        bail!("yt-dlp meta failed: {}", String::from_utf8_lossy(&out.stderr).trim());
    }
    let v: Value = serde_json::from_slice(&out.stdout).context("yt-dlp json")?;
    let title = v.get("title").and_then(|x| x.as_str()).unwrap_or("").to_string();
    let duration_sec = v.get("duration").and_then(|x| x.as_u64()).unwrap_or(0) as u32;
    let description = v.get("description").and_then(|x| x.as_str()).unwrap_or("").to_string();
    Ok(YtdlpMeta { title, duration_sec, description, chapters: chapters_from_json(&v) })
}

pub async fn ytdlp_fetch_vtt(url: &str, out_dir: &Path) -> Result<PathBuf> {
    let bin = ytdlp_bin();
    let template = out_dir.join("%(id)s.%(ext)s");
    let mut cmd = Command::new(&bin);
    cmd.arg("--skip-download")
        .arg("--write-sub")
        .arg("--write-auto-sub")
        .arg("--sub-langs")
        .arg("en,id")
        .arg("--sub-format")
        .arg("vtt/best")
        .arg("--no-playlist")
        .arg("-o")
        .arg(template.to_string_lossy().as_ref())
        .arg(url)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    apply_proxy(&mut cmd);
    let out = cmd.output().await.context("yt-dlp subs spawn")?;
    if !out.status.success() {
        bail!("yt-dlp subs failed: {}", String::from_utf8_lossy(&out.stderr).trim());
    }
    for entry in std::fs::read_dir(out_dir).context("read temp dir")? {
        let path = entry?.path();
        if path.extension().and_then(|e| e.to_str()) == Some("vtt") {
            return Ok(path);
        }
    }
    bail!("no vtt file produced")
}

fn ytdlp_bin() -> String {
    std::env::var("YTDLP_BIN").ok().filter(|s| !s.trim().is_empty()).unwrap_or_else(|| "yt-dlp".to_string())
}

fn apply_proxy(cmd: &mut Command) {
    for (k, v) in proxy_env() {
        cmd.env(k, v);
    }
}

fn chapters_from_json(v: &Value) -> Vec<Chapter> {
    let mut out = Vec::new();
    if let Some(arr) = v.get("chapters").and_then(|c| c.as_array()) {
        for ch in arr {
            let title = ch.get("title").and_then(|x| x.as_str()).unwrap_or("").trim();
            let start = ch.get("start_time").and_then(|x| x.as_f64()).unwrap_or(0.0) as u32;
            if !title.is_empty() {
                out.push(Chapter { title: title.to_string(), start_sec: start, synthetic: false });
            }
        }
    }
    out
}