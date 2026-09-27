from pathlib import Path
ROOT = Path(r"D:\c35\remotes\c_remote_drive\src")

def patch_vfs_winfsp():
    p = ROOT / "vfs_winfsp.rs"
    t = p.read_text(encoding="utf-8")
    t = t.replace("use c_remote_drive::vfs::VfsDriveManager;", "use crate::vfs::VfsDriveManager;")
    t = t.replace("c_remote_drive::vfs_winfsp_mount::start_winfsp_volume", "crate::vfs_winfsp_mount::start_winfsp_volume")
    old = """    pub fn label(&self) -> String {
        let pct = if self.limit_bytes == 0 {
            0
        } else {
            ((self.used_bytes as f64 / self.limit_bytes as f64) * 100.0).round() as u64
        };
        format!(\"Alien AI · {pct}% used\")
    }"""
    new = """    pub fn label(&self) -> String {
        \"Alien AI\".to_string()
    }"""
    if old in t:
        t = t.replace(old, new)
    t = t.replace("/v1/device/storage", "/v1/agent/storage")
    t = t.replace(".bearer_auth(session_key).send().await.ok()?", ".header(\"X-Device-Session\", session_key).send().await.ok()?")
    if "quota_from_agent_storage" not in t:
        t = t.rstrip() + "\n\npub async fn quota_from_agent_storage(client: &reqwest::Client, api_base: &str, session_key: &str) -> Option<QuotaSnapshot> {\n    quota_from_device_storage(client, api_base, session_key).await\n}\n"
    p.write_text(t, encoding="utf-8")

def patch_sync():
    p = ROOT / "sync.rs"
    t = p.read_text(encoding="utf-8")
    t = t.replace("use c_remote_drive::vfs::VfsDriveManager;", "use crate::vfs::VfsDriveManager;")
    t = t.replace(".bearer_auth(&self.token)", ".header(\"X-Device-Session\", &self.token)")
    if "pub url: String" not in t:
        t = t.replace("    pub size: i64,\n}", "    pub size: i64,\n    #[serde(default)]\n    pub url: String,\n}")
    old = "let url = format!(\"{}/fs/{}\", self.base_url, f.hash);"
    new = "let url = if !f.url.is_empty() { f.url.clone() } else { format!(\"{}/fs/{}\", self.base_url, f.hash) };"
    t = t.replace(old, new)
    p.write_text(t, encoding="utf-8")

def patch_runtime():
    p = ROOT / "runtime.rs"
    t = p.read_text(encoding="utf-8")
    if "file_service_url" not in t:
        t = t.replace(
            "    let engine = SyncEngine::from_session(key, base_url, vfs.backing_dir.clone());",
            "    let file_base = vfs_winfsp::file_service_url(base_url);\n    let engine = SyncEngine::from_session(key, &file_base, vfs.backing_dir.clone());",
        )
    p.write_text(t, encoding="utf-8")

patch_vfs_winfsp()
patch_sync()
patch_runtime()
print("patched")