use crate::db;
use crate::media::extract_message_payload;
use crate::nats::{ActChannelWhatsappPair, EvChannelAttachment, EvChannelMsgIn, EvChannelPairUpdate, NatsService, SUBJ_PAIR};
use crate::outbound::start_outbound_worker;
use anyhow::{Context, Result};
use dashmap::DashMap;
use futures_util::StreamExt;
use sqlx::PgPool;
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::sync::watch;
use tracing::{debug, error, info, warn};
use wa_rs::Client;
use wa_rs_core::types::events::Event;
use wa_rs_sqlite_storage::SqliteStore;
use wa_rs_tokio_transport::TokioWebSocketTransportFactory;
use wa_rs_ureq_http::UreqHttpClient;

fn nats_client(nats: &Option<NatsService>) -> Option<async_nats::Client> {
    nats.as_ref().map(|n| n.client().clone())
}

async fn wa_channel_log(
    pool: &PgPool,
    nats: Option<async_nats::Client>,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    topic: &str,
    text: &str,
    meta: serde_json::Value,
) {
    let _ = db::channel_log(pool, nats.as_ref(), owner_iid, bot_iid, channel_id, topic, text, meta).await;
}

const MIN_SESSION_BYTES: usize = 8192;
const LINKED_DEVICE_NAME: &str = "Alien AI";

fn is_session_migration_error(err: &anyhow::Error) -> bool {
    let msg = format!("{err:#}").to_lowercase();
    msg.contains("migration error") || msg.contains("lid_pn_mapping")
}

fn user_facing_session_error(err: &anyhow::Error) -> String {
    if is_session_migration_error(err) {
        "Session reset — try scanning QR again".to_string()
    } else {
        err.to_string()
    }
}

async fn wipe_channel_session(pool: &PgPool, bot_iid: i64, channel_id: &str, session_path: &PathBuf) -> Result<()> {
    if session_path.exists() {
        let _ = tokio::fs::remove_file(session_path).await;
    }
    db::channel_session_blob_clear(pool, bot_iid, channel_id).await?;
    Ok(())
}

async fn open_sqlite_store(pool: &PgPool, bot_iid: i64, channel_id: &str, session_path: &PathBuf) -> Result<Arc<SqliteStore>> {
    match SqliteStore::new(session_path.to_string_lossy().as_ref()).await {
        Ok(store) => Ok(Arc::new(store)),
        Err(e) => {
            let err = anyhow::Error::from(e);
            if !is_session_migration_error(&err) {
                return Err(err);
            }
            warn!(
                "[wa-device] session migration failed channel_id={channel_id}, wiping and retrying: {err:#}"
            );
            wipe_channel_session(pool, bot_iid, channel_id, session_path).await?;
            Ok(Arc::new(
                SqliteStore::new(session_path.to_string_lossy().as_ref())
                    .await
                    .map_err(anyhow::Error::from)?,
            ))
        }
    }
}

/// Per-channel runtime (one wa-rs Bot per WhatsApp linked device).
struct ChannelRuntime {
    bot_iid: i64,
    channel_id: String,
    owner_iid: i64,
    session_path: PathBuf,
    stop: watch::Sender<()>,
    was_active: bool,
}

#[derive(Clone)]
pub struct ChannelManager {
    pub pool: PgPool,
    pub nats: Option<NatsService>,
    pub sessions_dir: String,
    runtimes: Arc<DashMap<String, ChannelRuntime>>,
    clients: Arc<DashMap<String, Arc<Client>>>,
}

impl ChannelManager {
    pub fn new(pool: PgPool, nats: Option<NatsService>, sessions_dir: String) -> Self {
        Self {
            pool,
            nats,
            sessions_dir,
            runtimes: Arc::new(DashMap::new()),
            clients: Arc::new(DashMap::new()),
        }
    }

    pub fn client_for(&self, channel_id: &str) -> Option<Arc<Client>> {
        self.clients.get(channel_id).map(|c| c.value().clone())
    }

