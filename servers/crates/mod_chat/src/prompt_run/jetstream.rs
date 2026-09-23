use anyhow::Result;
use async_nats::Client;
use async_nats::jetstream::{self, consumer::AckPolicy, stream::RetentionPolicy};
use async_nats::jetstream::consumer::pull;
use c35_proto::PromptRunJob;
use std::time::Duration;

pub const STREAM_NAME: &str = "C35_CHAT_PROMPT";
pub const SUBJECT_WORK: &str = "c35.prompt.run";
pub const CONSUMER_NAME: &str = "c35-prompt-dispatch";
pub const QUEUE_GROUP: &str = "c35-prompt-dispatch";

pub async fn prompt_jetstream_ensure(client: &Client) -> Result<jetstream::Context> {
    let js = jetstream::new(client.clone());
    js.get_or_create_stream(jetstream::stream::Config {
        name: STREAM_NAME.into(),
        subjects: vec![SUBJECT_WORK.into()],
        retention: RetentionPolicy::WorkQueue,
        ..Default::default()
    })
    .await?;
    Ok(js)
}

pub async fn prompt_jetstream_consumer(js: &jetstream::Context) -> Result<jetstream::consumer::Consumer<pull::Config>> {
    let stream = js.get_stream(STREAM_NAME).await?;
    let consumer = stream
        .get_or_create_consumer(
            CONSUMER_NAME,
            pull::Config {
                durable_name: Some(CONSUMER_NAME.into()),
                ack_policy: AckPolicy::Explicit,
                ack_wait: Duration::from_secs(60),
                max_deliver: super::checkpoint::PROMPT_RUN_MAX_DELIVER as i64,
                ..Default::default()
            },
        )
        .await?;
    Ok(consumer)
}

pub async fn prompt_run_job_publish(js: &jetstream::Context, job: &PromptRunJob) -> Result<()> {
    let payload = serde_json::json!({
        "req_id": job.req_id,
        "owner_iid": job.owner_iid,
        "chat_id": job.chat_id,
    });
    js.publish(SUBJECT_WORK, serde_json::to_vec(&payload)?.into())
        .await?;
    Ok(())
}
