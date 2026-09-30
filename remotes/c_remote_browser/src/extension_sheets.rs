use std::sync::OnceLock;
use std::time::Duration;

use serde_json::Value;
use tokio::sync::Mutex;

static SHEETS_RPC_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

async fn sheets_rpc(op: &str, params: Value) -> anyhow::Result<Value> {
    let lock = SHEETS_RPC_LOCK.get_or_init(|| Mutex::new(()));
    let _guard = lock.lock().await;
    let bridge = crate::extension_ipc::extension_bridge_get()
        .ok_or_else(crate::extension_ipc::extension_ipc_not_ready_err)?;
    let op_s = op.to_string();
    tokio::task::spawn_blocking(move || bridge.call(&op_s, params, Duration::from_secs(45)))
        .await?
        .map_err(|e| anyhow::anyhow!("{e}"))
}

pub async fn extension_sheets_method(method: &str, params: &Value) -> anyhow::Result<Value> {
    match method {
        "sheets.append_row" => sheets_rpc("sheets.append_row", params.clone()).await,
        "sheets.cell_set" => sheets_rpc("sheets.cell_set", params.clone()).await,
        "sheets.cell_read" => sheets_rpc("sheets.cell_read", params.clone()).await,
        "sheets.row_read" => sheets_rpc("sheets.row_read", params.clone()).await,
        other => anyhow::bail!("unknown sheets method: {other}"),
    }
}