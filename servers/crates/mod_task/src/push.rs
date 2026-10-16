use async_nats::Client;
use c35_proto::{pb_encode, TaskRun, TaskRunPush};
use tracing::warn;

pub fn task_run_push(nats: Option<&Client>, owner_iid: i64, run: &TaskRun) {
    if let Some(nc) = nats {
        let push = TaskRunPush { run: Some(run.clone()) };
        let subject = c35_nats::user_app_subject_task_run(owner_iid);
        let bytes = pb_encode(&push).into();
        let nc = nc.clone();
        tokio::spawn(async move {
            if let Err(e) = nc.publish(subject, bytes).await {
                warn!("task_run_push: {e}");
            }
        });
    }
}
