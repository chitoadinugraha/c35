use std::path::PathBuf;

use anyhow::Context;
use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;
use tracing::{info, warn};

#[cfg(target_os = "windows")]
mod dpapi {
    use anyhow::{Context, Result};
    use windows::core::PCWSTR;
    use windows::Win32::Foundation::{LocalFree, HLOCAL};
    use windows::Win32::Security::Cryptography::{
        CryptProtectData, CryptUnprotectData, CRYPTPROTECT_UI_FORBIDDEN, CRYPT_INTEGER_BLOB,
    };

    pub fn encrypt_bytes(data: &[u8]) -> Result<Vec<u8>> {
        if data.is_empty() {
            return Ok(Vec::new());
        }
        let in_blob = CRYPT_INTEGER_BLOB {
            cbData: data.len() as u32,
            pbData: data.as_ptr() as *mut u8,
        };
        let mut out_blob = CRYPT_INTEGER_BLOB::default();

        unsafe {
            CryptProtectData(
                &in_blob,
                PCWSTR::null(),
                None,
                None,
                None,
                CRYPTPROTECT_UI_FORBIDDEN,
                &mut out_blob,
            )
            .context("CryptProtectData failed")?;

            if out_blob.pbData.is_null() {
                anyhow::bail!("CryptProtectData returned null pointer");
            }

            let slice = std::slice::from_raw_parts(out_blob.pbData, out_blob.cbData as usize);
            let result = slice.to_vec();
            let _ = LocalFree(HLOCAL(out_blob.pbData as _));
            Ok(result)
        }
    }

    pub fn decrypt_bytes(data: &[u8]) -> Result<Vec<u8>> {
        if data.is_empty() {
            return Ok(Vec::new());
        }
        let in_blob = CRYPT_INTEGER_BLOB {
            cbData: data.len() as u32,
            pbData: data.as_ptr() as *mut u8,
        };
        let mut out_blob = CRYPT_INTEGER_BLOB::default();

        unsafe {
            CryptUnprotectData(
                &in_blob,
                None,
                None,
                None,
                None,
                CRYPTPROTECT_UI_FORBIDDEN,
                &mut out_blob,
            )
            .context("CryptUnprotectData failed")?;

            if out_blob.pbData.is_null() {
                anyhow::bail!("CryptUnprotectData returned null pointer");
            }

            let slice = std::slice::from_raw_parts(out_blob.pbData, out_blob.cbData as usize);
            let result = slice.to_vec();
            let _ = LocalFree(HLOCAL(out_blob.pbData as _));
            Ok(result)
        }
    }
}

#[cfg(target_os = "windows")]
pub fn encrypt_secret(plain: &str) -> anyhow::Result<String> {
    let cipher = dpapi::encrypt_bytes(plain.as_bytes())?;
    Ok(BASE64.encode(cipher))
}

#[cfg(not(target_os = "windows"))]
pub fn encrypt_secret(plain: &str) -> anyhow::Result<String> {
    Ok(plain.to_string())
}

#[cfg(target_os = "windows")]
pub fn decrypt_secret(enc_b64: &str) -> anyhow::Result<String> {
    let cipher = BASE64.decode(enc_b64.trim())?;
    let plain = dpapi::decrypt_bytes(&cipher)?;
    String::from_utf8(plain).context("decrypted bytes not valid utf8")
}

#[cfg(not(target_os = "windows"))]
pub fn decrypt_secret(enc: &str) -> anyhow::Result<String> {
    Ok(enc.to_string())
}

pub fn config_path() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Ok(appdata) = std::env::var("LOCALAPPDATA") {
            let mut p = PathBuf::from(appdata);
            p.push("AlienAI");
            let _ = std::fs::create_dir_all(&p);
            p.push("config.json");
            return p;
        }
    }
    let mut p = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    p.push(".alienai_config.json");
    p
}

pub fn config_load() -> Option<serde_json::Value> {
    let content = std::fs::read_to_string(config_path()).ok()?;
    serde_json::from_str(&content).ok()
}

pub fn session_key_load() -> Option<String> {
    let json = config_load()?;

    // 1. Prefer DPAPI encrypted key
    if let Some(enc) = json.get("session_key_enc").and_then(|v| v.as_str()) {
        match decrypt_secret(enc) {
            Ok(key) if !key.trim().is_empty() => return Some(key.trim().to_string()),
            Err(e) => {
                warn!("failed to decrypt session_key_enc: {e}");
            }
            _ => {}
        }
    }

    // 2. Fallback to legacy plaintext key & migrate to encrypted
    if let Some(raw) = json.get("session_key").and_then(|v| v.as_str()) {
        let key = raw.trim();
        if !key.is_empty() {
            let device_iid = json.get("device_iid").and_then(|v| v.as_i64()).unwrap_or(0);
            if let Err(e) = session_key_save(key, device_iid) {
                warn!("failed to migrate legacy plaintext session_key: {e}");
            } else {
                info!("migrated legacy plaintext session_key to DPAPI-encrypted storage");
            }
            return Some(key.to_string());
        }
    }

    None
}

pub fn device_iid_load() -> Option<i64> {
    config_load()
        .and_then(|j| j.get("device_iid").and_then(|v| v.as_i64()))
        .filter(|id| *id > 0)
}

pub fn session_key_save(session_key: &str, device_iid: i64) -> anyhow::Result<()> {
    let trimmed = session_key.trim();
    if trimmed.is_empty() {
        anyhow::bail!("session_key is empty");
    }
    let path = config_path();
    if let Some(dir) = path.parent() {
        std::fs::create_dir_all(dir)
            .with_context(|| format!("create config dir {}", dir.display()))?;
    }
    let enc = encrypt_secret(trimmed)?;
    let json = serde_json::json!({
        "session_key_enc": enc,
        "device_iid": device_iid,
        "saved_at": unix_now_secs(),
    });
    std::fs::write(&path, json.to_string())
        .with_context(|| format!("write config {}", path.display()))
}

pub fn session_key_clear() -> anyhow::Result<()> {
    let path = config_path();
    match std::fs::remove_file(&path) {
        Ok(()) => Ok(()),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(e) => {
            warn!("Failed to clear session key: {e}");
            Err(e).with_context(|| format!("remove config {}", path.display()))
        }
    }
}

pub fn server_url() -> String {
    std::env::var("C35_SERVER_URL")
        .or_else(|_| std::env::var("C35_SERVER"))
        .unwrap_or_else(|_| "https://alienai.id".to_string())
        .trim()
        .trim_end_matches('/')
        .to_string()
}

fn unix_now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_secret_encryption_roundtrip() {
        let plain = "sec_test_secret_key_1234567890abcdef";
        let encrypted = encrypt_secret(plain).expect("encrypt should succeed");
        #[cfg(target_os = "windows")]
        assert_ne!(encrypted, plain, "encrypted string should not be plaintext on Windows");
        let decrypted = decrypt_secret(&encrypted).expect("decrypt should succeed");
        assert_eq!(decrypted, plain, "decrypted secret should match original");
    }
}
