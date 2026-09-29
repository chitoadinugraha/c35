use std::path::PathBuf;
use tokio::sync::Mutex;
use tracing::{info, warn};
use crate::update::{extract_zip, ReleaseRes};
use crate::version::agent_build;

pub const FFMPEG_VERSION_PLATFORM: &str = "ffmpeg-windows";
static FFMPEG_DOWNLOAD_LOCK: Mutex<()> = Mutex::const_new(());
const VERSION_FILE: &str = "version";
const FFMPEG_EXE: &str = "ffmpeg.exe";

pub fn ffmpeg_root() -> PathBuf {
    std::env::var("LOCALAPPDATA")
        .map(|a| PathBuf::from(a).join("AlienAI").join("ffmpeg"))
        .unwrap_or_else(|_| PathBuf::from(".alienai_ffmpeg"))
}

fn ffmpeg_staging_dir(version: i64) -> PathBuf { ffmpeg_root().join("staging").join(version.to_string()) }
fn ffmpeg_ready_marker(version: i64) -> PathBuf { ffmpeg_staging_dir(version).join(".ready") }

pub fn ffmpeg_local_version() -> i64 {
    std::fs::read_to_string(ffmpeg_root().join(VERSION_FILE)).ok().and_then(|s| s.trim().parse().ok()).unwrap_or(0)
}

pub fn ffmpeg_exe_path() -> PathBuf { ffmpeg_root().join(FFMPEG_EXE) }

pub fn ffmpeg_release_requires_update(local: i64, rel: &ReleaseRes) -> bool {
    rel.version > local && (rel.min <= 0 || agent_build() >= rel.min)
}

pub async fn ffmpeg_poll(base_url: &str) -> Result<Option<ReleaseRes>, anyhow::Error> {
    let url = format!("{}/version/{}", base_url.trim_end_matches('/'), FFMPEG_VERSION_PLATFORM);
    let res = reqwest::Client::new().get(&url).send().await?;
    if !res.status().is_success() { return Ok(None); }
    let body: ReleaseRes = res.json().await?;
    Ok(ffmpeg_release_requires_update(ffmpeg_local_version(), &body).then_some(body))
}

pub async fn ffmpeg_download(rel: &ReleaseRes) -> Result<(), anyhow::Error> {
    let _dl = FFMPEG_DOWNLOAD_LOCK.lock().await;
    if ffmpeg_local_version() >= rel.version { return Ok(()); }
    let hash = rel.hash.as_deref().filter(|h| !h.is_empty()).ok_or_else(|| anyhow::anyhow!("missing hash"))?;
    let staging = ffmpeg_staging_dir(rel.version);
    if staging.exists() { let _ = std::fs::remove_dir_all(&staging); }
    std::fs::create_dir_all(&staging)?;
    let bytes = reqwest::Client::new().get(&rel.url).send().await?.bytes().await?;
    if blake3::hash(&bytes).to_hex().to_string() != hash.to_lowercase() { anyhow::bail!("blake3 mismatch"); }
    let zip_path = staging.join("bundle.zip");
    std::fs::write(&zip_path, &bytes)?;
    extract_zip(&zip_path, &staging)?;
    let _ = std::fs::remove_file(&zip_path);
    std::fs::write(ffmpeg_ready_marker(rel.version), b"ok")?;
    ffmpeg_apply(rel.version)?;
    info!(version = rel.version, "ffmpeg installed");
    Ok(())
}

fn ffmpeg_apply(version: i64) -> Result<(), anyhow::Error> {
    let staging = ffmpeg_staging_dir(version);
    let root = ffmpeg_root();
    std::fs::create_dir_all(&root)?;
    for name in [FFMPEG_EXE, "ffprobe.exe"] {
        let src = staging.join(name);
        if src.is_file() { std::fs::copy(&src, root.join(name))?; }
    }
    if !ffmpeg_exe_path().is_file() { anyhow::bail!("ffmpeg.exe missing"); }
    std::fs::write(root.join(VERSION_FILE), version.to_string())?;
    let _ = std::fs::remove_dir_all(&staging);
    Ok(())
}

pub fn trigger_background_ffmpeg_update(base_url: String) {
    tokio::spawn(async move {
        match ffmpeg_poll(&base_url).await {
            Ok(Some(rel)) => { if let Err(e) = ffmpeg_download(&rel).await { warn!("ffmpeg download: {e}"); } }
            Ok(None) => {}
            Err(e) => warn!("ffmpeg poll: {e}"),
        }
    });
}

pub async fn ffmpeg_tick(base_url: &str) {
    if let Ok(Some(rel)) = ffmpeg_poll(base_url).await {
        if let Err(e) = ffmpeg_download(&rel).await { warn!("ffmpeg tick: {e}"); }
    }
}