use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::time::Duration;

use serde::{Deserialize, Serialize};
use tracing::{info, warn};

use crate::vfs::VfsDriveManager;

#[derive(Debug, Deserialize)]
pub struct RemoteFile {
    pub path: String,
    pub hash: String,
    pub size: i64,
    #[serde(default)]
    pub url: String,
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct SyncManifest {
    paths: HashMap<String, String>,
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
        loop {
            if let Err(e) = self.pull_remote_changes().await {
                warn!("VFS pull: {e:#}");
            }
            if let Err(e) = self.push_local_changes().await {
                warn!("VFS push: {e:#}");
            }
            if let Err(e) = self.propagate_local_deletions().await {
                warn!("VFS delete push: {e:#}");
            }
            tokio::time::sleep(Duration::from_secs(30)).await;
        }
    }

    fn load_manifest(&self) -> SyncManifest {
        std::fs::read_to_string(&self.manifest_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    }

    fn save_manifest(&self, manifest: &SyncManifest) -> anyhow::Result<()> {
        let data = serde_json::to_vec_pretty(manifest)?;
        std::fs::write(&self.manifest_path, data)?;
        Ok(())
    }

    pub async fn pull_remote_changes(&self) -> anyhow::Result<usize> {
        let files = self.list_remote().await?;
        let remote_paths: HashSet<String> = files.iter().map(|f| normalize_rel_path(&f.path)).collect();
        let mut n = 0;
        for f in &files {
            let rel = normalize_rel_path(&f.path);
            let rel_path = Path::new(&rel);
            if VfsDriveManager::is_sync_skipped(rel_path) {
                continue;
            }
            let abs = self.local_root.join(&rel);
            let need = if abs.exists() {
                let data = tokio::fs::read(&abs).await?;
                blake3::hash(&data).to_hex().to_string() != f.hash
            } else {
                true
            };
            if !need {
                continue;
            }
            if let Some(parent) = abs.parent() {
                tokio::fs::create_dir_all(parent).await?;
            }
            let url = if !f.url.is_empty() { f.url.clone() } else { format!("{}/fs/{}", self.base_url, f.hash) };
            let bytes = self.client.get(url).send().await?.error_for_status()?.bytes().await?;
            tokio::fs::write(&abs, bytes).await?;
            info!("VFS pulled {}", rel);
            n += 1;
        }
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

    pub async fn push_local_changes(&self) -> anyhow::Result<usize> {
        let remote: HashMap<String, String> = self
            .list_remote()
            .await?
            .into_iter()
            .map(|f| (normalize_rel_path(&f.path), f.hash))
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
                let data = tokio::fs::read(&path).await?;
                let hash = blake3::hash(&data).to_hex().to_string();
                let rel_s = rel.to_string_lossy().replace('\\', "/");
                if remote.get(&rel_s).map(|h| h.as_str()) == Some(hash.as_str()) {
                    manifest.paths.insert(rel_s.clone(), hash.clone());
                    continue;
                }
                self.lock_path(&rel_s).await?;
                self.upload(&rel_s, data).await?;
                manifest.paths.insert(rel_s.clone(), hash);
                info!("VFS pushed {}", rel_s);
                n += 1;
            }
        }
        let _ = self.save_manifest(&manifest);
        Ok(n)
    }

    pub async fn propagate_local_deletions(&self) -> anyhow::Result<usize> {
        let remote: HashSet<String> = self
            .list_remote()
            .await?
            .into_iter()
            .map(|f| normalize_rel_path(&f.path))
            .collect();
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
}