    pub fn spawn_background_tasks(&self, poll_interval_secs: u64) {
        let mgr = self.clone();
        tokio::spawn(async move {
            if let Err(e) = mgr.subscribe_pair_events().await {
                error!("[wa-device] pair subscriber failed: {e:#}");
            }
        });
        if let Some(nats) = self.nats.clone() {
            let mgr = self.clone();
            tokio::spawn(async move {
                start_outbound_worker(mgr, nats).await;
            });
        }
        let mgr = self.clone();
        tokio::spawn(async move {
            mgr.poll_db_loop(poll_interval_secs).await;
        });
    }

    pub fn stop_channel(&self, bot_iid: i64, channel_id: String) {
        self.stop_channel_inner(bot_iid, &channel_id, true);
    }

    fn stop_runtime(&self, bot_iid: i64, channel_id: &str) {
        self.stop_channel_inner(bot_iid, channel_id, false);
    }

    fn stop_channel_inner(&self, bot_iid: i64, channel_id: &str, wipe_session: bool) {
        if let Some((_, rt)) = self.runtimes.remove(channel_id) {
            info!("[wa-device] stopping channel_id={channel_id} wipe_session={wipe_session}");
            let _ = rt.stop.send(());
        }
        self.clients.remove(channel_id);
        let pool = self.pool.clone();
        let nats = nats_client(&self.nats);
        let channel_id_log = channel_id.to_string();
        tokio::spawn(async move {
            if let Ok(Some(row)) = db::channel_get(&pool, bot_iid, &channel_id_log).await {
                wa_channel_log(
                    &pool,
                    nats,
                    row.owner_iid,
                    bot_iid,
                    &channel_id_log,
                    "worker_stop",
                    "WhatsApp worker stopped",
                    serde_json::json!({ "wipe_session": wipe_session }),
                )
                .await;
            }
        });
        if !wipe_session {
            return;
        }
        let session_path = self.session_path(bot_iid, channel_id);
        let channel_id_wipe = channel_id.to_string();
        tokio::spawn(async move {
            if session_path.exists() {
                let _ = tokio::fs::remove_file(&session_path).await;
                info!("[wa-device] session file removed channel_id={channel_id_wipe}");
            }
        });
    }

    pub fn restart_channel(&self, bot_iid: i64, channel_id: String) {
        if let Some((_, rt)) = self.runtimes.remove(&channel_id) {
            info!("[wa-device] stopping channel_id={channel_id}");
            let _ = rt.stop.send(());
        }
        self.clients.remove(&channel_id);
        let mgr = self.clone();
        let session_path = self.session_path(bot_iid, &channel_id);
        tokio::spawn(async move {
            if session_path.exists() {
                let _ = tokio::fs::remove_file(&session_path).await;
                info!("[wa-device] session file removed channel_id={channel_id}");
            }
            if let Err(e) = mgr.start_channel(bot_iid, channel_id.clone()).await {
                error!("[wa-device] restart failed channel_id={channel_id}: {e:#}");
            }
        });
    }

    async fn subscribe_pair_events(self) -> Result<()> {
        let nats = self.nats.as_ref().context("NATS required for pair events")?;
        let mut sub = nats.client().subscribe(SUBJ_PAIR.to_string()).await?;
        info!("[wa-device] subscribed NATS subject={SUBJ_PAIR}");
        while let Some(msg) = sub.next().await {
            let act = match serde_json::from_slice::<ActChannelWhatsappPair>(&msg.payload) {
                Ok(v) => v,
                Err(e) => {
                    warn!("[wa-device] invalid pair payload: {e}");
                    continue;
                }
            };
            info!("[wa-device] pair event channel_id={} owner_iid={}", act.channel_id, act.owner_iid);
            self.restart_channel(act.bot_iid, act.channel_id.clone());
        }
        Ok(())
    }

