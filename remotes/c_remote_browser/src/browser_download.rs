use anyhow::{anyhow, Result};
use base64::Engine as _;
use serde_json::json;

pub const MAX_UPLOAD_BYTES: usize = 32 * 1024 * 1024;

pub async fn ipc_file_upload(
    bridge: &crate::engine::ipc::EngineBridge,
    tab_id: Option<&str>,
    selector: &str,
    file_name: &str,
    bytes: &[u8],
) -> Result<()> {
    if bytes.len() > MAX_UPLOAD_BYTES {
        return Err(anyhow!("upload exceeds {} bytes cap", MAX_UPLOAD_BYTES));
    }
    let b64 = base64::engine::general_purpose::STANDARD.encode(bytes);
    let params = json!({
        "tab_id": tab_id,
        "selector": selector,
        "files": [{ "name": file_name, "b64": b64 }],
    });
    bridge.call("file.upload", params).await?;
    Ok(())
}