use tracing::info;

pub async fn conn_ws_run(server_url: &str, session_key: &str) -> anyhow::Result<()> {
    info!(
        "paired; conn_ws stub (server={}, session_key_len={})",
        server_url,
        session_key.len()
    );
    Ok(())
}
