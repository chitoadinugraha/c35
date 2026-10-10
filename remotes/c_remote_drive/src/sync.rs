use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::time::{Duration, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use tracing::{info, warn};

use crate::sync_wake;
use crate::vfs::VfsDriveManager;

#[derive(Debug, Deserialize)]
pub struct RemoteFile {
    pub path: String,
    pub hash: String,
    pub size: i64,
    #[serde(default)]
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
struct ManifestEntry {
    hash: String,
    size: u64,
    mtime_ms: u64,
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct SyncManifest {
    #[serde(default)]
    remote_since_ms: u64,
    #[serde(default)]
    paths: HashMap<String, ManifestEntry>,
}

#[derive(Debug, Deserialize)]
struct RemoteChange {
    path: String,
    hash: String,
    #[allow(dead_code)]
    size: i64,
    #[allow(dead_code)]
    updated_ts_ms: i64,
    deleted: bool,
}

#[derive(Debug, Deserialize)]
struct ChangesPage {
    entries: Vec<RemoteChange>,
    next_since_ms: i64,
    has_more: bool,
}

fn file_stamp(meta: &std::fs::Metadata) -> (u64, u64) {
    let size = meta.len();
    let mtime_ms = meta
        .modified()
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);
    (size, mtime_ms)
}

fn manifest_entry_from_value(v: serde_json::Value) -> Option<ManifestEntry> {
    match v {
        serde_json::Value::String(hash) => Some(ManifestEntry {
            hash,
            size: 0,
            mtime_ms: 0,
        }),
        serde_json::Value::Object(_) => serde_json::from_value(v).ok(),
        _ => None,
    }
}

fn load_manifest_file(path: &Path) -> SyncManifest {
    let raw = match std::fs::read_to_string(path) {
        Ok(s) => s,
        Err(_) => return SyncManifest::default(),
    };
    let root: serde_json::Value = match serde_json::from_str(&raw) {
        Ok(v) => v,
        Err(_) => return SyncManifest::default(),
    };
    let paths_val = root
        .get("paths")
        .cloned()
        .unwrap_or(serde_json::Value::Object(Default::default()));
    let paths_obj = match paths_val.as_object() {
        Some(o) => o,
        None => return SyncManifest::default(),
    };
    let mut paths = HashMap::new();
    for (k, v) in paths_obj {
        if let Some(entry) = manifest_entry_from_value(v.clone()) {
            paths.insert(k.clone(), entry);
        }
    }
    let remote_since_ms = root
        .get("remote_since_ms")
        .and_then(|v| v.as_u64())
        .unwrap_or(0);
    SyncManifest {
        remote_since_ms,
        paths,
    }
}

pub struct SyncEngine {
    client: reqwest::Client,
    base_url: String,
    token: String,
    local_root: PathBuf,
    manifest_path: PathBuf,
}

/// Local sync state lives beside the drive cache, not on A:\.
pub fn sync_manifest_path(local_root: &Path) -> PathBuf {
    local_root
        .parent()
        .map(|p| p.join("sync_manifest.json"))
        .unwrap_or_else(|| local_root.join(".alienai_sync_manifest.json"))
}

impl SyncEngine {
    pub fn from_session(session_key: &str, file_base_url: &str, local_root: PathBuf) -> Self {
        migrate_legacy_manifest(&local_root);
        Self {
            client: reqwest::Client::builder().build().unwrap_or_default(),
            base_url: file_base_url.trim_end_matches('/').to_string(),
            token: session_key.trim().to_string(),
            local_root: local_root.clone(),
            manifest_path: sync_manifest_path(&local_root),
        }
    }

    pub fn from_env(local_root: PathBuf) -> Option<Self> {
        let token = std::env::var("SESSION_TOKEN").ok().filter(|s| !s.is_empty())?;
        let base_url = std::env::var("FILE_SERVICE_URL").unwrap_or_else(|_| "https://f.alienai.id".into());
        Some(Self::from_session(&token, &base_url, local_root))
    }

    pub async fn run_loop(&self) {
        let wake = sync_wake::wake_notify();
        let mut idle_cycles = 0u32;
        loop {
            let changed = match self.sync_cycle().await {
                Ok(n) => n,
                Err(e) => {
                    warn!("VFS sync cycle: {e:#}");
                    0
                }
            };
            idle_cycles = if changed > 0 { 0 } else { idle_cycles.saturating_add(1) };
            let sleep_secs = if idle_cycles >= 4 {
                1800
            } else if idle_cycles >= 2 {
                300
            } else if idle_cycles >= 1 {
                60
            } else {
                30
            };
            tokio::select! {
                _ = wake.notified() => {}
                _ = tokio::time::sleep(Duration::from_secs(sleep_secs)) => {}
            }
        }
    }

    async fn sync_cycle(&self) -> anyhow::Result<usize> {
        let mut n = 0;
        n += self.pull_remote_delta().await?;
        let pending = sync_wake::pending_take();
        if !pending.is_empty() {
            n += self.push_paths(&pending).await?;
        } else if sync_wake::should_full_push_scan() {
            let remote_files = self.list_remote().await?;
            n += self.push_local_changes(&remote_files).await?;
        }
        let remote_files = self.list_remote().await?;
        n += self.propagate_local_deletions(&remote_files).await?;
        Ok(n)
    }

    fn load_manifest(&self) -> SyncManifest {
        load_manifest_file(&self.manifest_path)
    }

    fn save_manifest(&self, manifest: &SyncManifest) -> anyhow::Result<()> {
        let data = serde_json::to_vec_pretty(manifest)?;
        std::fs::write(&self.manifest_path, data)?;
        Ok(())
    }

    async fn pull_remote_delta(&self) -> anyhow::Result<usize> {
        let mut manifest = self.load_manifest();
        let mut since = manifest.remote_since_ms as i64;
        let mut n = 0usize;
        let mut used_delta = false;
        loop {
            match self.list_remote_changes(since, 500).await {
                Ok(page) => {
                    used_delta = true;
                    for entry in &page.entries {
                        n += self.apply_remote_change(entry, &mut manifest).await?;
                    }
                    since = since.max(page.next_since_ms);
                    manifest.remote_since_ms = since.max(0) as u64;
                    self.save_manifest(&manifest)?;
                    if !page.has_more {
                        break;
                    }
                }
                Err(e) => {
                    let msg = e.to_string();
                    if msg.contains("404") || msg.contains("Not Found") {
                        warn!("VFS: /v1/file/changes unavailable; using full tree pull");
                        let files = self.list_remote().await?;
                        n += self.pull_remote_changes(&files).await?;
                        if let Ok(cursor) = self.fetch_sync_cursor().await {
                            manifest.remote_since_ms = cursor.max(0) as u64;
                            self.save_manifest(&manifest)?;
                        }
                    } else {
                        return Err(e);
                    }
                    break;
                }
            }
        }
        if used_delta && manifest.remote_since_ms == 0 {
            if let Ok(cursor) = self.fetch_sync_cursor().await {
                manifest.remote_since_ms = cursor.max(0) as u64;
                self.save_manifest(&manifest)?;
            }
        }
        Ok(n)
    }

    async fn apply_remote_change(
        &self,
        entry: &RemoteChange,
        manifest: &mut SyncManifest,
    ) -> anyhow::Result<usize> {
        let rel = normalize_rel_path(&entry.path);
        let rel_path = Path::new(&rel);
        if VfsDriveManager::is_sync_skipped(rel_path) {
            return Ok(0);
        }
        let abs = self.local_root.join(&rel);
        if entry.deleted {
            if abs.is_file() {
                let _ = tokio::fs::remove_file(&abs).await;
            }
            manifest.paths.remove(&rel);
            info!("VFS pulled delete {}", rel);
            return Ok(1);
        }
        let need = if abs.exists() {
            let data = tokio::fs::read(&abs).await?;
            blake3::hash(&data).to_hex().to_string() != entry.hash
        } else {
            true
        };
        if !need {
            if let Ok(meta) = tokio::fs::metadata(&abs).await {
                let (size, mtime_ms) = file_stamp(&meta);
                manifest.paths.insert(
                    rel.clone(),
                    ManifestEntry {
                        hash: entry.hash.clone(),
                        size,
                        mtime_ms,
                    },
                );
            }
            return Ok(0);
        }
        if let Some(parent) = abs.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        let url = format!("{}/fs/{}", self.base_url, entry.hash);
        let bytes = self.fetch_blob(&url).await?;
        tokio::fs::write(&abs, &bytes).await?;
        let (size, mtime_ms) = tokio::fs::metadata(&abs)
            .await
            .map(|m| file_stamp(&m))
            .unwrap_or((bytes.len() as u64, 0));
        manifest.paths.insert(
            rel.clone(),
            ManifestEntry {
                hash: entry.hash.clone(),
                size,
                mtime_ms,
            },
        );
        info!("VFS pulled {}", rel);
        Ok(1)
    }

    async fn push_paths(&self, paths: &HashSet<String>) -> anyhow::Result<usize> {
        let remote: HashMap<String, String> = self
            .list_remote()
            .await?
            .into_iter()
            .map(|f| (normalize_rel_path(&f.path), f.hash))
            .collect();
        let mut manifest = self.load_manifest();
        let mut n = 0usize;
        for rel_s in paths {
            let path = self.local_root.join(rel_s);
            if VfsDriveManager::is_internal_path(Path::new(rel_s)) {
                continue;
            }
            if !path.is_file() {
                continue;
            }
            let meta = tokio::fs::metadata(&path).await?;
            let (size, mtime_ms) = file_stamp(&meta);
            if let Some(entry) = manifest.paths.get(rel_s) {
                if entry.size == size
                    && entry.mtime_ms == mtime_ms
                    && remote.get(rel_s).map(|h| h.as_str()) == Some(entry.hash.as_str())
                {
                    continue;
                }
            }
            let data = tokio::fs::read(&path).await?;
            let hash = blake3::hash(&data).to_hex().to_string();
            if remote.get(rel_s).map(|h| h.as_str()) == Some(hash.as_str()) {
                manifest.paths.insert(
                    rel_s.clone(),
                    ManifestEntry {
                        hash: hash.clone(),
                        size,
                        mtime_ms,
                    },
                );
                continue;
            }
            self.lock_path(rel_s).await?;
            self.upload(rel_s, data).await?;
            manifest.paths.insert(
                rel_s.clone(),
                ManifestEntry {
                    hash,
                    size,
                    mtime_ms,
                },
            );
            info!("VFS pushed {}", rel_s);
            n += 1;
        }
        let _ = self.save_manifest(&manifest);
        Ok(n)
    }

    pub async fn pull_remote_changes(&self, files: &[RemoteFile]) -> anyhow::Result<usize> {
        let remote_paths: HashSet<String> = files.iter().map(|f| normalize_rel_path(&f.path)).collect();
        let mut manifest = self.load_manifest();
        let mut n = 0;
        for f in files {
            let rel = normalize_rel_path(&f.path);
            let rel_path = Path::new(&rel);
            if VfsDriveManager::is_sync_skipped(rel_path) {
                continue;
            }
            let abs = self.local_root.join(&rel);
            if let Some(entry) = manifest.paths.get(&rel) {
                if entry.hash == f.hash {
                    if let Ok(meta) = tokio::fs::metadata(&abs).await {
                        let (size, mtime_ms) = file_stamp(&meta);
                        if size == entry.size && mtime_ms == entry.mtime_ms {
                            continue;
                        }
                    }
                }
            }
            let need = if abs.exists() {
                let data = tokio::fs::read(&abs).await?;
                blake3::hash(&data).to_hex().to_string() != f.hash
            } else {
                true
            };
            if !need {
                if let Ok(meta) = tokio::fs::metadata(&abs).await {
                    let (size, mtime_ms) = file_stamp(&meta);
                    manifest.paths.insert(
                        rel.clone(),
                        ManifestEntry {
                            hash: f.hash.clone(),
                            size,
                            mtime_ms,
                        },
                    );
                }
                continue;
            }
            if let Some(parent) = abs.parent() {
                tokio::fs::create_dir_all(parent).await?;
            }
            let url = if !f.url.is_empty() { f.url.clone() } else { format!("{}/fs/{}", self.base_url, f.hash) };
            let bytes = self.fetch_blob(&url).await?;
            tokio::fs::write(&abs, &bytes).await?;
            let (size, mtime_ms) = tokio::fs::metadata(&abs).await.map(|m| file_stamp(&m)).unwrap_or((bytes.len() as u64, 0));
            manifest.paths.insert(
                rel.clone(),
                ManifestEntry {
                    hash: f.hash.clone(),
                    size,
                    mtime_ms,
                },
            );
            info!("VFS pulled {}", rel);
            n += 1;
        }
        let _ = self.save_manifest(&manifest);
        n += self.prune_local_orphans(&remote_paths).await?;
        Ok(n)
    }

    async fn prune_local_orphans(&self, remote_paths: &HashSet<String>) -> anyhow::Result<usize> {
        let mut removed = 0usize;
        let mut manifest = self.load_manifest();
        let mut stack = vec![self.local_root.clone()];
        while let Some(dir) = stack.pop() {
            let mut rd = match tokio::fs::read_dir(&dir).await {
                Ok(rd) => rd,
                Err(_) => continue,
            };
            while let Ok(Some(ent)) = rd.next_entry().await {
                let path = ent.path();
                let rel = path.strip_prefix(&self.local_root).unwrap_or(&path);
                if VfsDriveManager::is_internal_path(rel) {
                    continue;
                }
                let ft = ent.file_type().await?;
                if ft.is_dir() {
                    stack.push(path);
                    continue;
                }
                if !ft.is_file() {
                    continue;
                }
                let rel_s = rel.to_string_lossy().replace('\\', "/");
                if !remote_paths.contains(&rel_s) && manifest.paths.contains_key(&rel_s) {
                    tokio::fs::remove_file(&path).await?;
                    manifest.paths.remove(&rel_s);
                    info!("VFS pruned local orphan {}", rel_s);
                    removed += 1;
                }
            }
        }
        let _ = self.save_manifest(&manifest);
        Ok(removed)
    }

    pub async fn push_local_changes(&self, files: &[RemoteFile]) -> anyhow::Result<usize> {
        let remote: HashMap<String, String> = files
            .iter()
            .map(|f| (normalize_rel_path(&f.path), f.hash.clone()))
            .collect();
        let mut manifest = self.load_manifest();
        let mut n = 0;
        let mut stack = vec![self.local_root.clone()];
        while let Some(dir) = stack.pop() {
            let mut rd = match tokio::fs::read_dir(&dir).await {
                Ok(rd) => rd,
                Err(_) => continue,
            };
            while let Ok(Some(ent)) = rd.next_entry().await {
                let path = ent.path();
                let rel = path.strip_prefix(&self.local_root).unwrap_or(&path);
                if VfsDriveManager::is_internal_path(rel) {
                    continue;
                }
                let ft = ent.file_type().await?;
                if ft.is_dir() {
                    stack.push(path);
                    continue;
                }
                if !ft.is_file() {
                    continue;
                }
                let rel_s = rel.to_string_lossy().replace('\\', "/");
                let meta = tokio::fs::metadata(&path).await?;
                let (size, mtime_ms) = file_stamp(&meta);
                if let Some(entry) = manifest.paths.get(&rel_s) {
                    if entry.size == size
                        && entry.mtime_ms == mtime_ms
                        && remote.get(&rel_s).map(|h| h.as_str()) == Some(entry.hash.as_str())
                    {
                        continue;
                    }
                }
                let data = tokio::fs::read(&path).await?;
                let hash = blake3::hash(&data).to_hex().to_string();
                if remote.get(&rel_s).map(|h| h.as_str()) == Some(hash.as_str()) {
                    manifest.paths.insert(
                        rel_s.clone(),
                        ManifestEntry {
                            hash: hash.clone(),
                            size,
                            mtime_ms,
                        },
                    );
                    continue;
                }
                self.lock_path(&rel_s).await?;
                self.upload(&rel_s, data).await?;
                manifest.paths.insert(
                    rel_s.clone(),
                    ManifestEntry {
                        hash,
                        size,
                        mtime_ms,
                    },
                );
                info!("VFS pushed {}", rel_s);
                n += 1;
            }
        }
        let _ = self.save_manifest(&manifest);
        Ok(n)
    }

    pub async fn propagate_local_deletions(&self, files: &[RemoteFile]) -> anyhow::Result<usize> {
        let remote: HashSet<String> = files.iter().map(|f| normalize_rel_path(&f.path)).collect();
        let mut manifest = self.load_manifest();
        let mut deleted = 0usize;
        for path in manifest.paths.keys().cloned().collect::<Vec<_>>() {
            let local = self.local_root.join(&path);
            if !local.exists() && remote.contains(&path) {
                self.delete_remote(&path).await?;
                manifest.paths.remove(&path);
                info!("VFS deleted remote {}", path);
                deleted += 1;
            }
        }
        let _ = self.save_manifest(&manifest);
        Ok(deleted)
    }

    async fn fetch_blob(&self, url: &str) -> anyhow::Result<Vec<u8>> {
        let res = self
            .client
            .get(url)
            .header("X-Device-Session", &self.token)
            .send()
            .await?
            .error_for_status()?;
        Ok(res.bytes().await?.to_vec())
    }

    async fn lock_path(&self, rel_path: &str) -> anyhow::Result<()> {
        let url = format!("{}/v1/file/lock", self.base_url);
        let body = serde_json::json!({ "path": format!("/{rel_path}") });
        let res = self.client.post(url).header("X-Device-Session", &self.token).json(&body).send().await?;
        if res.status().is_success() || res.status().as_u16() == 423 {
            return Ok(());
        }
        anyhow::bail!("lock {rel_path} {}", res.status())
    }

    async fn delete_remote(&self, rel_path: &str) -> anyhow::Result<()> {
        let url = format!("{}/v1/file/delete", self.base_url);
        let body = serde_json::json!({ "path": format!("/{rel_path}") });
        let res = self.client.post(url).header("X-Device-Session", &self.token).json(&body).send().await?;
        if !res.status().is_success() {
            anyhow::bail!("delete {rel_path} {}", res.status());
        }
        Ok(())
    }

    async fn list_remote(&self) -> anyhow::Result<Vec<RemoteFile>> {
        let url = format!("{}/v1/file/tree", self.base_url);
        let res = self.client.get(url).header("X-Device-Session", &self.token).send().await?;
        if !res.status().is_success() {
            anyhow::bail!("file tree {}", res.status());
        }
        Ok(res.json().await?)
    }

    async fn list_remote_changes(&self, since_ms: i64, limit: i64) -> anyhow::Result<ChangesPage> {
        let url = format!(
            "{}/v1/file/changes?since_ms={}&limit={}",
            self.base_url,
            since_ms.max(0),
            limit.clamp(1, 2000)
        );
        let res = self.client.get(url).header("X-Device-Session", &self.token).send().await?;
        if !res.status().is_success() {
            anyhow::bail!("file changes {}", res.status());
        }
        Ok(res.json().await?)
    }

    async fn fetch_sync_cursor(&self) -> anyhow::Result<i64> {
        let url = format!("{}/v1/file/sync_cursor", self.base_url);
        let res = self.client.get(url).header("X-Device-Session", &self.token).send().await?;
        if !res.status().is_success() {
            anyhow::bail!("file sync_cursor {}", res.status());
        }
        let body: serde_json::Value = res.json().await?;
        Ok(body.get("since_ms").and_then(|v| v.as_i64()).unwrap_or(0))
    }

    async fn upload(&self, rel_path: &str, data: Vec<u8>) -> anyhow::Result<()> {
        let url = format!("{}/v1/file/upload", self.base_url);
        let name = Path::new(rel_path).file_name().and_then(|s| s.to_str()).unwrap_or(rel_path);
        let res = self
            .client
            .post(url)
            .header("X-Device-Session", &self.token)
            .header("x-file-path", format!("/{rel_path}"))
            .header("x-file-name", name)
            .body(data)
            .send()
            .await?;
        if !res.status().is_success() {
            anyhow::bail!("upload {rel_path} {}", res.status());
        }
        Ok(())
    }
}

fn normalize_rel_path(path: &str) -> String {
    path.trim_start_matches('/').replace('\\', "/")
}

fn migrate_legacy_manifest(local_root: &Path) {
    let legacy = local_root.join(".alienai_sync_manifest.json");
    if !legacy.exists() {
        return;
    }
    let dest = sync_manifest_path(local_root);
    if let Some(parent) = dest.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    if dest.exists() {
        let _ = std::fs::remove_file(&legacy);
    } else {
        let _ = std::fs::rename(&legacy, &dest);
    }
}

#[cfg(test)]
mod session_tests {
    use super::*;

    #[test]
    fn from_session_uses_device_key_and_file_base() {
        let root = std::env::temp_dir().join("alienai_sync_test").join("drive_a");
        let engine = SyncEngine::from_session("tok_device_abc", "https://ai.alienai.id", root.clone());
        assert_eq!(engine.token, "tok_device_abc");
        assert_eq!(engine.base_url, "https://ai.alienai.id");
        assert_eq!(engine.local_root, root);
        assert_eq!(engine.manifest_path, root.parent().unwrap().join("sync_manifest.json"));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_rel_strips_leading_slash() {
        assert_eq!(normalize_rel_path("/foo/bar.txt"), "foo/bar.txt");
        assert_eq!(normalize_rel_path("foo/bar.txt"), "foo/bar.txt");
    }

    #[test]
    fn drive_nudge_json_parses() {
        let cmd = "c35.drive:{\"since_ms\":12345}";
        let rest = cmd.strip_prefix("c35.drive:").unwrap();
        let v: serde_json::Value = serde_json::from_str(rest).unwrap();
        assert_eq!(v.get("since_ms").and_then(|x| x.as_i64()), Some(12345));
    }

    #[test]
    fn manifest_loads_legacy_hash_only_entries() {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("sync_manifest.json");
        std::fs::write(
            &path,
            r#"{"paths":{"a.txt":"abc123","b.txt":{"hash":"def456","size":10,"mtime_ms":99}}}"#,
        )
        .unwrap();
        let m = load_manifest_file(&path);
        assert_eq!(m.paths.get("a.txt").map(|e| e.hash.as_str()), Some("abc123"));
        assert_eq!(m.paths.get("a.txt").map(|e| e.size), Some(0));
        let b = m.paths.get("b.txt").unwrap();
        assert_eq!(b.hash, "def456");
        assert_eq!(b.size, 10);
        assert_eq!(b.mtime_ms, 99);
    }
}
