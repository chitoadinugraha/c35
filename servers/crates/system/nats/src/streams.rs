use anyhow::Context as _;
use async_nats::jetstream::{self, response::Response, stream::RetentionPolicy};
use async_nats::Client;

pub const STREAM_CHAT_PROMPT: &str = "C35_CHAT_PROMPT";
pub const SUBJECT_CHAT_PROMPT: &str = "c35.prompt.run";

pub const STREAM_TASK_SCHEDULE: &str = "C35_TASK_SCHEDULE";
pub const SUBJECT_TASK_SCHEDULE: &str = "c35.schedule.task.>";
pub const SUBJECT_TASK_FIRE: &str = "c35.task.fire.>";

pub const STREAM_DEVICE_TASK: &str = "C35_DEVICE_TASK";
pub const SUBJECT_DEVICE_TASK: &str = "c35.act.device.*.task.run";

pub async fn jetstream_streams_ensure(client: &Client) -> anyhow::Result<()> {
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
    let config = serde_json::json!({
        "name": STREAM_TASK_SCHEDULE,
        "subjects": [SUBJECT_TASK_SCHEDULE, SUBJECT_TASK_FIRE],
        "allow_msg_schedules": true,
        "allow_msg_ttl": true,
    });
    let create_subject = format!("STREAM.CREATE.{}", STREAM_TASK_SCHEDULE);
    let resp: Response<serde_json::Value> = js.request(create_subject, &config).await?;
    if matches!(resp, Response::Err { .. }) {
        let update_subject = format!("STREAM.UPDATE.{}", STREAM_TASK_SCHEDULE);
        let resp: Response<serde_json::Value> = js.request(update_subject, &config).await?;
        if let Response::Err { error } = resp {
            anyhow::bail!("{} update failed: {}", STREAM_TASK_SCHEDULE, error);
        }
    }
    Ok(())
}