    async fn poll_db_loop(self, poll_interval_secs: u64) {
        let mut tick = tokio::time::interval(std::time::Duration::from_secs(poll_interval_secs));
        loop {
            tick.tick().await;
            self.cleanup_expired_pairing().await;
            let channels = match db::list_whatsapp_active_channels(&self.pool).await {
                Ok(c) => c,
                Err(e) => {
                    warn!("[wa-device] poll list channels failed: {e:#}");
                    continue;
                }
            };
            debug!("[wa-device] poll found {} active whatsapp channels", channels.len());
            for ch in channels {
                if self.runtimes.contains_key(&ch.channel_id) {
                    continue;
                }
                info!("[wa-device] poll starting channel_id={} status={}", ch.channel_id, ch.status);
                if let Err(e) = self.start_channel(ch.bot_iid, ch.channel_id.clone()).await {
                    error!("[wa-device] poll start failed channel_id={}: {e:#}", ch.channel_id);
                }
            }
        }
    }

    async fn cleanup_expired_pairing(&self) {
        let stale = match db::list_expired_pairing_channels(&self.pool).await {
            Ok(v) => v,
            Err(e) => {
                warn!("[wa-device] list expired pairing failed: {e:#}");
                return;
            }
        };
        for ch in stale {
            if self.runtimes.contains_key(&ch.channel_id) {
                info!("[wa-device] stopping expired pairing channel_id={}", ch.channel_id);
                self.stop_runtime(ch.bot_iid, &ch.channel_id);
            }
            if let Err(e) = db::channel_abort_pairing(&self.pool, ch.bot_iid, &ch.channel_id).await {
                warn!("[wa-device] abort expired pairing channel_id={}: {e:#}", ch.channel_id);
                continue;
            }
            wa_channel_log(
                &self.pool,
                nats_client(&self.nats),
                ch.owner_iid,
                ch.bot_iid,
                &ch.channel_id,
                "pair_expired",
                "Pairing ended — no app watching",
                serde_json::json!({}),
            )
            .await;
        }
    }

