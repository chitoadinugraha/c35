use async_nats::Client;
use c35_proto::ReqTaskRunStart;
use futures_util::StreamExt;
use sqlx::{PgPool, Row};
use tracing::{info, warn};

pub fn task_scheduler_start(pool: PgPool, nats: Client) -> tokio::task::JoinHandle<()> {
    tokio::spawn(async move {
        task_scheduler_loop(pool, nats).await;
    })
}

async fn task_scheduler_loop(pool: PgPool, nats: Client) {
    info!("[c35:task_scheduler] starting JetStream schedule consumer on C35_TASK_SCHEDULE filter=c35.task.fire.>");
    let js = async_nats::jetstream::new(nats.clone());
    let stream = match js.get_stream("C35_TASK_SCHEDULE").await {
        Ok(s) => s,
        Err(e) => {
            warn!("[c35:task_scheduler] get_stream C35_TASK_SCHEDULE failed: {e}");
            return;
        }
    };
    let consumer = match stream
        .get_or_create_consumer(
            "c35-task-schedule-consumer",
            async_nats::jetstream::consumer::pull::Config {
                durable_name: Some("c35-task-schedule-consumer".to_string()),
                filter_subject: "c35.task.fire.>".to_string(),
                ack_policy: async_nats::jetstream::consumer::AckPolicy::Explicit,
                ..Default::default()
            },
        )
        .await
    {
        Ok(c) => c,
        Err(e) => {
            warn!("[c35:task_scheduler] get_or_create_consumer failed: {e}");
            return;
        }
    };
    let mut messages = match consumer.messages().await {
        Ok(m) => m,
        Err(e) => {
            warn!("[c35:task_scheduler] consumer.messages failed: {e}");
            return;
        }
    };

    while let Some(msg_res) = messages.next().await {
        let msg = match msg_res {
            Ok(m) => m,
            Err(e) => {
                warn!("[c35:task_scheduler] message fetch error: {e}");
                continue;
            }
        };
        let _ = msg.ack().await;
        let payload: serde_json::Value = match serde_json::from_slice(&msg.payload) {
            Ok(v) => v,
            Err(e) => {
                warn!("[c35:task_scheduler] invalid JSON on {}: {e}", msg.subject);
                continue;
            }
        };

        let trigger_id = payload.get("trigger_id").and_then(|v| v.as_i64()).unwrap_or(0);
        let task_id = payload.get("task_id").and_then(|v| v.as_i64()).unwrap_or(0);
        let owner_iid = payload.get("owner_iid").and_then(|v| v.as_i64()).unwrap_or(0);
        let device_iid = payload.get("device_iid").and_then(|v| v.as_i64()).unwrap_or(0);

        if trigger_id == 0 || task_id == 0 || owner_iid == 0 {
            warn!("[c35:task_scheduler] missing fields in schedule fire: {payload}");
            continue;
        }

        info!(trigger_id, task_id, owner_iid, device_iid, "[c35:task_scheduler] schedule fired");

        // Lookup task & trigger state in DB
        let check = sqlx::query(
            r#"
            SELECT t.id AS task_id, t.owner_iid, COALESCE(t.device_iid, 0) AS device_iid,
                   t.prompt, t.skill_id, t.model, t.is_active AS task_active,
                   tt.id AS trigger_id, tt.kind, tt.is_active AS trigger_active
            FROM ai.task t
            JOIN ai.task_trigger tt ON tt.task_id = t.id
            WHERE tt.id = $1 AND t.deleted_ts IS NULL AND tt.deleted_ts IS NULL
            "#,
        )
        .bind(trigger_id)
        .fetch_optional(&pool)
        .await;

        let row = match check {
            Ok(Some(r)) => r,
            Ok(None) => {
                info!(trigger_id, "[c35:task_scheduler] trigger or task deleted/inactive, skipping");
                continue;
            }
            Err(e) => {
                warn!("[c35:task_scheduler] DB query error: {e}");
                continue;
            }
        };

        let task_active: bool = row.get("task_active");
        let trigger_active: bool = row.get("trigger_active");
        if !task_active || !trigger_active {
            info!(trigger_id, task_active, trigger_active, "[c35:task_scheduler] task/trigger inactive, skipping");
            continue;
        }

        let target_device_iid: i64 = if device_iid > 0 { device_iid } else { row.get("device_iid") };
        let prompt: String = row.get("prompt");
        let skill_id: i64 = row.get("skill_id");
        let model: String = row.get("model");
        let kind: String = row.get("kind");

        let req = ReqTaskRunStart {
            device_iid: target_device_iid,
            task_id,
            prompt,
            skill_id,
            model,
            chat_id: 0,
            req_id: format!("sched.{}.{}", trigger_id, c35_store::snowflake_id()),
        };

        match crate::rpc::task_run_start_rpc(&pool, Some(&nats), owner_iid, req).await {
            Ok(res) => {
                if let Some(run) = res.run {
                    info!(run_id = run.id, trigger_id, "[c35:task_scheduler] task run started");
                }
            }
            Err(e) => {
                warn!(trigger_id, error = %e, "[c35:task_scheduler] task_run_start failed");
            }
        }

        if kind == "once" {
            let _ = sqlx::query("UPDATE ai.task_trigger SET is_active = FALSE, updated_ts = NOW() WHERE id = $1")
                .bind(trigger_id)
                .execute(&pool)
                .await;
        }
    }
}
