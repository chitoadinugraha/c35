use anyhow::Context as _;
use async_nats::jetstream::{self, stream::RetentionPolicy};
use async_nats::Client;

pub const STREAM_CHAT_PROMPT: &str = "C35_CHAT_PROMPT";
pub const SUBJECT_CHAT_PROMPT: &str = "c35.prompt.run";

pub const STREAM_TASK_SCHEDULE: &str = "C35_TASK_SCHEDULE";
pub const SUBJECT_TASK_SCHEDULE: &str = "c35.schedule.task.>";
pub const SUBJECT_TASK_FIRE: &str = "c35.task.fire.>";

pub const STREAM_NOTIFY_SCHEDULE: &str = "C35_NOTIFY_SCHEDULE";
pub const SUBJECT_NOTIFY_SCHEDULE: &str = "c35.schedule.notify.>";
pub const SUBJECT_NOTIFY_FIRE: &str = "c35.notify.fire.>";

pub const STREAM_DEVICE_TASK: &str = "C35_DEVICE_TASK";
pub const SUBJECT_DEVICE_TASK: &str = "c35.act.device.*.task.run";

pub async fn jetstream_streams_ensure(client: &Client) -> anyhow::Result<()> {
    crate::stats_kv::stats_kv_ensure(client)
        .await
        .context("c35_stats KV")?;
    let js = jetstream::new(client.clone());
    js.get_or_create_stream(jetstream::stream::Config {
        name: STREAM_CHAT_PROMPT.into(),
        subjects: vec![SUBJECT_CHAT_PROMPT.into()],
        retention: RetentionPolicy::WorkQueue,
        ..Default::default()
    })
    .await
    .context("C35_CHAT_PROMPT")?;

    task_schedule_stream_ensure(&js).await?;
    notify_schedule_stream_ensure(&js).await?;

    js.get_or_create_stream(jetstream::stream::Config {
        name: STREAM_DEVICE_TASK.into(),
        subjects: vec![SUBJECT_DEVICE_TASK.into()],
        retention: RetentionPolicy::WorkQueue,
        ..Default::default()
    })
    .await
    .context("C35_DEVICE_TASK")?;

    Ok(())
}

async fn task_schedule_stream_ensure(js: &jetstream::Context) -> anyhow::Result<()> {
    js.get_or_create_stream(jetstream::stream::Config {
        name: STREAM_TASK_SCHEDULE.into(),
        subjects: vec![SUBJECT_TASK_SCHEDULE.into(), SUBJECT_TASK_FIRE.into()],
        ..Default::default()
    })
    .await
    .context("C35_TASK_SCHEDULE")?;
    Ok(())
}

async fn notify_schedule_stream_ensure(js: &jetstream::Context) -> anyhow::Result<()> {
    js.get_or_create_stream(jetstream::stream::Config {
        name: STREAM_NOTIFY_SCHEDULE.into(),
        subjects: vec![SUBJECT_NOTIFY_SCHEDULE.into(), SUBJECT_NOTIFY_FIRE.into()],
        ..Default::default()
    })
    .await
    .context("C35_NOTIFY_SCHEDULE")?;
    Ok(())
}