    pub async fn start_channel(&self, bot_iid: i64, channel_id: String) -> Result<()> {
        if self.runtimes.contains_key(&channel_id) {
            debug!("[wa-device] channel_id={channel_id} already running");
            return Ok(());
        }

        let row = db::channel_get(&self.pool, bot_iid, &channel_id)
            .await?
            .with_context(|| format!("channel {channel_id} not found"))?;
        wa_channel_log(
            &self.pool,
            nats_client(&self.nats),
            row.owner_iid,
            bot_iid,
            &channel_id,
            "worker_start",
            "Starting WhatsApp worker",
            serde_json::json!({ "status": row.status }),
        )
        .await;

        let superseded: Vec<String> = self
            .runtimes
            .iter()
            .filter(|e| e.owner_iid == row.owner_iid && e.channel_id != channel_id)
            .map(|e| e.channel_id.clone())
            .collect();
        for other_cid in superseded {
            warn!(
                "[wa-device] stopping duplicate runtime owner_iid={} channel_id={other_cid} (keep={channel_id})",
                row.owner_iid
            );
            self.stop_runtime(row.bot_iid, &other_cid);
        }

        let session_path = self.session_path(bot_iid, &channel_id);
        if session_path.exists() {
            let len = tokio::fs::metadata(&session_path).await.map(|m| m.len() as usize).unwrap_or(0);
            if len < MIN_SESSION_BYTES {
                warn!("[wa-device] removing stale session file channel_id={channel_id} bytes={len}");
                let _ = tokio::fs::remove_file(&session_path).await;
            }
        }
        if !session_path.exists() {
            if let Some(bytes) = db::channel_session_blob_get(&self.pool, bot_iid, &channel_id).await? {
                tokio::fs::write(&session_path, &bytes).await?;
                info!("[wa-device] restored sqlite session channel_id={channel_id} bytes={}", bytes.len());
            }
        }

        let (stop_tx, mut stop_rx) = watch::channel(());
        let stop_bot = stop_tx.clone();
        let was_active = row.status == "connected" || !row.phone_jid.is_empty();
        let rt = ChannelRuntime {
            bot_iid,
            channel_id: channel_id.clone(),
            owner_iid: row.owner_iid,
            session_path: session_path.clone(),
            stop: stop_tx,
            was_active,
        };
        self.runtimes.insert(channel_id.clone(), rt);

        let pool = self.pool.clone();
        let nats = self.nats.clone();
        let owner_iid = row.owner_iid;
        let runtimes = self.runtimes.clone();
        let clients = self.clients.clone();

        let clients_cleanup = clients.clone();
        let mgr = self.clone();
        tokio::spawn(async move {
            let nats_log = nats_client(&nats);
            let result = run_channel_bot(
                pool.clone(),
                nats,
                bot_iid,
                channel_id.clone(),
                owner_iid,
                was_active,
                session_path.clone(),
                clients,
                stop_bot,
                &mut stop_rx,
            )
            .await;
            runtimes.remove(&channel_id);
            clients_cleanup.remove(&channel_id);
            let migration_reset = match result {
                Ok(()) => {
                    let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path).await;
                    false
                }
                Err(e) => {
                    error!("[wa-device] bot exited channel_id={channel_id}: {e:#}");
                    wa_channel_log(
                        &pool,
                        nats_log,
                        owner_iid,
                        bot_iid,
                        &channel_id,
                        "error",
                        &user_facing_session_error(&e),
                        serde_json::json!({ "detail": format!("{e:#}") }),
                    )
                    .await;
                    if is_session_migration_error(&e) {
                        let _ = wipe_channel_session(&pool, bot_iid, &channel_id, &session_path).await;
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "pairing").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "error_message": "" }),
                        )
                        .await;
                        true
                    } else {
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "error").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "error_message": user_facing_session_error(&e) }),
                        )
                        .await;
                        let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path).await;
                        false
                    }
                }
            };
            info!("[wa-device] channel task ended channel_id={channel_id}");
            if migration_reset {
                mgr.restart_channel(bot_iid, channel_id.clone());
            }
        });

        Ok(())
    }

    fn session_path(&self, bot_iid: i64, channel_id: &str) -> PathBuf {
        PathBuf::from(&self.sessions_dir).join(format!("wa_{bot_iid}_{channel_id}.db"))
    }
}

async fn persist_session_file(pool: &PgPool, bot_iid: i64, channel_id: &str, path: &PathBuf) -> Result<()> {
    if !path.exists() {
        return Ok(());
    }
    let bytes = tokio::fs::read(path).await?;
    if bytes.len() < MIN_SESSION_BYTES {
        debug!("[wa-device] skip session persist channel_id={channel_id} bytes={} (too small)", bytes.len());
        return Ok(());
    }
    db::channel_session_blob_put(pool, bot_iid, channel_id, &bytes).await?;
    Ok(())
}

async fn publish_pair_update(
    nats: &Option<NatsService>,
    owner_iid: i64,
    bot_iid: i64,
    channel_id: &str,
    status: &str,
    qr_raw: &str,
    error_message: &str,
    phone_jid: &str,
    skip_if_active: bool,
) {
    if skip_if_active && status == "connected" && qr_raw.is_empty() && error_message.is_empty() {
        return;
    }
    if let Some(nats) = nats {
        let ev = EvChannelPairUpdate {
            bot_iid,
            channel_id: channel_id.to_string(),
            owner_iid,
            status: status.to_string(),
            qr_raw: qr_raw.to_string(),
            error_message: error_message.to_string(),
            phone_jid: phone_jid.to_string(),
        };
        if let Err(e) = nats.publish_pair_update(&ev).await {
            warn!("[wa-device] pair update publish failed channel_id={channel_id}: {e:#}");
        }
    }
}

