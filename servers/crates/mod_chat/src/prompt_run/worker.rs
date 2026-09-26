use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context as AnyhowCtx, Result};
use async_nats::jetstream::message::AckKind;
use async_nats::Client;
use c35_mod_billing::{billing_gate_with_hold, billing_gate_scoped, billing_reservation_refund, billing_resolve, TurnBillingCtx};
use c35_proto::{PromptRunJob, ResPromptEnd, ResPromptFail};
use futures_util::StreamExt;
use serde::Deserialize;
use sqlx::PgPool;
use tokio::sync::Semaphore;
use tokio::task::JoinHandle;
use tokio_util::sync::CancellationToken;
use tracing::{error, info, warn, Instrument};

use crate::prompt_turn::{prompt_turn, PromptTurnHooks};

use super::checkpoint::{prompt_run_max_concurrent, prompt_run_should_stop};
use super::fanout::{
    prompt_run_fanout_delta, prompt_run_fanout_end, prompt_run_fanout_fail, prompt_run_fanout_publish,
    prompt_run_push_from_row,
};
use super::jetstream::{prompt_jetstream_consumer, prompt_jetstream_ensure};
use super::store::{
    prompt_run_delivery_inc, prompt_run_finish, prompt_run_get, prompt_run_is_cancelled,
    prompt_run_lease_touch, prompt_run_over_max_deliver, prompt_run_status_set,
};

#[derive(Debug, Deserialize)]
struct PromptRunJobJson {
    req_id: String,
}

pub struct PromptRunWorker {
    drain: Arc<AtomicBool>,
    handle: JoinHandle<()>,
}

impl PromptRunWorker {
    pub async fn drain(self) {
        self.drain.store(true, Ordering::SeqCst);
        let _ = self.handle.await;
    }
}

pub fn prompt_run_worker_start(pool: PgPool, nats: Client) -> PromptRunWorker {
    let drain = Arc::new(AtomicBool::new(false));
    let drain_loop = drain.clone();
    let handle = tokio::spawn(async move {
        if let Err(e) = prompt_run_worker_loop(pool, nats, drain_loop).await {
            error!("[c35:prompt_run] worker stopped: {e:#}");
        }
    });
    PromptRunWorker { drain, handle }
}

async fn prompt_run_worker_loop(pool: PgPool, nats: Client, draining: Arc<AtomicBool>) -> Result<()> {
    let js = prompt_jetstream_ensure(&nats).await?;
    let consumer = prompt_jetstream_consumer(&js).await?;
    let max_concurrent = prompt_run_max_concurrent();
    let sem = Arc::new(Semaphore::new(max_concurrent));
    info!(
        max_concurrent,
        "[c35:prompt_run] JetStream consumer ready stream={} subject={}",
        super::jetstream::STREAM_NAME,
        super::jetstream::SUBJECT_WORK
    );
    let mut messages = consumer.messages().await?;
    while !draining.load(Ordering::Relaxed) {
        let msg = tokio::select! {
            m = messages.next() => m,
            _ = tokio::time::sleep(Duration::from_secs(1)) => {
                if draining.load(Ordering::Relaxed) { break; }
                continue;
            }
        };
        let Some(msg) = msg else { break };
        let msg = msg.context("jetstream message")?;
        let permit = sem
            .clone()
            .acquire_owned()
            .await
            .context("prompt_run concurrency semaphore closed")?;
        let pool = pool.clone();
        let nats = nats.clone();
        let draining = draining.clone();
        tokio::spawn(async move {
            let _permit = permit;
            if let Err(e) = process_prompt_job(pool, nats, msg, draining).await {
                warn!("[c35:prompt_run] job failed: {e:#}");
            }
        });
    }
    info!("[c35:prompt_run] worker draining, stopped accepting jobs");
    Ok(())
}

