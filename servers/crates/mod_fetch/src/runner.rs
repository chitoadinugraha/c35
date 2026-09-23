use std::time::{Duration, Instant};

use anyhow::Result;
use async_trait::async_trait;
use prost::Message;
use tracing::{info, warn};

use crate::FetchCtx;

pub struct FetchOutcome {
    pub changed: bool,
    pub nats_subject: Option<&'static str>,
    pub nats_payload: Option<Vec<u8>>,
}

#[async_trait]
pub trait FetchTask: Send + Sync {
    fn name(&self) -> &'static str;
    fn interval(&self) -> Duration;
    async fn run(&self, ctx: &FetchCtx) -> Result<FetchOutcome>;
}

pub async fn fetcher_run(ctx: FetchCtx, tasks: Vec<Box<dyn FetchTask>>) -> ! {
    for task in tasks {
        let ctx = FetchCtx {
            pool: ctx.pool.clone(),
            nats: ctx.nats.clone(),
            http: ctx.http.clone(),
        };
        tokio::spawn(async move {
            run_task_loop(ctx, task).await;
        });
    }
    loop {
        tokio::time::sleep(Duration::from_secs(86_400)).await;
    }
}

async fn run_task_loop(ctx: FetchCtx, task: Box<dyn FetchTask>) {
    let name = task.name();
    let interval = task.interval();
    if let Err(e) = run_once(&ctx, task.as_ref(), name).await {
        warn!(task = name, error = %e, "fetch task initial run failed");
    }
    let mut tick = tokio::time::interval(interval);
    tick.tick().await;
    loop {
        tick.tick().await;
        if let Err(e) = run_once(&ctx, task.as_ref(), name).await {
            warn!(task = name, error = %e, "fetch task run failed");
        }
    }
}

async fn run_once(ctx: &FetchCtx, task: &dyn FetchTask, name: &'static str) -> Result<()> {
    let t0 = Instant::now();
    let outcome = task.run(ctx).await?;
    let ms = t0.elapsed().as_millis();
    if outcome.changed {
        if let (Some(subject), Some(payload)) = (outcome.nats_subject, outcome.nats_payload) {
            ctx.nats.publish(subject, payload.into()).await?;
            info!(task = name, subject, duration_ms = ms, "fetch published");
        } else {
            info!(task = name, duration_ms = ms, "fetch changed (no nats)");
        }
    } else {
        info!(task = name, duration_ms = ms, changed = false, "fetch skipped");
    }
    Ok(())
}

pub fn encode_push<M: Message>(msg: &M) -> Vec<u8> {
    msg.encode_to_vec()
}