async fn run_channel_bot(
    pool: PgPool,
    nats: Option<NatsService>,
    bot_iid: i64,
    channel_id: String,
    owner_iid: i64,
    was_active: bool,
    session_path: PathBuf,
    clients: Arc<DashMap<String, Arc<Client>>>,
    stop_bot: watch::Sender<()>,
    stop_rx: &mut watch::Receiver<()>,
) -> Result<()> {
    info!(
        "[wa-device] building bot channel_id={channel_id} owner_iid={owner_iid} session={} was_active={was_active}",
        session_path.display()
    );
    if was_active {
        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "connected").await;
        let _ = db::channel_patch_session(
            &pool,
            bot_iid,
            &channel_id,
            serde_json::json!({ "qr_raw": "", "error_message": "" }),
        )
        .await;
    } else {
        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "pairing").await;
    }

    let pool_ev = pool.clone();
    let http = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .unwrap_or_else(|_| reqwest::Client::new());
    let skip_active_pair = was_active;
    let stop_bot_ev = stop_bot.clone();
    let webhook_secret = String::new();
    let session_path_outer = session_path.clone();

    let backend = open_sqlite_store(&pool_ev, bot_iid, &channel_id, &session_path).await?;
    let pool_ev_loop = pool_ev.clone();
    let nats_loop = nats.clone();
    let clients_loop = clients.clone();
    let session_path_loop = session_path.clone();
    let http_loop = http.clone();
    let webhook_secret_loop = webhook_secret.clone();
    let channel_id_ev = channel_id.clone();
    let mut bot = wa_rs::bot::Bot::builder()
        .with_backend(backend)
        .with_transport_factory(TokioWebSocketTransportFactory::new())
        .with_http_client(UreqHttpClient::new())
        .with_device_props(Some(LINKED_DEVICE_NAME.to_string()), None, None)
        .on_event(move |event, client| {
            let pool = pool_ev_loop.clone();
            let nats = nats_loop.clone();
            let clients = clients_loop.clone();
            let session_path = session_path_loop.clone();
            let http = http_loop.clone();
            let webhook_secret = webhook_secret_loop.clone();
            let skip_active_pair = skip_active_pair;
            let stop_bot = stop_bot_ev.clone();
            let channel_id = channel_id_ev.clone();
            async move {
                clients.entry(channel_id.clone()).or_insert_with(|| client.clone());
                match event {
                    Event::PairingQrCode { code: _, timeout: _ } if skip_active_pair => {
                        warn!("[wa-device] invalid session channel_id={channel_id}, refusing background QR");
                        let msg = "Session expired — open the app to pair again";
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "error").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "error_message": msg, "qr_raw": "" }),
                        )
                        .await;
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            msg,
                            serde_json::json!({ "event": "session_expired" }),
                        )
                        .await;
                        publish_pair_update(&nats, owner_iid, bot_iid, &channel_id, "error", "", msg, "", true).await;
                        let _ = stop_bot.send(());
                    }
                    Event::PairingQrCode { code, timeout } => {
                        if !db::channel_pair_watch_active(&pool, bot_iid, &channel_id).await.unwrap_or(false) {
                            warn!("[wa-device] pair watch expired channel_id={channel_id}, stopping QR");
                            let _ = stop_bot.send(());
                            return;
                        }
                        info!(
                            "[wa-device] QR channel_id={channel_id} len={} timeout_secs={}",
                            code.len(),
                            timeout.as_secs()
                        );
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "pairing").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "qr_raw": code, "error_message": "" }),
                        )
                        .await;
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "qr",
                            "QR code ready — scan to pair",
                            serde_json::json!({ "timeout_secs": timeout.as_secs() }),
                        )
                        .await;
                        publish_pair_update(&nats, owner_iid, bot_iid, &channel_id, "pairing", &code, "", "", false).await;
                    }
                    Event::PairSuccess(p) => {
                        let phone = p.id.to_string();
                        info!("[wa-device] paired channel_id={channel_id} phone={phone}");
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "connected").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "phone_jid": phone, "qr_raw": "", "error_message": "" }),
                        )
                        .await;
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "connected",
                            "WhatsApp paired successfully",
                            serde_json::json!({ "phone": phone, "event": "pair_success" }),
                        )
                        .await;
                        publish_pair_update(&nats, owner_iid, bot_iid, &channel_id, "connected", "", "", &phone, false).await;
                        let pool_p = pool.clone();
                        let path_p = session_path.clone();
                        tokio::spawn(async move {
                            let _ = persist_session_file(&pool_p, bot_iid, &channel_id, &path_p).await;
                        });
                    }
                    Event::PairError(e) => {
                        let msg = format!("{e:?}");
                        error!("[wa-device] pair error channel_id={channel_id}: {msg}");
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "error").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "error_message": msg }),
                        )
                        .await;
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            &format!("Pairing failed: {msg}"),
                            serde_json::json!({ "event": "pair_error" }),
                        )
                        .await;
                        publish_pair_update(&nats, owner_iid, bot_iid, &channel_id, "error", "", &msg, "", false).await;
                    }
                    Event::Connected(_) => {
                        let phone = client.get_pn().await.map(|j| j.to_string()).unwrap_or_default();
                        info!("[wa-device] connected channel_id={channel_id} phone={phone}");
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "connected").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "phone_jid": phone, "qr_raw": "", "error_message": "" }),
                        )
                        .await;
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "connected",
                            "WhatsApp session connected",
                            serde_json::json!({ "phone": phone }),
                        )
                        .await;
                        publish_pair_update(&nats, owner_iid, bot_iid, &channel_id, "connected", "", "", &phone, skip_active_pair).await;
                        let pool_p = pool.clone();
                        let path_p = session_path.clone();
                        tokio::spawn(async move {
                            let _ = persist_session_file(&pool_p, bot_iid, &channel_id, &path_p).await;
                        });
                    }
                    Event::LoggedOut(_) => {
                        warn!("[wa-device] logged out channel_id={channel_id}");
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "disconnected",
                            "Logged out from phone — scan QR again",
                            serde_json::json!({ "event": "logged_out" }),
                        )
                        .await;
                        let _ = db::channel_update_status(&pool, bot_iid, &channel_id, "error").await;
                        let _ = db::channel_patch_session(
                            &pool,
                            bot_iid,
                            &channel_id,
                            serde_json::json!({ "error_message": "logged out from phone — scan QR again" }),
                        )
                        .await;
                    }
                    Event::Disconnected(_) => {
                        warn!("[wa-device] disconnected channel_id={channel_id}");
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "disconnected",
                            "WhatsApp session disconnected — reconnecting",
                            serde_json::json!({}),
                        )
                        .await;
                    }
                    Event::ConnectFailure(f) => {
                        let msg = if f.message.is_empty() {
                            format!("{:?}", f.reason)
                        } else {
                            f.message.clone()
                        };
                        error!("[wa-device] connect failure channel_id={channel_id}: {msg}");
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            &format!("Connect failed: {msg}"),
                            serde_json::json!({ "reason": format!("{:?}", f.reason) }),
                        )
                        .await;
                    }
                    Event::StreamError(e) => {
                        error!("[wa-device] stream error channel_id={channel_id} code={}", e.code);
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            &format!("Stream error: {}", e.code),
                            serde_json::json!({ "code": e.code }),
                        )
                        .await;
                    }
                    Event::ClientOutdated(_) => {
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            "WhatsApp client outdated — update required",
                            serde_json::json!({}),
                        )
                        .await;
                    }
                    Event::TemporaryBan(b) => {
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "error",
                            &format!("Temporary ban: {:?}", b),
                            serde_json::json!({}),
                        )
                        .await;
                    }
                    Event::StreamReplaced(_) => {
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "disconnected",
                            "Session replaced by another connection",
                            serde_json::json!({}),
                        )
                        .await;
                    }
                    Event::Message(msg, info) => {
                        if info.source.is_from_me {
                            return;
                        }
                        let payload = match extract_message_payload(&http, &client, bot_iid, &channel_id, &webhook_secret, &msg).await {
                            Some(v) => v,
                            None => return,
                        };
                        let peer_id = info
                            .source
                            .sender_alt
                            .as_ref()
                            .map(|j| j.to_string())
                            .unwrap_or_else(|| info.source.chat.to_string());
                        let peer_name = info.push_name.clone();
                        let msg_id = info.id.to_string();
                        let peer_avatar_hash = if webhook_secret.is_empty() {
                            String::new()
                        } else {
                            crate::media::peer_avatar_hash(&http, &client, bot_iid, &channel_id, &webhook_secret, &peer_id).await
                        };
                        info!(
                            "[wa-device] inbound channel_id={channel_id} peer={peer_id} text_len={} attachments={} is_voice={} msg_id={} avatar={}",
                            payload.text.len(),
                            payload.attachments.len(),
                            payload.is_voice,
                            msg_id,
                            !peer_avatar_hash.is_empty()
                        );
                        let preview = if payload.text.is_empty() {
                            "[attachment]".to_string()
                        } else {
                            payload.text.clone()
                        };
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "msg_received",
                            &format!("Inbound from {peer_id}: {preview}"),
                            serde_json::json!({
                                "msg_id": msg_id,
                                "peer_id": peer_id,
                                "attachments": payload.attachments.len(),
                            }),
                        )
                        .await;
                        if let Some(nats) = &nats {
                            let ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs() as i64;
                            let ev = EvChannelMsgIn {
                                bot_iid,
                                channel_id: channel_id.clone(),
                                channel_type: "whatsapp".into(),
                                owner_iid,
                                peer_id: peer_id.clone(),
                                peer_username: Some(peer_id.clone()),
                                peer_name: Some(peer_name.clone()),
                                msg_id,
                                text: payload.text,
                                timestamp: ts,
                                is_voice: payload.is_voice,
                                quoted_msg_id: payload.quoted_msg_id,
                                quoted_text: payload.quoted_text,
                                attachments: payload
                                    .attachments
                                    .into_iter()
                                    .map(|a| EvChannelAttachment {
                                        hash: a.hash,
                                        name: a.name,
                                        mime: a.mime,
                                    })
                                    .collect(),
                                peer_avatar_hash,
                            };
                            if let Err(e) = nats.publish_msg_in(&ev).await {
                                error!("[wa-device] NATS publish failed channel_id={channel_id}: {e:#}");
                            }
                        }
                    }
                    other => {
                        debug!("[wa-device] event channel_id={channel_id} {:?}", std::mem::discriminant(&other));
                    }
                }
            }
        })
        .build()
        .await?;

    let mut run_handle = bot.run().await?;
    loop {
        tokio::select! {
            _ = stop_rx.changed() => {
                info!("[wa-device] shutdown channel_id={channel_id}");
                wa_channel_log(
                    &pool,
                    nats_client(&nats),
                    owner_iid,
                    bot_iid,
                    &channel_id,
                    "worker_stop",
                    "WhatsApp worker shutting down",
                    serde_json::json!({}),
                )
                .await;
                let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path_outer).await;
                return Ok(());
            }
            res = &mut run_handle => {
                match res {
                    Ok(()) => {
                        warn!("[wa-device] client run ended channel_id={channel_id}");
                        wa_channel_log(
                            &pool,
                            nats_client(&nats),
                            owner_iid,
                            bot_iid,
                            &channel_id,
                            "disconnected",
                            "WhatsApp session ended",
                            serde_json::json!({}),
                        )
                        .await;
                    }
                    Err(e) => {
                        error!("[wa-device] client run task failed channel_id={channel_id}: {e:#}");
                        return Err(e.into());
                    }
                }
                break;
            }
            _ = tokio::time::sleep(std::time::Duration::from_secs(30)) => {
                if session_path_outer.exists() {
                    let _ = persist_session_file(&pool, bot_iid, &channel_id, &session_path_outer).await;
                    debug!("[wa-device] periodic session flush channel_id={channel_id}");
                }
            }
        }
    }
    Ok(())
}
