use async_nats::jetstream::context::Publish;
use async_nats::Client;
use c35_proto::PromptRunJob;
use sqlx::PgPool;

use super::jetstream::{prompt_jetstream_ensure, SUBJECT_WORK};
use super::store::prompt_run_list_queued;

pub async fn prompt_run_hydrate_replay(client: &Client, pool: &PgPool) -> anyhow::Result<u32> {
    let queued = prompt_run_list_queued(pool).await?;
    if queued.is_empty() {
        return Ok(0);
    }
    let js = prompt_jetstream_ensure(client).await?;
    let mut count = 0u32;
    for (req_id, owner_iid, chat_id) in queued {
        let job = PromptRunJob {
            req_id: req_id.clone(),
            owner_iid,
            chat_id,
        };
        let payload = serde_json::json!({
            "req_id": job.req_id,
            "owner_iid": job.owner_iid,
            "chat_id": job.chat_id,
        });
        js.send_publish(
            SUBJECT_WORK,
            Publish::build()
                .payload(serde_json::to_vec(&payload)?.into())
                .message_id(&req_id),
        )
        .await?
        .await?;
        count += 1;
    }
    Ok(count)
}