async fn process_prompt_job(
    pool: PgPool,
    nats: Client,
    msg: async_nats::jetstream::Message,
    draining: Arc<AtomicBool>,
) -> Result<()> {
    let job: PromptRunJobJson = serde_json::from_slice(&msg.payload)
        .context("invalid prompt run job payload")?;
    let req_id = job.req_id.clone();
    let delivery_count = prompt_run_delivery_inc(&pool, &req_id).await?;
    let Some(mut row) = prompt_run_get(&pool, &req_id).await? else {
        let _ = msg.ack_with(AckKind::Term).await;
        return Ok(());
    };
    let prompt_preview: String = row.text.chars().take(200).collect();
    let span = tracing::info_span!(
        "prompt_run",
        req_id = %req_id,
        owner_iid = row.owner_iid,
        chat_id = row.chat_id,
        prompt = %prompt_preview
    );

    async {
    if matches!(row.status.as_str(), "done" | "failed" | "cancelled") {
        let _ = msg.ack().await;
        return Ok(());
    }

    if prompt_run_over_max_deliver(delivery_count) {
        let _ = prompt_run_status_set(&pool, &req_id, "failed", Some("fatal_deliver"), Some("max_deliver exceeded")).await;
        let _ = billing_reservation_refund(&pool, &req_id).await;
        row.status = "failed".into();
        row.fail_class = Some("fatal_deliver".into());
        let _ = prompt_run_fanout_publish(&nats, row.owner_iid, row.chat_id, prompt_run_push_from_row(&row)).await;
        let _ = msg.ack().await;
        return Ok(());
    }

    if let Some(reason) = prompt_run_should_stop(&row) {
        if matches!(reason, "fatal" | "fatal_checkpoint" | "fatal_repeat" | "stuck_ui") {
            let fc = row.fail_class.clone().or_else(|| Some("fatal_checkpoint".into()));
            let _ = prompt_run_status_set(&pool, &req_id, "failed", fc.as_deref(), Some(reason)).await;
            let _ = billing_reservation_refund(&pool, &req_id).await;
            row.status = "failed".into();
            row.fail_class = fc;
            let _ = prompt_run_fanout_publish(&nats, row.owner_iid, row.chat_id, prompt_run_push_from_row(&row)).await;
            let _ = msg.ack().await;
            return Ok(());
        }
    }

    let pod = std::env::var("HOSTNAME").unwrap_or_else(|_| "local".into());
    let _ = prompt_run_lease_touch(&pool, &req_id, &pod, 120).await?;
    let _ = prompt_run_status_set(&pool, &req_id, "running", None, None).await?;

    let bctx = billing_resolve(
        &pool,
        TurnBillingCtx {
            owner_iid: row.owner_iid,
            bot_iid: None,
            device_iid: None,
        },
    )
    .await?;
    let brow = billing_gate_scoped(&pool, &bctx).await?;
    billing_gate_with_hold(&pool, row.owner_iid, &brow, &req_id).await?;

    let cancel = CancellationToken::new();
    let cancel_token = cancel.clone();
    let pool_cancel = pool.clone();
    let req_id_cancel = req_id.clone();
    let cancel_watch = tokio::spawn(async move {
        loop {
            if cancel_token.is_cancelled() {
                break;
            }
            match prompt_run_is_cancelled(&pool_cancel, &req_id_cancel).await {
                Ok(true) => {
                    cancel_token.cancel();
                    break;
                }
                Ok(false) => {}
                Err(e) => warn!("[c35:prompt_run] cancel poll: {e}"),
            }
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    });

    let (_msg, acker) = async_nats::jetstream::Message::split(msg);
    let acker_mutex = Arc::new(tokio::sync::Mutex::new(acker));
    let heartbeat_acker = Arc::clone(&acker_mutex);
    let heartbeat = tokio::spawn(async move {
        loop {
            tokio::time::sleep(Duration::from_secs(30)).await;
            if heartbeat_acker
                .lock()
                .await
                .ack_with(AckKind::Progress)
                .await
                .is_err()
            {
                break;
            }
        }
    });

    let owner_iid = row.owner_iid;
    let chat_id = row.chat_id;
    let locale = row.locale.clone();
    let req = row.to_req_prompt();
    let req_id_fanout = req_id.clone();
    let nats_fanout = nats.clone();

    let pool_hop = pool.clone();
    let req_id_hop = req_id.clone();
    let cancel_hop = cancel.clone();
    let hooks = PromptTurnHooks {
        skip_billing_gate: true,
        on_hop: Some(Arc::new(move |hop| {
            if hop.fail_class.starts_with("fatal_")
                || matches!(hop.fail_class.as_str(), "fatal_repeat" | "stuck_ui" | "turn_cap")
            {
                cancel_hop.cancel();
            }
            let pool = pool_hop.clone();
            let req_id = req_id_hop.clone();
            let checkpoint = if hop.checkpoint_json.trim().is_empty() || hop.checkpoint_json == "{}" {
                serde_json::json!({
                    "hop": hop.hop,
                    "turn_count": hop.turn_count,
                    "blocks_json": hop.blocks_json,
                    "fail_class": hop.fail_class,
                })
            } else {
                serde_json::from_str(&hop.checkpoint_json).unwrap_or_else(|_| serde_json::json!({
                    "hop": hop.hop,
                    "turn_count": hop.turn_count,
                }))
            };
            tokio::spawn(async move {
                let _ = super::store::prompt_run_checkpoint_save(
                    &pool,
                    &req_id,
                    &checkpoint,
                    hop.turn_count,
                    hop.tokens_in,
                    hop.tokens_out,
                    hop.cost_usd,
                )
                .await;
            });
        })),
    };

    let turn_result = prompt_turn(
        &pool,
        Some(&nats),
        owner_iid,
        &req_id,
        req,
        &locale,
        |thought, d| {
            let nats = nats_fanout.clone();
            let req_id = req_id_fanout.clone();
            tokio::spawn(async move {
                let _ = prompt_run_fanout_delta(
                    &nats,
                    owner_iid,
                    chat_id,
                    &req_id,
                    c35_proto::ResPromptDelta {
                        text: d,
                        thought,
                        blocks_json: String::new(),
                    },
                )
                .await;
            });
        },
        |blocks_json| {
            let nats = nats_fanout.clone();
            let req_id = req_id_fanout.clone();
            tokio::spawn(async move {
                let _ = prompt_run_fanout_delta(
                    &nats,
                    owner_iid,
                    chat_id,
                    &req_id,
                    c35_proto::ResPromptDelta {
                        text: String::new(),
                        thought: false,
                        blocks_json,
                    },
                )
                .await;
            });
        },
        &cancel,
        hooks,
    )
    .await;

    heartbeat.abort();
    cancel_watch.abort();

    if draining.load(Ordering::Relaxed) {
        return Ok(());
    }

    match turn_result {
        Ok(turn) => {
            let _ = prompt_run_finish(
                &pool,
                &req_id,
                "done",
                turn.tokens_in,
                turn.tokens_out,
                turn.cost_usd,
                turn.duration_ms,
                None,
                None,
            )
            .await;
            if let Ok(Some(row)) = prompt_run_get(&pool, &req_id).await {
                let _ = prompt_run_fanout_publish(&nats, owner_iid, chat_id, prompt_run_push_from_row(&row)).await;
            }
            let _ = prompt_run_fanout_end(
                &nats,
                owner_iid,
                chat_id,
                &req_id,
                ResPromptEnd {
                    msg_id: turn.assistant_msg_id,
                    tokens_in: turn.tokens_in,
                    tokens_out: turn.tokens_out,
                    cost_usd: turn.cost_usd,
                    duration_ms: turn.duration_ms,
                    model: turn.model,
                    req_id: req_id.clone(),
                    trace_json: String::new(),
                    error_message: turn.error_text,
                },
            )
            .await;
            c35_mod_billing::billing_notify_owner(&pool, Some(&nats), owner_iid, None).await;
            if let Err(e) = crate::prompt_followup::prompt_followup_start_next_queued(&pool, &nats, &req_id).await {
                tracing::warn!("[c35:prompt_followup] start_next_queued failed req_id={req_id}: {e:#}");
            }
            let _ = acker_mutex.lock().await.ack().await;
        }
        Err(e) => {
            let is_cancel = cancel.is_cancelled() || e.to_string().contains("aborted");
            let err_msg = e.to_string();
            let (status, fail_class, fail_reason) = if is_cancel {
                ("cancelled", "cancel", "user abort".to_string())
            } else {
                ("failed", "transient", err_msg)
            };
            let _ = prompt_run_finish(
                &pool,
                &req_id,
                status,
                0,
                0,
                0.0,
                0,
                Some(fail_class),
                Some(fail_reason.as_str()),
            )
            .await;
            if let Ok(Some(row)) = prompt_run_get(&pool, &req_id).await {
                let _ = prompt_run_fanout_publish(&nats, owner_iid, chat_id, prompt_run_push_from_row(&row)).await;
            }
            let _ = prompt_run_fanout_fail(
                &nats,
                owner_iid,
                chat_id,
                &req_id,
                ResPromptFail {
                    message: fail_reason,
                },
            )
            .await;
            let _ = acker_mutex.lock().await.ack().await;
        }
    }

    Ok(())
    }
    .instrument(span)
    .await
}

pub async fn prompt_run_enqueue(
    nats: &Client,
    job: &PromptRunJob,
) -> Result<()> {
    let js = prompt_jetstream_ensure(nats).await?;
    super::jetstream::prompt_run_job_publish(&js, job).await
}
